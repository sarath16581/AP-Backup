/**
 * @description       : Test class for STCaseInvestigationDomain
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 **/
@IsTest
private class STCaseInvestigationDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		List<CaseInvestigation__c> caseInvestigations = new List<CaseInvestigation__c>();

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		STCaseInvestigationDomain.Constructor constructor = new STCaseInvestigationDomain.Constructor();
		
		ApplicationDomain appDomain = constructor.construct(caseInvestigations);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(STCaseInvestigationArticleModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

	@IsTest
	static void checkDomainFilter() {
		Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike(CaseInvestigation__c.class.getName(), 'StarTrack').keySet();
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(validRecordTypes.size() + 1, null, null, null, true);
		for(Id validRTId: validRecordTypes) {
			caseInvestigations
		}
	}
}
