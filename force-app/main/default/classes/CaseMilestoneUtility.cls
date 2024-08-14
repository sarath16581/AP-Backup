/**
  * @author	   : nandan.narasappa@auspost.com.au
  * @date		 : 09/10/2015
  * @description  : Milestone Utility Class for Case Triggers
  * @changelog
  * 09/10/2015		  nandan.narasappa@auspost.com.au			 Added insertMilestones method
  * 12/10/2015		  nandan.narasappa@auspost.com.au			 Added updateSLA method
  * 13/10/2015		  nandan.narasappa@auspost.com.au			 Added setEscalationMail method
  * 14/10/2015		  nandan.narasappa@auspost.com.au			 Added updateMilestones method
  * 24/12/2015		  nandan.narasappa@auspost.com.au			 updated setSLA method to populate NetworkTierSLA__c
  * 27/01/2015		  nandan.narasappa@auspost.com.au			 updated updateMilestones method to complete First customer response mileStone on case close
  * 10/03/2016		  nandan.narasappa@auspost.com.au			 updated updateMilestones method to send additional paramter to populate completion date for violated mileStone
  * 14/05/2019		  gunith.devasurendra@auspost.com.au		  Fixed issue where Network Escalation emails don't have email addresses set (INC1370890)
  * 09/07/2019		  gunith.devasurendra@auspost.com.au		  Set Network Email 1 to Case Network Escalation Email in Level 1 (INC1370890)
  * 28/01/2020		  vcheng@salesforce.com					   MW0009344 update to assign and complete BGS Milestones, aligned with SSSW flow
  * 07/10/2021		  naveen.rajanna@auspost.com.au			   REQ2616056 Modified updateCaseStatusTracking to update only when there is a change and api version to 52
  * 15/11/2021		  ashapriya.gadi@auspost.com.au			   SMWD-312 - MW0004779 - Assign the correct entitlement process and business hours record to the case
  * 12/01/2022		  naveen.rajanna@auspost.com.au			   REQ2656153 Added check for whether Batch invoked call before making future call
  * 17/01/2022		  ashapriya.gadi@auspost.com.au			   SMWD-312 - MW0004779 - defaulting all the manual service delivery cases' entitlement to VIC
  * 2022-02-16 - Nathan Franklin - Uplifted BGS entitlement to limit scope of entitlement selection
  * 2023-06-02 - Mahesh Parvathaneni - Added logic to assign entitlement to transport enquiry record type cases
  * 2024-05-07 - Boris Bachovski - Add logic to assign entitlement to bulk mail record type cases
  * 2024-08-12 - George Nguyen - Added Unified Entitlement process to cases with Unifield Investigation record types
  */
public with sharing class CaseMilestoneUtility{
	   
	// variables
	public static Boolean isCaseEscalationSet = false;	  // flag to prevent setting escalation mail recursively
	public static Boolean isCaseSLASet = false;	  // flag to prevent setting SLA recursively
	public static Boolean isMilestoneUpdated = false;	  // flag to prevent recursive execution of updateMilestones
	
	private static Set<Id> ssswRecTypes;	// SSSW record types
	private static Set<String> closedStatus;				// set of closed case statuses
	private static Id STD_ENTITLEMENT;  // sssw entitlement to be linked with case
	@TestVisible
	private static Id UNIFIED_ENTITLEMENT_ID; // Unifield Entitlement to be linked with case
	@TestVisible
	private static Set<Id> unifiedRecordTypes;

	// Added for BGS Case Milestones
	private static Set<Id> bgsRecTypes;  // the BGS Case Record Type "Service Delivery/Sales_Ops_Delivery"

	private static final Set<String> NETWORK_MILESTONE_SENSITIVE_FIELDS = new Set<String>{
			'Facility_Milestones_Violated__c',
			'Network__c',
			'IsEscalated'
	};

	static{
		try{
			// get all valid record types for the SSSW functionality
			ssswRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			STD_ENTITLEMENT = Utility.getStandardEntitlement(); // fetch the default Entitlement account
			closedStatus = Utility.getCaseClosedStatus();   // set of closed case statuses

			// Get the Record Type Id for BGS Service Delivery Cases
			bgsRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()), BGSConstants.SERVICE_DELIVERY_NAME);

			List<Entitlement> entitlements = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}, new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS});
			if(entitlements.isEmpty() == false) {
				UNIFIED_ENTITLEMENT_ID = entitlements[0].Id;
			}

			unifiedRecordTypes = Utility.getRecordTypesAsSObjectByDevName(String.valueOf(Case.getsObjectType()),new Set<String>{SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME}).keySet();
		}
		catch(Exception exp){
			system.debug('>>>> Exception initialising static block in CaseMilestoneUtility...');
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseMilestoneUtility.class.getName(), SSSWConstants.STATIC_BLOCK, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}

		
	}

	private static Id transportEnquiryEntitlementId {
		get {
			if (transportEnquiryEntitlementId == null) {
				transportEnquiryEntitlementId = TransportEnquiryCaseService.getInstance().getTransportEnquiryEntitlementId();
			}
			return transportEnquiryEntitlementId;
		}
		private set;
	}

	private static Id transportEnquiryRecTypeId {
		get {
			if (transportEnquiryRecTypeId == null) {
				transportEnquiryRecTypeId = TransportEnquiryCaseService.getInstance().getTransportEnquiryRecordTypeId();
			}
			return transportEnquiryRecTypeId;
		}
		private set;
	}
	
	private static Id bulkMailEntitlementId {
		get {
			if (bulkMailEntitlementId == null) {
				bulkMailEntitlementId = BulkMailCaseService.getInstance().getBulkMailEntitlementId();
			}
			return bulkMailEntitlementId;
		}
		private set;
	}
	
	private static Id bulkMailRecTypeId {
		get {
			if (bulkMailRecTypeId == null) {
				bulkMailRecTypeId = BulkMailCaseService.getInstance().getBulkMailRecordTypeId();
			}
			return bulkMailRecTypeId;
		}
		private set;
	}

	/**
	  * @description	   This method is invoked in Before insert event, fetches the default Entitlement 
						   and links to SSSW Cases
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void insertMilestones(List<Case> caseList){
		try{
			Set<Id> usrIds = new Set<Id>();
			List<Case> updateCaseEscalationList = new List<Case>();
			List<Case> bgsCases = new List<Case>();

			// fetch Id of the System Support user from the Custom Setting
			ConfigSetting__c configSetting = ConfigSetting__c.getInstance();
			String systemSupportUserId = configSetting.AutomatedCaseUser__c;

			//fetch the origin values from custom metadata Case_Entitlements__mdt
			Case_Entitlements__mdt caseEntitlement = Case_Entitlements__mdt.getInstance('origins');
			List<String> originList = new List<String>();
			originList = caseEntitlement.Case_Origin__c.split(',');

			for(Case csRec : caseList){

				// SSSW entitlement assignment
				if(Utility.isValidRecordType(ssswRecTypes,csRec.RecordTypeId) && STD_ENTITLEMENT != null){  // verify if its SSSW recordtype
					csRec.EntitlementId = STD_ENTITLEMENT;  // assign default entitlement to cases
				}
				else if(UNIFIED_ENTITLEMENT_ID != null && unifiedRecordTypes.contains(csRec.RecordTypeId) == true && csRec.Type == SSSWConstants.INVESTIGATION) {
					csRec.EntitlementId = UNIFIED_ENTITLEMENT_ID; 
				}
				else if(Utility.isValidRecordType(bgsRecTypes, csRec.RecordTypeId) && (!originList.contains(csRec.Origin) || (originList.contains(csRec.Origin) && UserInfo.getUserId() != systemSupportUserId)))//only this condition modified for SMWD-312 - MW0004779
				{
					// 2020-01 MW0009344 BGS Cases
					// Add a new BGS Case (NOT created from Email to Case) to the bgsCases,
					// which will Assign BGS entitlements based on the contact's mailing state
					bgsCases.add(csRec);
				}
				else if(Utility.isValidRecordType(new Set<Id>{transportEnquiryRecTypeId}, csRec.RecordTypeId) && transportEnquiryEntitlementId != null) {
					//assign transport enquiry entitlement record for transport enquiry record type cases
					csRec.EntitlementId = transportEnquiryEntitlementId;
				}
				else if (Utility.isValidRecordType(new Set<Id>{bulkMailRecTypeId}, csRec.RecordTypeId) && bulkMailEntitlementId != null) {
					//assign bulk mail entitlement record for bulk mail record type cases
					csRec.EntitlementId = bulkMailEntitlementId;
				}

				// check if case is assigned to agent to set escalation mail
				if((csRec.Internal_Milestones_Violated__c == null || csRec.Internal_Milestones_Violated__c == 0)
						&& csRec.OwnerId != null && csRec.OwnerId.getSObjectType() == User.sObjectType){

					usrIds.add(csRec.OwnerId);
					updateCaseEscalationList.add(csRec);
				}
			}

			if(!bgsCases.isEmpty())
			{
				// 2020-01 MW0009344 Assign BGS Entitlements to any new Service Delivery Cases, only on CREATE
				AssignBGSEntitlement(bgsCases);
			}

			if(!updateCaseEscalationList.isEmpty()){	// check if updateCaseEscalationList got values
				setEscalationMail(usrIds,updateCaseEscalationList,false);   // set escalation mail if case assigned to agent
			}

		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
					CaseMilestoneUtility.class.getName(), SSSWConstants.METH_INSERT_MILESTONES,
					SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * Added 2020-01 Assigns a BGS Entitlement to a list of Cases for MW0009344
	  * This replaces the functionality of the existing Process Builder "Case Entitlement Assignment BGS"
	  *
	  * @param bgsCases a list of Cases of type Service Delivery/Sales_Ops_Delivery
	  */
	private static void AssignBGSEntitlement(List<Case> bgsCases)
	{
		System.debug('CaseMilestoneUtility::AssignBGSEntitlement:');

		//query just the VIC entitlement to default all cases to VIC
		List<Entitlement> entitlementList = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{BGSConstants.BGS_ENTITLEMENT_VIC}, new Set<String>{BGSConstants.BGS_ENTITLEMENT_STANDARD});
		if(!entitlementList.isEmpty()) {
			for (Case csRec : bgsCases) {
				csRec.EntitlementId = entitlementList[0].Id;
				csRec.BusinessHoursId = entitlementList[0].BusinessHoursId;
			}
		}
	}

	
	/**
	  * @description	   This method is invoked in after insert event, updates Target SLA & Customer SLA for case
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void updateSLA(List<Case> caseList){
		try{
			List<Case> casesToUpdate = new List<Case>();
			String casesJson ;
			for(Case csRec : caseList){
				if(Utility.isValidRecordType(ssswRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					if(csRec.SLATargetDate__c == null || 
						(csRec.CustomerTierSLA__c == null 
							&& SSSWConstants.STAT_AWAITING_CUST_RESPONSE.equalsIgnoreCase(csRec.Status))){
						casesToUpdate.add(csRec);
					}
				}
			}
			if(!casesToUpdate.isEmpty()){
				isCaseSLASet = true;		// set flag to true
				
				if(!System.IsFuture() && !System.IsBatch()){ //REQ2656153
					casesJson = JSON.serialize(casesToUpdate);
					setSLA(casesJson);
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseMilestoneUtility.class.getName(), SSSWConstants.METH_UPDATESLA, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	   This method is invoked from updateSLA, sets Target SLA & Customer SLA for case
	  * @param			 caseList - List<Case> 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by calling method
	  */
	@future  
	@TestVisible private static void setSLA(String casesJson){
		try{
			List<Case> caseList = (List<Case>)JSON.deserialize(casesJson,List<Case>.class);
			Map<Id,CaseMileStone> charterMileStoneMap = new Map<Id,CaseMileStone>();	
			Map<Id,CaseMileStone> customerMileStoneMap = new Map<Id,CaseMileStone>();   
			Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
			for(CaseMileStone mileStone : [SELECT TargetDate,CaseId,MilestoneType.Name FROM CaseMileStone 
											WHERE CaseId IN: caseList AND (MileStoneType.Name =: SSSWConstants.CHARTER_MILESTONE 
												OR MileStoneType.Name LIKE: SSSWConstants.CUSTOMER_MILESTONE_LIKE) 
												ORDER BY CaseId,CreatedDate DESC,MileStoneType.Name LIMIT : rowLimit]){
				
				if(SSSWConstants.CHARTER_MILESTONE.equalsIgnoreCase(mileStone.MileStoneType.Name) 
					&& !charterMileStoneMap.containsKey(mileStone.CaseId)){
					charterMileStoneMap.put(mileStone.CaseId,mileStone);
				}
				else if (mileStone.MileStoneType.Name.contains(SSSWConstants.CUSTOMER_TIER) 
							&& !customerMileStoneMap.containsKey(mileStone.CaseId)){
					customerMileStoneMap.put(mileStone.CaseId,mileStone);
				}
			}
			
			Id userBusinessHourId = Utility.getCurrentUserBussinessHour();  // get current user's business hour
			MilestoneWarningTime__c settings = MilestoneWarningTime__c.getValues(SSSWConstants.CHARTER_MILESTONE);
			Decimal percentage = (settings != null) ? (settings.Percentage__c/100) : SSSWConstants.DEF_MILESTONE_WARNING_PERCENT;
			System.debug('** userBusinessHourId ==>'+ userBusinessHourId);
			Map<Id,Case> updateMap = new Map<Id,Case>();
			Case updatedCase = null;
			for(Case csRec : caseList){
				updatedCase = new Case(Id = csRec.Id);
				if(!charterMileStoneMap.isEmpty()){
					if(charterMileStoneMap.containsKey(csRec.Id)){
						DateTime targetDate = (charterMileStoneMap.get(csRec.Id) != null) ? 
											charterMileStoneMap.get(csRec.Id).TargetDate : null;
						updatedCase.SLATargetDate__c = targetDate != null ? targetDate : csRec.SLATargetDate__c;
						if(userBusinessHourId != null){
							Long bizDiffInSeconds = BusinessHours.diff(userBusinessHourId, DateTime.Now(), updatedCase.SLATargetDate__c);
							Long warningTargetInSeconds = bizDiffInSeconds - (bizDiffInSeconds * percentage).longValue();
							updatedCase.MilestoneWarningTarget__c = BusinessHours.add(userBusinessHourId, DateTime.Now(), warningTargetInSeconds);
						}
						updatedCase.Bypass_Data_enforcement__c = true;
						updateMap.put(csRec.Id,updatedCase);
					}
				}
				
				if(!customerMileStoneMap.isEmpty()){
					if(customerMileStoneMap.containsKey(csRec.Id)){
						CaseMileStone custMilestone = customerMileStoneMap.get(csRec.Id);
						if(custMilestone != null){
							updatedCase.Previous_Milestone_Time__c = ((csRec.Previous_Milestone_Time__c == null) 
																	|| (custMilestone.TargetDate > csRec.Previous_Milestone_Time__c )) ? 
																		custMilestone.TargetDate : csRec.Previous_Milestone_Time__c;
							updatedCase.CustomerTierSLA__c = custMilestone.TargetDate;
							updatedCase.Bypass_Data_enforcement__c = true;
							updateMap.put(csRec.Id,updatedCase);
						}
					}
				}
			}

			if(!updateMap.isEmpty()){
		List<Database.SaveResult> saveResults = Database.update(updateMap.values(),false);
				for(Database.SaveResult result : saveResults){  // iterate through saveresults & throw validation error
					if (!result.isSuccess()) {
						if(result.getErrors().get(0).getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION){
							new Case(Id = result.getId()).addError(result.getErrors().get(0).getMessage());
						}
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseMilestoneUtility.class.getName(), SSSWConstants.METH_SETSLA, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	   This method is invoked from insertMilestones and updateMilestones, 
						   sets the escalation mail if case is assigned to network or agent 
	  * @param			 usrOrNtwrkIds - Set<Id>, caseList - List<Case>, isNetwork - Boolean 
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	@TestVisible private void setEscalationMail(Set<Id> usrOrNtwrkIds,List<Case> caseList,Boolean isNetwork){
		
		try{
			Map<Id,Map<Decimal,String>> escalationMap = new Map<Id,Map<Decimal,String>>();
			String soql = isNetwork ? SSSWConstants.NTWRK_SOQL : SSSWConstants.USR_SOQL;

			escalationMap = getEscalationMap(soql,usrOrNtwrkIds,isNetwork);
			Set<Id> caseIds = new Set<Id>();
			for(Case csRec : caseList){
				if(isNetwork){
					if(escalationMap.containsKey(csRec.Network__c) && escalationMap.get(csRec.Network__c) != null){
						isCaseEscalationSet = true;	 // set flag to true
						csRec.Facility_Tier_Escalation_Email__c = escalationMap.get(csRec.Network__c).get(
																											csRec.Facility_Milestones_Violated__c != null ? 
																												csRec.Facility_Milestones_Violated__c : 0);
					}
				}
				else{
					if(escalationMap.containsKey(csRec.OwnerId) && escalationMap.get(csRec.OwnerId) != null){
						isCaseEscalationSet = true;	 // set flag to true
						csRec.Internal_Tier_Escalation_Email__c = escalationMap.get(csRec.OwnerId).get(
																										csRec.Internal_Milestones_Violated__c != null ? 
																											csRec.Internal_Milestones_Violated__c : 0);
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseMilestoneUtility.class.getName(), SSSWConstants.METH_SETESCALATION, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	   This method is invoked from setEscalationMail, fetches network & user details to 
						   assign the escalation mail.
	  * @param			 soql - String, isNetwork - Boolean 
	  * @return			Map<Id,Map<Decimal,String>>
	  * @throws			Method might throw exception which is handled by calling method
	  */
	private Map<Id,Map<Decimal,String>> getEscalationMap(String soql,Set<Id> usrOrNtwrkIds,Boolean isNetwork){
		List<Network__c> ntwkList = new List<Network__c>();
		List<User> usrList = new List<User>();
		List<sObject> objList = new List<sObject>();
		Map<Id,Map<Decimal,String>> escalationMap = new Map<Id,Map<Decimal,String>>();
		Map<Decimal,String> tierMap = new Map<Decimal,String>();
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit			
		objList = Database.query(soql);
		if(isNetwork){
			ntwkList = (List<Network__c>) objList;
			
			if(!ntwkList.isEmpty()){
				for(Network__c ntwrk : ntwkList){
					tierMap = new Map<Decimal,String>();
					tierMap.put(1, ntwrk.Email_1__c);   //Gunith (9-7-19): Setting Email 1 as default address due to INC1370890
					tierMap.put(2, ntwrk.Email_1__c);   //Email 1 is sent once it moves to Tier 2.
					tierMap.put(3, ntwrk.Email_2__c);
					tierMap.put(4, ntwrk.Email_3__c);
					tierMap.put(5, ntwrk.Email_4__c);
					tierMap.put(6, ntwrk.Email_5__c);
					escalationMap.put(ntwrk.Id,tierMap);
				}
			}
		}
		else{
			usrList = (List<User>) objList;
			
			if(!usrList.isEmpty()){
				for(User usr : usrList){
					tierMap = new Map<Decimal,String>();
					tierMap.put(0, usr.Manager.Email);
					tierMap.put(1, usr.Email);		  //This should never be used by workflow - sent on number increment.
					tierMap.put(2, usr.Email);
					tierMap.put(3, usr.Manager.Email);
					tierMap.put(4, usr.Manager.Manager.Email);  
					escalationMap.put(usr.Id,tierMap);
				}
			}
		}
		
		return escalationMap;
	}
	
	/**
	  * @description	   This method is invoked in Before udpate event, sets the escalation mail if 
						   case is assigned to network or assigned to agent or case owner is changed
	  * @param			 caseList - List<Case>, oldMap - Map<Id,Case>
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void updateMilestones(List<Case> caseList,Map<Id,Case> oldMap){
		//try{
			Set<Id> ownerIds = new Set<Id>();
			List<Case> ownerChangedCases = new List<Case>();
			List<Case> completeCharterCases = new List<Case>();
			List<Case> milestoneStoppedCases = new List<Case>();
			List<Case> milestoneResumedCases = new List<Case>();

			for(Case csRec : caseList){
				Case oldCase = oldMap.get(csRec.Id);	// get old values of case

				if(UNIFIED_ENTITLEMENT_ID != null && unifiedRecordTypes.contains(csRec.RecordTypeId) == true) {
					if(oldCase.Type == SSSWConstants.GENERAL_ENQUIRY && csRec.Type == SSSWConstants.INVESTIGATION) {
						csRec.EntitlementId = UNIFIED_ENTITLEMENT_ID;
					}

					if(closedStatus.contains(oldCase.Status) == false && closedStatus.contains(csRec.Status) == true) {
						csRec.IsStopped = true;
						milestoneStoppedCases.add(csRec);
					} else if(closedStatus.contains(oldCase.Status) == true && closedStatus.contains(csRec.Status) == false) {
						csRec.IsStopped = false;
						milestoneResumedCases.add(csRec);
					}
				}

				if(Utility.isValidRecordType(ssswRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
					// check if owner is changed and an agent (user)
					if(oldCase != null && csRec.OwnerId != oldCase.OwnerId 
						&& csRec.OwnerId.getSObjectType() == User.sObjectType){
						
						ownerIds.add(csRec.OwnerId);
						ownerChangedCases.add(csRec);
					}
				} 

				// verify if its SSSW recordtype or transport enquiry case recordtype
				if(Utility.isValidRecordType(ssswRecTypes,csRec.RecordTypeId) || Utility.isValidRecordType(new Set<Id>{transportEnquiryRecTypeId}, csRec.RecordTypeId)) {
					// check if case is closed
					if((csRec.IsClosed && !oldCase.IsClosed) || (
							closedStatus.contains(csRec.Status) && csRec.Status != oldCase.Status)){
						completeCharterCases.add(csRec);
					}
				}
			}
			
			if(!ownerChangedCases.isEmpty()){   // check if ownerChangedCases got values
				setEscalationMail(ownerIds,ownerChangedCases,false);	// set escalation mail for owner change scenario
			}
			
			if(!completeCharterCases.isEmpty()){	// check if completeCharterCases got values 
				Utility.completeCaseMilestones(completeCharterCases,new Set<String>{SSSWConstants.CHARTER_MILESTONE,
																					SSSWConstants.FCR_MILESTONE},true);  // complete charter & First customer response mileStone if case is closed
			}
			isMilestoneUpdated = true;  // set flag to true
			
			updateCaseStatusTracking(caseList,oldMap);  // update open status tracking record

			if(milestoneStoppedCases.isEmpty() == false) {
				setMilestoneCompletionDates(milestoneStoppedCases, Datetime.now()); // this will set the Completion Date and IsCompleted will be come True
			}

			if(milestoneResumedCases.isEmpty() == false) {
				setMilestoneCompletionDates(milestoneResumedCases, null); // this will resume the milestone
			}
			try{
		}
		catch(Exception exp){
			System.debug('>>>> Exception thrown on CaseMilestoneUtility.updateMilestones(...): ' + exp.getMessage());
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseMilestoneUtility.class.getName(), SSSWConstants.METH_UPDATE_MILESTONES, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/*
		Ths method will scan for all non-violated milestones and set them to Completed
	*/
	private void setMilestoneCompletionDates(List<Case> cases, Datetime completionDate){

		List<CaseMilestone> milestonesToUpdate = new List<CaseMIlestone>();
		Map<Id, Case> casesMap = new Map<Id, Case>(cases);
		Datetime now = Datetime.now();
		Set<Object> filterOptions = new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_VIOLATED};

		// if the completion date is specified then only update the ones that have IsCompleted = False, or else update only those with IsComplete = True (ie. setting it to null)
		if(completionDate != null) {
			filterOptions.add(CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED);
		} else {
			filterOptions.add(CaseMilestonesSelector.Options.FILTER_COMPLETED);
		}

		for(CaseMilestone cm: CaseMilestonesSelector.newInstance().selectByCase(casesMap.keySet(), filterOptions).values()) {
			cm.CompletionDate = completionDate;
			milestonesToUpdate.add(cm);
		}
		
		if(milestonesToUpdate.isEmpty() == false) {
			try{
				ApplicationDatabase.getInstance().dmlUpdate(milestonesToUpdate);
			}
			catch(Exception exp){
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.UNIFIED_ENTITLEMENTS, 
														CaseMilestoneUtility.class.getName(), SSSWConstants.UNIFIED_ENTITLEMENTS, 
														SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
			}
		}
	} 
	
	/**
	  * @description	   This method is invoked from updateMilestones which creates task for milestone violation
	  * @param			 caseList - List<Case>, oldMap - Map<Id,Case>
	  * @return			Task
	  * @throws			NA
	  */
	private void updateCaseStatusTracking(List<Case> caseList,Map<Id,Case> oldMap){
		Map<Id, Decimal> caseEscalationTierMap = new Map<Id, Decimal>();
		List<Task> activityHistories = new List<Task>();
		
		for(Case csRec : caseList){
			if(Utility.isValidRecordType(ssswRecTypes,csRec.RecordTypeId)){  // verify if its SSSW recordtype
				Case oldCase = oldMap.get(csRec.Id);	// get old values of case
				Boolean isValid = false;
				String type = '';
				Decimal escalationTier = 0.0;

				// check if case is assigned to network & escalated
				if(csRec.Facility_Milestones_Violated__c > 0 && 
						((csRec.Facility_Milestones_Violated__c == 5 && (csRec.IsEscalated != oldCase.IsEscalated))
							|| csRec.Facility_Milestones_Violated__c != oldCase.Facility_Milestones_Violated__c)){
					isValid = true;
					type = SSSWConstants.SUBJ_NETWORK;
					escalationTier = csRec.Facility_Milestones_Violated__c;
				} // check if case is awaiting customer response & escalated
				else if(csRec.Customer_Milestones_Violated__c > 0 &&
							(csRec.Customer_Milestones_Violated__c == 3 && (csRec.ClosedBySystem__c != oldCase.ClosedBySystem__c))
								|| csRec.Customer_Milestones_Violated__c != oldCase.Customer_Milestones_Violated__c){
					isValid = true;
					type = SSSWConstants.SUBJ_CUSTOMER;
					escalationTier = csRec.Customer_Milestones_Violated__c;
				}   // check if case pending action from agent & escalated
				else if(csRec.Internal_Milestones_Violated__c > 0 &&
							(csRec.Internal_Milestones_Violated__c == 3 && (csRec.IsEscalated != oldCase.IsEscalated))
								|| csRec.Internal_Milestones_Violated__c != oldCase.Internal_Milestones_Violated__c){
					isValid = true;
					type = SSSWConstants.SUBJ_INTERNAL;
					escalationTier = csRec.Internal_Milestones_Violated__c;
				}

				if(isValid) {
					caseEscalationTierMap.put(csRec.Id, escalationTier);
					activityHistories.add( // create closed task for each escalation
						createTask(csRec.Id, 
							getTaskSubject(csRec.CaseNumber, type, (escalationTier - 1)), 
							Date.Today(), 
							SSSWConstants.STAT_COMPLETED
						)
					);
				}
			}
		}
		
		if(!caseEscalationTierMap.isEmpty()){ 
			List<StatusTracking__c> stList = getCaseStatusTrackingToUpdate(caseEscalationTierMap); //get relevant Status Tracking records and update escalation tier
			if(!stList.isEmpty()){ 
				Database.update(stList, false);
			}
			/* Invoke future update for case to avoid mileStone evaluation limitation */
			if(!System.isFuture()){
				futureUpdate(caseEscalationTierMap.keyset());
			}
		}
		
		if(!activityHistories.isEmpty()){   // check if activityHistories got values before DML
			Database.insert(activityHistories,false);
		}
	}
	
	/**
	  * @description	   This method is invoked from updateCaseStatusTracking to update case for evaluating milestone criteria
						   to overcome limitation https://help.salesforce.com/apex/HTViewSolution?id=000199066&language=en_US
	  * @param			 caseIds - Set<Id>
	  * @return			void
	  * @throws			Method might throw exception which is handled by try-catch block
	  */
	@future
	@TestVisible private static void futureUpdate(Set<Id> caseIds){
		try{
			// Creating instance of case from caseId to update preventing SOQL
			List<Case> caseList = new List<Case>();
			for(Id caseId : caseIds){
				Case caseRec = new Case(Id = caseId);
				caseList.add(caseRec);
			}
			if(!caseList.isEmpty()){
				Database.update(caseList,false);
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseMilestoneUtility.class.getName(), SSSWConstants.METH_FUTURE_UPDATE, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	   This method is invoked from updateMilestones which creates task for milestone violation
	  * @param			 caseList - List<Case>, oldMap - Map<Id,Case>
	  * @return			Task
	  * @throws			NA
	  */
	private Task createTask(Id caseId,String subj,Date taskDate,String taskStatus){
		Task closedTask = new Task(whatId = caseId, Subject = subj, ActivityDate = Date.Today(), Status = taskStatus);
		return closedTask;
	}  
	
	/**
	  * @description	   This method is invoked from updateCaseStatusTracking which fetch the status tracking records for case
	  * @param			 caseEscalationTierMap - Map<Id, Decimal> Map of Case Id and Case Escalation Tier
	  * @return			Map<Id,StatusTracking__c>
	  * @throws			NA
	*/
	private List<StatusTracking__c> getCaseStatusTrackingToUpdate(Map<Id, Decimal> caseEscalationTierMap){
		List<StatusTracking__c> stList = new List<StatusTracking__c>();
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
		for(StatusTracking__c tracking : [SELECT Case__c, EscalationTier__c 
											FROM StatusTracking__c WHERE Case__c IN: caseEscalationTierMap.keySet() 
											ORDER BY Case__c, StartDate__c DESC LIMIT : rowLimit]) {
			if(caseEscalationTierMap.containsKey(tracking.Case__c) && tracking.EscalationTier__c != caseEscalationTierMap.get(tracking.Case__c)) {
				tracking.EscalationTier__c = caseEscalationTierMap.get(tracking.Case__c);
				stList.add(tracking);
			}
		}
		return stList;
	}
	
	/**
	  * @description	   This method is invoked from updateMilestones which creates task for milestone violation
	  * @param			 caseNumber - String, type - String,escalationTier - Decimal
	  * @return			String
	  * @throws			NA
	  */
	private String getTaskSubject(String caseNumber,String type,Decimal escalationTier){
		String subj = SSSWConstants.SUBJ_EMAIL + caseNumber + type + escalationTier + SSSWConstants.SUBJ_NOTIFICATION;
		return subj;
	}

	/**
	 * Update Case's Network Escalation Emails when escalation is hit. Refactored out of updateCaseStatusTracking()
	 *
	 * @param caseList The updated Cases in the trigger context
	 * @param oldMap The old versions of the updated Cases
	 */
	public void updateNetworkEscalationEmails(List<Case> caseList, Map<Id,Case> oldMap) {
		try {

			// Gunith (14-05-19): To capture Network Milestone violations updated via Workflows,
			// we have to find which if the relevant attributes were really updated
			List<Case> networkMilestonesUpdatedCases =
					(oldMap != null)
							?
							RecursionUtility.getUnprocessedRecords('UpdateNetworkEscalationEmailsTriggerContext',
									caseList, NETWORK_MILESTONE_SENSITIVE_FIELDS)
							:
							caseList;

			// If no cases to process, do nothing
			if (networkMilestonesUpdatedCases.isEmpty()) {
				return;
			}

			Set<Id> networkIds = new Set<Id>();
			List<Case> updateNetworkEscalationCases = new List<Case>();

			for (Case updatedCase : networkMilestonesUpdatedCases) {
				if (!Utility.isValidRecordType(ssswRecTypes, updatedCase.RecordTypeId)) {  // verify if its SSSW recordtype
					continue;
				}

				Case oldCase = oldMap.get(updatedCase.Id);	// get old values of case

				// check if case is assigned to network & escalated
				if (updatedCase.Facility_Milestones_Violated__c > 0 &&
						updatedCase.Facility_Milestones_Violated__c != oldCase.Facility_Milestones_Violated__c) {

					if (updatedCase.Network__c != null) {
						networkIds.add(updatedCase.Network__c);
					}

					updateNetworkEscalationCases.add(updatedCase);	// update escalation mail for network
				}
			}

			if (!updateNetworkEscalationCases.isEmpty()) {	// check if updateNetworkEscalationCases got values
				setEscalationMail(networkIds, updateNetworkEscalationCases, true);
			}

		} catch (Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
					CaseMilestoneUtility.class.getName(), 'updateNetworkEscalationEmails',
					SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	
	/**
	  * MW0009344 get all entitlement records for BGS. It expects the records to be named as BGS Entitlement Standard VIC/NSW/etc
	  *
	  * @return a Map of <Name , Id> of entitlement records
	  * commented by Asha for SMWD-312: retreiving all the entitlements is not required anymore as we are defaulting all cases to VIC entitlement
	  */
	/*public static Map<String, Id> getBGSEntitlementIds()
	{
		// Get all the entitlement names from the account
		List<Entitlement> bgsEntitlements = [
				SELECT Id, Name
				FROM Entitlement
				WHERE Account.Name =: BGSConstants.BGS_ENTITLEMENT_STANDARD
				LIMIT 15
		];

		Map<String, Id> bgsEntitlementIds = new Map<String, Id>();
		for(Entitlement ent:bgsEntitlements)
		{
			bgsEntitlementIds.put(ent.Name, ent.Id);
		}
		//System.debug('BGS Entitlements:' + bgsEntitlementIds);
		return bgsEntitlementIds;
	}*/
	
}