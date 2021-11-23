/**
 * @description The controller for the Genesys CTI functionality
 * @author Nathan Franklin
 * @date 2018-09-13
 * @changelog
 * 2021-09-07 - Nathan Franklin - Fixed bug where WhoId from CTI adapter is 'false'. WhoId will only be set if it's not 'false' (string)
 * 2021-09-07 - Nathan Franklin - Changed the findContactByPhone to be consistent with how search is done within the SearchContactCOmponentController for phone number
 */
global with sharing class AP_ConnectorController2 {

	/**
	 * When searching a contact by field name we need the person account equivalent field names
	 */
	private static Map<String, String> personAccountFieldNameMappings = new Map<String, String>{
		'Id' => 'Id'
	};

	/**
	  * method used to find the contact record from the phone number based on incoming phone call
	  */
	@RemoteAction
	global static Object findContactByPhone(String phoneNumber) {
		System.debug('findContact: phoneNumber - ' + phoneNumber);

		// TODO: This search is not the best way to search for customer records.
		// NOTE: This same way of searching for phone numbers has also been rolled out to SerarchContactComponentController for custom record searching
		// If changes are made to how contacts are searched by phone number, it's important that SerarchContactComponentController is also updated! (And discussed beforehand!)
		String reverseNumber = Util.reversePhoneString(phoneNumber) + '%';
		String query = 'SELECT Id, Name, AccountId FROM Contact WHERE ReversePhoneFields__c LIKE :reverseNumber Order By CreatedDate Desc LIMIT 2';
		List<Contact> contacts = Database.query(query);

		if (!contacts.isEmpty()) {
			Integer numContacts = contacts.size();
			System.debug('contacts found=' + numContacts);

			if (numContacts > 1) {
				Contact c = contacts[0];
				c.Id = null; // indicator for multiple contacts
				return c;
			} else if (numContacts == 1) {
				return contacts[0];
			}
		}

		return null;
	}

	/**
	  * method used to find the contact record based on an id that was passed into the CTI
	  */
	@RemoteAction
	global static Object findContactByField(String fieldName, String fieldValue) {
		System.debug('findContactById - ' + fieldName + ', ' + fieldValue);

		// if there is a person account field mapping that maps the fieldname passed in with a field name on the account record, we include this in our search criteria
		// this allows us to search person accounts and contacts at the same time
		String personAccountFieldName = personAccountFieldNameMappings.get(fieldName);

		String query = 'SELECT Id, Name FROM Contact WHERE ' + String.escapeSingleQuotes(fieldName) + ' = :fieldValue ';

		if(!String.isEmpty(personAccountFieldName)) {
			query += ' Or (Account.IsPersonAccount = true And Account.' + String.escapeSingleQuotes(personAccountFieldName) + ' = :fieldValue )';
		}

		query += ' Order By LastModifiedDate Desc LIMIT 2 ';

		System.debug('findContactByField ' + query);

		List<Contact> contacts = Database.query(query);

		if (!contacts.isEmpty()) {
			if(contacts.size() > 1) {
				contacts[0].Id = null;
			}
			return contacts[0];
		}

		return null;
	}

	/**
	 * Based on specific filters passed, return  a small sample of cases
	 */
	private static List<Case> getCases(Map<String, Object> filters, Integer limitVar) {
		// only get SSSW cases
		Set<Id> recordTypes = Utility.getRecordTypeIds('Case', 'SSSW');
		System.debug('>> SSSW Record Types: ' + recordTypes);

		String soql = 'Select Id, CaseNumber, Type, ProductSubCategory__c, ProductCategory__c, EnquirySubType__c, ContactId, Contact.Name, Contact.Id, Contact.AccountId, Contact.Account.IsPersonAccount, AccountId, Account.IsPersonAccount, ReferenceID__c From Case ' +
						' Where RecordTypeId In :recordTypes ';
		String whereClause = '';
		for(String filterName : filters.keySet()) {
			if(filters.get(filterName) instanceof Boolean) {
				Object value = filters.get(filterName);
				soql += ' And ' + String.escapeSingleQuotes(filterName) + ' =  ' + (Boolean.valueOf(value) ? 'true' : 'false');
			} else {
				Object value = filters.get(filterName);
				soql += ' And ' + String.escapeSingleQuotes(filterName) + ' = :value ';
			}
		}

		soql += ' Order By CreatedDate Desc ';
		soql += ' Limit ' + limitVar; // no need to escape limit because it's an integer

		System.debug('>> getCases QUERY: ' + soql);

		List<Case> output = Database.query(soql);

		System.debug('>> Cases: ' + output);

		return output;
	}

	/**
	  * Retrieve an existing Case from caseNumber from incoming call
	  */
	@RemoteAction
	global static Case getCaseByCaseNumber(String caseNumber) {
		System.debug('getCaseByCaseNumber: ' + caseNumber);

		List<Case> cases = getCases(new Map<String, String>{'CaseNumber' => caseNumber}, 1);

		if (!cases.isEmpty()) {
			return cases[0];
		}

		return null;
	}

	/**
	  * Retrieve an existing Case from caseNumber from incoming call
	  */
	@RemoteAction
	global static Case getCaseById(String id) {
		System.debug('getCaseById: ' + id);

		List<Case> cases = getCases(new Map<String, String>{'Id' => id}, 1);

		if (!cases.isEmpty()) {
			return cases[0];
		}

		return null;
	}


	/**
	  * Retrieve an existing Case from Reference Id from incoming call
	  */
	@RemoteAction
	global static List<Case> getCaseByReferenceId(String referenceId) {
		System.debug('getCaseByReferenceId: ' + referenceId);

		// we only return up to 2 cases
		// if more than 1 case exists then the search window should be displayed to the user
		// if only 1 case exists, we redirect the user to the case page
		List<Case> cases = getCases(new Map<String, Object>{'ReferenceID__c' => referenceId, 'IsClosed' => false}, 2);

		if (!cases.isEmpty()) {
			return cases;
		} else {
			return null;
		}
	}

	/**
	  * Create a task record on call start
	  */
	@RemoteAction
	global static Task createTask(String contactId, String whatId, String subject, Map<String, String> userData, Map<String, String> taskMap) {
		System.debug('createActivity: ' + contactId);

		// check to see if this is an account and not a contact
		String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
		String prefix = !String.isBlank(contactId) ? contactId.substring(0, 3) : '' ;
		if (!String.isBlank(prefix)) { //added by kalpita for check of no contact
			if (prefix == accountPrefix) {
				// see if the 'what' needs to be an account
				String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
				if (String.isBlank(whatId)) {
					whatId = contactId;
				}

				contactId = [Select Id, AccountId from Contact where accountId = :whatId limit 1].Id;
			}
			if (prefix == Schema.SObjectType.Contact.getKeyPrefix()) {
				if (String.isBlank(whatId)) {
					whatId = null;
				}
			}
		}

		Task task = new Task(
			Status = 'In Progress',
			Subject = subject
		);
		if (!String.isBlank(whatId)) {
			task.whatId = whatId;
		}
		if (!String.isBlank(contactId)) {
			task.whoId = contactId;
		}

		if (taskMap != null) {
			for (String sfdcField : taskMap.keySet()) {
				System.debug(sfdcField + ':' + taskMap.get(sfdcField));
				task.put(sfdcField, taskMap.get(sfdcField));
			}
		}

		insert task;
		System.debug('Task id = ' + task.Id);

		return task;
	}

	/**
	  * method to close an existing or create new and mark same as completed on end of call.
	  */
	@RemoteAction
	global static Task closeTask(String taskId, String whatId, String whoId, String subject, String comments, Map<String, String> userData,
									String dispositionKVP, Map<String, String> taskMap, Integer callDuration, String interactionId, String callType) {

		// whoId may be a person account id
		// if thats the case we need to lookup the contact id
		if(!String.isEmpty(whoId) && whoId.substring(0, 3) == '001') {
			// check to see if the account is a person account
			List<Account> accounts = [Select Id, IsPersonAccount, PersonContactId From Account Where Id = :whoId];
			if(!accounts.isEmpty() && accounts[0].IsPersonAccount) {
				whoId = accounts[0].PersonContactId;
			}
		}

		System.debug('closeActivity: ' + taskId);
		System.debug('taskMap: ' + taskMap);

		Task task = null;
		List<Task> tasks = new List<Task>();
		if (!String.isBlank(taskId)) {
			tasks = [SELECT Id, Description FROM Task WHERE Id = :taskId];
		}

		if (tasks.size() == 0) { // created yet? this should never happen but it's a failsafe
			task = createTask(whoId, whatId, subject, userData, taskMap); // task id is actually the contact id //updated by kalpita to rectify the whatId which is case.
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
			System.debug(sfdcField + ':' + taskMap.get(sfdcField));
			task.put(sfdcField, taskMap.get(sfdcField));
		}

		task.CallDisposition = disposition;
		task.CallDurationInSeconds = callDuration;
		task.Status = 'Completed';
		task.Subject = subject;
		task.WhatId = (!String.isEmpty(whatId) ? whatId : null); //findCase().Id;
		task.WhoId = (!String.isEmpty(whoId) && !'false'.equalsIgnoreCase(whoId) ? whoId : null);
		task.RecordTypeId = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWCall' limit 1].Id;
		task.target_skill__c = userData.get('RRequestedSkillCombination');
		task.Description = 'For logs, please see attachment';
		task.Phone__c = userData.get('PhoneNumber');
		task.Type = 'Call';
		task.Queue__c = userData.get('IWS_DNIS');
		task.ServiceType__c = userData.get('r_IWS_ServiceType');
		task.Segment__c = userData.get('r_IWS_CustomerSegment');
		task.Outcome__c = userData.get('BusinessResultDisplay');
		task.Enquiry_Type__c = userData.get('ENG_DimAttribute_2');
		task.Enquiry_Sub_Type__c = userData.get('ENG_DimAttribute_1');
		task.Product_Category__c = userData.get('r_IWS_ServiceType');
		task.Product_Sub_Category__c = userData.get('r_IWS_ServiceSubType');
		task.IWS_CallUUID__c = userData.get('IWS_CallUuid');
		task.IWS_CaseUid__c = userData.get('IW_CaseUid');
		task.ActivityDate = date.today();
		task.CTIInteractionID__c = interactionID;
		task.CallType = callType;
		//task.WrapTime__c = wrapTime
		/*
		if (comments != '') {
		  if (task.Description == null) {
			task.Description = '';
		  }
		  task.Description += '\n' + comments;
		}

		for (String sfdcField : taskMap.keySet()) {
			System.debug(sfdcField + ':' + taskMap.get(sfdcField));
			task.put(sfdcField, taskMap.get(sfdcField));
		}
		*/
		update task;
		System.debug('Task id = ' + task.Id);

		comments += (!String.isEmpty(comments) ? '\n\n' : '') + JSON.serialize(userData);
		insert new Attachment(Name = 'InboundLog.txt', parentId = task.id, body = Blob.valueOf(comments));

		moveNewCasesToBackOffice();

		return task;
	}

	/**
	 * Check whether the account passed in is a person account.
	 * This is used when tracking the users navigation through service cloud.
	 */
	@RemoteAction
	global static Boolean isPersonAccount(String accountId) {
		List<Account> acc = [Select Id, IsPersonAccount From Account Where Id = :accountId LIMIT 1];
		return (acc.size() > 0 ? acc[0].IsPersonAccount : false);
	}

	/**
	  * @description	   method used to move the created cases on the call back to SSSW Back Office Queue after call ending
	  * @param			 NA
	  * @return			NA
	  * @throws			NA
	  */
	private static void moveNewCasesToBackOffice() {
		List<Case> cases = [select AllocateToQueue__c from Case where OwnerId = :UserInfo.getUserId() and createddate = today and Status = 'New'];
		for (Case c : cases) {
			c.AllocateToQueue__c = true;
			c.Bypass_Data_enforcement__c = true;
		}
		update cases;
	}

}