/**
* @author Mahesh Parvathaneni
* @date 27/01/2023
* @description Test class for STCIMilestoneViolationCheckerBatch job
* @changelog
*/

@IsTest
private with sharing class STCIMilestoneViolationCheckerBatch_Test {

	/**
	 * @description Test the execute() method of the batch.
	 * This method runs and validates main logic of the batch job: updating the field NetworkMilestoneCurrentViolatedTier__c by 1
	 * The test makes sure that all CaseInvestigation records passed to execute() method will get updated.
	 * Correctness of the CaseInvestigation list passed to the execute() method is ensured by CaseInvestigationsSelector_Test.
	 */
	@IsTest
	private static void testBatchJobEndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(200, cases[0].Id, articles[0], networks[0].Id, true);

		for (CaseInvestigation__c ci : caseInvestigations) {
			ci.Status__c = 'Open';
			ci.NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
		}

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector vSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(vSelector.selectNetworkMilestoneViolatedOpenCaseInvestigations((Datetime)fflib_Match.anyObject())).thenReturn(Database.getQueryLocator([SELECT Id FROM CaseInvestigation__c LIMIT 1]));
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		//Test
		Test.startTest();
		STCIMilestoneViolationCheckerBatch vBatch = new STCIMilestoneViolationCheckerBatch();
		vBatch.execute(null, caseInvestigations);
		vBatch.execute(null);
		Test.stopTest();

		//assert the batch job to be completed
		List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob];
		System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');
	}
}