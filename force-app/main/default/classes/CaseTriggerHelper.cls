/**
  * @author	   : nandan.narasappa@auspost.com.au
  * @date		 : 16/05/2015
  * @description  : Helper Class for CaseCommonTrigger
  * @test BGSCase_Test, CaseCommonTrigger_Test
  * @changelog
  * 16/05/2015		  nandan.narasappa@auspost.com.au			 Created
  * 05/11/2015		  nandan.narasappa@auspost.com.au			 Added updateParentCase method
  * 05/11/2015		  nandan.narasappa@auspost.com.au			 Added copyAuthorisedContacts method
  * 10/03/2016		  nandan.narasappa@auspost.com.au			 Updated completeMilestone method to send additional parameter
  * 14/04/2017		  kalpita.talwadekar@auspost.com.au		   Updated the recurssion flags to move one level up in the methods
  * 17/01/2020		  vcheng@salesforce.com   Added BGS milestone completion on Case Closure
  * 27/04/2020			arjun.singh@auspost.com.au					Added a method to update case sent to network date
  * 07/05/2020		  vcheng@salesforce.com   Added sendClosureEmails to send an email on close BGS case
  * 29/05/2020		  arjun.singh@auspost.com.au				  Updated updateSentToNetworkDate to reset Sent to Network Date and assign to attibute of Case on Network Change for MyNetwork Community
  * 15/07/2020			seth.heang@auspost.com.au					STP2240,STP2242 - Updated sendClosureEmails to stop sending outbound email if reason is due to duplicate, and update OrgWideEmailAddress to 'noreply@auspost.com.au'
  * 2022-02-17 - Nathan Franklin - updated minor comments
  * 2022-11-04 - Nathan Franklin - slightly refactor processHLCCases to only execute a dml if needed... NOTE: The method should be refactored... I don't think a DML is needed at all, but have ran out of time
  * 2023-06-02 - Mahesh Parvathaneni - Added logic to complete milestones for transport enquiry record type cases
  */
  public with sharing class CaseTriggerHelper{

	// Constants
	private static final String HLC = 'HLC';
	private static final String CR = 'CR';
	private static final String SSSW = 'SSSW';
	private static final String CHARTER_MILESTONE = 'Charter';
	private static final String INTERNAL_MILESTONE_STATUS = 'On Hold';
	private static final String MILESTONE_COMP_ERROR_MSG = 'Error in milestone completion. Please contact system administrator.';
	public static final Map<String,String> QUEUE_FIELD_MAP = new Map<String,String> {'HLC' => 'IsHLC__c',
	'CR' => 'IsCR__c'};
	public static final Map<String,String> OPP_QUEUE_FIELD_MAP = new Map<String,String> {'HLC' => 'IsCR__c',
	'CR' => 'IsHLC__c'};

	public static Boolean isUpdateHLCRecursive = false;	 // flag for HLC recursive
	public static Boolean isCompleteMilestonRecursive = false;	  // flag for milestone completion
	public static Boolean isUpdateParentCaseRecursive = false;	  // flag to prevent recusive execution of Update parent case

	public static Map<Id,String> recordTypeMap = new Map<Id,String>();

	public static Map<Id,Group> queueMap = new Map<Id,Group>();
	public static Map<Id,GroupMember> queueMbrMap = new Map<Id,GroupMember>();

	public static Set<String> nonCharterMileStones = new Set<String>();
	private static Set<Id> validRecTypes;				   // type of cases for which code executes
	private static Set<Id> bgsRecTypes;				   // type of cases for Service Delivery
	private static Id transportEnquiryRecTypeId;

	// Set the recordTypeMap variable to store the map of id and record type name
	static{
		try{
			// get case record type
			recordTypeMap = recordTypeMap.isEmpty() ? Utility.getsObjectRecordTypeNames(String.valueOf(Case.getsObjectType())) : recordTypeMap;

			// get all valid record types for the SSSW functionality
			validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);


			bgsRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),BGSConstants.SERVICE_DELIVERY_NAME);
			// Get the Record Type Id for Transport Enquiry Cases
			transportEnquiryRecTypeId = TransportEnquiryCaseService.getInstance().getTransportEnquiryRecordTypeId();

			if(queueMap.isEmpty()){
				queueMap = HLCUtility.getGroupDetails(HLCUtility.AGENT_QUEUE_SET,HLCUtility.QUEUE);   // variable to store queue details
			}
			if(queueMbrMap.isEmpty() && !queueMap.isEmpty()){
				queueMbrMap = HLCUtility.getGroupMembers(queueMap.keyset());					// fetch Group members
			}

			System.debug('** queueMap ==>'+queueMap);
			System.debug('** queueMbrMap ==>'+queueMbrMap);
			Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());						// Get Query Row Limit
			for(MilestoneType type : [SELECT Name FROM MilestoneType
			WHERE Name !=: SSSWConstants.CHARTER_MILESTONE LIMIT : rowLimit]){
				nonCharterMileStones.add(type.Name);
			}
		}
		catch(Exception exp){
			System.debug('** StackTrack ==>'+ exp.getStackTraceString());
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), SSSWConstants.STATIC_BLOCK,
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method update IsHLC or IsCR based on ownership
	  * @param			 caseList - List<Case> , oldCaseMap - Map<Id,Case>
	  * @return			Void
	  * @throws			NA
	  */
	public void updateHLC(List<Case> caseList,Map<Id,Case> oldCaseMap){
		List<Case> updateCaseList = new List<Case>();   // cases to be updated
		isUpdateHLCRecursive = true;  // -- kalpita 4.11.17 - moved recursion flag up
		try{
			if(oldCaseMap == null){	 // insert scenario
				Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());						// Get Query Row Limit
				updateCaseList = [SELECT Id,IsHLC__c,IsCR__c,RecordTypeId,OwnerId FROM Case WHERE Id IN: caseList LIMIT : rowLimit]; // Fetch case for After insert scenario
				updateCaseList = processHLCCases(updateCaseList,null);	 // Update flag based on ownership
			}
			else{   // update scenario
				processHLCCases(caseList,oldCaseMap);	  // Update flag based on ownership
			}

			if(!updateCaseList.isEmpty()){
				//isUpdateHLCRecursive = true;		// set recursive flag to true // -- kalpita 4.11.17 - commented recursion flag in loop
				// Updates newly created records and throw errors only for failed records using transaction control
				List<Database.SaveResult> saveResults = Database.update(updateCaseList,false);
				for(Database.SaveResult result : saveResults){  // iterate through saveResults to throw DML error to user
					if(!result.isSuccess()){
						System.debug('** Error Message ==>'+result.getErrors().get(0).getMessage());
						new Case(Id = result.getId()).addError(result.getErrors().get(0).getMessage()); // throw error message to user in case of failure
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), SSSWConstants.METH_UPDATEHLC,
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method populates IsHLC or IsCR based on ownership
	  * @param			 caseList - List<Case> , queueMap - Map<Id,Group>, queueMbrMap - Map<Id,GroupMember>
	  * @return			List<Case>
	  * @throws			NA
	  */
	private static List<Case> processHLCCases(List<Case> caseList,Map<Id,Case> oldCaseMap){
		Boolean hasUpdates = false;
		String queueType = null;			// would contain HLC or CR if part of HLC or CR queue
		List<Case> updateCaseList = new List<Case>();
		for(Case caseRec : caseList){
			if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
				if(queueMap.containsKey(caseRec.OwnerId)){  // check if case owner is HLC or CR queue
					queueType = HLCUtility.QUEUE_NAME_MAP.get(queueMap.get(caseRec.OwnerId).DeveloperName);
				}
				else if(queueMbrMap.containsKey(caseRec.OwnerId)){  // check if agent is part of HLC or CR queue
					queueType = HLCUtility.QUEUE_NAME_MAP.get(queueMap.get(queueMbrMap.get(caseRec.OwnerId).GroupId).DeveloperName);
				}
				else{
					queueType = null;   // set queue type to null if case owner is not part of HLC/CR queue
				}
				// verify if agent is part of HLC/CR queue and populate IsHLC & IsCR field
				if(String.isNotBlank(queueType) && QUEUE_FIELD_MAP.get(queueType) != null
					&& OPP_QUEUE_FIELD_MAP.get(queueType) != null){

					if(caseRec.get(QUEUE_FIELD_MAP.get(queueType)) !== true) {
						caseRec.put(QUEUE_FIELD_MAP.get(queueType),true);
						hasUpdates = true;
					}
					if(caseRec.get(OPP_QUEUE_FIELD_MAP.get(queueType)) === true) {
						caseRec.put(OPP_QUEUE_FIELD_MAP.get(queueType),false);
						hasUpdates = true;
					}
				}
				else{
					if(caseRec.get(QUEUE_FIELD_MAP.get(HLC)) === true) {
						caseRec.put(QUEUE_FIELD_MAP.get(HLC),false);
						hasUpdates = true;
					}
					if(caseRec.get(QUEUE_FIELD_MAP.get(CR)) === true) {
						caseRec.put(QUEUE_FIELD_MAP.get(CR),false);	 // Nandan : corrected map variable
						hasUpdates = true;
					}
				}
				if(hasUpdates) {
					updateCaseList.add(caseRec);
				}
			}
		}
		return updateCaseList;
	}

	/**
	  * @description	   This method sets the milestone completion date to persist it in case
	  * @param			 caseList - List<Case> , oldCaseMap - Map<Id,Case>
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void completeMilestone(List<Case> caseList,Map<Id,Case> oldCaseMap){
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
		List<CaseMilestone> updateMilestones = new List<CaseMilestone>();	   // milestones to be updated
		List<Case> compMilestoneCases = new List<Case>();   // cases to be processed
		List<Case> milestoneCasesToProcess = new List<Case>();
		isCompleteMilestonRecursive = true; // -- kalpita 4.11.17 - moved recursion flag up
		try{
			Case oldCase = null;
			QM__c queueCS = QM__c.getInstance();	// fetch queue management custom setting values
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
					oldCase = oldCaseMap.get(caseRec.Id);	   // get old values of case
					/* verify if status is changed and the combination of customer milestone violated, internal milestone violated, 
						network milestone violated and status */
					if(caseRec.Status != null && caseRec.Status != oldCase.Status &&
						(recordTypeMap.get(caseRec.RecordTypeId).contains(SSSW)
							&& ((caseRec.Customer_Milestones_Violated__c != null && caseRec.Status != queueCS.Customer_Status__c) ||
							(caseRec.Internal_Milestones_Violated__c != null && !INTERNAL_MILESTONE_STATUS.equalsIgnoreCase(caseRec.Status)) ||
							(caseRec.Facility_Milestones_Violated__c != null && caseRec.Status != queueCS.Network_Status__c))
						)){

						compMilestoneCases.add(caseRec);
					}
				}
				else if((Utility.isValidRecordType(bgsRecTypes, caseRec.RecordTypeId) && caseRec.IsClosed == true) || 
					Utility.isValidRecordType(new Set<Id>{transportEnquiryRecTypeId}, caseRec.RecordTypeId))
				{
					// only complete milestones if the BGS Case is moving to closed (or) case is of transport enquiry
					// compare with existing fields to confirm that we need to action, anti-recursion guard
					oldCase = oldCaseMap.get(caseRec.Id);
					if(oldCase.Status != caseRec.Status)
					{
						//complete all the milestones for BGS/Transport enquiry cases
						milestoneCasesToProcess.add(caseRec);
					}
				}
			}

			if(!compMilestoneCases.isEmpty()){  // check if cases require milestone to be completed
				//isCompleteMilestonRecursive = true;		// set recursive flag to true // -- kalpita 4.11.17 - commented recursion flag in loop
				System.debug('** nonCharterMileStones==>'+nonCharterMileStones);
				Utility.completeCaseMilestones(compMilestoneCases,nonCharterMileStones,false);
			}

			if(!milestoneCasesToProcess.isEmpty())
			{
				Utility.completeCaseMilestones(milestoneCasesToProcess, nonCharterMileStones, true);
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), SSSWConstants.METH_COMP_MILESTONE,
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method is invoked in before update event, sets the Parent Case to 
						   Allocate to the Queue when a Child is reallocated
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void updateParentCase(Map<Id,Case> caseMap){
		try{
			Set<Id> parentCaseIds = new Set<Id>();  // stores parent case Id not in current context
			List<Case> caseList = new List<Case>(); // stores valid SSSW case
			//isUpdateParentCaseRecursive = true; // -- kalpita 4.11.17 - moved recursion flag up
			for(Case csRec : caseMap.values()){
				if(Utility.isValidRecordType(validRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					if(csRec.AllocateToQueue__c && csRec.ParentId != null){
						if(!caseMap.containsKey(csRec.ParentId)){
							parentCaseIds.add(csRec.ParentId);
						}
						caseList.add(csRec);
					}
				}
			}

			if(!caseList.isEmpty()){	// check if caseList got values
				isUpdateParentCaseRecursive = true; // set flag to true // -- kalpita 4.11.17 - commented recursion flag in loop
				// get the child queue id to assign case
				Id childQueueId = Utility.getGroupId(SSSWConstants.QUEUE_CHILDCASE_DEV,SSSWConstants.QUEUE);
				Map<Id,Case> parentCaseMap = new Map<Id,Case>();
				if(childQueueId != null){   // check if child queue id is available
					if(!parentCaseIds.isEmpty()){   // check if parentCaseIds got value
						Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
						// fetch parent cases to reallocate
						for(Case parentCase : [SELECT Id,Status,ParentId,AllocateToQueue__c,SystemUpdate__c,IsClosed FROM Case
						WHERE Id IN: parentCaseIds AND Permanent_Close__c = false LIMIT : rowLimit]){
							parentCase.Bypass_Data_enforcement__c = true;
							parentCaseMap.put(parentCase.Id,parentCase);
						}
					}
					List<Case> parenCaseList = new List<Case>();
					for(Case childCase : caseList){
						// Disable queue allocation for child case & assign to child case queue
						childCase.OwnerId = childQueueId;
						childCase.AllocateToQueue__c = false;
						childCase.Bypass_Data_enforcement__c = true;
						Case parentCase;
						// Set AllocateToQueue__c to true to trigger Case routing & set system update to child case update
						if(parentCaseMap.containsKey(childCase.ParentId) && parentCaseMap.get(childCase.ParentId) != null){
							parentCase = parentCaseMap.get(childCase.ParentId);
							parentCase.AllocateToQueue__c = true;
							parentCase.SystemUpdate__c = SSSWConstants.STAT_CHILD_CASE_UPDATE;
							parentCase.Status = parentCase.IsClosed ? SSSWConstants.STAT_CHILD_CASE_UPDATE : parentCase.Status;
							parenCaseList.add(parentCase);
						}
						else{   // scenario where parent case is in trigger context
							if(caseMap.containsKey(childCase.ParentId) && caseMap.get(childCase.ParentId) != null){
								parentCase = caseMap.get(childCase.ParentId);
								parentCase.AllocateToQueue__c = true;
								parentCase.SystemUpdate__c = SSSWConstants.STAT_CHILD_CASE_UPDATE;
								parentCase.Status = parentCase.IsClosed ? SSSWConstants.STAT_CHILD_CASE_UPDATE : parentCase.Status;
							}
						}
					}

					if(!parenCaseList.isEmpty()){   // check if parenCaseList got values before DML
						Database.update(parenCaseList,false);
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), SSSWConstants.METH_UPDATE_PARENT_CASE,
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method is invoked in after insert event, creates authorized contacts for the case
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void copyAuthorisedContacts(List<Case> caseList){
		try{
			// get record type details for Authorized contacts
			Map<String,Id> authContRecTypeMap = Utility.getsObjectRecordTypes(String.valueOf(AuthorisedContacts__c.getsObjectType()));
			Set<Id> contactIds = new Set<Id>();
			List<Case> validCases = new List<Case>();
			for(Case csRec : caseList){
				// check if record type is valid & case got contact
				if(validRecTypes.contains(csRec.RecordTypeId) && csRec.ContactId != null){
					contactIds.add(csRec.ContactId);
					validCases.add(csRec);
				}
			}

			if(!validCases.isEmpty()){  // check if validCases got value
				Map<Id,Id> authorizedConMap = new Map<Id,Id>();
				Id allCaseRecTypeId = authContRecTypeMap.get(SSSWConstants.RECTYPE_ACON_ALLCASE);   // get AllCases record type
				Id caseOnlyRecTypeId = authContRecTypeMap.get(SSSWConstants.RECTYPE_ACON_CASEONLY); // get CaseOnly record type
				Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
				// fetch authorized contacts to copy
				for(AuthorisedContacts__c authCon : [SELECT AuthorisingContact__c,AuthorisedContact__c FROM AuthorisedContacts__c
				WHERE AuthorisingContact__c IN: contactIds AND RecordTypeId =: allCaseRecTypeId
				LIMIT : rowLimit]){
					authorizedConMap.put(authCon.AuthorisingContact__c,authCon.AuthorisedContact__c);
				}

				if(!authorizedConMap.isEmpty()){	// check if authorizedConMap got values
					List<AuthorisedContacts__c> authConList = new List<AuthorisedContacts__c>();
					// create case only authorized contact for case
					for(Case csRec : validCases){
						if(csRec != null && csRec.ContactId != null){
							AuthorisedContacts__c authCon = new AuthorisedContacts__c();
							authCon.AuthorisingContact__c = csRec.ContactId;
							authCon.AuthorisedContact__c = authorizedConMap.containsKey(csRec.ContactId) ?
								authorizedConMap.get(csRec.ContactId) : authCon.AuthorisedContact__c;
							authCon.RecordTypeId = caseOnlyRecTypeId;
							authCon.Case__c = csRec.Id;
							authConList.add(authCon);
						}
					}

					if(!authConList.isEmpty()){ // check if authConList got values before DML
						Database.insert(authConList,false);
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), SSSWConstants.METH_UPDATE_PARENT_CASE,
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method is invoked in after insert event, creates authorized contacts for the case
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void updateCaseIdonArticle(List<Case> cseList) {
		try {
			set<Id> articleIDs = new set<id>();
			for(Case cse: cseList){
				if(Utility.isValidRecordType(validRecTypes,cse.RecordTypeId)) {
					articleIDs.add(cse.ArticleTest__c);
				}
			}

			list<Article__c> artlist = new list<Article__c>();
			for(Article__c art: [select Id, Case__c from Article__c where Id in: articleIDs]) {
				for(Case c: cseList) {
					if(art.Id == c.ArticleTest__c) {
						art.Case__c = c.Id;
						artlist.add(art);
					}
				}
			}

			if(!artList.isEmpty()) {
				database.update(artList);
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), SSSWConstants.METH_UPDATE_PARENT_CASE,
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method is called on before update to populate/update
	  *					 'Sent to Network Date' field when the case is assigned to network queue
	  * @param			 caseList - List<Case> , oldCaseMap - Map<Id,Case>
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void updateSentToNetworkDate(List<Case> caseList,Map<Id,Case> oldCaseMap){

		try{
			Case oldCase = null;
			Id networkQueue = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
			for(Case caseRecord : caseList){
				oldCase = oldCaseMap.get(caseRecord.Id);
				//When case is assigned to Network Queue , then Sent to Netwok Date should be updated
				if(caseRecord.ownerId != oldCase.ownerId && caseRecord.ownerId == networkQueue){
					caseRecord.Sent_To_Network_Date__c = system.now();
					caseRecord.PONUser__c = null;
				}else if (caseRecord.ownerId != oldCase.ownerId && caseRecord.ownerId != networkQueue){//When case is re-assigned back to contact center then sent to network date and assign to should be reset
					caseRecord.Sent_To_Network_Date__c = null;
					caseRecord.PONUser__c = null;
				}
				else if(caseRecord.Network__c != oldCase.Network__c && caseRecord.ownerId == networkQueue){ //When Case Network is changed then Sent to network date should be updated and assign to should be reset
					caseRecord.Sent_To_Network_Date__c = system.now();
					caseRecord.PONUser__c = null;
				}
			}

		}catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				CaseTriggerHelper.class.getName(), 'updateSentToNetworkDate',
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}


	/**
	*
	* @description		Method to send emails to newly closed cases
	*					STP-2240 Outbound Email is sending from 'noreply@auspost.com.au' using OrgWideEmailAddress
	*					STP-2242 Stop outbound email on case 'closed' if reason is due to duplicate
	* @param			newCaseMap a Map of Id - Cases from Trigger.New
	* @param 			oldCaseMap a Map of Id - Cases from Trigger.Old to compare if it's a newly closed case
	* @return			Void
	* @throws			EmailException - BGS_CASE_CLOSURE_TEMPLATE Email template not found
	*/
	public void sendClosureEmails(Map<Id,Case> newCaseMap, Map<Id,Case> oldCaseMap)
	{
		List<Case> newlyClosedBGSCases = new List<Case>();
		List<Id> contactIdsToEmail = new List<Id>();

		// loop through each case to check if it's newly closed
		for(Id caseId: newCaseMap.keySet())
		{
			Case newCase = newCaseMap.get(caseId);
			Case oldCase = oldCaseMap.get(caseId);

			// if newly closed and ContactId is available
			if(!oldCase.IsClosed && newCase.IsClosed && newCase.ContactId != null)
			{
				// store the Contact Id to SOQL the email later
				contactIdsToEmail.add(newCase.ContactId);

				// separate into Case RecTypes
				if(Utility.isValidRecordType(bgsRecTypes, newCase.RecordTypeId))
				{
					// do not store case and do not send out email if reason was 'Duplicate Case'
					if(BGSConstants.CASE_RESOLUTION_CODE_CLOSED_DUPLICATE.equals(newCase.ResolutionCode__c)){
						continue;
					}
					newlyClosedBGSCases.add(newCase);
				}
				// if any other case types are to be added in the future
			}
		}


		// Create Emails for BGS (Service Delivery) Cases using the email Template
		if(newlyClosedBGSCases.size() > 0)
		{
			System.debug('CaseTriggerHelper:: send Emails count ' + newlyClosedBGSCases.size());
			// reserve sending email limit
			Messaging.reserveSingleEmailCapacity(newlyClosedBGSCases.size());

			// soql for Contact email addresses
			List<Contact> contactsToEmail = [
				SELECT Id, Email
				FROM Contact
				WHERE Id IN :contactIdsToEmail
			];

			// parse results into a Map for creating the email below
			Map<Id, String> contactEmails = new Map<Id, String>();
			for(Contact con: contactsToEmail)
			{
				contactEmails.put(con.Id, con.Email);
			}

			// email template
			List<EmailTemplate> bgsTemplates = [SELECT Id, Subject, HtmlValue, Body
			FROM EmailTemplate
			WHERE Name =: BGSConstants.BGS_CASE_CLOSURE_TEMPLATE
			LIMIT 1];

			// Early out if no template found
			if(bgsTemplates.size() < 1) {
				// If the template is not found, throw an error
				throw new EmailException('CaseTriggerHelper:: Email Template ' + BGSConstants.BGS_CASE_CLOSURE_TEMPLATE + ' not found.');
			}
			Id bgsTemplateID = bgsTemplates[0].Id;

			// loop through the closed cases and create the emails
			List<Messaging.Email> bgsClosureEmails = new List<Messaging.Email>();
			// retrieve 'noreply@auspost.com.au' email adress from Organization-Wide Email Address
			OrgWideEmailAddress[] owea = [select id from OrgWideEmailAddress where address =: BGSConstants.AUSPOST_NOREPLY_EMAIL];
			for(Case closedCase:newlyClosedBGSCases)
			{
				Messaging.SingleEmailMessage bgsEmail = new Messaging.SingleEmailMessage();

				// create the email
				String toAddress = contactEmails.get(closedCase.ContactId);
				bgsEmail.setToAddresses(new List<String>{toAddress});

				/* 
				 * comment out bgsEmail.setSenderDisplayName to prevent DUPLICATE_SENDER_DISPLAY_NAME error
				 * because OrgWideEmailAddress has already been set to 'noreply@auspost.com.au'
				 */
				//bgsEmail.setSenderDisplayName('Australia Post Support');
				bgsEmail.setReplyTo('noreply@auspost.com.au');
				bgsEmail.setTemplateId(bgsTemplateID);
				bgsEmail.setTargetObjectId(closedCase.ContactId);
				bgsEmail.setWhatId(closedCase.Id);
				bgsEmail.setOrgWideEmailAddressId(owea.get(0).Id);

				//bgsEmail.setSubject('Your Case #' + closedCase.CaseNumber + ' has been closed');
				//bgsEmail.setPlainTextBody('Your Case #' + closedCase.CaseNumber + ' has been closed. For Further assistance, please create another case');
				//bgsEmail.setHtmlBody('Your Case #' + closedCase.CaseNumber + ' has been closed. For Further assistance, please create another case');
				bgsClosureEmails.add(bgsEmail);
			}
			// send them out!

			System.debug('CaseTriggerHelper:: email list: ' + bgsClosureEmails);
			Messaging.sendEmail(bgsClosureEmails);
		}

	}
}