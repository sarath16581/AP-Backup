/***
 * @description Test class for CaseAutomationTriggerHandler
 * @author Nathan Franklin
 * @date 2023-06-19
 * @changelog
 */
@IsTest
private class CaseAutomationTriggerHandler_Test {
	
	/**
	 * This class does not do much so we just need a single test for coverage
	 */
	@IsTest
	private static void testForCoverage() {

		CaseAutomationTriggerHandler handler = new CaseAutomationTriggerHandler();

		ApplicationUnitOfWork uow = handler.newUnitOfWork();

		handler.registerModules();

		Id ssswRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'SSSW'}).keySet())[0];
		Id ssswSocialRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'Social'}).keySet())[0];
		Id starTrackRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'StarTrack'}).keySet())[0];

		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].RecordTypeId = ssswRecordType;
		cases[1].RecordTypeId = ssswSocialRecordType;
		cases[2].RecordTypeId = starTrackRecordType;

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(cases);

		System.assertEquals(4, filteredGroupRecords.size());

		System.assertEquals(1, filteredGroupRecords.get('filterSSSW').size());
		System.assertEquals(cases[0].Id, filteredGroupRecords.get('filterSSSW')[0].Id);

		System.assertEquals(2, filteredGroupRecords.get('filterSSSWWithSocial').size());
		System.assertEquals(cases[0].Id, filteredGroupRecords.get('filterSSSWWithSocial')[0].Id);
		System.assertEquals(cases[1].Id, filteredGroupRecords.get('filterSSSWWithSocial')[1].Id);

		System.assertEquals(1, filteredGroupRecords.get('filterStarTrack').size());
		System.assertEquals(cases[2].Id, filteredGroupRecords.get('filterStarTrack')[0].Id);

		System.assertEquals(Case.SObjectType, handler.getSObjectType());

	}

}