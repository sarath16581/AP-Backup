/***
 * @description Test class for BillingAccountCreationEventHandler
 * @author Ranjeewa Silva
 * @date 2023-11-27
 * @changelog
 * 2023-11-07 - Ranjeewa Silva - created
 */
@IsTest
private class BillingAccountCreationEventHandler_Test {

	/**
	 * This class does not do much so we just need a single test for coverage
	 */
	@IsTest
	private static void testForCoverage() {

		BillingAccountCreationEventHandler handler = new BillingAccountCreationEventHandler();

		handler.registerModules();

		System.assert(BillingAccountCreationEvent__e.SObjectType == handler.getSObjectType());
		System.assert(handler.newUnitOfWork() != null, 'Expected a valid unit of work instance, but got null');

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();
		events.add(new BillingAccountCreationEvent__e(Source_System__c='SAP', Additional_Info__c=APT_Constants.RATING_PLAN_ACTIVATION_LABEL));
		events.add(new BillingAccountCreationEvent__e(Source_System__c='SAP'));
		events.add(new BillingAccountCreationEvent__e(Source_System__c='TEAM'));

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(events);
		Assert.areEqual(3, filteredGroupRecords.size(), 'Expected the event records to be filtered into 3 groups, SAP rating plans, SAP billing accounts and TEAM billing accounts');

		Assert.areEqual(1, filteredGroupRecords.get('filterNewAusPostRatingPlans').size());
		Assert.areEqual(events[0].Id, filteredGroupRecords.get('filterNewAusPostRatingPlans')[0].Id);

		Assert.areEqual(1, filteredGroupRecords.get('filterNewAusPostBillingAccounts').size());
		Assert.areEqual(events[1].Id, filteredGroupRecords.get('filterNewAusPostBillingAccounts')[0].Id);

		Assert.areEqual(1, filteredGroupRecords.get('filterNewStarTrackBillingAccounts').size());
		Assert.areEqual(events[2].Id, filteredGroupRecords.get('filterNewStarTrackBillingAccounts')[0].Id);
	}
}