/*** 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Utility
 * @domain Routing 
 * @description Test class for the MyCustomerClosedCaseModule_Test class
 * @changelog
 * 2022-10-17 - Noel Lim - Created
 */
@IsTest
private class MyCustomerClosedCaseModule_Test {

    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    
	/**
	 * Covers the following positive test scenarios:
	 * a) Closed Case in a Queue with Routing config and related Agent Work
     * b) Closed Case in a Queue with Routing config, no Agent Work related
     * 
     * Covers the following test scenarios (negative testing):
	 * a) Closed Case in a Queue without Routing config
     * b) Case not in a Closed Status
     * c) Case with no change in Status
     * 
	 */
	@IsTest
	private static void testClosedCaseReassigned() {

		// =====================================
		// Data Preparation
		// =====================================		
        
		//Group (Queue)
        QueueRoutingConfig qrc = [SELECT Id FROM QueueRoutingConfig WHERE DeveloperName LIKE '%SSSW%' LIMIT 1];
		List<Group> queues = ApplicationTestDataFactory.getGroups(2,'Queue',true);        
        queues[0].QueueRoutingConfigId = qrc.Id;
        
        List<Case> cases = ApplicationTestDataFactory.getCases(5, true);

        //Cases for positive scenario
        cases[0].Status = 'Closed';
        cases[0].OwnerId = queues[0].Id;
        cases[1].Status = 'Closed';
        cases[1].OwnerId = queues[0].Id;

        List<Case> positiveCases = new List<Case>{cases[0],cases[1]};


        //Cases for negative scenario
        cases[2].Status = 'Closed';
        cases[2].OwnerId = queues[1].Id;
        cases[3].Status = 'New';
        cases[3].OwnerId = queues[0].Id;
        cases[4].Status = 'Closed';
        cases[4].OwnerId = queues[0].Id;


        //Agent User
        User ssswAgent = ApplicationTestDataFactory.getUsers(1, true)[0];

        //Clone to simulate change from existing Case records
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true),
            cases[2].clone(true),
            cases[3].clone(true),
            cases[4].clone(true)
        };
        oldCases[0].Status = 'New'; 
        oldCases[1].Status = 'New'; 
        oldCases[2].Status = 'New'; 
        oldCases[3].Status = 'Open'; 
        oldCases[4].Status = 'Closed';   
        
        //AgentWork
        List<AgentWork> aws = new List<AgentWork>{new AgentWork(WorkItemId = cases[0].Id, UserId = ssswAgent.Id)};  


        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);     
        AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);    
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
        
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.eq((new Map<Id,Group>(queues)).keySet().clone()))).thenReturn(new Map<Id, Group>(queues));
        MockUtility.Mocks.when(mockAgentWorkSelector.selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.eq((new Map<Id,Case>(positiveCases)).keySet().clone()), (Set<Object>)fflib_Match.anyObject())).thenReturn(aws);

        MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing

		// =====================================
		Test.startTest();

        MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();        

        module.onBeforeUpdate((List<SObject>) cases, new Map<Id, SObject>(oldCases), mockUow);
		
        Test.stopTest();

        ((AgentWorkSelector)MockUtility.Mocks.verify(mockAgentWorkSelector, 1)).selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

        //Positive test scenarios
        system.assertEquals(ssswAgent.Id, cases[0].OwnerId, 'Expected the Case Owner to be the previous User based on AgentWork' );
        system.assertEquals(omnichannelClosedCaseQueueId, cases[1].OwnerId, 'Expected the Case Owner to be the default Closed Case Queue' );     
        
        //Negative test scenarios
        system.assertEquals(cases[2].OwnerId, cases[2].OwnerId, 'Expected no change to OwnerId for negative scenario' );    
        system.assertEquals(cases[3].OwnerId, cases[3].OwnerId, 'Expected no change to OwnerId for negative scenario' );  
        system.assertEquals(cases[4].OwnerId, cases[4].OwnerId, 'Expected no change to OwnerId for negative scenario' );    
	}
	
}