/*** 
 * @description
 * Domain Module to reassign Closed Cases from Omnichannel Queues.
 * This prevents Closed Cases from being routed by Omni-channel to an Agent
 * Only Cases in Queues with a Routing Configuration are reassigned.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-10-17 - Noel Lim - Created
 */
public with sharing class MyCustomerClosedCaseModule extends ApplicationDomain.Module {

	public static MyCustomerClosedCaseModule newInstance() {
		return (MyCustomerClosedCaseModule)Application.Utilities.newInstance(MyCustomerClosedCaseModule.class);
	}

    // Setup which triggers this module should respond to
	public MyCustomerClosedCaseModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        processClosedCases(records, uow);
    }

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        processClosedCases(records, uow);
    }

    /**
     * Filter to Closed Cases by IsClosed and eligible Queues
     * NOTE: IsClosed is only set to True in Trigger.IsAfter
     */
    private void processClosedCases(List<SObject> records, ApplicationUnitOfWork uow) {
        Map<Id, Case> closedCases = new Map<Id, Case>();
        Map<Id, Group> queues = new Map<Id, Group>();

        for(Case c: (List<Case>)records) {
            if(c.IsClosed == true 
                && c.OwnerId != null
                && c.OwnerId.getSobjectType() == Group.sObjectType) {

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
            reassignToPreviousAgentIfApplicable(closedCases, uow);
        }
    }

    /**
     * Attempt to assign the Case to the previous Agent, otherwise assign to a default Queue
     */
    private void reassignToPreviousAgentIfApplicable(Map<Id, Case> closedCases, ApplicationUnitOfWork uow) {        
        if(closedCases.isEmpty() == false) {
            Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
            Map<Id, Id> caseIdVsAgentId = new Map<Id, Id>();
            for(AgentWork aw: AgentWorkSelector.newInstance().selectByAcceptedWorkItemIds(closedCases.keySet(),new Set<Object>())){

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
}