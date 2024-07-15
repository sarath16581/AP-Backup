/**
 * @description This is called from quick action to hand-off cases from Unified team to Classic team
 * @author Vasu Gorakati
 * @date 2024-06-18
 * @changelog
 * 2024-06-18 - Vasu Gorakati - Case Hand-off
 **/
public with sharing class CaseHandOffController {
	private static final String AUSTRALIAPOST = 'AustraliaPost';
	private static final String STARTRACK = 'StarTrack';
	private static final String RECORDTYPEID = 'RecordTypeId';
	private static StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
	private static AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture continuationState = null;

	/**
	 * Returns business unit
	 * @param  Article product id
	 */
	@AuraEnabled(cacheable=true)
	public static String getBusinessUnit(String productId) {
		List<String> starTracKProducts = new List<String>();

		for (StarTrackConsignmentProductIDs__c stProduct : StarTrackConsignmentProductIDs__c.getAll().Values()) {
			starTracKProducts.add(stProduct.Name);
		}

		return starTracKProducts.contains(productId) ? STARTRACK : AUSTRALIAPOST;
	}

	/**
	 * Method to process Hand-off case to classic team
	 * @param  caseDetails - case record
	 * @param  comment - additinal comments to specify hand-off details
	 * @param  businessUnit - business unit
	 * @param  contactCenter - contact center (queue name)
	 * @param  caseRecordType - case Record Type
	 */
	@AuraEnabled
	public static void handOffCase(CaseHandOffWrapper handoffWrapper) {
		Set<SObjectField> fields = new Set<SObjectField>{
			Case.Id,
			Case.Address3__c,
			Case.Address3Country__c,
			Case.Address3Line2__c,
			Case.Address3Postcode__c,
			Case.Address3State__c,
			Case.Address3Suburb__c,
			Case.Address4__c,
			Case.Address4Country__c,
			Case.Address4Line2__c,
			Case.Address4Postcode__c,
			Case.Address4State__c,
			Case.Address4Suburb__c,
			Case.ArticleTest__c,
			Case.ContactId,
			Case.CaseNumber,
			Case.Contact.AccountId,
			Case.CaseOriginator__c,
			Case.CaseTransferDate__c,
			Case.CHASEnquiryType__c,
			Case.CaseTransferReason__c,
			Case.EnquirySubType__c,
			Case.EntitlementId,
			Case.ProductCategory__c,
			Case.ProductSubCategory__c,
			Case.Subject,
			Case.Status,
			Case.Type,
			Case.ReferenceID__c,
			Case.Recent_Caller_Type__c,
			Case.Notification_Required__c,
			Case.Origin
		};

		Case caseDetails = CasesSelector.newInstance(fields).selectById(new Set<Id>{ handoffWrapper.caseId }, new Set<Object>{ CasesSelector.Options.WITH_CONTACT }).values();
		// Set case transfer details}
		casedetails.CaseTransferDate__c = DateTime.Now();
		casedetails.CaseTransferReason__c = handoffWrapper.handoffReason;

		// Set traige queue as owner
		GroupsSelector groupsSelector = GroupsSelector.newInstance();
		Map<Id, Group> queueMap = groupsSelector.selectByGroupTypeAndDeveloperName(new Set<String>{ 'Queue' }, new Set<String>{ handoffWrapper.contactCenter });

		if (!queueMap.isEmpty()) {
			casedetails.OwnerId = queueMap.keySet().iterator().next();
		}

		ImpactedArticlesSelector impactedArticlesSelector = ImpactedArticlesSelector.newInstance();
		List<ImpactedArticle__c> impactedArticles = impactedArticlesSelector.selectByCaseId(new Set<Id>{ casedetails.Id }, new Set<Object>());

		if (handoffWrapper.businessUnit == AUSTRALIAPOST) {
			casedetails.EntitlementId = getSSSWEntitlementId();

			//Single consigment article so assign impacted article to case
			if (impactedArticles.size() == 1) {
				caseDetails.ArticleTest__c = impactedArticles[0].Article__c;
				caseDetails.ReferenceID__c = impactedArticles[0].ArticleId__c;
			}
		} else {
			caseDetails.ArticleTest__c = handoffWrapper.articleId;
		}

		CaseHandOffMappingWrapper fieldMappingwrapper = getCaseHandOffMappings(handoffWrapper.businessUnit, handoffWrapper.caseRecordType);

		// Loop through the mappings and update case details
		for (CaseHandOffMappingWrapper.FieldMapping mapping : fieldMappingwrapper.mappings) {
			String unifiedField = mapping.unifiedField;
			Map<String, String> unifiedToClassicValues = mapping.valuesMapping;

			String unifiedValue = (unifiedField == RECORDTYPEID) ? handoffWrapper.caseRecordType : String.valueOf(caseDetails.get(unifiedField));

			if (unifiedToClassicValues.containsKey(unifiedValue)) {
				if (unifiedField == RECORDTYPEID) {
					String recordTypeName = unifiedToClassicValues.get(unifiedValue);
					String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
					caseDetails.put(unifiedField, recordTypeId);
				} else {
					caseDetails.put(unifiedField, unifiedToClassicValues.get(unifiedValue));
				}
			}
		}

		ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{ casedetails });

		//Add related contact for star track
		if (handoffWrapper.businessUnit == AUSTRALIAPOST) {
			//This is added after parent case update so that latest info is available for child cases
			if (impactedArticles.size() > 1) {
				createChildCases(casedetails, impactedArticles);
			}
		} else {
			createRelatedContact(casedetails);
		}

		//Delete impacted articles
		if (impactedArticles.size() > 0) {
			ApplicationDatabase.getInstance().dmlDelete(impactedArticles);
		}

		//Create case comment
		createCaseComment(casedetails, casedetails.CaseTransferReason__c, handoffWrapper.comment);
	}

	/**
	 * Method to provide field mapping between unified vs classic
	 * @param  businessUnit - business unit
	 * @param  recordTypeDeveloperName - case Record Type
	 */
	public static CaseHandOffMappingWrapper getCaseHandOffMappings(String businessUnit, String recordTypeDeveloperName) {
		// Query to retrieve custom metadata records based on Business Unit and Record Type Developer Name
		Set<SObjectField> caseHandoffMappingFields = new Set<SObjectField>{ CaseHandOffMapping__mdt.Id, CaseHandOffMapping__mdt.DeveloperName, CaseHandOffMapping__mdt.Mapping__c };

		// Query the CaseHandOffMapping__mdt records for the specified business unit
		List<CaseHandOffMapping__mdt> mappingRecords = CaseHandoffMappingSelector.newInstance(caseHandoffMappingFields)
			.selectByBusinesssUnitRecordType(new Set<String>{ businessUnit }, new Set<String>{ recordTypeDeveloperName }, new Set<Object>());
		  
		CaseHandOffMappingWrapper fieldMappingwrapper;

	// Deserialize JSON string from Mapping__c field into list of CaseHandOffMappingWrapper
		if (!mappingRecords.isEmpty() && mappingRecords[0].Mapping__c != null) {
			fieldMappingwrapper = (CaseHandOffMappingWrapper) JSON.deserialize(mappingRecords[0].Mapping__c, CaseHandOffMappingWrapper.class);
		}

		return fieldMappingwrapper;
	}

	/**
	 * Method to create case comment
	 * @param  caseRec - case record
	 * @param  comment - comment
	 */
	public static void createCaseComment(Case caseRec, String transferReason, String comment) {
		CaseComment caseComment = new CaseComment();
		caseComment.ParentId = caseRec.Id;
		caseComment.CommentBody = 'Case Transfer Reason: ' + transferReason + '\n' + comment;
		ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{ caseComment });
	}

	/**
	 * Method to create child cases
	 * @param  impactedArticles - List of Impacted Articles
	 */
	public static void createChildCases(case parentCase, List<ImpactedArticle__c> impactedArticles) {
		List<Case> childCaseList = new List<Case>();

		for (ImpactedArticle__c imp : impactedArticles) {
			Case childCase = parentCase.clone(false, true);
			childCase.ReferenceID__c = imp.ArticleId__c;
			childCase.ArticleTest__c = imp.Article__c;
			childCase.ParentId = parentCase.Id;
			childCase.Bypass_Data_enforcement__c = true;
			childCaseList.add(childCase);
		}

		ApplicationDatabase.getInstance().dmlInsert(childCaseList);
	}

	@AuraEnabled(continuation=true cacheable=true)
	public static Object searchConsignmentStarTrack(String consignmentNumber) {
		// Generate request
		wwwAuspostComAuSchemaCustomercarema.SearchRequest request = StarTrackConsignmentSearchUtil.generateSearchRequest(
			consignmentNumber,
			StarTrack_Constants.TYPE_CONSIGNMENT,
			StarTrack_Constants.REQUEST_ACTION_FULL,
			StarTrack_Constants.SOURCEID_SALESFORCE,
			UserInfo.getUserName()
		);

		// Generate async stub
		AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = StarTrackConsignmentSearchUtil.generateAsyncStub();

		// Create continuation with timeout
		Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
		cont.continuationMethod = 'processSearchRemoteConsignment'; // Set callback method

		// Initiate async call and store state in continuationState
		continuationState = emsAsyncStub.beginSearch_x(cont, request);
		cont.state = continuationState;

		return cont;
	}

	// Callback method for continuation
	public static Object processSearchRemoteConsignment() {
		return processSearchRemoteConsignment(continuationState);
	}

	// method to process consignment search response
	@AuraEnabled
	public static Object processSearchRemoteConsignment(Object state) {
		// Process callout response
		// Cast state to response element
		AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse = (AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture) state;

		// Process response using utility method
		StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), false);

		// Assuming articleList is a list, return first item
		if (conWrapper.articleList != null && !conWrapper.articleList.isEmpty()) {
			return conWrapper.articleList;
		} else {
			return null;
		}
	}

	/**
	 * Method to create new related contact under the StarTrack case
	 * @param  caseRec - case record
	 */
	public static void createRelatedContact(Case caseRec) {
		AuthorisedContacts__c relCont = new AuthorisedContacts__c();
		relCont.Case__c = caseRec.Id;
		relCont.RecordTypeId = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get(StarTrack_Constants.STRELCONT_RT).getRecordTypeId();
		relCont.Related_Contact__c = caserec.ContactId;
		relCont.Contact_Email__c = caseRec.Contact.Email;
		relCont.Contact_Mobile_Number__c = caseRec.Contact.MobilePhone;
		relCont.Contact_Phone_Number__c = caseRec.Contact.Phone;
		relCont.First_Name__c = caseRec.Contact.FirstName;
		relCont.Last_Name__c = caseRec.Contact.LastName;
		relCont.Contact_Type__c = caseRec.Recent_Caller_Type__c;
		relCont.Notification_Required__c = caseRec.Notification_Required__c;

		ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{ relCont });
	}

	public static Id getSSSWEntitlementId() {
		List<Entitlement> entitlements = EntitlementsSelector.newInstance()
			.selectByNameAndAccountName(new Set<String>{ SSSWConstants.SSSW_ENTITLEMENT }, new Set<String>{ SSSWConstants.ENTITLEMENT_ACC });
		if (!entitlements.isEmpty()) {
			return entitlements[0].Id;
		}
		return null;
	}

	public class CaseHandOffWrapper {
		@AuraEnabled
		public String caseId { get; set; }
		@AuraEnabled
		public String articleId { get; set; }
		@AuraEnabled
		public String handoffReason { get; set; }
		@AuraEnabled
		public String comment { get; set; }
		@AuraEnabled
		public String businessUnit { get; set; }
		@AuraEnabled
		public String contactCenter { get; set; }
		@AuraEnabled
		public String caseRecordType { get; set; }
	}
}