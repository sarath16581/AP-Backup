/*** 
 * @description
 * Domain Module to reassign Closed Cases from Omnichannel Queues.
 * This prevents Closed Cases from being routed by Omni-channel to an Agent.
 * Only Cases in Queues with a Routing Configuration are reassigned.
 * NOTE: IsClosed is only set to True in Trigger.IsAfter, hence the logic runs onAfter
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-10-17 - Noel Lim - Created
 * 2022-11-16 - Noel Lim - Update
 						a) Added inner class WithoutSharingRetrieveData to allow guest users to access the AgentWork object
 * 						b) New logic to route cases that are reopened and are in the SSSW_Closed_Omnichannel_Cases queue
 */
public inherited sharing class MyCustomerClosedCaseModule extends ApplicationDomain.Module {

	public static MyCustomerClosedCaseModule newInstance() {
		return (MyCustomerClosedCaseModule)Application.Utilities.newInstance(MyCustomerClosedCaseModule.class);
	}

	// Setup which triggers this module should respond to
	public MyCustomerClosedCaseModule() {
		getTriggerEvents().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			routeReopenedCases(filterToReopenedCases(records, existingRecords), uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ClosedCase', MyCustomerClosedCaseModule.class.getName(), 'onAfterInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}		
	}
	
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			reassignClosedCases(filterToClosedCases(records, null), uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ClosedCase', MyCustomerClosedCaseModule.class.getName(), 'onAfterInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}		
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			reassignClosedCases(filterToClosedCases(records, existingRecords), uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ClosedCase', MyCustomerClosedCaseModule.class.getName(), 'onAfterUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}		
	}

	/**
	 * Filter based on the following:
	 * a) Closed Cases, via IsClosed field
	 * b) Case Status changed or Case Owner changed
	 * c) Case is assigned to a queue with a routing configuration
	 */
	private Map<Id,Case> filterToClosedCases(List<SObject> records, Map<Id, SObject> existingRecords) {

		Map<Id, Case> closedCases = new Map<Id, Case>();
		Map<Id, Group> queues = new Map<Id, Group>();
		Case existingCase;

		for(Case c: (List<Case>)records) {
			if(existingRecords != null){
				existingCase = (Case)existingRecords.get(c.Id);
			}

			if(c.OwnerId != null && c.OwnerId.getSobjectType() == Group.sObjectType && c.IsClosed == true && 
				(existingCase == null || (existingCase != null && 
						((existingCase.IsClosed != c.IsClosed) ||
						(existingCase.OwnerId != c.OwnerId))
				))
			){
				closedCases.put(c.id, c);
				queues.put(c.OwnerId, null);
			}
		}	

		if(queues.isEmpty() == false) {
			queues = GroupsSelector.newInstance().selectById(queues.keySet());
			
			for(Case c: closedCases.values()) {
				if(queues.get(c.OwnerId).QueueRoutingConfigId == null) { // only interested in Omni queues
					closedCases.remove(c.Id);
				}
			}	
		}

		return closedCases;
	}

	/**
	 * Assign the Case to the previous Agent, otherwise assign to the Closed Omnichannel Queue
	 */
	private void reassignClosedCases(Map<Id, Case> closedCases, ApplicationUnitOfWork uow) {		

		if(closedCases.isEmpty() == false) {
			Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
			Map<Id, Id> caseIdVsAgentId = new Map<Id, Id>();
			
			List<AgentWork> aws = new WithoutSharingRetrieveData().getAgentWorkItems(closedCases.keySet());

			for(AgentWork aw: aws){

				// grabs the first user id from agent work since it is sorted by DESC 
				if(caseIdVsAgentId.containsKey(aw.WorkItemId) == false) {
					caseIdVsAgentId.put(aw.WorkItemId, aw.UserId);
				}
			}

			List<Case> casesToUpdate = new List<Case>();
			for(Case c: CasesSelector.newInstance().selectById(closedCases.keySet()).values()) {
				if(caseIdVsAgentId.containsKey(c.Id) == true) {
					casesToUpdate.add(new Case(Id = c.Id, OwnerId = caseIdVsAgentId.get(c.Id)));
				} else {
					casesToUpdate.add(new Case(Id = c.Id, OwnerId = omnichannelClosedCaseQueueId));
				}
			}

			uow.registerDirty(casesToUpdate, new List<SObjectField> {Case.OwnerId}, String.valueOf(MyCustomerClosedCaseModule.Class));
		}
	}

	/**
	 * Filter based on the following:
	 * a) Reopened Cases, via IsClosed field
	 * b) Case is assigned to the Closed Queue
	 */
	private Map<Id,Case> filterToReopenedCases(List<SObject> records, Map<Id, SObject> existingRecords) {

		Map<Id, Case> reopenedCases = new Map<Id, Case>();
		Case existingCase;

		if(existingRecords != null){
			Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;

			for(Case c: (List<Case>)records) {
				existingCase = (Case)existingRecords.get(c.Id);

				if(c.IsClosed == false && existingCase.IsClosed != c.IsClosed && c.OwnerId == omnichannelClosedCaseQueueId){
					reopenedCases.put(c.id, c);
				}
			}
		}	

		return reopenedCases;
	}



	/**
	 * Set the Case to be routed in CaseTriggerHandler.cls
	 */
	private void routeReopenedCases(Map<Id, Case> reopenedCases, ApplicationUnitOfWork uow) {	

		if(reopenedCases.isEmpty() == false) {
			for(Case c: (List<Case>)reopenedCases.values()) {
				c.AllocateToQueue__c = true;
			}
		}
	}

	/**
	 *	Required to provide elevated privileges for guest users to query the AgentWork object 
	 */
	public without sharing class WithoutSharingRetrieveData{
		
		private List<AgentWork> getAgentWorkItems(Set<Id> closedCaseIds){
			return AgentWorkSelector.newInstance().selectByAcceptedWorkItemIds(closedCaseIds,new Set<Object>());
		}
	}
}
