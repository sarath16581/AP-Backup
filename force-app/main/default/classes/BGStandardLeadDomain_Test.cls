/**
* @description Test class for BGStandardLeadDomain
* @author PRatyush Chalasani
* @date 2023-03-27
* @group Domains
* @changelog
*/
@IsTest
private class BGStandardLeadDomain_Test {

	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);
		List<Lead> leads = ApplicationTestDataFactory.getLeads(2, true);
		leads[0].RecordTypeId = ApplicationTestDataFactory.leadBGStandardRecordType;
		ApplicationDomain appDomain = BGStandardLeadDomain.newInstance(leads);

		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(BGStandardLeadModule.class);

		BGStandardLeadDomain domain = BGStandardLeadDomain.newInstance(leads);
		List<SObject> filteredResult = domain.filter(leads);
		System.assertEquals(1, filteredResult.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(leads[0].Id, filteredResult[0].Id, 'Expected BG Standard record');

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

}