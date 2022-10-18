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

    private static Set<String> closedStatusAPINames;

	public static MyCustomerClosedCaseModule newInstance() {
		return (MyCustomerClosedCaseModule)Application.Utilities.newInstance(MyCustomerClosedCaseModule.class);
	}

    // Setup which triggers this module should respond to
	public MyCustomerClosedCaseModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

    /**
     * Filter to Closed Cases and eligible Queues
     */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        Map<Id, Case> closedCases = new Map<Id, Case>();
        Map<Id, Group> queues = new Map<Id, Group>();

        initClosedStatusApiNames();

        for(Case c: (List<Case>)records) {
            if(c.Status != ((Case)existingRecords.get(c.Id)).Status 
                && closedStatusAPINames.contains(c.Status)
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

            if(closedCases.isEmpty() == false) {
                reassignToPreviousAgentIfApplicable(closedCases);
            }
        }
    }

    /**
     * Attempt to assign the Case to the previous Agent, otherwise assign to a default Queue
     */
    private void reassignToPreviousAgentIfApplicable(Map<Id, Case> closedCases) {
        System.debug('in Module reassign()');
        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
        Map<Id, Id> caseIdVsAgentId = new Map<Id, Id>();
        for(AgentWork aw: AgentWorkSelector.newInstance().selectByAcceptedWorkItemIds(closedCases.keySet(),new Set<Object>())){
            System.debug('Agentwork: '+aw);
            // grabs the first user id from agent work since it is sorted by DESC 
            if(caseIdVsAgentId.containsKey(aw.WorkItemId) == false) {
                caseIdVsAgentId.put(aw.WorkItemId, aw.UserId);
            }
        }

        for(Case c: closedCases.values()) {
            if(caseIdVsAgentId.containsKey(c.Id) == true) {
                c.OwnerId = caseIdVsAgentId.get(c.Id);
                System.debug('Assigned to User');
            } else {
                c.OwnerId = omnichannelClosedCaseQueueId;
                System.debug('Assigned to Queue');
            }
        }
    }
    /*
    [SELECT 
                                WorkItemId,
                                UserId 
                            FROM AgentWork 
                            WHERE WorkItemId in :closedCases.keySet() 
                                AND AcceptDateTime != NULL 
                            ORDER BY WorkItemId, AcceptDateTime DESC])
                            */



    /**
     * populate a Set of Status values
     */
    private static void initClosedStatusApiNames(){
        if(closedStatusAPINames == null || closedStatusAPINames.size() == 0){
            closedStatusAPINames = new Set<String>();
            List<CaseStatus> closedStatusList = [Select Id,ApiName From CaseStatus Where IsClosed = true];
            for(CaseStatus cstatus : closedStatusList){
                closedStatusAPINames.add(cstatus.ApiName);
            }
        }
    }
}
