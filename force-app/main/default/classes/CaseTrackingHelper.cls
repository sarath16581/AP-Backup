/**
  * @author		: nandan.narasappa@auspost.com.au
  * @date		 : 21/10/2015
  * @description  : Helper class for CaseTriggers for Case Tracking related requirements
  *
  */
/*******************************  History ************************************************
	Date				User										Comments
	21/10/2015		  nandan.narasappa@auspost.com.au			 Added setLastStatusChange method
	02/11/2015		  nandan.narasappa@auspost.com.au			 Added insertCaseStatusTracking & updateCaseStatusTracking method
	03/11/2015		  nandan.narasappa@auspost.com.au			 Added setStatusTracking method
	05/11/2015		  nandan.narasappa@auspost.com.au			 Added deleteCaseForFax method
	09/12/2015		  nandan.narasappa@auspost.com.au			 updated createStatusTracking method for INC0650131 fix
	19/09/2016		  nandan.narasappa@auspost.com.au			 updated conversion for hour difference in setStatusTracking method & removed debug methods

	09/09/2016		  kalpita.talwadekar@auspost.com.au			MWT0002177
																	updated code to handle status tracking for Social Cases
																	udpated code to capture the previous owner
																	updated code to get all the time captures in AEST timezone
	11/03/2021		  neha.mehta@auspost.com.au					Created inner class CaseTrackingUpdate for INC1708377	
	20/04/2023		  noel.lim7@auspost.com.au					Added class variable caseFieldsForTracking, which is used in AgentWork trigger handler logic
																	
*******************************  History ************************************************/
public with sharing class CaseTrackingHelper{
	
	// constants
	private static final Map<String,String> FIELD_CHANGE_MAP = new Map<String,String>{'OwnerId' => 'Owner', 
																						'Status' => 'Status', 
																						'Network__c' => 'Network', 
																						'NetworkComments__c' => 'Network Comments',
																						'Network_Response__c' => 'Network Response'};
	
	/*
	 * All the Case fields used in this class to execute Status Tracking logic.
	 * Used for overriding fields in Case Selector. As more Case fields are required for tracking, add them here.
	 */
	public static final Set<SObjectField> caseFieldsForTracking {
		get {
			if(caseFieldsForTracking == null) {
				caseFieldsForTracking = new Set<SObjectField>{
					Case.OwnerId,Case.Status,Case.RecordTypeId,Case.Network__c,Case.NetworkComments__c,Case.Network_Response__c				
				};
			}
			return caseFieldsForTracking;
		}
		private set;
	}

	// variables
	public static Boolean isSetStatusTrackRecursive = false;	  // flag for status tracking 
	public static Boolean isUpdateStatusTrackRecursive = false;	  // flag for update status tracking 
	public static Boolean isDeleteCaseFaxRecursive = false;	  // flag for deleting fax cases
	
	private static Boolean isValid;
	private static Id defaultBusinessHour;				  // get default business hour Id
	private static Set<String> closedStatus;				// set of closed case statuses
	private static Set<Id> validRecTypes;					// type of cases for which code executes
	private static Map<String,Id> businessHourMap;		  // SSSW Business Hours
	private static String userPrefix = USER.sobjecttype.getDescribe().getKeyPrefix();
	
	static{ // code executed to fetch details when class is invoked
		try{
			isValid = false;
			// get all valid record types for the SSSW functionality
			validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			//below updated by Kalpita - to open up for social cases - 'Status Tracking MWT0002177 '
			validRecTypes.addAll(Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),'Social'));
			 
			businessHourMap = Utility.getBussinessHourMap();	// get business hours for SSSW application
			closedStatus = Utility.getCaseClosedStatus();	// set of closed case statuses
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingHelper.class.getName(), SSSWConstants.STATIC_BLOCK, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	This method is invoked in Before insert event, sets default values for 
							last status change and time with customer & support
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void setLastStatusChange(List<Case> caseList){
		try{
			for(Case csRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					// Set default values 
					csRec.Last_Status_Change__c = System.Now();
					csRec.Time_With_Customer__c = 0;
					csRec.Time_With_Support__c = 0;
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingHelper.class.getName(), SSSWConstants.METH_INSERT_MILESTONES, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	This method is invoked in after insert event, creates the status tracking record
							for new SSSW cases capturing owner & status details
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void insertCaseStatusTracking(List<Case> caseList){
		try{
			// set the default fields to be tracked when case is created (Owner,Status)
			String fieldList = SSSWConstants.OWNER + SSSWConstants.WHITE_SPACE 
								+ SSSWConstants.SEMI_COLON + SSSWConstants.WHITE_SPACE + SSSWConstants.STATUS;
			Set<Id> ownerIds = new Set<Id>();				// set of case owners
			Set<Id> prevOwnerIds = new Set<Id>();			// set of case previous owners
			List<Case> casesTobeTracked = new List<Case>(); // list of cases for tracking record to be created
			Map<Id,String> fieldMap = new Map<Id,String>(); // map of case id & the fields changed during case creation
			for(Case csRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					ownerIds.add(csRec.OwnerId);
					casesTobeTracked.add(csRec);
					fieldMap.put(csRec.Id,fieldList);
				}
			}
			
			if(!casesTobeTracked.isEmpty()){	// verify if case list got values
				Map<Id,sObject> ownerMap = getOwnerMap(ownerIds);	// map of case id and owner (user or queue)
				Map<Id,sObject> pervOwnerMap = new Map<Id,sObject>(); //getOwnerMap(prevOwnerIds);	// map of case id and previous owner (user or queue)
				system.debug('--pervOwnerMap '+pervOwnerMap );
				if(!ownerMap.isEmpty()){	// verify if ownerMap got values
					// create status tracking records for the case
					List<StatusTracking__c> trackingRecords = createStatusTracking(casesTobeTracked,ownerMap,fieldMap,pervOwnerMap,true);
					if(!trackingRecords.isEmpty()){	 // verify if trackingRecords got values before DML
					 /* Added by Neha Mehta for incident INC1708377 start */
						CaseTrackingHelper.CaseTrackingUpdate statusTrackingUpdate=new CaseTrackingHelper.CaseTrackingUpdate();
						statusTrackingUpdate.insertStatusTrackingStatus(trackingRecords);//to create Status Tracking record when cases are created by Guest Users.
						//Database.insert(trackingRecords,false);
					/* Added by Neha Mehta for incident INC1708377 end */
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingHelper.class.getName(), SSSWConstants.METH_INSERT_TRACKING, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	This method is invoked in after update event, creates the status tracking record
	  *					for status change in SSSW cases & updates the open tracking record
	  * 
	  * This is called by CaseTriggerHandler.cls during normal Case trigger execution.
	  *
	  * In addition, this is also called by AgentWorkAPCaseAutomationModule.cls. Reason is due to OTB behaviour when a Case is pushed by Omni to an Agent.
	  * The Case Owner changes to the Agent, but no Case trigger is executed. Therefore this is manually called to generate the StatusTracking in that scenario when the Agent Accepts.
	  *
	  * @param			 caseList - List<Case>, oldCaseMap - Map<Id,Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void updateCaseStatusTracking(List<Case> caseList, Map<Id,Case> oldCaseMap){
		try{
			Set<Id> ownerIds = new Set<Id>();					// set of case owners
			Set<Id> prevOwnerIds = new Set<Id>();					// set of case owners
			Map<Id,Case> casesTobeTracked = new Map<Id,Case>(); // list of cases for tracking record to be created
			Map<Id,String> fieldMap = new Map<Id,String>();	 // map of case id & the fields changed during case creation
			for(Case csRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					Case oldCase = oldCaseMap.get(csRec.Id);		// get old values of case
					String fieldList = getFieldList(csRec,oldCase); // get fields updated
					if(isValid){	// verify if owner/status/network/network response is changed
						ownerIds.add(csRec.OwnerId);
						prevOwnerIds.add(oldCase.OwnerId);
						casesTobeTracked.put(csRec.Id,csRec);
						if(String.isNotBlank(fieldList)){	// check if fieldList got value
							fieldMap.put(csRec.Id,fieldList);
						}
					}
				}
			}
			
			if(!casesTobeTracked.isEmpty()){	// verify if case list got values
				isUpdateStatusTrackRecursive = true;	// set flag to true;
				Map<Id,sObject> ownerMap = getOwnerMap(ownerIds);	// map of case id and owner (user or queue)
				Map<Id,sObject> prevOwnerMap = getOwnerMap(prevOwnerIds);	// map of case id and owner (user or queue)
				if(!ownerMap.isEmpty()){	// verify if ownerMap got values
					// create status tracking records for the case
					List<StatusTracking__c> trackingRecords = createStatusTracking(casesTobeTracked.values(),ownerMap,fieldMap,prevOwnerMap,false );
					// Fetch updated old case tracking records
					Map<Id,List<StatusTracking__c>> oldTrackings = getOldCaseTrackings(fieldMap.keyset());
					system.debug('old--'+oldTrackings );
					Set<String> previOwners = new Set<String>();
					Map<Id,StatusTracking__c> caseStatTrackMap  = new Map<Id,StatusTracking__c>();
					//loop through old tracking to get map of status tracking id and record itself 
					for(Id caseId : oldTrackings.keySet()) {
						for(StatusTracking__c oldStatTrack: oldTrackings.get(caseId) ) {
							system.debug('old owner--'+oldStatTrack.OwnerName__c);
							caseStatTrackMap.put(oldStatTrack.Case__c, oldStatTrack);
							previOwners.add(oldStatTrack.OwnerId__c);
						}
					}
					if(!oldTrackings.isEmpty()){	// verify if oldTrackings got values
						//update the trackingRecords for prev owner
						
						if(!caseStatTrackMap.keySet().isEmpty()) {
							for(StatusTracking__c newStatTrack: trackingRecords  ) {
								system.debug('newStatTrack--'+newStatTrack);
								//check the prefix of id - if user? yes then add it to previous owner 
								 if(caseStatTrackMap.keySet().contains(newStatTrack.Case__c) && 
									!String.isBlank(caseStatTrackMap.get(newStatTrack.Case__c).OwnerId__c) && 
									!userPrefix.equalsIgnoreCase(caseStatTrackMap.get(newStatTrack.Case__c).OwnerId__c.substring(0,3))) {
									newStatTrack.Previous_Owner_Id__c = caseStatTrackMap.get(newStatTrack.Case__c).OwnerId__c;
									newStatTrack.Previous_Owner_Name__c = caseStatTrackMap.get(newStatTrack.Case__c).OwnerName__c;
								}
								
							}
						}
						trackingRecords.addAll(updateOldTrackings(oldTrackings,casesTobeTracked,fieldMap));
					}
					
					if(!trackingRecords.isEmpty()){ // verify if trackingRecords got values before DML
					 /* Added by Neha Mehta for incident INC1708377 start */
						CaseTrackingHelper.CaseTrackingUpdate statusTrackingUpdate=new CaseTrackingHelper.CaseTrackingUpdate();
						statusTrackingUpdate.upsertStatusTrackingStatus(trackingRecords);// guest users can’t have more than read access.With this change new tracking & update old tracking records can be created.
						//Database.upsert(trackingRecords,false); // creates new tracking & updates old tracking records
						/* Added by Neha Mehta for incident INC1708377 end */
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingHelper.class.getName(), SSSWConstants.METH_INSERT_MILESTONES, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	This method is invoked from updateCaseStatusTracking to 
							check if tracking fields changed and return the changed fields.
	  * @param			 newCase - Case, oldCase - Case 
	  * @return			String
	  * @throws			NA
	  */
	private String getFieldList(Case newCase,Case oldCase){
		String fieldList = SSSWConstants.EMPTY_SPACE;	// variable to store fields changed, semi-colon separated
		if(newCase != null && oldCase != null){ // check if newCase & oldCase are not null
			for(String field : FIELD_CHANGE_MAP.keyset()){  
				// check if network is changed & status is Awaiting Network Response
				if(SSSWConstants.FLD_NETWORK.equalsIgnoreCase(field)){
					if(newCase.get(field) != oldCase.get(field) 
						&& SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE.equalsIgnoreCase((String) newCase.get(SSSWConstants.STATUS))){
						fieldList += SSSWConstants.WHITE_SPACE + FIELD_CHANGE_MAP.get(field) 
										+ SSSWConstants.WHITE_SPACE + SSSWConstants.SEMI_COLON ;
						isValid = true;
					}
				}
				else if(SSSWConstants.STATUS.equalsIgnoreCase(field)){
					if(newCase.get(field) != oldCase.get(field)){
						if(SSSWConstants.STAT_NETWORK_RESPONDED.equalsIgnoreCase((String) newCase.get(SSSWConstants.STATUS)) || SSSWConstants.STAT_CUSTOMER_RESPONDED.equalsIgnoreCase((String) newCase.get(SSSWConstants.STATUS))){
							if(newCase.get(SSSWConstants.FLD_Owner) != oldCase.get(SSSWConstants.FLD_Owner)){
								fieldList += SSSWConstants.WHITE_SPACE + FIELD_CHANGE_MAP.get(field) 
										+ SSSWConstants.WHITE_SPACE + SSSWConstants.SEMI_COLON ;
								isValid = true;
							}
							else{
								isValid = false;
								break;
							}
						}
						else{
							fieldList += SSSWConstants.WHITE_SPACE + FIELD_CHANGE_MAP.get(field) 
										+ SSSWConstants.WHITE_SPACE + SSSWConstants.SEMI_COLON ;
							isValid = true;
						}
					}
				}
				else{
					if(newCase.get(field) != oldCase.get(field)){	// check if tracking field values changed
						fieldList += SSSWConstants.WHITE_SPACE + FIELD_CHANGE_MAP.get(field) 
										+ SSSWConstants.WHITE_SPACE + SSSWConstants.SEMI_COLON ;
						isValid = true;
					}
				}
			}
		}
		return fieldList;
	}

	/**
	  * @description	This method creates the status tracking record for status,owner & network details
							change in SSSW cases 
	  * @param			 caseList - List<Case>, ownerMap - Map<Id,sObject> , fieldMap - Map<Id,String>
	  * @return			List<StatusTracking__c>
	  * @throws			Method might throw exception which is handled by invoked method
	  */
	private static List<StatusTracking__c> createStatusTracking(List<Case> caseList,Map<Id,sObject> ownerMap,Map<Id,String> fieldMap, 
																Map<Id,sObject> prevOwnerMap, Boolean isInsert){
		Map<Id,StatusTracking__c> statusTrackingMap = new Map<Id,StatusTracking__c>();
		for(Case csRec : caseList){
			if(!statusTrackingMap.containsKey(csRec.Id)){	// check if map got tracking record for case
				// get the case owner
				sObject caseOwner = ownerMap.containsKey(csRec.OwnerId) ? ownerMap.get(csRec.OwnerId) : null;
				system.debug('--here'+prevOwnerMap);
				sObject prevOwner = prevOwnerMap!=null && prevOwnerMap.containsKey(csRec.OwnerId) ? prevOwnerMap.get(csRec.OwnerId) : null; //added by kalpita
				system.debug('--here'+prevOwner );
				DateTime currentTime = DateTime.Now();  //kalpita: uncommented back - to get across user time zone
				/*DateTime currentTimeNow = DateTime.Now(); // -- kalpita: added to get across single time zone
				system.debug(currentTimeNow+'before formatting time now#');
				String TimeZones = '(GMT+11:00) Australian Eastern Daylight Time (Australia/Sydney)';
				List<String> lststrsplit = TimeZones.substring(12,TimeZones.length()).split('\\(',2);
				string strTimeZone = lststrsplit[1].substring(0,lststrsplit[1].length()-1);
				string strCurrentTime = currentTimeNow.format('YYYY-MM-dd HH:mm:ss', strTimeZone);
				Datetime currentTime = Datetime.valueof(strCurrentTime);
				system.debug('-new curr time'+currentTime);*/
				StatusTracking__c tracking = new StatusTracking__c(); 
				//tracking.First_Agent_Action__c = isInsert;		  
				tracking.Name = currentTime.format(SSSWConstants.STAT_TRACK_FORMAT);
				tracking.OwnerId__c = csRec.OwnerId;
				tracking.OwnerName__c = caseOwner != null ? (String)caseOwner.get(SSSWConstants.FLD_NAME) : tracking.OwnerName__c;
				tracking.StatusValue__c  = csRec.Status;
				tracking.Case__c = csRec.Id;
				tracking.Previous_Owner_Id__c = prevOwner != null  && 
													!userPrefix.equalsIgnoreCase(String.valueOf(prevOwner.get('Id')).substring(0,3)) && 
													!userPrefix.equalsIgnoreCase(String.valueOf(tracking.OwnerId__c).substring(0,3))? 
													(String)prevOwner.get('Id') : tracking.Previous_Owner_Id__c;
				tracking.Previous_Owner_Name__c = prevOwner != null && 
													!userPrefix.equalsIgnoreCase(String.valueOf(prevOwner.get('Id')).substring(0,3)) && 
													!userPrefix.equalsIgnoreCase(String.valueOf(tracking.OwnerId__c).substring(0,3))? 
													(String)prevOwner.get(SSSWConstants.FLD_NAME) : tracking.Previous_Owner_Name__c;
				tracking.FieldsChanged__c = fieldMap.get(csRec.Id);
				// set user's business hour if available else defaulted to Australia/Sydney
				String timeZoneKey = (caseOwner != null && caseOwner.getSObjectType() == User.sObjectType) ? (String)caseOwner.get(SSSWConstants.FLD_TZKEY) : null;
				tracking.BusinessHours__c = (String.isNotBlank(timeZoneKey) && businessHourMap.containsKey(timeZoneKey)) ? 
												businessHourMap.get(timeZoneKey) : businessHourMap.get(SSSWConstants.DEF_TZKEY);
				tracking.CreatedDateList__c = currentTime;
				tracking.StartDate__c = currentTime;
				//if('Closed'.equalsIgnoreCase(csRec.Status)) tracking.EndDate__c = currentTime ;
				// set network if case is assigned to network & in Awaiting Network Response status
				tracking.Network__c = (SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE.equalsIgnoreCase(csRec.Status) 
										&& csRec.Network__c != null) ? csRec.Network__c : tracking.Network__c;
				//commented below by Kalpita to remove the usage of network comments and response from case
				//tracking.NetworkCommentsValue__c = csRec.NetworkComments__c; // --commented by kalpita for status tracking MW
				//tracking.NetworkResponseValue__c  = csRec.Network_Response__c; // --commented by kalpita for status tracking MW
				// set agent if the case owner is user
				tracking.Agent__c = (csRec.OwnerId.getsObjectType() == User.sObjectType) ? csRec.OwnerId : tracking.Agent__c ;
				tracking.RecordTypeId  = getMatchingSTRecordType(csRec.RecordTypeId);
				// Updating the Assigned By Fill Inbox flag. It will let users identify that the status tracking was created wrt. case owner changed by Fill Inbox
				if(SSSW_FillInbox.checkFillInboxClicked != null && SSSW_FillInbox.checkFillInboxClicked){
					tracking.AssignedByFillInbox__c = true;
				}
				statusTrackingMap.put(csRec.Id,tracking);
			}
		}
		SSSW_FillInbox.checkFillInboxClicked = false;
		return statusTrackingMap.values();  // return tracking records
	}
	
	/**
	  * @description	This method returns Status tracking recordtype corresponding to Case Recordtype
	  * @param			 caseRecTypeId - Id 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by invoked method
	  */
	private static Id getMatchingSTRecordType(Id caseRecTypeId){
		Id trackingRecTypeId;
		// get Case Recordtypes
		Map<Id,String> caseRecTypeMap = Utility.getsObjectRecordTypeNames(String.valueOf(Case.sObjectType));
		// get Status Tracking Recordtypes
		Map<String,Id> trackingRecTypeMap =  Utility.getsObjectRecordTypes(String.valueOf(StatusTracking__c.sObjectType));
		// get case record type name
		String caseRecTypeName = caseRecTypeMap.containsKey(caseRecTypeId) ?  caseRecTypeMap.get(caseRecTypeId) : null;
		if(String.isNotBlank(caseRecTypeName)){ // verify if case recordtype name is not null
			// get custom setting values for recordtype mapping
			StatusTrackingRecordTypeMapping__c mapping = StatusTrackingRecordTypeMapping__c.getValues(caseRecTypeName);
			trackingRecTypeId = (mapping != null) ?trackingRecTypeMap.get(mapping.StatusTrackingRecordType__c) : null;
		}
		if(trackingRecTypeId == null){  // set default status tracking record type to SSSW General if custom setting not available
			trackingRecTypeId = trackingRecTypeMap.get(SSSWConstants.RECTYPE_ST_GENERAL);
		}
		return trackingRecTypeId;
	}

	/**
	  * @description	This method returns owner details based on the id
	  * @param			 ownerIds - Set<Id> 
	  * @return			Map<Id,sObject>
	  * @throws			Method might throw exception which is handled by invoked method
	  */
	private static Map<Id,sObject> getOwnerMap(Set<Id> ownerIds){
		Map<Id,sObject> ownerMap = new Map<Id,sObject>();
		for(User usr : Utility.getUsers(ownerIds).values()){	// get details of case owners
			ownerMap.put(usr.Id,usr);
		}
		// get SSSW queue details
		for(Group queue : Utility.getGroupDetails(ownerIds,SSSWConstants.QUEUE).values()){
			ownerMap.put(queue.Id,queue);
		}
		return ownerMap;
	}
	
	/**
	  * @description	This method returns current open status tracking records for a case
	  * @param			 caseIds - Set<Id> 
	  * @return			Map<Id,List<StatusTracking__c>>
	  * @throws			Method might throw exception which is handled by invoked method
	  */
	private static Map<Id,List<StatusTracking__c>> getOldCaseTrackings(Set<Id> caseIds){
		Map<Id,List<StatusTracking__c>> trackingMap = new Map<Id,List<StatusTracking__c>>();
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
		// fetch status tracking records for case and add to map
		for(Case csRec : [SELECT Id, 
							(SELECT Case__c, Name, Duration__c, BusinessHours__c, Fax__c, StatusValue__c, OwnerId__c, OwnerName__c,
								CreatedDate, StartDate__c, EndDate__c, SubsequentStatusValue__c FROM Status_Tracking__r
								WHERE Duration__c = null)
							FROM Case WHERE Id IN: caseIds LIMIT : rowLimit]){
			trackingMap.put(csRec.Id,csRec.Status_Tracking__r);
		}
		return trackingMap;
	}
	
	/**
	  * @description	This method returns the updated open case tracking records with duration & subsequent status value
	  * @param			 trackingMap - Map<Id,List<StatusTracking__c>>,caseMap - Map<Id,Case>, fieldMap - Map<Id,String>
	  * @return			List<StatusTracking__c>
	  * @throws			Method might throw exception which is handled by invoked method
	  */
	private static List<StatusTracking__c> updateOldTrackings(Map<Id,List<StatusTracking__c>> trackingMap,
																Map<Id,Case> caseMap,
																Map<Id,String> fieldMap){
		List<StatusTracking__c> updatedTrackingList = new List<StatusTracking__c>();
		for(Id caseId : trackingMap.keyset()){  // iterate through map of case & status tracking records
			if(trackingMap.containsKey(caseId) && trackingMap.get(caseId) != null){ // verify if map got case & tracking records
				for(StatusTracking__c tracking : trackingMap.get(caseId)){
					tracking.EndDate__c = (tracking.EndDate__c == null) ? DateTime.Now() : tracking.EndDate__c; //kalpita: uncommented back - to get across user time zone
					/*DateTime currentTimeNow = DateTime.Now(); // -- kalpita: added to get across single time zone
					system.debug(currentTimeNow+'before formatting time now#');
					String TimeZones = '(GMT+11:00) Australian Eastern Daylight Time (Australia/Sydney)';
					List<String> lststrsplit = TimeZones.substring(12,TimeZones.length()).split('\\(',2);
					string strTimeZone = lststrsplit[1].substring(0,lststrsplit[1].length()-1);
					string strCurrentTime = currentTimeNow.format('YYYY-MM-dd HH:mm:ss', strTimeZone);
					Datetime currentTime = Datetime.valueof(strCurrentTime);
					system.debug('-new curr time'+currentTime);
					tracking.EndDate__c = (tracking.EndDate__c == null) ? currentTime : tracking.EndDate__c; //added by kalpita to get in single time zone
					*/
					// Duration Calculation
					Double durationInSecs = 0;
					// get diff based on business hours					
					tracking.Duration__c = (tracking.BusinessHours__c != null) ? 
												BusinessHours.diff(tracking.BusinessHours__c, tracking.StartDate__c, tracking.EndDate__c)
												: tracking.Duration__c;
					if(tracking.Duration__c != null){
						durationInSecs = tracking.Duration__c / 1000;	// convert milliseconds to seconds
						tracking.DurationHours__c = (Integer) durationInSecs / 3600 ;	// convert seconds to hours
						durationInSecs = durationInSecs - (tracking.DurationHours__c * 3600);	// get remaining seconds
						tracking.DurationMins__c  = (Integer) durationInSecs / 60	;	// convert seconds to hours
						durationInSecs = durationInSecs - (tracking.DurationMins__c * 60);  // get remaining seconds
						tracking.DurationSeconds__c = (Integer) durationInSecs; // set remaining seconds
					}
					// set the subsequent status value for old tracking record
					if(String.isBlank(tracking.SubsequentStatusValue__c) && fieldMap.containsKey(caseId) 
						&& fieldMap.get(caseId).contains(SSSWConstants.STATUS)){
						tracking.SubsequentStatusValue__c = caseMap.get(caseId).Status;
					}	
					updatedTrackingList.add(tracking);
				}
			}
		}
		return updatedTrackingList;
	}
	
	/**
	  * @description	This method is invoked in before update event, sets value for time spent with customer
							& support
	  * @param			 caseList - List<Case>, oldCaseMap - Map<Id,Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void setStatusTracking(List<Case> caseList, Map<Id,Case> oldCaseMap){
		try{		
			for(Case csRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					Case oldCase = oldCaseMap.get(csRec.Id);	// get old values of case
					if(oldCase != null && csRec.Status != oldCase.Status && csRec.Last_Status_Change__c != null){
						isSetStatusTrackRecursive = true;	// set flag to true
						// get case business hour if available else defaulted to Australia/Sydney
						Id businessHourId = (csRec.BusinessHoursId != null) ? 
												csRec.BusinessHoursId : businessHourMap.get(SSSWConstants.DEF_TZKEY);
						Double caseInLastStatusHour = (businessHourId != null) ? 
														BusinessHours.diff(businessHourId,csRec.Last_Status_Change__c,DateTime.Now()) / 3600000 : 0;	// Nandan : updated conversion for hour diff
						if(SSSWConstants.STAT_AWAITING_CUST_RESPONSE.equalsIgnoreCase(oldCase.Status)){
							csRec.Time_With_Customer__c += caseInLastStatusHour;
						}
						else{
							csRec.Time_With_Support__c += caseInLastStatusHour;
						}
						// set case age if its closed
						if(closedStatus.contains(csRec.Status)){
							csRec.Case_Age_In_Business_Hours__c = csRec.Time_With_Customer__c + csRec.Time_With_Support__c ;
						}
						
						csRec.Last_Status_Change__c = DateTime.Now();
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingHelper.class.getName(), SSSWConstants.METH_SET_TRACKING, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	This method is invoked in after update event, associates the fax record of child cases
							to parent case & deletes the child case
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void deleteCaseForFax(List<Case> caseList){
		try{
			Set<Id> faxCaseIds = new Set<Id>();
			// get fax case recordtypes
			Set<Id> faxRecTypeIds = Utility.getRecordTypeIds(String.valueOf(Case.sObjectType),SSSWConstants.RECTYPE_CASE_FAX); 
			for(Case csRec : caseList){
				if(!faxRecTypeIds.isEmpty() && faxRecTypeIds.contains(csRec.RecordTypeId) && csRec.ParentId != null){
					faxCaseIds.add(csRec.Id);
				}
			}
			
			if(!faxCaseIds.isEmpty()){  // check if faxCaseIds got value
				isDeleteCaseFaxRecursive = true;	// set flag to true
				List<Fax__c> faxList = new List<Fax__c>();
				Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
				// fetch faxes & transfer to parent case
				for(Fax__c fax : [SELECT Id,Case__c,Case__r.ParentId 
									FROM Fax__c WHERE Case__c IN: faxCaseIds LIMIT : rowLimit]){
					fax.Case__c = fax.Case__r.ParentId;
					faxList.add(fax);
				}
				if(!faxList.isEmpty()){ // check if faxList got values before DML
					Database.update(faxList,false);		 // update fax records
					Database.delete(new List<Id>(faxCaseIds),false);	// delete child cases
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingHelper.class.getName(), SSSWConstants.METH_DEL_CASEFAX, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	 /**
	  * @description	This inner class is created to update Status Tracking related list, when cases are created by Guest users.
	  *					 As due to critical update “Secure Object Permissions for Guest Users”
	  *					 guest users can’t have more than read access.
	  */
	public without sharing class CaseTrackingUpdate{

		public void insertStatusTrackingStatus( List<StatusTracking__c> trackingRecords){
			try{
				Database.insert(trackingRecords,false);
			}
			catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingUpdate.class.getName(), SSSWConstants.METH_DEL_CASEFAX, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
			}
		}
		public void upsertStatusTrackingStatus( List<StatusTracking__c> trackingRecords){
			try{
				List<Database.upsertResult> uResults = Database.upsert(trackingRecords,false);
			}
			catch(Exception exp){
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseTrackingUpdate.class.getName(), SSSWConstants.METH_DEL_CASEFAX, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
			}
		}
	} 
}