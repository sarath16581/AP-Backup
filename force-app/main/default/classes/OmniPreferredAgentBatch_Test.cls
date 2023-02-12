/**
* @author George Nguyen
* @group Batch
* @tag Batch
* @tag Omni SObject
* @description test class for OmniPreferredAgentBatch
* @changelog
* 2023-02-10 - George Nguyen - Created
*/
@IsTest
public with sharing class OmniPreferredAgentBatch_Test {
	
	@IsTest
	static void execute() {

		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		List<PendingServiceRouting> psrs = OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true);

		OmniChannelService mockService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.rerouteCasesWithPreferredAgentByPass((List<PendingServiceRouting>)fflib_Match.eq(psrs))).thenReturn(cases.values());
		MockUtility.Mocks.stopStubbing();

		Integer lastNDays = 2;
		OmniPreferredAgentBatch batch = new OmniPreferredAgentBatch();
		String expectedQuery = 'SELECT WorkItemId FROM PendingServiceRouting WHERE IsPushed = FALSE AND WorkItem.PreferredAgentExpiry__c < :now AND Workitem.OwnerId = :preferredAgentRoutingQueueId';
		System.assertEquals(expectedQuery, batch.query, 'Ensuring if there are changes in the query it is being captured');

		Test.startTest();
		
		batch.execute(null, psrs); 

		((OmniChannelService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).rerouteCasesWithPreferredAgentByPass((List<PendingServiceRouting>)fflib_Match.eq(psrs));
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>)fflib_Match.eq(cases.values()));
	  
		Database.executeBatch(batch);
		batch.execute(null); 
		Test.stopTest();
	}
}