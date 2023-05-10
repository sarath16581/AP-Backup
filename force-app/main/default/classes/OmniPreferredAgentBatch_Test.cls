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
	
	/**
	 * @description 
	 * Test the execute() method of the batch.
	 * The test validates that based on the PSRs passed to execute() method, the corresponding Cases will get updated by rerouteCasesWithPreferredAgentByPass method.
	 * 
	 * Test the full run of the batch, ensure that the batch job completes normally.
	 */
	@IsTest
	static void testBatchRunAndExecute() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		List<PendingServiceRouting> psrs = OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true);

		// =====================================
		// Stubbing
		// =====================================
		OmniChannelService mockService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.rerouteCasesWithPreferredAgentByPass((List<PendingServiceRouting>)fflib_Match.eq(psrs))).thenReturn(cases.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		OmniPreferredAgentBatch batch = new OmniPreferredAgentBatch(10);
		String expectedQuery = 'SELECT WorkItemId FROM PendingServiceRouting WHERE IsPushed = FALSE AND WorkItem.PreferredAgentExpiry__c < :now AND Workitem.OwnerId = :preferredAgentRoutingQueueId';
		System.assertEquals(expectedQuery, batch.query, 'Ensuring if there are changes in the query it is being captured');

		Test.startTest();
		
		batch.execute(null, psrs); 

		((OmniChannelService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).rerouteCasesWithPreferredAgentByPass((List<PendingServiceRouting>)fflib_Match.eq(psrs));
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>)fflib_Match.eq(cases.values()), (Boolean)fflib_Match.eq(false));

		Database.executeBatch(batch);

		Test.stopTest();

		List<AsyncApexJob> apexJobs = [SELECT Status FROM AsyncApexJob];
		System.assertEquals(1, apexJobs.size(), 'Batch failed to run');
		System.assertEquals('Completed', apexJobs[0].Status, 'Batch did not Complete');
	}
}