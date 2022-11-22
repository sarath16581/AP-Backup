/**
 * @author George Nguyen
 * @group Tests
 * @tag MyCustomerCaseRoutingModule
 * @domain MyCustomer
 * @description Test class for MyCustomerCaseRoutingModule
 * @changelog
 * 2022-11-03 George Nguyen - Created
 */
@IsTest
public with sharing class MyCustomerCaseRoutingModule_Test {
   
	@IsTest
	static void onBeforeInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = ''; // invalid case

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		MyCustomerCaseRoutingModule.newInstance().onBeforeInsert(cases, uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1] }), 
																								(Boolean)fflib_Match.eq(true)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	@IsTest
	static void onBeforeUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = 'High';

		List<Case> oldCases = cases.deepClone(true, false, false);
		oldCases[0].OwnerId = omniQueue.Id; // invalid case
		oldCases[0].Priority = 'High';

		oldCases[1].OwnerId = UserInfo.getUserId();
		oldCases[1].Priority = 'Low';

		oldCases[2].OwnerId = omniQueue.Id; 
		oldCases[2].Priority = ''; 

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		MyCustomerCaseRoutingModule.newInstance().onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1], cases[2] }), 
																								(Boolean)fflib_Match.eq(false)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}
	
}