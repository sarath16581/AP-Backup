/**
 * @description       : Test class for STCaseInvestigationDomain
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-01-23 - Dattaraj Deshmukh - Added unit test for STCaseInvestigationLifecycleModule.
 **/
@IsTest
private class STCaseInvestigationDomain_Test {

	/**
	 * @test: Ensure modules are registered with domain class.
	 */
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		List<CaseInvestigation__c> caseInvestigations = new List<CaseInvestigation__c>();

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();
		
		ApplicationDomain appDomain = STCaseInvestigationDomain.newInstance(caseInvestigations);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(STCaseInvestigationArticleModule.class);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(STCaseInvestigationLifecycleModule.class);
		

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

	/**
	 * @test: Ensure records are filtered when passed to modules. 
	 * Expected to receive on Case Investigations having ONLY StarTrack record types. 
	 */
	@IsTest
	static void domainFilter() {
		List<Id> validRecordTypes = new List<Id>(new RecordTypesSelector().selectByDeveloperNameLike(CaseInvestigation__c.class.getName(), 'StarTrack').keySet());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(validRecordTypes.size() + 1, cases[0].Id, null, null, true);
		for(Integer i = 0; i < validRecordTypes.size(); i++) {
			caseInvestigations[0].recordTypeId = validRecordTypes[0];
		}
		List<RecordType> invalidRTs = new List<RecordType>{new RecordType()};
		ApplicationTestDataFactory.generateRecordIds(invalidRTs);
		caseInvestigations[validRecordTypes.size()].recordTypeId = invalidRTs[0].Id;

		List<CaseInvestigation__c> filteredList = (List<CaseInvestigation__c>)STCaseInvestigationDomain.newInstance(caseInvestigations).filter(caseInvestigations);
		System.assertEquals(validRecordTypes.size(), filteredList.size(), 'should be the same size as the RT list');
		System.assert(filteredList.contains(caseInvestigations[validRecordTypes.size()]) == false, 'should filter out this record');
	}
}