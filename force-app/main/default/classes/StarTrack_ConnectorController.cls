/**************************************************
Description:    Used for the CTI Integration for StarTrack
History:
--------------------------------------------------
2018-01-01  kalpita.talwadekar@auspost.com.au  Created
2018-02-01  angelo.rivera@auspost.com.au  Updated
2018-05-22  nathan.franklin@auspost.com.au  Bug fixes for findConsignment
2018-05-25  nathan.franklin@auspost.com.au  Adding async searchRemoteConsignment operation where the consignment doesn't already exist in SF
2018-07-03  nathan.franklin@auspost.com.au  Adding IVR transactional exclusions from findConsignment
2024-03-12 - Nathan Franklin - Add code to save attachments
**************************************************/
global class StarTrack_ConnectorController {

	private static StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

	/**
	 * This used on in unit tests which use Test.invokeContinuationMethod. This is because Test.invokeContinuationMethod requires an instance method without any parameters (state),
	 *      so the state needs to be stored somewhere else
	 */
	private static AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture continuationState = null;

	@RemoteAction
	global static Object findContact(String searchId, String searchValue) {
		System.Debug('findContact: searchId - ' + searchId + ', searchValue - ' + searchValue);

		try {

			String query = 'SELECT Id, Name, AccountId FROM Contact WHERE ' + String.escapeSingleQuotes(searchId) + ' = :searchValue ';
			System.Debug('query = ' + query);
			List<Contact> contacts = Database.query(query);

			if (!contacts.isEmpty()) {
				Integer numContacts = contacts.size();
				System.Debug('contacts found=' + numContacts);

				if (numContacts > 1) {
					Contact c = contacts[0];
					c.Id = null; // indicator for multiple contacts
					return c;
				} else if (numContacts == 1) {
					return contacts[0];
				}
			}
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
		}

		try {
			// throw in an account search if we've found nothing while we're here
			String query = 'SELECT Id, Name FROM Account WHERE ' + String.escapeSingleQuotes(searchId) + ' = :searchValue ';
			List<Account> accounts = Database.query(query);

			if (!accounts.isEmpty()) {
				Integer numAccounts = accounts.size();
				System.Debug('accounts found=' + numAccounts);

				if (numAccounts > 1) {
					Account c = accounts[0];
					c.Id = null; // indicator for multiple accounts
					return c;
				} else if (numAccounts == 1) {
					return accounts[0];
				}
			}
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
		}

		try {
			// and lead as well
			String query = 'SELECT Id, Name FROM Lead WHERE ' + String.escapeSingleQuotes(searchId) + ' = :searchValue ';
			List<Lead> leads = Database.query(query);

			if (!leads.isEmpty()) {
				Integer numLeads = leads.size();
				System.Debug('leads found=' + numLeads);

				if (numLeads > 1) {
					Lead c = leads[0];
					c.Id = null; // indicator for multiple leads
					return c;
				} else if (numLeads == 1) {
					return leads[0];
				}
			}
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
		}

		return null;
	}

	@RemoteAction
	global static Object getContact(String contactId, String field) {
		System.Debug('getContact: contactId - ' + contactId);
		if (field != null) {
			field = ', ' + field;
		} else {
			field = '';
		}

		try {
			String query = 'SELECT Id, Name, AccountId' + String.escapeSingleQuotes(field) + ' FROM Contact WHERE Id = :contactId';
			System.Debug('query = ' + query);
			List<Contact> contacts = Database.query(query);
			if (!contacts.isEmpty()) {
				return contacts[0];
			}
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
		}

		try {
			String query = 'SELECT Id, Name' + String.escapeSingleQuotes(field) + ' FROM Account WHERE Id= :contactId';
			System.Debug('query = ' + query);
			List<Account> accounts = Database.query(query);
			if (!accounts.isEmpty()) {
				return accounts[0];
			}
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
		}

		try {
			String query = 'SELECT Id, Name' + String.escapeSingleQuotes(field) + ' FROM Lead WHERE Id= :contactId';
			System.Debug('query = ' + query);
			List<Lead> leads = Database.query(query);
			if (!leads.isEmpty()) {
				return leads[0];
			}
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
		}

		return null;
	}

	@RemoteAction
	global static Task getContactByTask(String taskId) {
		System.Debug('getContactByTask: taskId - ' + taskId);

		Task task = [SELECT WhoId, WhatId FROM Task WHERE Id = :taskId];
		System.Debug('contact id = ' + task.WhoId);

		// see if this task has an associated case
		List<Case> cases = [SELECT CaseNumber FROM Case WHERE Id = :task.WhatId];

		if (!cases.isEmpty()) {
			// return the case number in the call object field
			task.CallObject = cases[0].CaseNumber;
		}

		return task;
	}

	@RemoteAction
	global static Task createTask(String ixnId,
		String contactId,
		String whatId,
		String subject,
		Map<String, String> userData,
		Map<String, String> taskMap) {
		System.Debug('createActivity: ' + contactId);

		// check to see if this is an account and not a contact
		String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
		if (contactId != null) {
			String prefix = contactId.substring(0, 3);
			if (prefix == accountPrefix) {
				// see if the 'what' needs to be an account
				String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
				if (whatId == null || whatId.substring(0, 3) != casePrefix) {
					whatId = contactId;
				}

				contactId = null;
			}
		}

		Task task = new Task(
			Status = 'In Progress',
			Subject = subject,
			WhoId = contactId,
			WhatId = whatId,
			CallObject = ixnId
		);

		if (taskMap != null) {
			for (String sfdcField : taskMap.keySet()) {
				System.Debug(sfdcField + ':' + taskMap.get(sfdcField));
				task.put(sfdcField, taskMap.get(sfdcField));
			}
		}

		insert task;
		System.Debug('Task id = ' + task.Id);

		try {
			String jsonPayload = JSON.serialize(userData);
			insert new Attachment(Name = 'InboundLog.txt', parentId = task.id, body = Blob.valueOf(jsonPayload));
		} catch (Exception ex) {
			// fail silently..
			// we did this because it was on on-the-fly type of change to reduce the risk of anything going wrong in production.
		}

		return task;
	}

	@RemoteAction
	global static Task closeTask(String ixnId, ID taskId, ID whatId, String subject, String comments, Map<String, String> userData,
		String dispositionKVP, Map<String, String> taskMap, Integer callDuration) {
		System.Debug('closeActivity: ' + taskId);

		Task[] tasks = [SELECT Id, Description FROM Task WHERE Id = :taskId];
		Task task = null;

		if (tasks.size() == 0) { // created yet?
			task = createTask(ixnId, taskId, whatId, subject, userData, taskMap); // task id is actually the contact id
			if (task == null) {
				return null;
			}
		} else {
			task = tasks[0];
		}

		String disposition = '';
		if (userData != null && userData.containsKey(dispositionKVP)) {
			disposition = userData.get(dispositionKVP);
		}

		for (String sfdcField : taskMap.keySet()) {
			System.Debug(sfdcField + ':' + taskMap.get(sfdcField));
			task.put(sfdcField, taskMap.get(sfdcField));
		}

		task.CallDisposition = disposition;
		task.CallDurationInSeconds = callDuration;
		task.Status = 'Completed';
		task.Subject = subject;

		if (comments != '') {
			if (task.Description == null) {
				task.Description = '';
			}

			task.Description += '\n' + comments;
		}

		for (String sfdcField : taskMap.keySet()) {
			System.Debug(sfdcField + ':' + taskMap.get(sfdcField));
			task.put(sfdcField, taskMap.get(sfdcField));
		}

		update task;
		System.Debug('Task id = ' + task.Id);
		return task;
	}

	@RemoteAction
	global static Case findCase(String caseNumber) {
		System.Debug('findCase: ' + caseNumber);
		List<Case> cases = [SELECT CaseNumber, ContactId FROM Case WHERE CaseNumber = :caseNumber];

		if (!cases.isEmpty()) {
			return cases[0];
		}

		return null;
	}

	@RemoteAction
	global static Case createCase(String contactId, String accountId, String mediaType, String subject, Map<String, String> userData, Map<String, String> caseMap) {
		System.Debug('createCase: ' + subject);

		// check to see if this is an account and not a contact
		String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
		if (contactId != null) {
			String prefix = contactId.substring(0, 3);
			if (prefix == accountPrefix) {
				accountId = contactId;
				contactId = null;
			}
		}

		Case c = new Case(
			ContactId = contactId,
			AccountId = accountId,
			Subject = subject,
			Priority = 'Medium',
			Origin = mediaType
		);

		if (caseMap != null) {
			for (String sfdcField : caseMap.keySet()) {
				System.Debug(sfdcField + ':' + caseMap.get(sfdcField));
				c.put(sfdcField, caseMap.get(sfdcField));
			}
		}

		try {
			insert c;
			c = [select id, CaseNumber from Case where id = :c.id];
		} catch (QueryException e) {
			System.Debug('QueryException ' + e);
			return null;
		}

		System.Debug('Case id = ' + c.Id);
		return c;
	}


	//The method below is for the support of activating Mark Done and Call Result from Salesforce to Genesys WDE
	@AuraEnabled
	public static Sobject getRecord(Id recordId, String fieldsToShow) {
		String objectName = recordId.getSobjectType().getDescribe().getName();
		String soql = 'Select ' + fieldsToShow + '  from ' + objectName + ' where Id = :recordId';
		return Database.query(soql);
	}


	//Start - APRIVERA - 23/01/18 - Added new function that searches consignment number
	@RemoteAction
	global static Object findConsignment(String consignmentNumber) {
		String result = '';

		try {
			if (consignmentNumber != null) {
				// Search to see if the consignment already exists in salesforce
				// it will only exist if it's been queried in the past.
				List<Article__c> articles = [Select Id, Name from Article__c Where Name = :consignmentNumber And RecordType.DeveloperName = :StarTrack_Constants.CON_REC_TYPE];
				if (!articles.isEmpty()) {
					// ensure only delivery enquiry cases are selected
					// Note this will exclude transactional IVR cases triggered from SmartSpeak
					// Transactional IVR cases are currently defined
					Id articleId = articles[0].Id;
					String deliveryRecordType = StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT;
					String soql = 'Select Id, CaseNumber, Status from Case ' +
									' Where ArticleTest__c = :articleId ' +
									' And RecordType.DeveloperName = :deliveryRecordType ' +
									' And (Origin != \'IVR\' Or ' +
									'	(Origin = \'IVR\' ';


					// make sure we exclude 'transactional' IVR cases
					for(String fieldKey : StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.keySet()) {
						Set<String> values = StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get(fieldKey);
						soql += ' And ' + String.escapeSingleQuotes(fieldKey) + ' in :values ' ;
					}
					soql += ' ))';

					System.Debug('>> Dynamic SOQL: ' + soql);
					List<Case> lstCaseRecords = Database.query(soql);

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
					return searchRemoteConsignment(consignmentNumber);
				}
			}
		} catch (Exception e) {
			GlobalUtility.logMessage(StarTrack_Constants.ERROR, 'Class StarTrack_ConnectorController',
				'findConsignment', '', StarTrack_Constants.EXCEPTION_KYWRD,
				e.getMessage(), '', e, 0);
		}

		System.Debug('>> Returning findConsignment result: ' + result);

		return result;
	}


	//Start - APRIVERA - 31/01/18 - Added new function that checks the related contact of Case
	@RemoteAction
	global static AuthorisedContacts__c checkRelatedContactOfCase(Id caseId, String phoneNumber) {
		System.Debug('checkRelatedContactOfCase: ' + caseId);

		Map<Id, AuthorisedContacts__c> relatedContacts;
		AuthorisedContacts__c relContact = new AuthorisedContacts__c();

		relatedContacts = new Map<Id, AuthorisedContacts__c>([
			SELECT Id, RecordType.Name, Case__c, Calc_Contact_Email__c, Calc_Contact_Mobile_Number__c, Calc_Contact_Phone_Number__c, Contact_Type__c, Calc_First_Name__c, Calc_Last_Name__c,
				Notification_Required__c, Pref_Method_of_Contact__c, Related_Contact__c, Initial_Contact__c, Notified_on_Status__c
			FROM AuthorisedContacts__c
			WHERE Case__c != null AND Case__c = :caseId
			ORDER BY Initial_Contact__c DESC, Calc_First_Name__c ASC
		]);

		if (!relatedContacts.isEmpty()) {
			for (AuthorisedContacts__c ac : relatedContacts.values()) {
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

	//Start - APRIVERA - 31/01/18 - Added new function that checks the related contact of Case
	@RemoteAction
	global static Case updateCaseWithRecentCaller(AuthorisedContacts__c relContact, Id caseId) {
		System.Debug('updateCaseWithRecentCaller');
		Case cseRecord = new Case();
		String contactPhoneNumber = relContact.Calc_Contact_Phone_Number__c;
		String contactMobileNumber = relContact.Calc_Contact_Mobile_Number__c;

		try {
			if (contactPhoneNumber != null || contactMobileNumber != null) {
				cseRecord = [Select Id, CaseNumber, Recent_Caller_Phone_Number__c, Recent_Contact_Mobile_Number__c from Case where Id = :caseId];

				cseRecord.Recent_Caller_Phone_Number__c = contactPhoneNumber;
				cseRecord.Recent_Contact_Mobile_Number__c = contactMobileNumber;

				Database.update(cseRecord);
			}
		} catch (Exception e) {
			GlobalUtility.logMessage(StarTrack_Constants.ERROR, 'Class StarTrack_ConnectorController',
				'Function updateCaseWithRecentCaller', '', StarTrack_Constants.EXCEPTION_KYWRD,
				e.getMessage(), '', e, 0);
			return null;
		}
		return cseRecord;
	}

	//Start - APRIVERA - 29/01/18 - Added new function that creates case
	@RemoteAction
	global static Case createCasewithConsignmentNumber(Id consignmentId, String phoneNumber, Boolean atlFlag, String casePurpose, String caseType, String contactType) {
		Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
		Case c;
		System.Debug('createCasewithConsignmentNumber: ' + consignmentId);

		if (consignmentId != null) {
			c = new Case(
				Origin = 'Phone',
				ArticleTest__c = consignmentId,
				RecordTypeId = devRecordTypeId,
				Recent_Caller_Phone_Number__c = phoneNumber,
				Recent_Caller_Type__c = contactType,
				Callers_Data_Change__c = true, // Create call log in StarTrackAddContactSidePanel page
				ATL__c = atlFlag,
				Call_Purpose__c = casePurpose,
				Enquiry_Type__c = caseType
			);


			try {
				insert c;
				c = [select id, CaseNumber from Case where id = :c.id];
			} catch (QueryException e) {
				GlobalUtility.logMessage(StarTrack_Constants.ERROR, 'Class StarTrack_ConnectorController',
					'Function createCasewithConsignmentNumber', '', StarTrack_Constants.EXCEPTION_KYWRD,
					e.getMessage(), '', e, 0);
				return null;
			}
		}
		System.Debug('createCasewithConsignmentNumber_Case Id = ' + c.Id);
		return c;
	}

	//Start - APRIVERA - 29/01/18 - Added new function that creates call log
	@RemoteAction
	global static String createCallLog(Id caseId) {

		String result = '';
		try {
			if (caseId != null) {
				List<Id> caseIdList = new List<Id>();
				caseIdList.add(caseId);
				StarTrackCreateCallLogActivity.createLogACallRecord(caseIdList);
				result = 'Success';
			}
		} catch (Exception e) {
			GlobalUtility.logMessage(StarTrack_Constants.ERROR, 'Class StarTrack_ConnectorController',
				'Function createCallLog', '', StarTrack_Constants.EXCEPTION_KYWRD,
				e.getMessage(), '', e, 0);
			return null;
		}
		return result;
	}

	/**
	 * when calling findConsignment, if the consignment doesn't exist in SF this will query the .net interface and attempt to retrieve it.
	 */
	global static Object searchRemoteConsignment(String consignmentNumber) {
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
	global Object processSearchRemoteConsignment() {
		return processSearchRemoteConsignment(continuationState);
	}

	/**
	 * Handles the async return status of the search consignment operation.
	 * This is used to store the consignment retrieved and return the ID to visualforce.
	 **/
	global static Object processSearchRemoteConsignment(Object state) {

		//process callout response
		AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse = (AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture)state;
		StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), false);

		if(!conWrapper.articleList.isEmpty()) {
			System.Debug('>> Found Consignment from processSearchRemoteConsignment: ' + conWrapper.articleList[0].Id);
			return 'NoCase_' + conWrapper.articleList[0].Id;
		} else {
			System.Debug('Did not find a consignment result from processSearchRemoteConsignment');
			return '';
		}
	}

}