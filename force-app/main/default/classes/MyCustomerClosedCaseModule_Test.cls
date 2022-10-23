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
	private static void ensureClosedCasedInOmniQueueAreReassignedOnUpdate() {

        Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;

		QueueRoutingConfig qrc = new QueueRoutingConfig();
        ApplicationTestDataFactory.generateRecordIds(new List<SObject>{qrc});
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(2, 'Queue', true));    
        Group omniQueue = queues.values()[0];
        omniQueue.QueueRoutingConfigId = qrc.Id;
        Group nonOmniQueue = queues.values()[1];
        
        List<Case> cases = ApplicationTestDataFactory.getCases(5, true);
        
        // invalid cases
        cases[0].OwnerId = UserInfo.getUserId();
        cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object> { 'IsClosed' => true});

        cases[1].OwnerId = nonOmniQueue.Id;
        cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object> { 'IsClosed' => true});

        cases[2].OwnerId = omniQueue.Id;
        cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object> { 'IsClosed' => false});

        // valid cases
        Map<Id, Case> validCases = new Map<Id, Case>();
        cases[3].OwnerId = omniQueue.Id;
        cases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object> { 'IsClosed' => true});
        validCases.put(cases[3].id, cases[3]);

        cases[4].OwnerId = omniQueue.Id;
        cases[4] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object> { 'IsClosed' => true});
        validCases.put(cases[4].id, cases[4]);

        List<AgentWork> agentWorks = ApplicationTestDataFactory.getAgentWorks(1, UserInfo.getUserId(), new Set<Id>{cases[4].Id}, true);
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);     
        AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
        CasesSelector mockCaseSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);    
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
        
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.eq(queues.keySet()))).thenReturn(queues);
        MockUtility.Mocks.when(mockAgentWorkSelector.selectByAcceptedWorkItemIds((Set<Id>)fflib_Match.eq(validCases.keySet()), (Set<Object>)fflib_Match.anyObject())).thenReturn(agentWorks);
        MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.eq(validCases.keySet()))).thenReturn(validCases); 

        MockUtility.Mocks.stopStubbing();

        MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();        
        module.onAfterUpdate(cases, null, mockUow);
		
        System.assertEquals(omnichannelClosedCaseQueueId, cases[3].OwnerId, 'should be updated to omni closed case queue');
        System.assertEquals(UserInfo.getUserId(), cases[4].OwnerId, 'should be updated to the agent id on the Agent Work');

        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
            (List<SObject>)fflib_Match.eq(new List<Case>{
                new Case(Id = cases[3].Id, OwnerId = omnichannelClosedCaseQueueId), 
                new Case(Id = cases[4].Id, OwnerId = UserInfo.getUserId())
            }), 
            (List<SObjectField>)fflib_Match.eq(new List<SObjectField> {Case.OwnerId}),
            (String)fflib_Match.anyObject()
        );
	}
	
}