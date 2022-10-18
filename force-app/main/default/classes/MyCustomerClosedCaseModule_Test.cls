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
     * b) Closed Case in a Queue with Routing config, no related Agent Work
	 */
	@IsTest
	private static void testClosedCaseReassigned() {
		// =====================================
		// Data Preparation
		// =====================================		
        
		//Group (Queue)
        QueueRoutingConfig qrc = [SELECT Id FROM QueueRoutingConfig WHERE DeveloperName LIKE '%SSSW%' LIMIT 1];
		List<Group> queues = ApplicationTestDataFactory.getGroups(1,'Queue',true);        
        queues[0].QueueRoutingConfigId = qrc.Id;
        Map<Id,Group> mapQueues = new  Map<Id,Group>(queues);
        
        //Cases
        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
        cases[0].Status = 'Closed';
        cases[0].OwnerId = queues[0].Id;
        cases[1].Status = 'Closed';
        cases[1].OwnerId = queues[0].Id;

        //Agent User
        User ssswAgent = ApplicationTestDataFactory.getUsers(1, true)[0];

        //Clone to simulate change from existing Case records
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true)
        };
        oldCases[0].Status = 'New'; 
        oldCases[1].Status = 'New'; 
        
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
		
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>(mapQueues));
		MockUtility.Mocks.when(mockAgentWorkSelector.selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(aws);

        MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

        MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();        

        module.onBeforeUpdate((List<SObject>) cases, new Map<Id, SObject>(oldCases), mockUow);
		
        Test.stopTest();

        ((AgentWorkSelector)MockUtility.Mocks.verify(mockAgentWorkSelector, 1)).selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

        system.assertEquals(ssswAgent.Id, cases[0].OwnerId, 'Expected the Case Owner to be the previous User based on AgentWork' );
        system.assertEquals(omnichannelClosedCaseQueueId, cases[1].OwnerId, 'Expected the Case Owner to be the default Closed Case Queue' );        
	}
	
    /**
	 * Covers the following test scenarios (negative testing):
	 * a) Closed Case in a Queue without Routing config
     * b) Case not in a Closed Status
     * c) Case with no change in Status
	 * 
	 */
    @IsTest
	private static void testCasesNoReassign() {
		// =====================================
		// Data Preparation
		// =====================================		
        
		//Group (Queue)
        QueueRoutingConfig qrc = [SELECT Id FROM QueueRoutingConfig WHERE DeveloperName LIKE '%SSSW%' LIMIT 1];
		List<Group> queues = ApplicationTestDataFactory.getGroups(2,'Queue',true);        
        queues[0].QueueRoutingConfigId = qrc.Id;
        Map<Id,Group> mapQueues = new  Map<Id,Group>(queues);
        
        //Cases
        List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
        cases[0].Status = 'Closed';
        cases[0].OwnerId = queues[1].Id;
        cases[1].Status = 'New';
        cases[1].OwnerId = queues[0].Id;
        cases[2].Status = 'Closed';
        cases[2].OwnerId = queues[0].Id;

        //Agent User
        User ssswAgent = ApplicationTestDataFactory.getUsers(1, true)[0];

        //Clone to simulate change from existing Case records
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true),
            cases[2].clone(true)
        };
        oldCases[0].Status = 'New'; 
        oldCases[1].Status = 'Open'; 
        oldCases[2].Status = 'Closed';       

         //AgentWork
         ServiceChannel sc = [SELECT Id FROM ServiceChannel WHERE DeveloperName LIKE '%Case%' LIMIT 1];
         PendingServiceRouting psr = new PendingServiceRouting();
         List<AgentWork> aws = new List<AgentWork>{new AgentWork(WorkItemId = cases[0].Id, UserId = ssswAgent.Id, ServiceChannelId = sc.Id, PendingServiceRoutingId = psr.Id)};      

        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);     
        AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);    
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
        
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>(mapQueues));
		MockUtility.Mocks.when(mockAgentWorkSelector.selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(aws);

        MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

        MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();        

        module.onBeforeUpdate((List<SObject>) cases, new Map<Id, SObject>(oldCases), mockUow);
		
        Test.stopTest();

        //All cases will not pass the entry criteria, and therefore AgentWorkSelector will not be called 
        ((AgentWorkSelector)MockUtility.Mocks.verify(mockAgentWorkSelector, 0)).selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

        //PMD by-pass
        System.Assert(true);
    }
	
}