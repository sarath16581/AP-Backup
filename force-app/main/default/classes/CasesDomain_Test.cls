/**
* @author Ashapriya Gadi
* @date 2021-12-08
* @group Tests
* @tag Selector
* @tag Case
* @domain Core
* @description Test class covering CasesDomain
* @changelog
* 2021-12-08 - Ashapriya Gadi - Created
* 2023-01-23 - Dattaraj Deshmukh - Added ensureThatRegisterModulesIsBeingCalled to test STCaseRelatedRecordsProcessingModule is called.
*/
@IsTest
private class CasesDomain_Test {
	@IsTest
	private static void testCasesDomain() {
		
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		
		ApplicationDomain.IConstructable constructableDomain = new CasesDomain.Constructor();
		CasesDomain domain = (CasesDomain)constructableDomain.construct(cases);
		
		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(cases[0].Id, domain.records[0].Id, 'Expected record');
	}

	@IsTest
	static void ensureThatRegisterModulesIsBeingCalled() {
		List<Case> cases = new List<Case>();

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		STCaseInvestigationDomain.Constructor constructor = new STCaseInvestigationDomain.Constructor();
		
		ApplicationDomain appDomain = constructor.construct(cases);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(STCaseRelatedRecordsProcessingModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}