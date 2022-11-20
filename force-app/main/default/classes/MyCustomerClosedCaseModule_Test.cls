/*** 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Utility
 * @domain Routing 
 * @description Test class for the MyCustomerClosedCaseModule_Test class
 * @changelog
 * 2022-10-17 - Noel Lim - Created
 * 2022-11-16 - Noel Lim - Updated to cover additional entry criteria logic and new WithoutSharingRetrieveData inner class 
 */
@IsTest
private class MyCustomerClosedCaseModule_Test {

	/**
	 * For calls to onAfterUpdate()
	 * 
	 * Covers the following positive test scenarios:
	 * a) Closed Case in a Queue with Routing config and related Agent Work
	 * b) Closed Case in a Queue with Routing config, no Agent Work related
	 * c) Closed Case status changed from Open => Close
	 * d) Closed Case Owner changed 
	 * 
	 * Covers the following test scenarios (negative testing):
	 * a) Closed Case in a Queue without Routing config
	 * b) Case not in a Closed Status
	 * c) Case with no change in Status
	 * 
	 */
	@IsTest
	static void ensureAfterUpdateCasesReassigned(){

		//Queues
		Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;

		QueueRoutingConfig qrc = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject>{qrc});
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(2, 'Queue', true));	
		Group omniQueue = queues.values()[0];
		omniQueue.QueueRoutingConfigId = qrc.Id;
		Group nonOmniQueue = queues.values()[1];
		
		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(6, true);
		
		//invalid 
		cases[0].OwnerId = nonOmniQueue.Id; //Closed Case in a Queue without Routing config
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object> { 'IsClosed' => true});

		cases[1].OwnerId = omniQueue.Id; //Case not in a Closed Status
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object> { 'IsClosed' => false});

		cases[2].OwnerId = omniQueue.Id; //Case with no change in both Status and OwnerId
		cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object> { 'IsClosed' => true});

		//valid 
		Map<Id, Case> validCases = new Map<Id, Case>();
		cases[3].OwnerId = omniQueue.Id;
		cases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[3], new Map<String, Object> { 'IsClosed' => true});
		validCases.put(cases[3].id, cases[3]); //will route to Closed queue

		cases[4].OwnerId = omniQueue.Id;
		cases[4] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[4], new Map<String, Object> { 'IsClosed' => true});
		validCases.put(cases[4].id, cases[4]); //will route to previous Agent

		cases[5].OwnerId = omniQueue.Id;
		cases[5] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[5], new Map<String, Object> { 'IsClosed' => true});
		validCases.put(cases[5].id, cases[5]); //will route due to change in Owner Id



		//Clone to simulate existing Case records to test Case Update 
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true),
            cases[2].clone(true),
            cases[3].clone(true),
            cases[4].clone(true),
            cases[5].clone(true)
        };
		oldCases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(oldCases[0], new Map<String, Object> { 'IsClosed' => false});
		oldCases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(oldCases[1], new Map<String, Object> { 'IsClosed' => false});
		oldCases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(oldCases[2], new Map<String, Object> { 'IsClosed' => true});
		oldCases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(oldCases[3], new Map<String, Object> { 'IsClosed' => false});
		oldCases[4] = (Case)ApplicationTestDataFactory.setUnwritableFields(oldCases[4], new Map<String, Object> { 'IsClosed' => false});
		oldCases[5] = (Case)ApplicationTestDataFactory.setUnwritableFields(oldCases[5], new Map<String, Object> { 'IsClosed' => true});
		oldCases[5].OwnerId = UserInfo.getUserId();

		//AgentWork
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(1, UserInfo.getUserId(), new Set<Id>{cases[4].Id}, true);
		
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

		// =====================================
        // Testing
        // =====================================

		Test.startTest();

		MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();		
		module.onAfterUpdate((List<SObject>)cases, new Map<Id, SObject>(oldCases), mockUow);

		Test.stopTest();
		
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<SObject>)fflib_Match.eq(new List<Case>{
				new Case(Id = cases[3].Id, OwnerId = omnichannelClosedCaseQueueId), 
				new Case(Id = cases[4].Id, OwnerId = UserInfo.getUserId()),
				new Case(Id = cases[5].Id, OwnerId = omnichannelClosedCaseQueueId)
			}), 
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField> {Case.OwnerId}),
			(String)fflib_Match.anyObject()
		);

		// PMD warning
		System.assert(true);

	}

	/**
	 * For calls to onAfterUpdate()
	 * 
	 * Covers the following positive test scenarios:
	 * a) Closed Case in a Queue with Routing config and related Agent Work
	 * b) Closed Case in a Queue with Routing config, no Agent Work related
	 * 
	 * Covers the following test scenarios (negative testing):
	 * a) Closed Case in a Queue without Routing config
	 * b) Case not in a Closed Status
	 * 
	 */
	@IsTest
	static void ensureAfterInsertCasesReassigned() {

		//Queues
		Id omnichannelClosedCaseQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'SSSW_Closed_Omnichannel_Cases' LIMIT 1].Id;

		QueueRoutingConfig qrc = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject>{qrc});
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(2, 'Queue', true));	
		Group omniQueue = queues.values()[0];
		omniQueue.QueueRoutingConfigId = qrc.Id;
		Group nonOmniQueue = queues.values()[1];
		
		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(4, true);
		
		//invalid 
		cases[0].OwnerId = nonOmniQueue.Id; //Closed Case in a Queue without Routing config
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object> { 'IsClosed' => true});

		cases[1].OwnerId = omniQueue.Id; //Case not in a Closed Status
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object> { 'IsClosed' => false});


		//valid 
		Map<Id, Case> validCases = new Map<Id, Case>();
		cases[2].OwnerId = omniQueue.Id;
		cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object> { 'IsClosed' => true});
		validCases.put(cases[2].id, cases[2]); //will route to Closed queue

		cases[3].OwnerId = omniQueue.Id;
		cases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[3], new Map<String, Object> { 'IsClosed' => true});
		validCases.put(cases[3].id, cases[3]); //will route to previous Agent 

		//AgentWork
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(1, UserInfo.getUserId(), new Set<Id>{cases[3].Id}, true);
		
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

		// =====================================
        // Testing
        // =====================================
		Test.startTest();

		MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();		
		module.onAfterInsert(cases, mockUow);

		Test.stopTest();
		
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<SObject>)fflib_Match.eq(new List<Case>{
				new Case(Id = cases[2].Id, OwnerId = omnichannelClosedCaseQueueId), 
				new Case(Id = cases[3].Id, OwnerId = UserInfo.getUserId())
			}), 
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField> {Case.OwnerId}),
			(String)fflib_Match.anyObject()
		);

		// PMD warning
		System.assert(true);


	}

	/**
	 * Covers the following test scenarios:
	 * a) The user triggering the Case to be assigned to the Closed Queue is a guest user. With Sharing access will cause an Exception "sObject type 'AgentWork' is not supported."
	 * 
	 */
	@IsTest
	static void ensureGuestUserNoErrors() {



		//Queues
		QueueRoutingConfig qrc = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject>{qrc});
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(1, 'Queue', true));	
		Group omniQueue = queues.values()[0];
		omniQueue.QueueRoutingConfigId = qrc.Id;

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

		Map<Id, Case> validCases = new Map<Id, Case>();
		cases[0].OwnerId = omniQueue.Id;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object> { 'IsClosed' => true});
		validCases.put(cases[0].id, cases[0]);

		//User (Community User)

		Profile profile = [Select Id from Profile where name='Consumer Help and Support Profile' LIMIT 1];
		User communityUser = ApplicationTestDataFactory.getUsers(1, profile.id, false)[0];
		insert communityUser;
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);	 
		CasesSelector mockCaseSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);	
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.eq(queues.keySet()))).thenReturn(queues);
		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.eq(validCases.keySet()))).thenReturn(validCases); 

		MockUtility.Mocks.stopStubbing();

		// =====================================
        // Testing
        // =====================================
		
		Test.startTest();
		
		System.runAs(communityUser){
			MyCustomerClosedCaseModule module = MyCustomerClosedCaseModule.newInstance();		
			module.onAfterUpdate(validCases.values(), null, mockUow);			
		}
		Test.stopTest();


		//An exception should not be created
        ((ApplicationLogger)MockUtility.Mocks.verify(mockLogger,0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
        
        // PMD warning
		System.assert(true);
	}
	
}