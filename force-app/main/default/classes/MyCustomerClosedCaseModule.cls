public with sharing class MyCustomerClosedCaseModule extends ApplicationDomain.Module {

	public static MyCustomerClosedCaseModule newInstance() {
		return (MyCustomerClosedCaseModule)Application.Utilities.newInstance(MyCustomerClosedCaseModule.class);
	}

    // Setup which triggers this module should respond to
	public MyCustomerClosedCaseModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        Map<Id, Case> closedCases = new Map<Id, Case>();
        Map<Id, Group> queues = new Map<Id, Group>();
        for(Case c: (List<Case>)records) {
            if(c.Status != ((Case)existingRecords.get(c.Id)).Status 
                && c.Status == 'Closed' // TDOD this needs to be a list of Statuses where Closed = True    
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

    private void reassignToPreviousAgentIfApplicable(Map<Id, Case> closedCases) {
        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
        Map<Id, Id> caseIdVsAgentId = new Map<Id, Id>();
        for(AgentWork aw: [SELECT 
                                WorkItemId,
                                UserId 
                            FROM AgentWork 
                            WHERE WorkItemId in :closedCases.keySet() 
                                AND AcceptDateTime != NULL 
                            ORDER BY WorkItemId, AcceptDateTime DESC]) {

            // grabs the first user id from agent work since it is sorted by DESC 
            if(caseIdVsAgentId.containsKey(aw.WorkItemId) == false) {
                caseIdVsAgentId.put(aw.WorkItemId, aw.UserId);
            }
        }

        for(Case c: closedCases.values()) {
            if(caseIdVsAgentId.containsKey(c.Id) == true) {
                c.OwnerId = caseIdVsAgentId.get(c.Id);
            } else {
                c.OwnerId = omnichannelClosedCaseQueueId;
            }
        }
    }
}
