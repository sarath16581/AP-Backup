/**
 * @description Controller for the Lightning Web Component `UnifiedCaseHistory`. This controller retreives
 * and returns Cases which are related to either a Consignment/Article, or a Contact.
 *
 * @changelog
 * 2024-09-11 - Marcel HK - Created
 * 2024-09-12 - Seth Heang - added method getCountForDuplicatedCasesRelatedToArticle()
 */
public with sharing class UnifiedCaseHistoryController {
	// Case Record Types
	public static final String CLASSIC_GENERAL_ENQUIRY_CASE_RT = 'GeneralEnquiry';
	public static final String UNIFIED_GENERAL_ENQUIRY_CASE_RT = 'UnifiedGeneralEnquiry';
	public static final String UNIFIED_INVESTIGATION_CASE_RT = 'UnifiedInvestigation';

	// Case Types
	public static final String GENERAL_ENQUIRY_TYPE = 'General Enquiry';
	public static final String INVESTIGATION_TYPE = 'Investigation';

	private static final Set<SObjectField> FIELD_OVERRIDES = new Set<SObjectField>{
		Case.Id,
		Case.CaseNumber,
		Case.IsClosed,
		Case.Status,
		Case.Subject,
		Case.Type,
		Case.LastModifiedDate,
		Case.ContactId,
		Case.ArticleTest__c,
		Case.ReferenceID__c
	};

	private static final Set<Object> SELECTOR_OPTIONS = new Set<Object>{ CasesSelector.Options.WITH_RECORDTYPE };

	/**
	 * @description Retreives all of the Cases related to the specified `articleId`.
	 *
	 * This includes any Cases which are related to any child article of a consignment, or sibling articles.
	 *
	 * @param articleId - The Salesforce 18 digit Id for an `Article__c` record
	 * @param maxRecords - The maximum number of records to retreive
	 */
	@AuraEnabled(cacheable=true)
	public static CaseHistoryResponse getCasesRelatedToArticle(Id articleId, Integer maxRecords) {
		try {
			if (String.isBlank(articleId)) {
				return new CaseHistoryResponse();
			}

			// Need to grab the consignment's tracking number first, since it is used to query for related articles
			String consignmentTrackingNumber = getConsignmentTrackingNumber(articleId);

			// Query records with LIMIT +1 to check if there are more records not being returned
			CasesSelector selector = CasesSelector.newInstance(maxRecords + 1, FIELD_OVERRIDES);
			Map<Id, Case> casesMap = selector.selectByConsignmentTrackingNumberCaseHistory(new Set<String>{ consignmentTrackingNumber }, SELECTOR_OPTIONS);

			// Process the results and ensure the only the max records specified are returned
			CaseHistoryResponse response = processResults(casesMap.values(), maxRecords, true);

			return response;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description Retrieve count existing cases with specified criteria, used to prevent potential duplicate by blocking new case creation
	 * @param consignmentTrackingNumber
	 *
	 * @return Integer Count of existing cases
	 */
	@AuraEnabled(Cacheable=true)
	public static Integer getCountForDuplicatedCasesRelatedToArticle(String consignmentTrackingNumber) {
		return getDuplicatedCasesRelatedToArticle(consignmentTrackingNumber).size();
	}

	/**
	 * @description Retrieve existing cases with specified criteria, used to prevent potential duplicate by blocking new case creation
	 * @param consignmentTrackingNumber
	 *
	 * @return List<Case> existing cases
	 */
	public static List<Case> getDuplicatedCasesRelatedToArticle(String consignmentTrackingNumber) {
		try {
			if (String.isBlank(consignmentTrackingNumber)) {
				return new List<Case>();
			}
			CasesSelector selector = CasesSelector.newInstance(FIELD_OVERRIDES);
			Map<Id, Case> casesMap = selector.selectByConsignmentTrackingNumberCaseHistory(new Set<String>{ consignmentTrackingNumber }, SELECTOR_OPTIONS);
			List<Case> dupCases = new List<Case>();
			for (Case relatedCase : casesMap.values()) {
				if (isDuplicatedCase(relatedCase)) {
					dupCases.add(relatedCase);
				}
			}
			return dupCases;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description Retreives all of the Cases related to the specified `contactId`.
	 *
	 * @param articleId - The Salesforce 18 digit Id for an `Article__c` record
	 * @param maxRecords - The maximum number of records to retreive
	 */
	@AuraEnabled(cacheable=true)
	public static CaseHistoryResponse getCasesRelatedToContact(Id contactId, Integer maxRecords) {
		try {
			if (String.isBlank(contactId)) {
				return new CaseHistoryResponse();
			}

			// Query records with LIMIT +1 to check if there are more records not being returned
			CasesSelector selector = CasesSelector.newInstance(maxRecords + 1, FIELD_OVERRIDES);
			Map<Id, Case> casesMap = selector.selectByContactIdCaseHistory(new Set<Id>{ contactId }, SELECTOR_OPTIONS);

			// Process the results and ensure the only the max records specified are returned
			return processResults(casesMap.values(), maxRecords, false);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description Get the Consignment Tracking Number for the `Article__c` SObject record.
	 * @param articleId - The Salesforce 18-digit Id of the `Article__c` record.
	 *
	 * @return the Consignment Tracking Number
	 */
	@TestVisible
	private static String getConsignmentTrackingNumber(Id articleId) {
		// Select the specified Article
		Article__c article = ArticlesSelector.newInstance(1, new Set<SObjectField>{ Article__c.ArticleID__c, Article__c.ConsignmentTrackingNumber__c }).selectById(new Set<Id>{ articleId }).get(articleId);

		// Get the Consignment Tracking Number
		String consignmentTrackingNumber;
		if (String.isNotBlank(article.ConsignmentTrackingNumber__c)) {
			// Article is a child of a consignment
			consignmentTrackingNumber = article.ConsignmentTrackingNumber__c;
		} else {
			// Article is the consignment
			consignmentTrackingNumber = article.ArticleID__c;
		}

		if (String.isBlank(consignmentTrackingNumber)) {
			throw new UnifiedCaseHistoryControllerException('Cannot find the Consignment Tracking Number');
		}

		return consignmentTrackingNumber;
	}

	/**
	 * @description Creates a `CaseHistoryResponse` object by processing each Case record and converting
	 * into a `CaseHistoryResult` object and added to the `results` property. If there are more results
	 * than the max specified, the property `hasMore` will be set to `true`.
	 *
	 * Note: For the `hasMore` property to be set correctly, there must be more records passed into this
	 * method than the defined `maxRecords` parameter.
	 *
	 * @param cases - List of Cases SObject records
	 * @param maxRecords - The maximum number of records to return
	 * @param allowLinking - Allows setting `isLinkable` based on busienss rules
	 */
	@TestVisible
	private static CaseHistoryResponse processResults(List<Case> cases, Integer maxRecords, Boolean allowLinking) {
		CaseHistoryResponse response = new CaseHistoryResponse();
		response.results = new List<CaseHistoryResult>();

		// Indicate if the number of records returned exceed the `maxRecords` parameter
		response.hasMore = cases.size() > maxRecords;

		// Map each Case record to the result object (up until the maxRecords limit reached)
		for (Integer i = 0; i < (Math.min(cases.size(), maxRecords)); i++) {
			Case caseRecord = cases.get(i);
			CaseHistoryResult result = new CaseHistoryResult();
			result.caseId = caseRecord.Id;
			result.caseNumber = caseRecord.CaseNumber;
			result.contactId = caseRecord.ContactId;
			result.isClosed = caseRecord.IsClosed;
			result.isUnifiedCase = CommonUtils.isUnifiedCase(caseRecord.RecordType.DeveloperName);
			result.lastModifiedDate = caseRecord.LastModifiedDate;
			result.recordTypeDeveloperName = caseRecord.RecordType.DeveloperName;
			result.referenceId = caseRecord.ReferenceID__c;
			result.status = caseRecord.Status;
			result.subject = caseRecord.Subject;
			result.type = caseRecord.Type;

			// Set `isLinkable` property on the results per business rules
			if (allowLinking == true) {
				if (isOpenedUnifiedCase(caseRecord)) {
					// Allow allow linking 'Unified' Cases which are 'Open'
					result.isLinkable = true;
				} else if (isUnifiedGeneralEnquiryRecordTypeCase(caseRecord)) {
					// Allow linking 'Unified General Enquiry' Cases, even if they're closed
					result.isLinkable = true;
				}
			}

			response.results.add(result);
		}

		return response;
	}

	/**
	 * @description check if case is unified general enquiry record type
	 * @param caseRecord
	 *
	 * @return Boolean
	 */
	private static Boolean isUnifiedGeneralEnquiryRecordTypeCase(Case caseRecord) {
		return caseRecord.RecordType.DeveloperName == UNIFIED_GENERAL_ENQUIRY_CASE_RT;
	}

	/**
	 * @description check if case is an opened unified record type
	 * @param caseRecord
	 *
	 * @return Boolean
	 */
	private static Boolean isOpenedUnifiedCase(Case caseRecord) {
		return CommonUtils.isUnifiedCase(caseRecord.RecordType.DeveloperName) && caseRecord.IsClosed == false;
	}

	/**
	 * @description check if case is an opened classic or unified case where type = investigation
	 * @param caseRecord
	 *
	 * @return Boolean
	 */
	private static Boolean isOpenedClassicORUnifiedInvestigationCase(Case caseRecord) {
		return caseRecord.Type.equals(INVESTIGATION_TYPE) && caseRecord.IsClosed == false;
	}

	/**
	 * @description check if there is an existing case with specified criteria, used to prevent potential duplicate by blocking new case creation
	 * @param caseRecord
	 *
	 * @return Boolean
	 */
	private static Boolean isDuplicatedCase(Case caseRecord) {
		return isUnifiedGeneralEnquiryRecordTypeCase(caseRecord) || (isOpenedClassicORUnifiedInvestigationCase(caseRecord));
	}

	/**
	 * @description Wrapper class for the response send to the LWC.
	 */
	public class CaseHistoryResponse {
		@AuraEnabled
		public List<CaseHistoryResult> results;

		@AuraEnabled
		public Boolean hasMore;

		public CaseHistoryResponse() {
			this.results = new List<CaseHistoryResult>();
			this.hasMore = false;
		}
	}

	/**
	 * @description Wrapper class for each case record on the response.
	 */
	public class CaseHistoryResult {
		@AuraEnabled
		public Id caseId;

		@AuraEnabled
		public String caseNumber;
		
		@AuraEnabled
		public Id contactId;

		@AuraEnabled
		public Boolean isClosed;

		@AuraEnabled
		public Boolean isLinkable = false;

		@AuraEnabled
		public Boolean isUnifiedCase;

		@AuraEnabled
		public DateTime lastModifiedDate;

		@AuraEnabled
		public String recordTypeDeveloperName;

		@AuraEnabled
		public String referenceId;

		@AuraEnabled
		public String status;

		@AuraEnabled
		public String subject;

		@AuraEnabled
		public String type;
	}

	/**
	 * @description Generic exception class for this controller.
	 */
	public class UnifiedCaseHistoryControllerException extends Exception {
	}
}