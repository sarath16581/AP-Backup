/**************************************************
Description:   Controller class for page exposed as CTI adaptor for the upgraded version of workspace

History:
--------------------------------------------------
2018-03-17 kalpita.talwadekar@auspost.com.au created
2018-04-18 nathan.franklin@auspost.com.au changed query to increase performance
2018-06-01 nathan.franklin@auspost.com.au added phone number to task creation and minor tidyups
2024-06-13 Parveen Kaushik Added a filter in SOQL for mapping model. See CSLU-470 (JIRA) for details.
**************************************************/
global class AP_ConnectorController {

	public String proxyCase { get; set; }

	public String txtRefID { get; set; }

	public String txtPhoneNumber { get; set; }

	/**
	  * @description       method used to find the contact record based on incoming phone call
	  * @param             String searchId, String searchValue
	  * @return            Object
	  * @throws            NA
	  */
	@RemoteAction
	global static Object findContact(String searchId, String searchValue) {
		System.Debug('findContact: searchId - ' + searchId + ', searchValue - ' + searchValue);

		Long t1 = System.currentTimeMillis();
		String query = 'SELECT Id, Name, AccountId FROM Contact WHERE Phone = :searchValue OR  MobilePhone = :searchValue';
		System.Debug('query = ' + query);
		List<Contact> contacts = Database.query(query);

		Long t2 = System.currentTimeMillis();
		System.Debug('>> QUERYTIME Contact: ' + (t2 - t1));

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

		// throw in an account search if we've found nothing while we're here
		// NF - 2018-04-17: due to 31 second query time, I've split this up into 2 separate queries to ensure this returns fast.

		// Grab record types for account/person accounts
		// this will allow the query to be selective and reduce the overall query time.
		List<Id> accRecordTypes = new List<Id>();
		List<Id> personRecordTypes = new List<Id>();
		List<RecordType> recordTypes = [Select Id, IsPersonType From RecordType Where SObjectType = 'Account' And IsActive = true];
		for (RecordType recordType : recordTypes) {
			if (recordType.IsPersonType) {
				personRecordTypes.add(recordType.Id);
			} else {
				accRecordTypes.add(recordType.Id);
			}
		}
		System.Debug('>> accRecordTypes: ' + accRecordTypes);
		System.Debug('>> personRecordTypes: ' + personRecordTypes);

		List<Account> accounts = new List<Account>();

		// grab the person accounts
		t1 = System.currentTimeMillis();
		query = 'SELECT Id, Name FROM Account WHERE RecordTypeId In :personRecordTypes And PersonMobilePhone  = :searchValue';
		List<Account> accQuery = Database.query(query);
		accounts.addAll(accQuery);
		t2 = System.currentTimeMillis();
		System.Debug('>> QUERYTIME PersonAccount: ' + (t2 - t1));

		// grab any normal accounts
		t1 = System.currentTimeMillis();
		query = 'SELECT Id, Name FROM Account WHERE RecordTypeId In :accRecordTypes And Phone = :searchValue';
		accQuery = Database.query(query);
		accounts.addAll(accQuery);
		t2 = System.currentTimeMillis();
		System.Debug('>> QUERYTIME Account: ' + (t2 - t1));

		if (!accounts.isEmpty()) {
			Integer numAccounts = accounts.size();
			System.Debug('accounts found=' + numAccounts);

			if (numAccounts > 1) {
				Account c = accounts[0];
				c.Id = null; // indicator for multiple contacts
				return c;
			} else if (numAccounts == 1) {
				return accounts[0];
			}
		}

		return null;
	}

	/** START - APRIVERA - Modified 09/04/17 **/
	/**
	  * @description       method used to create a custom activity record
	  * @param             String searchId, String searchValue
	  * @return            Object
	  * @throws            NA

	@RemoteAction global static Task createCustomActivity (
								string inWhoId,
								string inWhatId,
								string subject,
								string description,
								string outcome,
								string duration,
								integer durationSecs,
								string refID,
								string phone,
								string queue,
								string serviceType,
								string segment,
								string interactionID,
								string calltype,
								String targetSkill,
								string enquiryType,
								string enquirySubtype,
								string productCategory,
								string productSubcategory,
								string IWS_CallUUID,
								string IWS_CaseUid,
								integer wrapTime
								) {
		Task result = null;
		string whoId = null;
		string whatId = null;

		if(!string.isEmpty(inWhoId) && inWhoId.startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())){
			whoId = inWhoId;
		}

		if(!string.isEmpty(inWhatId) && inWhatId.startsWith(Case.SObjectType.getDescribe().getKeyPrefix())){
			Case[] c = [select contactId from case where id = :inWhatId.trim() LIMIT 1];
			if (!c.isEmpty()) {
				whatId = c[0].id;

				if(string.isEmpty(whoId)) {
					whoId = c[0].ContactId;
				}
			}
		}

		ID recordTypeID = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWCall' limit 1].Id;
		Task task = new Task(ActivityDate = Date.today(),
						RecordTypeId = recordTypeId,
						CallDisposition =  outcome, //'Contact left a message',
						CallType = calltype,
						target_skill__c = targetSkill, //added by kalpita to recognize the target skill for callback
						Description = 'For logs, please see attachment.',
						Phone__c = phone,
						Status = 'New',
						Subject = subject,
						Type = 'Call',
						CallDuration__c = duration,
						CallDurationInSeconds = durationSecs,
						ReferenceID__c = refID,
						WhoId = whoId,
						WhatId = whatId,
						Queue__c = queue,
						ServiceType__c = serviceType,
						Segment__c = segment,
						Outcome__c = outcome,
						CTIInteractionID__c = interactionID,
						Enquiry_Type__c = enquiryType,
						Enquiry_Sub_Type__c = enquirySubtype,
						Product_Category__c = productCategory,
						Product_Sub_Category__c = productSubcategory,
						IWS_CallUUID__c = IWS_CallUUID,
						IWS_CaseUid__c = IWS_CaseUid,
						WrapTime__c = wrapTime
						);

		insert task;
		result = task;
		insert new Attachment(Name = 'InboundLog.txt', parentId = task.id, body = Blob.valueOf(description));
		//moveNewCasesToBackOffice();
		return result;
	}

	@RemoteAction global static Task closeTask(ID taskId,
			String whatId,
			String subject,
			String comments,
			Map<String, String> userData,
			String dispositionKVP,
			Map<String, String> taskMap,
			string callDuration,
			string description,
			string outcome,
			integer durationSecs,
			string refID,
			string phone,
			string queue,
			string serviceType,
			string segment,
			string interactionID,
			string calltype,
			String targetSkill,
			string enquiryType,
			string enquirySubtype,
			string productCategory,
			string productSubcategory,
			string IWS_CallUUID,
			string IWS_CaseUid,
			integer wrapTime) {
		System.Debug('closeActivity: ' + taskId);

		Task[] tasks = [SELECT Id, Description FROM Task WHERE Id= :taskId];
		Task task = null;

		if (tasks.size() == 0) { // created yet?
		   System.Debug('###Debug : Task Size - ' + tasks.size());
			task = createCustomActivity('',whatId,subject,description,outcome,callDuration,durationSecs,refID,phone,queue,serviceType,
					segment,interactionID,calltype,targetSkill,enquiryType,enquirySubtype,productCategory,
					productSubcategory,IWS_CallUUID,IWS_CaseUid,wrapTime);
		  //task = createTask(taskId, whatId, subject, userData, taskMap); // task id is actually the contact id
		  if (task == null) {
			return null;
		  }
		}
		else {
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
			task.CallDurationInSeconds = Integer.valueOf(callDuration);
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
			System.Debug('Task id = '  + task.Id);
			return task;
	   }

	/** END - APRIVERA - Modified 09/04/17 **/


	/**
	  * @description       method used to retreive an existing contact based on contact id from jscript
	  * @param             String contactId, String field
	  * @return            Contact
	  * @throws            NA
	  */
	@RemoteAction
	global static Contact getContact(String contactId, String field) {
		System.Debug('getContact: contactId - ' + contactId);
		if (field != null) {
			field = ', ' + field;
		} else {
			field = '';
		}

		String query = 'SELECT Id, Name, AccountId' + field + ' FROM Contact WHERE Id= :contactId';
		System.Debug('query = ' + query);
		List<Contact> contacts = Database.query(query);
		if (!contacts.isEmpty()) {
			return contacts[0];
		} else {
			return null;
		}
	}

	/**
	  * @description       method used to retreive an existing contact from a task/activity when a user clicks on dial (number) from task screen
	  * @param             String taskId
	  * @return            Task
	  * @throws            NA
	  */
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

	/**
	  * @description       method used to create a task record on call start
	  * @param             String taskId
	  * @return            Task
	  * @throws            NA
	  */
	@RemoteAction
	global static Task createTask(String contactId,
		String whatId,
		String subject,
		Map<String, String> userData,
		Map<String, String> taskMap) {
		System.Debug('createActivity: ' + contactId);

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
				System.Debug(sfdcField + ':' + taskMap.get(sfdcField));
				task.put(sfdcField, taskMap.get(sfdcField));
			}
		}

		insert task;
		System.Debug('Task id = ' + task.Id);

		return task;
	}


	/**
	  * @description       method used to retreive an existing Case from caseNumber from incoming call
	  * @param             String caseNumber
	  * @return            Case
	  * @throws            NA
	  */
	@RemoteAction
	global static Case findCase(String caseNumber) {
		System.Debug('findCase: ' + caseNumber);
		List<Case> cases = [SELECT CaseNumber, ContactId FROM Case WHERE CaseNumber = :caseNumber];

		if (!cases.isEmpty()) {
			return cases[0];
		}

		return null;
	}

	/**
	  * @description       method used to create an automated case record based on incoming call details (AP Call Center -- no use case)
	  * @param             String contactId, String accountId, String mediaType, String subject, Map<String, String> userData, Map<String, String> caseMap
	  * @return            Case
	  * @throws            NA
	  */
	@RemoteAction
	global static Case createCase(String contactId, String accountId, String mediaType, String subject, Map<String, String> userData, Map<String, String> caseMap) {
		System.Debug('createCase: ' + subject);

		// check to see if this is an account and not a contact
		String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
		String prefix = contactId.substring(0, 3);
		if (prefix == accountPrefix) {
			accountId = contactId;
			contactId = null;
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

	/**
	  * @description       method used to set the default - pre-populated clear view codes based on user selection in incoming call
	  * @param             string customerSegment, string serviceType
	  * @return            CTIDefaultValue
	  * @throws            NA
	  */
	@RemoteAction
	global static CTIDefaultValue defaultValues(string customerSegment, string serviceType) {
		CTIDefaultValue result = new CTIDefaultValue();
		string key = customerSegment.trim() + serviceType.trim();
		if (key != '') {
			List<MiniCaseFieldMapping__c> mappings = [select ProductCategory__c, ProductSubcategory__c, Type__c from MiniCaseFieldMapping__c where CTIKey__c like :key AND MappingModel__c =: SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL];
			if (mappings.size() > 0) {
				result = new CTIDefaultValue(mappings[0]);
			}
		}
		return result;
	}

	/**
	  * @description       inner wrapper class to set the default - pre-populated clear view codes based on user selection in incoming call
	  * @param             string customerSegment, string serviceType
	  * @return            CTIDefaultValue
	  * @throws            NA
	  */
	global class CTIDefaultValue {
		public string productCategory { get; set; }
		public string productSubcategory { get; set; }
		public string caseType { get; set; }

		public CTIDefaultValue(MiniCaseFieldMapping__c mapping) {
			this.productCategory = mapping.ProductCategory__c;
			this.productSubcategory = mapping.ProductSubcategory__c;
			this.caseType = mapping.Type__c;
		}

		public CTIDefaultValue() {

		}
	}

	/**
	  * @description        method to close an existing or create new and mark same as completed on end of call.
	  * @param              ID taskId, ID whatId, String subject, String comments,
	  *                      Map<String, String> userData,String dispositionKVP,Map<String, String> taskMap,
	  *                      Integer callDuration, String calltype,  string queue, String interactionID, String conId, String caseId
	  * @return             Task
	  * @throws            NA
	  */
	@RemoteAction
	global static Task closeTask(ID taskId, ID whatId, String subject, String comments, Map<String, String> userData,
									String dispositionKVP, Map<String, String> taskMap, Integer callDuration,
									//extra params added by Kalpita for mapping in task record
									String calltype, string queue, String interactionID, String conId, String caseId) {

		System.Debug('closeActivity: ' + taskId);

		Task task = null;
		List<Task> tasks = new List<Task>();
		if (!String.isBlank(taskId)) {
			tasks = [SELECT Id, Description FROM Task WHERE Id = :taskId];
		}

		if (tasks.size() == 0) { // created yet?
			//updated by Kalpit to add conId instead of whatId
			task = createTask(conId, caseid, subject, userData, taskMap); // task id is actually the contact id //updated by kalpita to rectify the whatId which is case.
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
		//fields updated by Kalpita
		//updated for caseId
		task.WhatId = !String.isBlank(caseid) ? caseId : conId; //findCase().Id;
		task.RecordTypeId = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWCall' limit 1].Id;
		task.CallType = calltype;
		task.target_skill__c = userData.get('RRequestedSkillCombination');
		task.Description = 'For logs, please see attachment';
		task.Phone__c = userData.get('PhoneNumber');
		task.Type = 'Call';
		task.Queue__c = userData.get('IWS_DNIS');
		task.ServiceType__c = userData.get('r_IWS_ServiceType');
		task.Segment__c = userData.get('r_IWS_CustomerSegment');
		task.Outcome__c = userData.get('BusinessResultDisplay');
		task.CTIInteractionID__c = interactionID;
		task.Enquiry_Type__c = userData.get('ENG_DimAttribute_2');
		task.Enquiry_Sub_Type__c = userData.get('ENG_DimAttribute_1');
		task.Product_Category__c = userData.get('r_IWS_ServiceType');
		task.Product_Sub_Category__c = userData.get('r_IWS_ServiceSubType');
		task.IWS_CallUUID__c = userData.get('IWS_CallUuid');
		task.IWS_CaseUid__c = userData.get('IW_CaseUid');
		task.ActivityDate = date.today();
		//task.WrapTime__c = wrapTime
		/*
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
		*/
		update task;
		System.Debug('Task id = ' + task.Id);

		insert new Attachment(Name = 'InboundLog.txt', parentId = task.id, body = Blob.valueOf(comments));

		moveNewCasesToBackOffice();

		return task;
	}


	/**
	  * @description       method used to move the created cases on the call back to SSSW Back Office Queue after call ending
	  * @param             NA
	  * @return            NA
	  * @throws            NA
	  */
	static void moveNewCasesToBackOffice() {
		List<Case> cases = [select AllocateToQueue__c from Case where OwnerId = :UserInfo.getUserId() and createddate = today and Status = 'New'];
		for (Case c : cases) {
			c.AllocateToQueue__c = true;
			c.Bypass_Data_enforcement__c = true;
		}
		update cases;
	}

	/**
	  * @description       method to pass through the full contact Id
	  * @param             id shortId
	  * @return            ID
	  * @throws            NA
	  */
	@RemoteAction
	global static id getFullID(id shortId) {
		return shortId;
	}
}