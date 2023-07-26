/***
 * @description Test class for LeadAutomationTriggerHandler
 * @author Ranjeewa Silva
 * @date 2023-07-05
 * @changelog
 * 2023-07-05 - Ranjeewa Silva - Created
 */

@IsTest
private class LeadAutomationTriggerHandler_Test {

	/**
	 * This class does not do much so we just need a single test for coverage
	 */
	@IsTest
	private static void testForCoverage() {
		LeadAutomationTriggerHandler handler = new LeadAutomationTriggerHandler();
		handler.registerModules();
		System.assert(handler.newUnitOfWork() != null, 'Expected a valid unit of work instance, but got null');
		System.assertEquals(Lead.SObjectType, handler.getSObjectType());

		Id bgStandardRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperName('Lead', new Set<String>{'BG_Standard'}).keySet())[0];
		Id conveyancerOnboardingRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperName('Lead', new Set<String>{'Conveyancer_Onboarding'}).keySet())[0];
		Id standardRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperName('Lead', new Set<String>{'Standard'}).keySet())[0];

		List<Lead> leads = ApplicationTestDataFactory.getLeads(3, true);
		leads[0].RecordTypeId = bgStandardRecordType;
		leads[1].RecordTypeId = conveyancerOnboardingRecordType;
		leads[2].RecordTypeId = standardRecordType;

		Map<String, List<SObject>> filteredRecords = handler.primeRecordFilters(leads);

		System.assertEquals(1, filteredRecords.size());

		System.assertEquals(1, filteredRecords.get('filterBGStandard').size());
		System.assertEquals(leads[0].Id, filteredRecords.get('filterBGStandard')[0].Id);
	}
}