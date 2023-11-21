/**************************************************
Type:         Utility Class for Task and Event ie Activities
Used By:      Task and Event Trigger
History:
--------------------------------------------------
19.10.2011    Carl Vescovi(Australia Post contractor)    Created
02.01.2014    Louis Wang (Bluewolf)                     Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
29.01.2016    nandan.narasappa@auspost.com.au           Updated sendSMSForTasks method to bypass future method if list is empty
10.03.2016    nandan.narasappa@auspost.com.au           Updated updateAssociatedCaseMilestones method to send additional parameter.
24.05.2016    Eric.Shen@auspost.com.au                  Updated to incorporate SMS sending out for case and lead creation for SNAP IT process
8.09.2017     Adrian Recio (Accenture)                  Added identifyWorkDay Method to assign matching work day record on create of a task
28.01.2020    Victor Cheng (Salesforce)                 Updated to complete a Response Time BGS milestone for BGS Cases on Email/Log a Call activities
10.08.2020    Ranjeewa Silva                            Optimised updateAssociatedCaseMilestones method to check if there are associated cases before
														attempting SOQL queries and milestone updates.
12.08.2020    Suman Gunaganti                           Updated updateAssociatedCaseMilestones to only process completed tasks.
18.12.2020    Suman Gunaganti                           Added method to capture datetime of first activity of sales person on lead
16.05.2022    SaiSwetha Pingali                         Removed snapIt logic as it is no longer required.
27.10.2023	  Talib Raza								Added new role Sales Specialist and for all roles capture Web Meetings and F2F meetings
**************************************************/

public with sharing class ActivityUtil {


	// Adrian Recio
	// Task and Event recortype getbylabel describe
	public static Map<String,Schema.RecordTypeInfo> tRecTypeMap = Schema.SObjectType.Task.getRecordTypeInfosByName();
	public static Map<String,Schema.RecordTypeInfo> eRecTypeMap = Schema.SObjectType.Event.getRecordTypeInfosByName();
	
	// Created by Adrian Recio
	// Determine the matching workday record based on assigned to field
	// 8/9/2017
	public static void identifyWorkDay(List<Task> tlist, List<Event> eList){

		// Build list of task assigned to Id set
		set<Id> assignedToSet = new set<Id>();

		// Filter task list by sales task recordtype
		List<Task> filterTaskList = new List<Task>();
		for(Task tVar: tlist){
			if(tVar.RecordtypeId == tRecTypeMap.get('Sales Task').getRecordTypeId()){                
			   if(tVar.Type == 'Phone Call' && 
				   tVar.Status == 'Completed' &&
				   (tVar.Category__c == 'Sales' || tVar.Category__c == 'Service') &&
					(tVar.WhatId != null || tVar.WhoId !=null)){
					filterTaskList.add(tVar);   
					assignedToSet.add(tVar.OwnerId);
			   }else if(tVar.Work_Day_Adjustments__c != null){
				  tVar.Work_Day_Adjustments__c = null;      
			   }
			}
		}
		
		// Filter event list by sales event recordtype
		List<Event> filterEventList = new List<Event>();
		for(Event eVar: eList){
			if(eVar.RecordtypeId == eRecTypeMap.get('Sales Event').getRecordTypeId()){
				if((eVar.Type == 'Face to Face Meeting' || eVar.Type == 'Web Meeting') && 
				   eVar.Status__c =='Completed' &&
				   (eVar.Category__c == 'Sales' || eVar.Category__c == 'Service') &&
				   (eVar.WhatId != null || eVar.WhoId !=null)){
					filterEventList.add(eVar);		
					assignedToSet.add(eVar.OwnerId);
				}else if(eVar.Work_Day_Adjustments__c != null){
				  eVar.Work_Day_Adjustments__c = null;      
				}
			}
		}
		
		if(assignedToSet.size()>0){        
			// Query work day adjustment where assigned to is in the owner Id set of task and is current active role
			List<Work_Day_Adjustments__c> workDayList = [Select Id, Role__c, FiscalYear__r.Name, OwnerId from Work_Day_Adjustments__c 
														 where Current_Role__c = true 
														 and OwnerId In :assignedToSet
														 and Role__c !=null];
			
			// Build map of work day adjustment where Key is assigned to field
			Map<Id,Work_Day_Adjustments__c> wdMap = new Map<Id,Work_Day_Adjustments__c>();
			for(Work_Day_Adjustments__c wdVar: workDayList){
				if(wdMap.containsKey(wdVar.OwnerId)){
					if(Integer.valueOf(wdVar.FiscalYear__r.Name)>Integer.valueOf(wdMap.get(wdVar.OwnerId).FiscalYear__r.Name)){
						wdMap.put(wdVar.OwnerId, wdVar);
					}
				}else{
					wdMap.put(wdVar.OwnerId, wdVar);
				}
			}
			
			// Loop across task&event record and pull the matching work day adjustment based on ownerId in the workday Map
			for(Task tVar: filterTaskList){
				
				Boolean IsMatched = false;
				
				Work_Day_Adjustments__c wdVar = wdMap.get(tVar.OwnerId);
				if(wdVar!=null){
					 if(wdVar.Role__c == 'Inside Sales'){
						tVar.Work_Day_Adjustments__c = wdVar.Id;
						IsMatched = true;
					 }
				}
				
				if(tVar.Work_Day_Adjustments__c!=null && IsMatched==false){
					tVar.Work_Day_Adjustments__c = null;
				}
			}
			
			for(Event eVar: filterEventList){
				
				 Boolean IsMatched = false;
				
				 Work_Day_Adjustments__c wdVar = wdMap.get(eVar.OwnerId);
				 if(wdVar!=null){
					 if(wdVar.Role__c == 'Key Accounts' || 
						wdVar.Role__c == 'Territory Sales' ||
						wdVar.Role__c == 'Sales Specialist' ||
						wdVar.Role__c == 'Inside Sales' ){
						eVar.Work_Day_Adjustments__c = wdVar.Id;
						IsMatched = true;   
					 }
				 }
				
				 if(eVar.Work_Day_Adjustments__c!=null && IsMatched==false){
					 eVar.Work_Day_Adjustments__c = null;
				 }
			}
		}
	}

	public static void prepareSMSForTasks(List<Task> tlist){
		ID recordTypeID = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWSMS' limit 1].Id;
		for(Task t: tlist){
			if(t.RecordTypeId == recordTypeId && t.whoID != null && String.valueOf(t.whoId).startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())) {
				t.SMSMessage__c = Util.getBodyFromEmailTemplate('SMSCustomerMilestone', t.whoId, t.whatId);
			}
		}
	}
	
	
	 public static void sendSMSForTasks(List<Task> tlist){
		Set<Id> taskIds = new Set<Id>();
	   // Map<Id, string> contactIdAndMobiles = new Map<Id, string>();
		//31-May-16 Eric Shen revise the retrieval of record type to avoid SOQL query
		Set<Id> taskRecTypeIds = Utility.getRecordTypeIds(String.valueOf(Task.SObjectType),'SSSW SMS');
		//ID recordTypeID = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWSMS' limit 1].Id;
		

		for(Task t: tlist){
		  //  if(t.RecordTypeId == recordTypeId && t.whoID != null && String.valueOf(t.whoId).startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())) {  //24-May-16 Eric Shen Redefine this if condition to incl. lead and case
			 
			//31-May-16 Eric Shen revise the retrieval of record type to avoid SOQL query

			if(Utility.isValidRecordType(taskRecTypeIds,t.RecordTypeId)){        
				//24-May-16 Eric Add condition for lead and case
				if((t.whoID != null && (t.whoid.getSObjectType() ==Contact.getSObjectType()||t.whoid.getSObjectType() ==Lead.getSObjectType()))
					|| (t.whoID == null && t.whatId !=null && t.whatId.getSObjectType()==Case.getSObjectType())) {

					 taskIds.add(t.id);
				}           
			 }     
		}
		// Nandan : empty check before future method invoke
		if(!taskIds.isEmpty() && !System.isFuture()){        
			futureSendSMSForTasks(taskIds);
		}
	 }
	
	@future(callout=true)
	static void futureSendSMSForTasks(Set<Id> taskIds) {
		Map<Id, SMSTaskWrapper> listOfTaskSMSToProcess = new Map<Id, SMSTaskWrapper>();
		Map<Id, string> contactIdAndMobiles = new Map<Id, string>();
 
		//25-May-16 Eric Shen create map variables for lead and case records for employee phone numbers    
		Map<Id, string> leadIdAndEmpMobiles = new Map<Id, string>();
		Map<Id, string> caseIdAndEmpMobiles = new Map<Id, string>();
		//30-May-16 Eric Shen create a total map variable to store all IDs and mobile no.
		Map<Id, string> allIDsAndMobiles = new Map<Id, string>();

		//24-May-16 Eric Shen add whatID from select query below from Task
		for(Task t: [select whoId, whatID, SMSMessage__c from Task where id in: taskIds]){

			//24-May-16 Eric Shen seperate contact, lead and case map variables to contain tasks associated with each 

			if (t.whoID !=null && t.whoid.getSObjectType() ==Contact.getSObjectType()) {

				 contactIdAndMobiles.put(t.whoId, null);
				 listOfTaskSMSToProcess.put(t.id, new SMSTaskWrapper(t.whoId, null, t.SMSMessage__c));
			}

			if (t.whoID !=null && t.whoid.getSObjectType() ==Lead.getSObjectType()) {

				 leadIdAndEmpMobiles.put(t.whoId, null);
				 listOfTaskSMSToProcess.put(t.id, new SMSTaskWrapper(t.whoId, null, t.SMSMessage__c));
			}

			if (t.whoID == null && t.whatId !=null && t.whatid.getSObjectType() ==Case.getSObjectType()) {

				 caseIdAndEmpMobiles.put(t.whatId, null);
				 listOfTaskSMSToProcess.put(t.id, new SMSTaskWrapper(t.whatId, null, t.SMSMessage__c));
			}
							
		}
	
		//31-May-16 Eric Shen Check if the map is empty for all three maps
		if(!contactIdAndMobiles.isEmpty()) {
			for(Contact ct:[select Name, MobilePhone from contact where id in:contactIdAndMobiles.keySet()]){
				 
				system.debug('George says: found contact with name = ' + ct.Name + ' and mobile = ' + ct.MobilePhone);
				contactIdAndMobiles.put(ct.Id, ct.MobilePhone);  
			}
		}
	   //30-May-16 Eric Shen Populates all maps into the finalmap.

		if (!contactIdAndMobiles.isEmpty()) {

			allIDsAndMobiles.putAll(contactIdAndMobiles);

		}

		if (!leadIdAndEmpMobiles.isEmpty()) {

			allIDsAndMobiles.putAll(leadIdAndEmpMobiles);
			
		}

		if (!caseIdAndEmpMobiles.isEmpty()) {

			allIDsAndMobiles.putAll(caseIdAndEmpMobiles);
			
		}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		for(Id taskId: listOfTaskSMSToProcess.keySet()){
			SMSTaskWrapper w = listOfTaskSMSToProcess.get(taskId);

			//w.mobile = contactIdAndMobiles.get(w.whoId);
			//30-May-16 Eric Shen send employee mobile phone numbers from leads and cases for SNAP IT initiative
			w.mobile = allIDsAndMobiles.get(w.oID);
			if(w.mobile != null) {
				string result = TIBCOSMSWrapper.sendSMS(w.mobile, w.sms);
				if(result.startsWith('Success:')){
					system.debug('George says: sms sent success...');
					w.dateSent = Datetime.now();
					w.success = true;
					w.successMessage = result;
				} else {
					system.debug('George says: sms sent failed...');
					w.error = result.length() > 255 ? result.substring(0, 255) : result;
				}
			} else {
				system.debug('George says: no mobile...');
				w.error = 'Unable to send SMS. Mobile is not specified on contact, lead or case.';
			}
		}
		
		List<Task> tasksToUpdate = new List<Task>();
		for(Task t: [select SMSDateSent__c, SMSMessage__c, SMSError__c from Task where id in: listOfTaskSMSToProcess.keySet()]){
			SMSTaskWrapper w = listOfTaskSMSToProcess.get(t.Id);
			system.debug('George says: updating task with message = ' + w.sms + ', error = ' + w.error);
			t.SMSDateSent__c = w.dateSent;
			t.SMSMessage__c = w.sms;
			t.SMSError__c = w.error; 
			if(w.success!=null && w.success) {
				t.Status='Completed';
				t.SMSError__c = w.successMessage;
			}
			tasksToUpdate.add(t);
		}
		update tasksToUpdate;
	}
	
	/*------------------------------------------------------------
	Author:        David Catindoy
	Company:       Cloud Sherpas
	Description:   Refactor the existing AU Post process of sending of SMS to send StarTrack SMS Tasks
				   Update existing tasks records once sending was done.
	Inputs:        List of Tasks records
	Returns:       None
	History:
	Feb 4, 2016 - David Catindoy - Created
	------------------------------------------------------------*/
	public static void sendSMSForStarTrackTasks(List<Task> tlist){
		Set<Id> taskIds = new Set<Id>();
		Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName = 'StarTrack_SMS' LIMIT 1].Id;
		for(Task t: tlist){
			if(t.RecordTypeId == recordTypeId && t.Case_Phone__c != null) {
				taskIds.add(t.Id);
			}
		}
		if(taskIds.size()>0){
			futureSendSMSForStarTrackTasks(taskIds);
		}
	 }

	@future(callout=true)
	static void futureSendSMSForStarTrackTasks(Set<Id> taskIds) {
		Map<Id, SMSTaskWrapper> listOfStarTrackTaskSMSToProcess = new Map<Id, SMSTaskWrapper>();
		for(Task t: [SELECT Case_Phone__c, SMSMessage__c FROM Task WHERE Id IN :taskIds]){
			listOfStarTrackTaskSMSToProcess.put(t.Id, new SMSTaskWrapper(t.Case_Phone__c, t.SMSMessage__c));
		}

		for(Id taskId: listOfStarTrackTaskSMSToProcess.keySet()){
			SMSTaskWrapper w = listOfStarTrackTaskSMSToProcess.get(taskId);
			if(w.mobile != null) {
				String result = TIBCOSMSWrapper.sendSMS(w.mobile, w.sms);
				if(result.startsWith('Success:')){
					System.debug('SMSServer says: SMS sent success...');
					w.dateSent = Datetime.now();
					w.success = true;
					w.successMessage = result;
				} else {
					System.debug('SMSServer says: SMS sent failed...');
					w.error = result.length() > 255 ? result.substring(0, 255) : result;
				}
			} else {
				System.debug('SMSServer says: no mobile...');
				w.error = 'Unable to send SMS. Phone number is not specified.';
			}
		}

		List<Task> tasksToUpdate = new List<Task>();
		for(Task t: [SELECT SMSDateSent__c, SMSMessage__c, SMSError__c FROM Task WHERE Id IN :listOfStarTrackTaskSMSToProcess.keySet()]){
			SMSTaskWrapper w = listOfStarTrackTaskSMSToProcess.get(t.Id);
			System.debug('SMSServer says: updating task with message = ' + w.sms + ', error = ' + w.error);
			t.SMSDateSent__c = w.dateSent;
			t.SMSMessage__c = w.sms;
			t.SMSError__c = w.error;
			if(w.success!=null && w.success) {
				t.Status='Completed';
				t.SMSError__c = w.successMessage;
			}
			tasksToUpdate.add(t);
		}
		update tasksToUpdate;
	}
	
	class SMSTaskWrapper {
		//public Id whoId {get;set;}

		//24-May-16 Eric Shen add oID to include both whoid and whatID as a property
		public Id oID {get;set;}

		public string mobile {get;set;}
		public string sms {get;set;}
		public string error {get;set;}
		public Boolean success {get; set;}
		public String successMessage {get; set;}
		public Datetime dateSent {get;set;}
		
		public SMSTaskWrapper(Id oID, string mobile, string sms){
			this.oID = oID;
			this.mobile = mobile;
			this.sms = sms;
		}
		
		public SMSTaskWrapper(string mobile, string sms){
			this.mobile = mobile;
			this.sms = sms;
		}
	}

	public static void updateLastActivityFromTask(List<Task> tList){
	
		// maintain last activity date 
	
		// get subset of accounts that are affected by the trigger Tasks
		
		List<Id> aIds = new List<Id>();
		for(Task t: tList) {
			if(t.WhatId != null) {
				if(String.valueOf(t.WhatId).startsWith('001')) aIds.add(t.WhatId);
			}
		}
		List<Account> accts = new List<Account>();
		//22-10-15 Eric Shen  add ActivityDate <>null to fix bug.
		
		accts = [Select id, Last_Activity_Date__c, (Select id, ActivityDate from Tasks where IsClosed=true and ActivityDate <>null Order By ActivityDate DESC limit 1) from Account where id in:aIds ];
	
		// cycle through list of retrieved accts and update custom activity date field to reflect most recent activity.
		
		for(Account a : accts) {
			if(a.Tasks.size()>0) {
				a.Last_Activity_Date__c = a.Tasks[0].ActivityDate; 
			} else {
				for(Task t: tList) { 
					if(t.WhatId != null) {
						if(t.WhatId == a.Id && t.IsClosed==true) a.Last_Activity_Date__c = t.ActivityDate;
					}
				}
			}
		}
		new ActivityUtilWithoutSharing(accts).updateAccounts();
	}

	public static void updateLastActivityFromEvent(List<Event> eList){
	
		// maintain last activity date 
	
		// get subset of accounts that are affected by the trigger Tasks
		
		List<Id> aIds = new List<Id>();
		for(Event e : eList) {
			if(e.WhatId !=null) {
				if(String.valueOf(e.WhatId).startsWith('001')) aIds.add(e.WhatId);
			}
		}
		List<Account> accts = new List<Account>();
		accts = [Select id, Last_Activity_Date__c, (Select id, ActivityDate from Events Where ActivityDate <: Date.today().addDays(1) Order By ActivityDate DESC limit 1) from Account where id in:aIds ];
	
		// cycle through list of retrieved accts and update custom activity date field to reflect most recent activity.
		
		for(Account a : accts) {
			if(a.Events.size()>0){
				if(a.Last_Activity_Date__c < a.Events[0].ActivityDate || a.Last_Activity_Date__c == null) {
					a.Last_Activity_Date__c = a.Events[0].ActivityDate; 
				}
			}
		}
		new ActivityUtilWithoutSharing(accts).updateAccounts();
	}

	// YL - 2015/10/12        
	// Now query for latest activities for stamping date on Event record.
	public static void updateLastActivityDateFromActivity(List<Event> eList){
		List<Id> aIds = new List<Id>();
		for(Event e : eList) {
			if(e.WhatId !=null) {
				if(String.valueOf(e.WhatId).startsWith('001')) aIds.add(e.WhatId);
			}
		}
		List<Account> accteventrecords = new List<Account>();
		accteventrecords = [Select id, Last_Activity_Date__c, (Select id, ActivityDate from Events Where ActivityDate <: Date.today().addDays(1) AND Type in ('Meeting','Face to Face Meeting') AND Status__c = 'Completed' Order By ActivityDate DESC limit 50) from Account where id in:aIds ];

		for(Event er : eList) {
			for(Account ar : accteventrecords) {
				 if(ar.Id == er.WhatId) {
					 if(ar.Events.size()>0){
						 Integer i = 0;
						 for(Event accounteventlist : ar.Events) {
							 if(accounteventlist.ActivityDate != null && 
								accounteventlist.ActivityDate <= er.EndDateTime && i == 0 && 
								accounteventlist.Id != er.Id) {
								  er.Last_Activity_Date__c = accounteventlist.ActivityDate;
								  i++;
							 }
						 }
					 }
				 }
			}
		//update er;
		}                 
	}   
	
	// christopher.henschke@auspost.com.au November 12, 2015.
	//created to add current date and time to Customer First Response milestone when email sent or phone call made.
	//2020-08-12  Suman Gunaganti (STP-2550) Only process completed tasks
	public static void updateAssociatedCaseMilestones(List<Task> taskList){
		
		// Get case id from task and then query for the Customer First Response milestone
		
		// Variables
		List<String> caseIDList = new List<String>();
		List<Case> caseList = new List<Case>();
		//System.debug(taskList[0].TaskSubtype);


		// get related cases from each Task
		for(Task t: taskList)
		{
			// for BGS custom Log A Call action created Tasks
			// 2020-08-12  Suman Gunaganti (STP-2550) Only process completed email tasks
			if(t.Case__c != null && 
					((t.Type == 'Email' && t.Status == 'Completed') || t.Type == 'Outbound'|| t.Type == 'Call' || t.TaskSubtype == 'Call' ))
			{
					caseIDList.add(t.Case__c);
				
			}

			//system.debug('** Task Type ' + t.Type + ' ** Case ID ** ' + t.Case__c);
		}

		//Check if we have found any any cases that require milestone updates related to the tasks.
		if (!caseIDList.isEmpty()) {
			Set<String> milestoneTypes = new Set<String>{SSSWConstants.FIRST_CUSTOMER_RESPONSE};
			// added to check if it's a BGS Case
			Set<Id> bgsRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()), BGSConstants.SERVICE_DELIVERY_NAME);
			//set of ids for recordtypes not working in SOQL where clause so converting into set of strings
			Set<String> bgsRecsStr = (Set<String>)JSON.deserialize(JSON.serialize(bgsRecTypes), Set<String>.class);
			//Only query cases with incompleted FCR milestones
			caseList = [SELECT Id, Origin, RecordTypeId 
						FROM Case 
						WHERE (Origin IN ('Email','Web','Portal') OR recordTypeId IN: bgsRecsStr) AND
						Id IN (SELECT caseId
								FROM CaseMilestone 
								WHERE CaseId IN: caseIDList AND
								MilestoneType.Name IN: milestoneTypes AND IsCompleted = false)];
			
			// Not required as conditions are placed in above SOQL 
		   /* List<Case> completeMilestoneCases = new List<Case>();

			for (Case c : caseList) {
				if (c.Origin == 'Email' || c.Origin == 'Web' || c.Origin == 'Portal'
						|| Utility.isValidRecordType(bgsRecTypes, c.RecordTypeId)) {

					completeMilestoneCases.add(c);
				}
			}*/

			if (!caseList.isEmpty()) {
				Utility.completeCaseMilestones(caseList, milestoneTypes, true);
			}
		}
	}
  
  /*------------------------------------------------------------
	Author:        Patrick James Franco
	Company:       Cloud Sherpas
	Description:   Logic to set date time when Task is updated to a specified Status
				   Method is callled via process builder (StarTrack Calculate Task Status Duration)
	Inputs:        Task Id List
	Returns:       None
	History:
	September 24, 2015 - Patrick James Franco - Created
	January 20, 2016 - Patrick James Franco - Updated logic to support LDC behavior
	March 30, 2016 - David Catindoy - Modified to update some logic
	------------------------------------------------------------*/
	@InvocableMethod
	public static void setStatusDate(List<Id> taskIdList){
		List<Task> taskList = [SELECT Id, Status, WhatId, Waiting_for_Operations_Date__c, Acknowledged_Date__c, CreatedDate, Finished_Date__c, Operations_to_Acknowledged_Time__c, Operations_to_Finished_Time__c, Create_to_Finished_Time__c FROM Task WHERE Id IN :taskIdList];

		Map<Id, Case> caseMap = new Map<Id, Case>();
		for(Task thisTask : taskList){
			caseMap.put(thisTask.WhatId, null);
		}
		caseMap = new Map<Id, Case>([SELECT Id, BusinessHoursId FROM Case WHERE Id IN :caseMap.keySet()]);

		for(Task thisTask : taskList){
			if(thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_WAITING)){
				thisTask.Waiting_for_Operations_Date__c = Datetime.now();
			}
			else if(thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED)){
				thisTask.Acknowledged_Date__c = Datetime.now();
			}
			else if(thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_FINISHED)){
				thisTask.Finished_Date__c = Datetime.now();
			}
		}

		for(Task thisTask : taskList){
			// Waiting for Operations to Acknowledged
			if(String.isNotBlank(String.valueOf(thisTask.Waiting_for_Operations_Date__c)) &&
			   String.isNotBlank(String.valueOf(thisTask.Acknowledged_Date__c))){
				thisTask.Operations_to_Acknowledged_Time__c = Integer.valueOf(BusinessHours.diff(caseMap.get(thisTask.WhatId).BusinessHoursId, thisTask.Waiting_for_Operations_Date__c, thisTask.Acknowledged_Date__c) * 0.0000166667);
			}

			// Waiting for Operations to Finished
			if(String.isNotBlank(String.valueOf(thisTask.Waiting_for_Operations_Date__c)) &&
			   String.isNotBlank(String.valueOf(thisTask.Finished_Date__c))){
				thisTask.Operations_to_Finished_Time__c = Integer.valueOf(BusinessHours.diff(caseMap.get(thisTask.WhatId).BusinessHoursId, thisTask.Waiting_for_Operations_Date__c, thisTask.Finished_Date__c) * 0.0000166667);
			}

			// CreatedDate to Finished
			if(String.isNotBlank(String.valueOf(thisTask.Finished_Date__c))){
				thisTask.Create_to_Finished_Time__c = Integer.valueOf(BusinessHours.diff(caseMap.get(thisTask.WhatId).BusinessHoursId, thisTask.CreatedDate, thisTask.Finished_Date__c) * 0.0000166667);
			}
		}

		UPDATE taskList;
	}
	/**
	  * @description       Method to populates lead first activity of sales person
	  * @param             List <Task> tList
	  * @return            void
	  * @throws            NA
	*/ 
	public static void updateLeadFirstActivityFromTask(List<Task> tList){    
		Map<Id, RecordType> taskRecordTypeMap = RecordTypesSelector.newInstance().selectBySObject('Task');
		// get subset of leads that are affected by the trigger Tasks
		List<String> taskTypes = new List<String>{'Phone Call', 'Email', 'Attempted Phone Call'};
		Map<Id,GroupMember> groupMbrMap = new Map<Id,GroupMember>();
		List<lead> leadRecs = new List<lead>();
		List<lead> leadsForUpdate = new List<lead>();

		List<Id> leadIds = new List<Id>();
		for(Task t: tList) {
			if(t.WhoId != null) {
				if(t.WhoId.getSobjectType() == Schema.Lead.SObjectType && 
					taskTypes.contains(t.Type) &&
					taskRecordTypeMap.get(t.RecordTypeId).DeveloperName == 'Sales_Task')

					leadIds.add(t.WhoId);
			}
		}
		leadRecs = [SELECT Id, First_Activity_of_Sales__c, 
						(SELECT id, createdDate, CreatedById 
						FROM Tasks 
						WHERE IsClosed = true AND type In :taskTypes and Recordtype.DeveloperName = 'Sales_Task' and CreatedById = :userinfo.getUserId() ORDER BY createdDate ASC limit 1) 
					FROM Lead 
					WHERE First_Activity_of_Sales__c = Null AND Id IN :leadIds ];
	
		if(!leadRecs.isEmpty()){

			groupMbrMap = BG_LeadUtility.getGroupMembers(new set<String>{'Sales_Managers', 'Account_Managers'});        
			
			String userRoleId  = UserInfo.getUserRoleId();
			// cycle through list of retrieved leads and update first activity of sales field.
			for(Lead l : leadRecs) {
				System.debug('leadeec@@ '+ l);
				if(l.Tasks.size()>0) {
					Task tmpTask = l.Tasks[0];
					if(groupMbrMap.containsKey(tmpTask.CreatedById)||groupMbrMap.containsKey(userRoleId))
						l.First_Activity_of_Sales__c = tmpTask.createdDate; 
						leadsForUpdate.add(l);
				} 
			}
			update leadsForUpdate;
		}
	}

	public without sharing class ActivityUtilWithoutSharing {
		private final List<Account> accounts;

		public ActivityUtilWithoutSharing(List<Account> accounts) {
			this.accounts = accounts;
		}

		public void updateAccounts() {
			ApplicationDatabase.getInstance().dmlUpdate(accounts);
		}
	}
}