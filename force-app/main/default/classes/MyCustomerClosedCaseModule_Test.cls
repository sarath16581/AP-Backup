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
        QueueRoutingConfig qrc = [select Id from QueueRoutingConfig where DeveloperName like '%SSSW%' LIMIT 1];
		List<Group> queues = ApplicationTestDataFactory.getGroups(1,'Queue',true);        
		queues[0].Name = 'Omni Queue';
        queues[0].QueueRoutingConfigId = qrc.Id;
        Map<Id,Group> mapQueues = new Map<Id,Group>(queues);
        
        //Cases
        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
        cases[0].Status = 'Closed';
        cases[0].OwnerId = queues[0].Id;
        cases[1].Status = 'Closed';
        cases[1].OwnerId = queues[0].Id;

        //Agent User
        Profile agentprof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ssswAgent = TestUtility.createUser('SAgent',agentprof.id,null);
        Database.insert(new List<User>{ssswAgent});

        //Clone to simulate change from existing Case records
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true)
        };
        oldCases[0].Status = 'New'; 
        oldCases[1].Status = 'New'; 

        AgentWork aw = new AgentWork(WorkItemId = cases[0].Id, UserId = ssswAgent.Id);
        Insert aw; 

        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);     
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
        
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>(mapQueues));
		
        MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

        MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();        

        module.onBeforeUpdate((List<SObject>) cases, new Map<Id, SObject>(oldCases), mockUow);
		
        Test.stopTest();

        system.assertEquals(ssswAgent.Id, cases[0].OwnerId, 'Expected the Case Owner to be the previous User based on AgentWork' );
        system.assertEquals(omnichannelClosedCaseQueueId, cases[0].OwnerId, 'Expected the Case Owner to be the previous User based on AgentWork' );        
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
        QueueRoutingConfig qrc = [select Id from QueueRoutingConfig where DeveloperName like '%SSSW%' LIMIT 1];
		List<Group> queues = ApplicationTestDataFactory.getGroups(1,'Queue',true);        
		queues[0].Name = 'Omni Queue';
        queues[0].QueueRoutingConfigId = qrc.Id;
        Map<Id,Group> mapQueues = new Map<Id,Group>(queues);
        
        //Cases
        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
        cases[0].Status = 'Closed';
        cases[0].OwnerId = queues[0].Id;
        cases[1].Status = 'Closed';
        cases[1].OwnerId = queues[0].Id;

        //Agent User
        Profile agentprof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ssswAgent = TestUtility.createUser('SAgent',agentprof.id,null);
        Database.insert(new List<User>{ssswAgent});

        //Clone to simulate change from existing Case records
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true)
        };
        oldCases[0].Status = 'New'; 
        oldCases[1].Status = 'New'; 

        AgentWork aw = new AgentWork(WorkItemId = cases[0].Id, UserId = ssswAgent.Id);
        Insert aw; 

        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;
    
    }
	
}