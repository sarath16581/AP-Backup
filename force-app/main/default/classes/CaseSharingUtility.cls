/**
 * @description Utility Class for adding/removing network users to/from case team
 * @author	   : nandan.narasappa@auspost.com.au
 * @date		 : 01/09/2015
 * @changelog
 * 01/09/2015 - nandan.narasappa@auspost.com.au			  Created
 * 06/11/2015 - nandan.narasappa@auspost.com.au			  Added createSignatureAttachments method
 * 18/01/2019 - disha.kariya@auspost.com.au				  Added insertCaseTeamMembersForChildCase method for Sharing Child Case to parent using Case Team member only for Service Delivery Setting Custom Metadata
 * 2021-10-04 - Nathan Franklin - Deprecated createSignatureAttachments, createAttachments, getArticleEventMessages
 * 2023-07-03 - Mahesh Parvathaneni - Updated handleCaseTeamMembers to ignore for transport enquiry cases
 */
public without sharing class CaseSharingUtility{	// Access is set without sharing to for creation of CaseTeamMember if executed from Community user
	
	// Constants
	private static final String SSSW_PON_ROLE = 'SSSW PON';
	private static final String CASE_VIEW = 'Case Viewer';
	
	// Variables
	public static Boolean isHandleTeamMemberRecursive = false;	  // flag for handling case team members
	public static Boolean isCreateSignatureRecursive = false;	  // flag for handling case team members
	private static Set<Id> validRecTypes;				   // type of cases for which code executes
	private static Id transportEnquiryRecTypeId;
	
	static{ // code executed to fetch details when class is invoked
		try{
			validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			// Get the Record Type Id for Transport Enquiry Cases
			transportEnquiryRecTypeId = TransportEnquiryCaseService.getInstance().getTransportEnquiryRecordTypeId();
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseSharingUtility.class.getName(), SSSWConstants.STATIC_BLOCK, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	   This method adds network user to case team and removes if network is changed.
	  * @param			 caseList - List<Case> , oldCaseMap - Map<Id,Case>
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */		
	public void handleCaseTeamMembers(List<Case> caseList,Map<Id,Case> oldCaseMap){
		Map<Id,List<Case>> addFacilityCaseMap = new Map<Id,List<Case>>();   // variable to store facility & list of cases associated
		Map<Id,List<Case>> delFacilityCaseMap = new Map<Id,List<Case>>();   // variable to store facility & list of cases associated
		Map<Id,List<Id>> facilityUsersMap = new Map<Id,List<Id>>(); // variable to store facility & network users
		
		Set<Id> facilityIds = new Set<Id>();	// set of ids for facilities
		
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
		
		try{
			for(Case caseRec : caseList){
				//ignore the assigment of case team members for transport enquiry case
				if(caseRec.RecordTypeId != transportEnquiryRecTypeId) {
					Case oldCase = oldCaseMap != null ? oldCaseMap.get(caseRec.Id) : null;  // get old case values
					if(oldCase != null){	// update scenario
						// verify if either old or new values of case contains network
						if((caseRec.Network__c != null || oldCase.Network__c != null) &&
							caseRec.Network__c != oldCase.Network__c){
							
							isHandleTeamMemberRecursive = true;	 // setting recursive flag for update scenario
							
							// members to be added to case team if network is populated for case
							if(caseRec.Network__c != null && oldCase.Network__c == null){
								addFacilityCaseMap = updateMap(addFacilityCaseMap,caseRec); 
							}
							// members to be removed from case team if network removed from case
							else if(caseRec.Network__c == null && oldCase.Network__c != null){
								delFacilityCaseMap = updateMap(delFacilityCaseMap,oldCase); 
							}
							else{   // members to be added to new network & removed from old network in case of network change
								addFacilityCaseMap = updateMap(addFacilityCaseMap,caseRec); 
								delFacilityCaseMap = updateMap(delFacilityCaseMap,oldCase); 
							}
						}
					}
					else{   // insert scenario 
						if(caseRec.Network__c != null){ // verify if network is populated
							addFacilityCaseMap = updateMap(addFacilityCaseMap,caseRec); 
						}
					}
				}
			}
			if(!addFacilityCaseMap.isEmpty()){  // store network ids of case for which user should be added to team
				facilityIds.addAll(addFacilityCaseMap.keyset());
			}
			
			if(!delFacilityCaseMap.isEmpty()){  // store network ids of case from which user should be removed
				facilityIds.addAll(delFacilityCaseMap.keyset());
			}
			if(!facilityIds.isEmpty()){ // verify if networks are available
				List<Id> tmpUserList = new List<Id>();
				// fetch network users for a network based on facilityIds
				for(Facility_User__c networkUser : [SELECT User__c,User__r.IsActive,Network__c FROM Facility_User__c WHERE Network__c IN: facilityIds 
													AND User__c != NULL AND User__r.IsActive = TRUE ORDER BY CreatedDate DESC LIMIT : rowLimit]){
					tmpUserList = (!facilityUsersMap.isEmpty() && facilityUsersMap.containsKey(networkUser.Network__c)) ?
									facilityUsersMap.get(networkUser.Network__c) : new List<Id>() ;
					tmpUserList.add(networkUser.User__c);
					facilityUsersMap.put(networkUser.Network__c,tmpUserList);
				}
				if(!facilityUsersMap.isEmpty()){	// verify if facilityUsersMap has values
					removeCaseTeamMembers(delFacilityCaseMap,facilityUsersMap); // invoked method deletes CaseTeamMembers from a case
					insertCaseTeamMembers(addFacilityCaseMap,facilityUsersMap); // invoked method creates CaseTeamMembers for a case
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													CaseSharingUtility.class.getName(), SSSWConstants.METH_HANDLE_MBRS, 
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	  * @description	   This method checks if contains key and updates value
	  * @param			 mapToUpdate - Map<Id,List<Case>> , caseRec - Case
	  * @return			Map<Id,List<Case>>
	  * @throws			NA
	  */  
	private static Map<Id,List<Case>> updateMap(Map<Id,List<Case>> mapToUpdate,Case caseRec){
		List<Case> tmpCaseList = new List<Case>();
		// verify if map contains key, if available assigns values for key from map else an empty list
		tmpCaseList = (mapToUpdate != null && !mapToUpdate.isEmpty() && mapToUpdate.containsKey(caseRec.Network__c)) ?
						mapToUpdate.get(caseRec.Network__c) : new List<Case>();
		tmpCaseList.add(caseRec);
		mapToUpdate.put(caseRec.Network__c,tmpCaseList);
		return mapToUpdate;
	}
	
	/**
	  * @description	   This method adds users to case team
	  * @param			 addMbrMap - Map<Id,List<Case>> , ntwrkUsrsMap - Map<Id,List<Id>>
	  * @return			void
	  * @throws			Method might throw DML exception which is handled by calling method - handleCaseTeamMembers
	  */  
	private static void insertCaseTeamMembers(Map<Id,List<Case>> addMbrMap,Map<Id,List<Id>> ntwrkUsrsMap){
		Set<CaseTeamMember> addMbrSet = new Set<CaseTeamMember>();
		if(addMbrMap != null && !addMbrMap.isEmpty()){
			List<Case> caseRecs = new List<Case>();
			for(List<Case> caseList : addMbrMap.values()){  // fetch all cases for which CaseTeamMember should be created
				caseRecs.addAll(caseList);
			}
			if(ntwrkUsrsMap != null && !ntwrkUsrsMap.isEmpty()){ // verify if ntwrkUsrsMap has values
				CaseTeamMember mbr = null;
				for(Case caseRec : caseRecs){
					// verify if map contains network & associated network users
					if(ntwrkUsrsMap.containsKey(caseRec.Network__c) && ntwrkUsrsMap.get(caseRec.Network__c) != null){
						for(Id usrId : ntwrkUsrsMap.get(caseRec.Network__c)){
							// instance of CaseTeamMember record
							mbr = new CaseTeamMember(ParentId = caseRec.Id,MemberId = usrId,
														TeamRoleId = Utility.getCaseTeamRole(SSSW_PON_ROLE));	
							addMbrSet.add(mbr);
						}
					}
				}
				if(!addMbrSet.isEmpty()){  // verify if list contains value before insert
					Database.insert(new List<CaseTeamMember>(addMbrSet));
				}
			}
		}
	}
	
	/**
	  * @description	   This method removes users from case team
	  * @param			 removeMbrMap - Map<Id,List<Case>> , ntwrkUsrsMap - Map<Id,List<Id>>
	  * @return			void
	  * @throws			Method might throw DML exception which is handled by calling method - handleCaseTeamMembers
	  */  
	private static void removeCaseTeamMembers(Map<Id,List<Case>> removeMbrMap,Map<Id,List<Id>> ntwrkUsrsMap){
		List<CaseTeamMember> delMbrList = new List<CaseTeamMember>();
		if(removeMbrMap != null && !removeMbrMap.isEmpty()){
			Set<Case> caseIds = new Set<Case>();	// variable to store case ids from which users should be removed
			Set<Id> usrIds = new Set<Id>();	 // variable to store users to be removed from Case Team
			Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
			
			// Get all case and the networkUser ids
			for(Id ntwrkId : removeMbrMap.keyset()){  
				caseIds.addAll(removeMbrMap.get(ntwrkId));  // fetch all cases from which users should be removed
				// verify if network id is available in ntwrkUsrsMap
				if(ntwrkUsrsMap.containsKey(ntwrkId) && ntwrkUsrsMap.get(ntwrkId) != null){
					usrIds.addAll(ntwrkUsrsMap.get(ntwrkId));
				}
			}
			// fetch case team member to be deleted
			delMbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember 
							WHERE ParentId IN: caseIds AND MemberId IN: usrIds
							LIMIT : rowLimit];
			if(!delMbrList.isEmpty()){  // verify if list contains value before delete
				Database.delete(delMbrList);
			}
		}
	}

	/**
	  * @description	   This method is invoked in after insert event, to add Parent Case Owner AND/OR 
							Requestor as Case Team Member on Child case creation when Parent Case Record Type 
							and Child Case Record type combination exist in Service Delivery Setting Meatadata
	  * @param			 cseMap - Map<Id, Case>
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void insertCaseTeamMembersForChildCase(Map<Id, Case> cseMap) {
		try {
			//List of case team members to be inserted
			Set<CaseTeamMember> addMembers = new Set<CaseTeamMember>();
			//list of target and source record type names to search metadata
			List<string> targetRecTypeIdList = new List<string>();
			List<string> sourceRecTypeIdList = new List<string>();
			//Query required child and parent case fields
			List<Case> childCases = [SELECT Id, RecordType.Name, Parent.RecordType.Name, ParentId, 
						Parent.OwnerId, OwnerId, ContactId, Description, Subject, CaseNumber, Requestor__c 
						FROM Case WHERE Id IN:cseMap.keySet() AND ParentId != null];
			for(Case cs :childCases){
				targetRecTypeIdList.add(cs.RecordtypeId);
				sourceRecTypeIdList.add(cs.Parent.RecordtypeId);
			}
			//Loop through the Service_Delivery_Setting__mdt values where record types are in childCaseMap 
			//and parentCaseMap and create Case Team Member checkbox is checked.
			for(Service_Delivery_Setting__mdt servDel : [SELECT Source_RecordType_Id__c, Target_RecordType_Id__c, 
										Case_Team_Member_Role__c FROM Service_Delivery_Setting__mdt where 
										Source_RecordType_Id__c in :sourceRecTypeIdList AND 
										Target_RecordType_Id__c in :targetRecTypeIdList AND 
										Create_Case_Team_Member_for_Child_Case__c = TRUE ]){
				//get case team role from metadata, if not present default it to case viewer
				string caseTeamMemberRole = '';
				if(!String.IsBlank(servDel.Case_Team_Member_Role__c)){
					caseTeamMemberRole = Utility.getCaseTeamRole(servDel.Case_Team_Member_Role__c);
				}
				else{
					caseTeamMemberRole = Utility.getCaseTeamRole(CASE_VIEW);
				}
				//Loop through Child Cases
				for(Case cs : childCases){ 
					//Add Case team Member with viewer access
					CaseTeamMember mbr = null;
					//Check if the case record type and Parent Case record type combination exist in Metadata.
					if(cs.RecordTypeId == servDel.Target_RecordType_Id__c && 
						cs.Parent.RecordTypeId == servDel.Source_RecordType_Id__c){
						// Add Child case Requestor__c to Case Team Member if not null
						if (cs.Requestor__c != null) {
							mbr = new CaseTeamMember(ParentId = cs.Id, MemberId = cs.Requestor__c,
									TeamRoleId = caseTeamMemberRole);
							addMembers.add(mbr);
						}
						//Add Parent Case Owner to Case Team Member if requestor is different to Parent Case Owner.
						// This will be true if Requestor is null
						if(cs.Requestor__c != cs.Parent.OwnerId){
							if(string.valueOf(cs.Parent.OwnerId).startsWith('005')){
									mbr = new CaseTeamMember(ParentId = cs.Id, MemberId = cs.Parent.OwnerId ,
									TeamRoleId = caseTeamMemberRole);
									addMembers.add(mbr);
							}
							else if(string.valueOf(cs.Parent.OwnerId).startsWith('00G')){
								mbr = new CaseTeamMember(ParentId = cs.Id, MemberId = UserInfo.getUserId() ,
									TeamRoleId = caseTeamMemberRole);
									addMembers.add(mbr);
							}
							
						}
					}
				}
			}
			
			// verify if list contains values before insert
			if(!addMembers.isEmpty()){
				Database.insert(new List<CaseTeamMember>(addMembers));
			}
		}
		catch (Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'Child Case creation',
				   CaseTriggerHelper.class.getName(), SSSWConstants.METH_HANDLE_MBRS_CHILD_CASE,
				   SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
}