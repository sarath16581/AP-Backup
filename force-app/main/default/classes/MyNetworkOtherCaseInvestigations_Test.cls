/**
 * @description Test class for MyNetworkOtherCaseInvestigationsCntr
 * @author Dattaraj Deshmukh
 * @date 2022-12-07
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-12-07 - Dattaraj Deshmukh - Created
*/
@IsTest
private class MyNetworkOtherCaseInvestigations_Test {
	
	/**
	 * Test: Get all open case investigations other than record Id being passed.
	 * Expected results: all open case investigations list, other than record Id being passed, is returned.
	 */
	@IsTest
	public static void testGetOtherCaseInvestigations() {

		// =====================================
		// Data Preparation
		// =====================================
		//create test data
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'Open';
		caseInvestigations[1].Status__c = 'Open';

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName()
		.get('StarTrack_MyNetwork').getRecordTypeId();

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById(new Set<Id>{caseInvestigations[0].Id})).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
		MockUtility.Mocks.when(mockSelector.selectOpenCaseInvestigationsByCaseIds(new Set<Id>{cases[0].Id}, new Set<Id>{stCaseInvestigationRecordTypeId}, new Set<Object>{CaseInvestigationsSelector.Options.WITH_CASE_DETAILS,
														CaseInvestigationsSelector.Options.WITH_ARTICLES,
														CaseInvestigationsSelector.Options.WITH_NETWORKS} ))
														.thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0],
																										 caseInvestigations[1].Id => caseInvestigations[1]});

		MockUtility.Mocks.stopStubbing();

		List<CaseInvestigation__c> otherCIs;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//calling method to get all case investigation records other than passed record Id.
		otherCIs = MyNetworkOtherCaseInvestigationsCntr.getOtherCaseInvestigations(caseInvestigations[0].Id);

		Test.stopTest();

		//verify that method is called once with expected list of jobs
		((CaseInvestigationsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{caseInvestigations[0].Id}));

		//assert other CIs are returned.
		system.assertEquals(caseInvestigations[1].Id, otherCIs[0].Id, 'Something is not right, map should contain CI other than passed case investigations');

	}
}
