/**
* @description Used for the CTI Integration for AP and StarTrack
* @author Vasu Gorakati/Paul Perry
* @date 2024-04-21
* @changelog
* 2024-04-21 - Vasu Gorakati/Paul Perry - CPIUplift project 
**/
global with sharing class GenesysConnectorController implements purecloud.CTIExtension.ScreenPop {
	private static StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
	private static AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture continuationState = null;
	
	/**
	* Returns cases for consignment number for Star Track
	* @param  consignment  consignment number
	*/
	@RemoteAction
	public static Object findConsignmentStarTrack(String consignmentNumber) {
		String result = '';
		
		ArticlesSelector selector = ArticlesSelector.newInstance();
		List<Article__c> articles = selector.selectByArticleNames(
			new Set<String> {consignmentNumber},
			StarTrack_Constants.CON_REC_TYPE,
			new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE});
	
		if (!articles.isEmpty()) {
			// ensure only delivery enquiry cases are selected
			List<Case> lstCaseRecordsSelected = CasesSelector.newInstance( new Set<SObjectField>{
				Case.Id, Case.CaseNumber, Case.Status, Case.Origin, Case.Call_Purpose__c}).
				selectByArticleId(New Set<Id>{articles[0].Id}, StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT,new Set<Object>());
			
			List<Case> lstCaseRecords = New List<Case>();
			// Note this will exclude transactional IVR cases triggered from SmartSpeak
			for (Case cs: lstCaseRecordsSelected){
				if (!'IVR'.equalsIgnoreCase(cs.Origin) ||
					('IVR'.equalsIgnoreCase(cs.Origin) && 
					 StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get('Call_Purpose__c').contains(cs.Call_Purpose__c))){
						 lstCaseRecords.add(cs);
					 }
			}
			
			if (lstCaseRecords.size() > 1) {
				result = 'MultipleCase';
			} else if (lstCaseRecords.size() == 1) {
				result = lstCaseRecords[0].Id + '_' + lstCaseRecords[0].CaseNumber + '_' + lstCaseRecords[0].Status;
			} else {
				result = 'NoCase_' + articles[0].Id;
			}
		} else {
			// attempt to query consignment because it doesn't already exist in Salesforce
			// this starts an async continuation operation
			return searchRemoteConsignmentStarTrack(consignmentNumber);
		}
		
		return result;
	}
	
	
	/**
	* Returns related contact of case for Star Track
	* @param  consignment  consignment number
	*/
	@RemoteAction
	public static AuthorisedContacts__c checkRelatedContactOfCaseStarTrack(Id caseId, String phoneNumber) {
		List<AuthorisedContacts__c> relatedContacts = new List<AuthorisedContacts__c>();
		AuthorisedContacts__c relContact;

		Set<SObjectField> authorisedContactFields = new Set<SObjectField>{
			AuthorisedContacts__c.Id, AuthorisedContacts__c.RecordType.Name, AuthorisedContacts__c.Case__c, 
			AuthorisedContacts__c.Calc_Contact_Email__c, AuthorisedContacts__c.Calc_Contact_Mobile_Number__c, 
			AuthorisedContacts__c.Calc_Contact_Phone_Number__c, AuthorisedContacts__c.Contact_Type__c, 
			AuthorisedContacts__c.Calc_First_Name__c, AuthorisedContacts__c.Calc_Last_Name__c,
			AuthorisedContacts__c.Notification_Required__c, AuthorisedContacts__c.Pref_Method_of_Contact__c, 
			AuthorisedContacts__c.Related_Contact__c, AuthorisedContacts__c.Initial_Contact__c, 
			AuthorisedContacts__c.Notified_on_Status__c
		};
					
		relatedContacts = AuthorisedContactsSelector.newInstance(authorisedContactFields).selectByCaseIdOrderByName(New Set<Id>{caseId},new Set<Object>());
		
		if (!relatedContacts.isEmpty()) {
			for (AuthorisedContacts__c ac : relatedContacts) {
				if (phoneNumber.equals(ac.Calc_Contact_Phone_Number__c) || phoneNumber.equals(ac.Calc_Contact_Mobile_Number__c)) {
					relContact = ac;
					break;
				}
			}
			return relContact;
		} else {
			return null;
		}
	}
	
	/**
	* Updates the case with recent call for Star Track
	* @param  AuthorisedContacts
	* @param  caseId
	*/
	@RemoteAction
	public static Case updateCaseWithRecentCallerStarTrack(AuthorisedContacts__c relContact, Id caseId) {
		List<Case> lstCaseRecords = new List<Case>();
		
		if (relContact.Calc_Contact_Phone_Number__c != null || relContact.Calc_Contact_Mobile_Number__c != null) {
			Set<SObjectField> fields = new Set<SObjectField>{
				Case.Id, Case.CaseNumber, Case.Recent_Caller_Phone_Number__c, Case.Recent_Contact_Mobile_Number__c
					};
						
						lstCaseRecords = CasesSelector.newInstance(fields).
						selectById(New Set<Id>{caseId}, new Set<Object>()).values();
			lstCaseRecords[0].Recent_Caller_Phone_Number__c = relContact.Calc_Contact_Phone_Number__c;
			lstCaseRecords[0].Recent_Contact_Mobile_Number__c = relContact.Calc_Contact_Mobile_Number__c;
			ApplicationDatabase.getInstance().dmlUpdate(lstCaseRecords);
		}
		
		return lstCaseRecords[0];
	}	
	
	/**
	* creates case for Star Track
	*/
	@RemoteAction
	public static Case createCasewithConsignmentNumberStarTrack(Id consignmentId, String phoneNumber, Boolean atlFlag, String casePurpose, String caseType, String contactType) {
		Case c;
		
		if (consignmentId != null) {
			c = new Case(
				Origin = 'Phone',
				ArticleTest__c = consignmentId,
				RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),
				Recent_Caller_Phone_Number__c = phoneNumber,
				Recent_Caller_Type__c = contactType,
				Callers_Data_Change__c = true, // Create call log in StarTrackAddContactSidePanel page
				ATL__c = atlFlag,
				Call_Purpose__c = casePurpose,
				Enquiry_Type__c = caseType
			);
			
			
			ApplicationDatabase.getInstance().dmlinsert(new List<SObject>{c});
			c = [select id, CaseNumber from Case where id = :c.id];
		}

		return c;
	}
	
	/**
	* creates class log for Star Track
	*/
	@RemoteAction
	public static String createCallLogStarTrack(Id caseId) {		
		String result = '';

		if (caseId != null) {
			StarTrackCreateCallLogActivity.createLogACallRecord(new List<Id>{ caseId });
			result = 'Success';
		}

		return result;
	}
	
	/**
	* when calling findConsignment, if the consignment doesn't exist in SF this will query the .net interface and attempt to retrieve it.
	* @param  consignmentNumber 
	*/
	public static Object searchRemoteConsignmentStarTrack(String consignmentNumber) {
		wwwAuspostComAuSchemaCustomercarema.SearchRequest request = StarTrackConsignmentSearchUtil.generateSearchRequest(consignmentNumber, StarTrack_Constants.TYPE_CONSIGNMENT, StarTrack_Constants.REQUEST_ACTION_FULL);
		AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = StarTrackConsignmentSearchUtil.generateAsyncStub();
		
		Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
		cont.continuationMethod = 'processSearchRemoteConsignment';
		
		// since cont.state is not accessible we call this first.
		continuationState = emsAsyncStub.beginSearch_x(cont, request);
		cont.state = continuationState;
		
		return cont;
	}
	
	/**
	* This has been created to support the testing of the continuation method.
	* Without this, it's not possible to use Test.invokeContinuationMethod
	*/
	public Object processSearchRemoteConsignment() {
		return processSearchRemoteConsignment(continuationState);
	}
	
	/**
	* Handles the async return status of the search consignment operation.
	* This is used to store the consignment retrieved and return the ID to visualforce.
	**/
	public static Object processSearchRemoteConsignment(Object state) {
		//process callout response
		AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse = (AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture)state;
		StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), false);
		
		if(!conWrapper.articleList.isEmpty()) {
			return 'NoCase_' + conWrapper.articleList[0].Id;
		} else {
			return '';
		}
	}
	
	
	/**
	* AP Callcenter related backend controller methods
	* @param event details from AP connector
	*/
	@RemoteAction
	public static Map<String,Object> searchAP(String event) {
		Map<String,Object> params = (Map<String,Object>)JSON.deserializeUntyped(event);

		for (String attribName :params.keySet()) {
			Object attributeValue = params.get(attribName);
			if (attributeValue == null || String.isBlank(String.valueOf(attributeValue))) {
				params.remove(attribName);
			}
		}
		
		List<SObject> matches;
		String matchParam;
		
		if ((matches == null || matches.isEmpty()) && params.containsKey('caseId')) {
			matches = searchCaseId((Id)params.get('caseId'));
			if (matches.size() == 1) {
				matchParam = 'caseId';
			}
		}
		if ((matches == null || matches.isEmpty()) && params.containsKey('caseNumber')) {
			matches = searchCaseNumber((String)params.get('caseNumber'));
			if (matches.size() == 1) {
				matchParam = 'caseNumber';
			}
		}
		if ((matches == null || matches.isEmpty()) && params.containsKey('trackingNumber')) {
			matches = searchTrackingNumber((String)params.get('trackingNumber'));
			if (matches.size() == 1) {
				matchParam = 'trackingNumber';
			}
		}
		if ((matches == null || matches.isEmpty()) && params.containsKey('contactId')) {
			matches = searchContactId((String)params.get('contactId'));
			if (matches.size() == 1) {
				matchParam = 'contactId';
			}
		}
		if ((matches == null || matches.isEmpty()) && params.containsKey('phoneNumber')) {
			String phoneNumber = (String)params.get('phoneNumber');

			if (String.isNotEmpty(phoneNumber) && phoneNumber.startsWith('+61')) {
				phoneNumber = phoneNumber.replace('+61', '0');
			}

			matches = searchPhoneNumber(phoneNumber);
			if (matches.size() == 1) {
				matchParam = 'phoneNumber';
			}
		}
		
		Map<String,Object> result = new Map<String,Object>{
			'userId' => UserInfo.getUserId()
		};
		
		if (matches != null) {
			result.put(String.valueOf(matches.getSObjectType()), matches);
			result.put('match', matchParam);
		}
		
		return result;
	}
	
	/**
	* Search by Case Id
	* @param caseId
	*/
	private static List<Case> searchCaseId(Id caseId) {
		Set<SObjectField> fields = new Set<SObjectField>{
			Case.Id, Case.ContactId, Case.CaseNumber, Case.Contact.AccountId 
		};

		return CasesSelector.newInstance(fields).selectById(
			new Set<Id>{caseId},
			new Set<Object>{CasesSelector.Options.WITH_CONTACT}
		).values();
	}
	
	/**
	* Search by case number
	* @param caseNumber
	*/	
	private static List<Case> searchCaseNumber(String caseNumber) {
		Set<SObjectField> fields = new Set<SObjectField>{
			Case.Id, Case.ContactId, Case.CaseNumber, Case.Contact.AccountId 
		};
			
		return CasesSelector.newInstance(fields).selectByCaseNumber(
			new Set<String>{caseNumber},
			new Set<Object>{CasesSelector.Options.WITH_CONTACT}
		).values();
	}
	
	/**
	* Search by case number
	* @param trackingNumber
	*/	
	private static List<Case> searchTrackingNumber(String trackingNumber) {
		Set<SObjectField> fields = new Set<SObjectField>{
			Case.Id, Case.ContactId, Case.CaseNumber, Case.Contact.AccountId 
		};

		return CasesSelector.newInstance(fields).selectCasesByReferenceId(
			new Set<String>{trackingNumber},
			new Set<Object>{CasesSelector.Options.WITH_CONTACT}
		);
	}
	
	/**
	* Search by contact Id
	* @param contactId
	*/	
	public static List<Contact> searchContactId(String contactId) {
		Set<SObjectField> fields = new Set<SObjectField>{Contact.Id, Contact.Name, Contact.AccountId, Contact.Account.IsPersonAccount};
		return ContactsSelector.newInstance(0, fields).selectById(
			new Set<Id>{contactId},
			new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE}
		).values();
	}
	
	/**
	* Search by phone Number
	* @param phoneNumber
	*/	
	private static List<Contact> searchPhoneNumber(String phoneNumber) {
		Set<SObjectField> fields = new Set<SObjectField>{Contact.Id, Contact.Name, Contact.AccountId, Contact.Account.IsPersonAccount};
		return ContactsSelector.newInstance(0, fields).selectByLikedAnyPhoneOrderByName(
			phoneNumber,
			new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE}
		).values();
	}
	
	/**
	* Update or insert the call log activity
	* @param callLog Serialised object with all Genesys interaction log properties
	* @param taskDetails Serialised object with all additional task details
	* @return UpsertResult
	*/
	@RemoteAction
	public static Object maintainTaskAP(String callLog, String taskDetails, String ctiLog) {
		Map<String,Object> callLogMap = (Map<String,Object>)JSON.deserializeUntyped(callLog);
		Map<String,Object> taskDetailMap = (Map<String,Object>)JSON.deserializeUntyped(taskDetails);
		
		// Get the existing task or new instance with all required default values
		Task activity = getSSSWCallTask((String)taskDetailMap.get('interactionId'));
		
		if (taskDetailMap.containsKey('contactId')) {
			Id accountId = (Id)taskDetailMap.get('contactId');
			// replace PersonAccountId with actual ContactId required for WhoId field assignment onto task
			if (accountId != null && accountId.getSObjectType() == Account.SObjectType) {
				AccountsSelector selector = AccountsSelector.newInstance(1, new Set<SObjectField>{ Account.Id, Account.PersonContactId });
				taskDetailMap.put('contactId', selector.selectById(new Set<Id>{ accountId }).get(accountId).PersonContactId);				
			}
		}

		// Which values to copy from the genesys interaction object
		Map<SObjectField,String> callLogMappings = new Map<SObjectField,String>{
			Task.CallType => 'callType',
			Task.IWS_CallUUID__c => 'callUuid',
			Task.Phone__c => 'phoneNumber',
			Task.Queue__c => 'queueName',
			Task.Segment__c => 'segment',
			Task.ServiceType__c => 'serviceType',
			Task.Target_Skill__c => 'targetSkill'
		};
			
		// Map all values from CTI callLog
		for (SObjectField targetField :callLogMappings.keySet()) {
			String attribName = callLogMappings.get(targetField);
			
			// Only update if value has been provided (can be null as well to unset the fieldvalue)
			if (callLogMap.containsKey(attribName)) {
				activity.put(targetField, callLogMap.get(attribName));
			}
		}
		
		// Map all additional task detail attributes
		Map<SObjectField,String> taskDetailMappings = new Map<SObjectField,String>{
			Task.CallDurationInSeconds => 'durationInSeconds',
			Task.CTIInteractionID__c => 'interactionId',
			Task.Enquiry_Type__c => 'enquiryType',
			Task.Enquiry_Sub_Type__c => 'enquirySubType',
			Task.Product_Category__c => 'productCategory',
			Task.Product_Sub_Category__c => 'productSubCategory',
			Task.Status => 'status',
			Task.Subject => 'subject',
			Task.WhatId => 'caseId',
			Task.WhoId => 'contactId',
			Task.Outcome__c => 'outcome'			
		};
			
		// Map all values from taskDetail
		for (SObjectField targetField :taskDetailMappings.keySet()) {
			String attribName = taskDetailMappings.get(targetField);
			
			if (taskDetailMap.containsKey(attribName)) {
				activity.put(targetField, taskDetailMap.get(attribName));
			}
		}
		
		ApplicationDatabase appDBInstance = ApplicationDatabase.getInstance();
		
		List<Task> taskList = new List<SObject>{ activity };
		Database.SaveResult result;

		if (activity.Id == null) {
			// Insert/Update the call Log activity to the Database
			result = appDBInstance.dmlInsert(taskList)[0];
		} else {
			result = appDBInstance.dmlUpdate(taskList)[0];
		}
		
		if (result.success && activity.Status == 'Completed' && String.isNotEmpty(ctiLog)) {
			// Include the ctiLog		
			String comments = String.valueOf(callLogMap.get('comments'));
			String attachmentBody = (!String.isEmpty(comments) ? '\n\n' : '') + ctiLog;
			
			appDBInstance.dmlInsert(new List<SObject>{
				new Attachment(
					Name = 'InboundLog.txt',
					parentId = result.id,
					body = Blob.valueOf(attachmentBody)
				)
			});
		}
		
		return result;
	}
	
	/**
	* Obtain case details from case Id
	* @param Id caseId
	* @return Case if found
	*/
	@RemoteAction
	public static Map<String,Object> getCaseByIdAP(Id caseId) {
		Map<SObjectField,String> fieldMappings = new Map<SObjectField,String>{
			Case.Id => 'caseId',
			Case.Type => 'enquiryType',
			Case.ProductCategory__c => 'productCategory',
			Case.ProductSubCategory__c => 'productSubCategory',
			Case.EnquirySubType__c => 'enquirySubType',
			Case.AccountId => 'accountId',
			Case.ContactId => 'contactId',
			Case.Contact.AccountId => 'personAccountId',
			Case.CaseNumber => 'caseNumber',
			Case.Complaint__c => 'complaint'
		};

		CasesSelector selector = CasesSelector.newInstance(fieldMappings.keySet());
		List<Case> cases = selector.selectById(new Set<Id> { caseId }).values();

		// // Best practice: Strip fields that are not accessible to the user
		// SObjectAccessDecision decision = Security.stripInaccessible(
		// 	AccessType.READABLE,
		// 	cases
		// );

		Map<String,Object> result = new Map<String,Object>();

		if (!cases.isEmpty()) {
			for (SObjectField field :fieldMappings.keySet()) {
				Object value = cases[0].get(field);

				if (field != null) {
					result.put(fieldMappings.get(field), value);
				}
			}
		}

		return result;
	}

	/**
	* Attempts to get the existing Task for this interactionId
	* In case it doesn't exist yet, return the default values for a SSSWCall Task record
	* @param (String) Unique interactionId for this call
	* @return (Task) Existing Task or default values
	*/
	private static Task getSSSWCallTask(String interactionId) {
		if (String.isBlank(interactionId)) {
			// interactionId should allways be present
			throw new NoDataFoundException();
		}
		
		List<Task> existingTasks = TasksSelector.newInstance().search(
			new Map<String,Set<String>>{
				'ctiInteractionIds' => new Set<String>{ interactionId }
			},
			new Set<Object>{},
			true
		).values();
		
		Task result = existingTasks.isEmpty() ? null : existingTasks[0];
		
		if (existingTasks.isEmpty()) {
			// Init new Task instance with default values
			result = new Task();
			result.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName(
				String.valueOf(Task.SObjectType),
				new Set<String>{ Constants.RECORDTYPE_NAME_TASK_SSSWCALL }
			).values()[0].Id;
			// Set default SSSWCall Task default values
			result.ActivityDate = Date.today();
			result.Description = 'For logs, please see attachment';
			result.Type = 'Phone Call';
		}
		
		return result;
	}

	/**
	 * Surpress Genesys' default screen pop on incoming call alert
	 * Implemented as described here: https://help.mypurecloud.com/articles/use-the-extension-points-to-customize-screen-pop/
	 * @param String Data
	 * @return String Payload to disable default screenpop
	 */
	global String onScreenPop(String data) {
		return JSON.serialize(new Map<String,Object>{
			'defaultScreenPop' => false,
			'url' => ''
		});
	}
}