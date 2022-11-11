/**
* @author George Nguyen
* @date 2022-11-06
* @group Batch
* @tag Batch
* @tag Omni SObject
* @description test class for OmniPsrSecondaryPriorityBatch
* @changelog
* 2022-11-06 - George Nguyen - Created
*/
@IsTest
public with sharing class OmniPsrSecondaryPriorityBatch_Test {
	
	@IsTest
	static void execute() {

		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		List<PendingServiceRouting> psrs = OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true);

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Integer lastNDays = 2;
		OmniPsrSecondaryPriorityBatch batch = new OmniPsrSecondaryPriorityBatch(lastNDays);
		String expectedQuery = 'SELECT WorkItem.Priority, WorkItem.CreatedDate FROM PendingServiceRouting WHERE IsPushed = FALSE AND LastModifiedDate < LAST_N_DAYS:' + lastNDays;
		System.assertEquals(expectedQuery, batch.query, 'Ensuring if there are changes in the query it is being captured');

		Test.startTest();
		
		batch.execute(null, psrs); 

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority((List<PendingServiceRouting>)fflib_Match.eq(psrs));
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<PendingServiceRouting>)fflib_Match.eq(psrs));
	  
		Database.executeBatch(batch);
		batch.execute(null); 
		Test.stopTest();
	}
}
