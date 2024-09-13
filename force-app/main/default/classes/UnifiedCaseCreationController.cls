/**
 * @description Controller for the Lightning Web Component `UnifiedCaseCreation`
 *				This controller manages the creation of case including appropriate error handling and query related data for the LWC
 * @author: Marcel HK
 * @tag Case, ImpactedArticle__c
 * @domain Core
 * @changelog:
 * 2024-08-21 - Marcel HK - Created
 * 2024-09-02 - Seth Heang - added wrapper class and case creation methods
*/
public with sharing class UnifiedCaseCreationController {
	@TestVisible
	private static final String GENERIC_ERROR_MESSAGE = 'An unexpected error has occurred. Please check the data you\'ve entered and try again. If this error persists, please inform your manager.';
	@TestVisible
	private static final String GENERAL_ENQUIRY_TYPE = 'General Enquiry';
	@TestVisible
	private static final String INVESTIGATION_ENQUIRY_TYPE = 'Investigation';
	@TestVisible
	private static final String UNCLEAR_EDD_ROOT_CAUSE = 'Unclear EDD';
	@TestVisible
	private static final String CLOSED_TRACKING_ONLY_RESOLUTION_CODE = 'Closed - Tracking only';

	/**
	 * @description This method is used to get the Record Type Ids for the selected Record Type Names.
	 * 				It was created out of necessity due to the `lightning/uiObjectInfoApi.getObjectInfo` method not
	 * 				including the Developer Name in the `recordTypeInfos` data.
	 *
	 * @param developerNames - List of Case Record Types
	 * @return Map<String, Object> - Map of record types similar to the `getObjectInfo` response.
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> getCaseRecordTypeInfos(List<String> developerNames) {
		try {
			if (developerNames == null || developerNames.isEmpty()) {
				AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
				ae.setMessage(GENERIC_ERROR_MESSAGE);
				throw ae;
			}

			Map<String, Object> recordTypeInfos = new Map<String, Object>();
			for (Schema.RecordTypeInfo info : Case.getSObjectType().getDescribe().getRecordTypeInfos()) {
				if (developerNames.contains(info.getDeveloperName())) {
					Map<String, Object> data = new Map<String, Object>();
					data.put('available', info.available);
					data.put('defaultRecordTypeMapping', info.defaultRecordTypeMapping);
					data.put('developerName', info.getDeveloperName());
					data.put('master', info.master);
					data.put('name', info.getName());
					data.put('recordTypeId', info.getRecordTypeId());
					recordTypeInfos.put(info.getRecordTypeId(), data);
				}
			}
			return recordTypeInfos;
		} catch (AuraHandledException ex) {
			AuraHandledException ae = new AuraHandledException(ex.getMessage());
			ae.setMessage(ex.getMessage());
			throw ae;
		} catch (Exception ex) {
			AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
			ae.setMessage(GENERIC_ERROR_MESSAGE);
			throw ae;
		}
	}

	/**
	 * @description Create Case with either 'UnifiedInvestigation' or 'UnifiedGeneralEnquiry' type from LWC form inputs
	 *			Also, create ImpactedArticle__c and link to case and article
	 * @param request LWC form inputs
	 *
	 * @return Case Id
	 */
	@AuraEnabled
	public static Id createNewCase(CaseCreationRequest request) {
		try {
			Set<String> impactedArticleNames = new Set<String>(request.impactedArticles);
			List<Article__c> articles = ArticlesSelector.newInstance().selectByConsignmentIdAndChildArticles(
					new Set<Id> { request.consignmentId },
					impactedArticleNames
			).values();

			// additional check for existing articles where the article count is mismatch due to duplicate in the system
			if(impactedArticleNames.size() != articles.size()){
				AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
				ae.setMessage(GENERIC_ERROR_MESSAGE);
				throw ae;
			}

			Id caseId = insertNewCaseRecord(request);
			createImpactedArticles(
					caseId,
					articles
			);
			return caseId;
		} catch (AuraHandledException ex) {
			AuraHandledException ae = new AuraHandledException(ex.getMessage());
			ae.setMessage(ex.getMessage());
			throw ae;
		} catch (DmlException ex){
			String updatedErrorMessage;
			if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				updatedErrorMessage = ex.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
			}else {
				updatedErrorMessage = ex.getMessage();
			}
			AuraHandledException ae = new AuraHandledException(updatedErrorMessage);
			ae.setMessage(updatedErrorMessage);
			throw ae;
		}
		catch (Exception ex) {
			AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
			ae.setMessage(GENERIC_ERROR_MESSAGE);
			throw ae;
		}
	}

	/**
	 * @description Populate case attributes mapping and insert a new case
	 * @param req LWC form input
	 *
	 * @return Case Id
	 */
	private static Id insertNewCaseRecord(CaseCreationRequest req) {
		Case newCase;
		if (isUnifiedGeneralEnquiryCase(req.enquiryType)) {
			newCase = buildGeneralEnquiryCaseAttributes(req);
		} else if (isUnifiedInvestigationCase(req.enquiryType)){
			newCase = buildInvestigationCaseAttributes(req);
		}
		if (newCase != null){
			ApplicationDatabase.getInstance().dmlInsert(new List<Case>{
					newCase
			});
		}
		return newCase.Id;
	}

	/**
	 * @description Check case's enquiry type if it is 'General Enquiry' case
	 * @param enquiryType LWC form input
	 *
	 * @return Boolean
	 */
	private static Boolean isUnifiedGeneralEnquiryCase(String enquiryType){
		return enquiryType == GENERAL_ENQUIRY_TYPE;
	}

	/**
	 * @description Check case's enquiry type if it is 'Investigation' case
	 * @param enquiryType LWC form input
	 *
	 * @return Boolean
	 */
	private static Boolean isUnifiedInvestigationCase(String enquiryType){
		return enquiryType == INVESTIGATION_ENQUIRY_TYPE;
	}

	/**
	 * @description build attributes mapping for 'UnifiedInvestigation' case
	 * @param req LWC form inputs
	 *
	 * @return Case
	 */
	@TestVisible
	private static Case buildInvestigationCaseAttributes(CaseCreationRequest req) {
		Case newCase = new Case();
		newCase = buildCommonFieldsAttributes(req);
		newCase.Status = APT_Constants.CASE_STATUS_NEW;
		newCase.RecordTypeId = req.recordTypeId;
		return newCase;
	}

	/**
	 * @description build attributes mapping for 'UnifiedGeneralEnquiry' case
	 * @param req LWC form inputs
	 *
	 * @return Case
	 */
	@TestVisible
	private static Case buildGeneralEnquiryCaseAttributes(CaseCreationRequest req) {
		Case newCase = new Case();
		newCase = buildCommonFieldsAttributes(req);
		newCase.Status = APT_Constants.CLOSED;
		newCase.Root_cause__c = UNCLEAR_EDD_ROOT_CAUSE;
		newCase.ResolutionCode__c = CLOSED_TRACKING_ONLY_RESOLUTION_CODE;
		newCase.RecordTypeId = req.recordTypeId;
		return newCase;
	}

	/**
	 * @description build common attributes mapping for case regardless of record types
	 * @param req LWC form inputs
	 *
	 * @return Case
	 */
	private static Case buildCommonFieldsAttributes(CaseCreationRequest req) {
		Case newCase = new Case();
		newCase.ArticleTest__c = req.consignmentId;
		newCase.Type = req.enquiryType;
		newCase.EnquirySubType__c = req.enquirySubType;
		newCase.ProductCategory__c = req.productCategory;
		newCase.ProductSubCategory__c = req.productSubCategory;
		newCase.Priority = StarTrack_Constants.PRIORITY_NORMAL;
		newCase.Recent_Caller_Type__c = StarTrack_Constants.CASE_CONTYPE_RECEIVER;
		newCase.OwnerId = UserInfo.getUserId();
		newCase.ContactId = req.contactId;
		newCase.Description = req.notes;
		return newCase;
	}

	/**
	 * @description Create ImpactedArticle__c and link to case and article
	 * @param caseId
	 * @param impactedArticles
	 */
	private static void createImpactedArticles(Id caseId, List<Article__c> impactedArticles) {
		List<ImpactedArticle__c> insertImpactArticles = new List<ImpactedArticle__c>();
		for (Article__c article : impactedArticles) {
			insertImpactArticles.add(
					new ImpactedArticle__c(
							Name = article.ArticleID__c,
							Case__c = caseId,
							Article__c = article.Id
					)
			);
		}
		if (!insertImpactArticles.isEmpty()){
			ApplicationDatabase.getInstance().dmlInsert(insertImpactArticles);
		}
	}

	/**
	 * @description A wrapper class used to receive inputs from the Case creation form in LWC
	 */
	public class CaseCreationRequest {
		@AuraEnabled
		public List<String> impactedArticles { get; set; }

		@AuraEnabled
		public Id contactId { get; set; }

		@AuraEnabled
		public String enquiryType { get; set; }

		@AuraEnabled
		public String enquirySubType { get; set; }

		@AuraEnabled
		public String productCategory { get; set; }

		@AuraEnabled
		public String productSubCategory { get; set; }

		@AuraEnabled
		public String notes { get; set; }

		@AuraEnabled
		public String recordTypeId { get; set; }

		@AuraEnabled
		public String consignmentId { get; set; }
	}
}