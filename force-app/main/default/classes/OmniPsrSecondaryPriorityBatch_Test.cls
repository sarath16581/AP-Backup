/**
* @author George Nguyen
* @date 2022-11-06
* @group Batch
* @tag Batch
* @tag Omni SObject
* @description test class for OmniPsrSecondaryPriorityBatch
* @changelog
* 2022-11-06 - George Nguyen - Created
* 2023-02-08 - Noel Lim - Updated to use PendingServiceRoutingSelector
*/
@IsTest
public with sharing class OmniPsrSecondaryPriorityBatch_Test {
	
	@IsTest
	static void execute() {

		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		List<PendingServiceRouting> psrs = OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true);

		// =====================================
		// Stubbing
		// =====================================
		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		PendingServiceRoutingSelector psr = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(psr.selectByLastModifiedDateLessThanEqualNDaysAgo(
			fflib_Match.eqInteger(1),
			(Set<Object>)fflib_Match.eq(new Set<Object>{PendingServiceRoutingSelector.Options.EXCLUDE_ISPUSHED,PendingServiceRoutingSelector.Options.WITH_WORKITEM})
		)).thenReturn(Database.getQueryLocator([SELECT Id FROM PendingServiceRouting]));

		MockUtility.Mocks.stopStubbing();

		Integer nDaysAgo = 1;
		OmniPsrSecondaryPriorityBatch batch = new OmniPsrSecondaryPriorityBatch(nDaysAgo);

		Test.startTest();
		
		batch.execute(null, psrs); 

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority((List<PendingServiceRouting>)fflib_Match.eq(psrs));
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<PendingServiceRouting>)fflib_Match.eq(psrs));
	  
		Database.executeBatch(batch);
		batch.execute(null); 
		Test.stopTest();
	}
}