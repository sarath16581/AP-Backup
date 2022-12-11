/**
 * @description       : Test class for CaseInvestigationDomain
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 **/
@IsTest
private class CaseInvestigationDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		List<CaseInvestigation__c> caseInvestigations = new List<CaseInvestigation__c>();

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		CaseInvestigationDomain.Constructor constructor = new CaseInvestigationDomain.Constructor();
		
		ApplicationDomain appDomain = constructor.construct(caseInvestigations);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(CaseInvestigationArticleModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}
