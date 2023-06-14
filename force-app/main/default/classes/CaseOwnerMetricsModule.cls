/**
 * @description
 * Domain Module to populate the role of the user who closed the case and the queue name if the case is assigned to a queue
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Ashapriya Gadi
 * @date 2021-12-06
 * @group Domain
 * @domain EmailMessage
 * @changelog
 * 02-02-2022 Ashapriya Gadi The closing owner user role field will be populated with the Role display name of the user that closes the case. Originally it was populated with the role name, but was requested by the BGS team to have this populated with the Role display name, so that it adheres to all their existing reporting.
 * 2023-06-14 - Nathan Franklin - uplift to domainless architecture
 */

public inherited sharing class CaseOwnerMetricsModule extends ApplicationModule  {

	/**
	 * @deprecated
	 */
	public static CaseOwnerMetricsModule newInstance() {
		return (CaseOwnerMetricsModule)Application.Utilities.newInstance(CaseOwnerMetricsModule.class);
	}
	
	// Setup which triggers this module should respond to
	public CaseOwnerMetricsModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}
	/**
	 * Called when a new Case is being inserted
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			assignCaseQueue(records, null , uow);
			assignCaseClosureOwnerRole(records, null, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), BGSConstants.SERVICE_DELIVERY_NAME, CaseOwnerMetricsModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	/**
	 * Called when a Case is being updated.
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			assignCaseQueue(records, existingRecords , uow);
			assignCaseClosureOwnerRole(records, existingRecords, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), BGSConstants.SERVICE_DELIVERY_NAME, CaseOwnerMetricsModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	public void assignCaseQueue(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		//Map to store the case records for which owner is changed in case of update scenario
		Map<Id, Set<SObjectField>> ownerChangedRecords = new Map<Id, Set<SObjectField>>();
		//Map to store the group records retrieved using ownerIds of the cases
		Map<Id, Group> queueMap = new Map<Id, Group>();
		//Set to store case owner Ids
		Set<Id> queueIds = new Set<Id>();
		Boolean isInsert = false;
		if(existingRecords == null || existingRecords.isEmpty()){
			isInsert = true;
		}else{
			//call getIsChanged method to retrieve the case records for which the ownerId is changed
			ownerChangedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{Case.OwnerId});
		}
		//collect the queueIds
		for(Case c : (List<Case>)records) {
			//check if the case owner is a queue(Id starts with 00G) and (if the owner is changed in case of update or if insert)
			if(String.ValueOf(c.OwnerId).startsWith('00G') &&  ( (!isInsert && !ownerChangedRecords.isEmpty() && ownerChangedRecords.keySet().contains(c.Id)) || isInsert) ){
				queueIds.add(c.OwnerId);
			}
		}
		//Fetch the userRole(to be assigned to ClosureOwnerRole__c field) using the UserRolesSelector. The roleId from UserInfo is sufficient here
		if(!queueIds.isEmpty()) {
			queueMap = GroupsSelector.newInstance().selectById(queueIds);
		}
		if(!queueMap.isEmpty()) {
			for (Case c : (List<Case>) records) {
				//check if the case owner is a queue(Id starts with 00G)
				if (String.ValueOf(c.OwnerId).startsWith('00G') && ((!isInsert && !ownerChangedRecords.isEmpty() && ownerChangedRecords.keySet().contains(c.Id)) || isInsert)) {
					c.Last_Assigned_Queue_ID__c = c.OwnerId;//assign ownerId to the last assigned queue Id field
					//assign the owner name to Last_Assigned_Queue__c
					c.Last_Assigned_Queue__c = queueMap.get(c.OwnerId).Name;
					//c.Last_Assigned_Queue__c = c.Calc_Owner_Name__c;//this value is available in before insert even after commenting the before update method call to assignCaseQueue; but still going to query the groups
				}
			}
		}
	}
	//Called when a Case is being updated to change the status. SMWD-323 - MW0004671- Populating the Case Closure Owner Role field
	public void assignCaseClosureOwnerRole(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		//Map to store the case records for which status is changed in case of update scenario
		Map<Id, Set<SObjectField>> statusChangedRecords = new Map<Id, Set<SObjectField>>();
		//List to store the cases for which status is changed
		List<Case> statusChangedCases = new List<Case>();
		//List to store user roles
		List<UserRole> userRolesList = new List<UserRole>();
		Boolean isInsert = false;
		if(existingRecords == null || existingRecords.isEmpty()){
			isInsert = true;
		}else{
			//call getIsChanged method to retrieve the case records for which the status is changed
			statusChangedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{Case.Status});
		}
		//get the set of statuses that define a case as closed{Closed, Closed - Expired, Closed-duplicate, Closed-out of scope, Discontinued, Merged, Resolved}
		Set<String> setOfClosedStatuses = Utility.getCaseClosedStatus();
		//populate statusChangedCases
		for(Case c : (List<Case>)records) {
			//if update and statusChangedRecords map contains the current case record. That would mean that the status is changed for that case record. Or if the case is created with closed status
			if((!isInsert && !statusChangedRecords.isEmpty() && statusChangedRecords.keySet().contains(c.Id)) || (isInsert && setOfClosedStatuses.contains(c.Status)) ){
					statusChangedCases.add(c);
			}
		}
		//Fetch the userRole(to be assigned to ClosureOwnerRole__c field) using the UserRolesSelector. The roleId from UserInfo is sufficient here
		if(!statusChangedCases.isEmpty() && String.isNotBlank(UserInfo.getUserRoleId())) {
			userRolesList = UserRolesSelector.newInstance().selectById(new Set<Id>{UserInfo.getUserRoleId()}).values();
		}
		if(!statusChangedCases.isEmpty()) {
			for (Case c : statusChangedCases) {
				//If the status is changed to closed, then assign ClosureOwnerRole__c to the user role display name of the user that closed the case(which will be the roleId from the userInfo).
				if (setOfClosedStatuses.contains(c.Status) && !userRolesList.isEmpty()) {
					c.ClosureOwnerRole__c = userRolesList[0].RollupDescription;
				}
				//If the status is changed to anything other than Closed, then we clear out the ClosureOwnerRole__c field
				else c.ClosureOwnerRole__c = '';
			}
		}
	}

}