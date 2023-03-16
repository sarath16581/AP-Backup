/**
* @author Mahesh Parvathaneni
* @date 27/01/2023
* @description Test class for STCIMilestoneViolationCheckerBatch job
* @changelog
*/

@IsTest
private class STCIMilestoneViolationCheckerBatch_Test {

	/**
	 * @description Test the execute() method of the batch.
	 * This method runs and validates main logic of the batch job: updating the field NetworkMilestoneCurrentTier__c by 1
	 * The test makes sure that all CaseInvestigation records passed to execute() method will get updated.
	 * Correctness of the CaseInvestigation list passed to the execute() method is ensured by CaseInvestigationsSelector_Test.
	 */
	@IsTest
	private static void testBatchJobExecute() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = '1234';
		networks[0].Email_1__c = 'test.test@test.com';
		networks[0].Email_2__c = 'test.test@test.com';
		networks[1].Org_ID__c = '4567';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(150, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(50, cases[0].Id, articles[0], networks[1].Id, true));

		//assigning network to case investigations
		//so email is populated from network record
		for (Integer i = 0; i < 50 ; i++) {
			caseInvestigations[i].Status__c = 'New';
			caseInvestigations[i].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
			caseInvestigations[i].NetworkMilestoneCurrentTier__c = 1;
			caseInvestigations[i].NetworkMilestonesViolated__c = null;
			caseInvestigations[i].Network__r = networks[0];
		}

		//assigning no network to case investigations
		//so case investigations are assigned to the owner
		for (Integer i = 50; i < 100 ; i++) {
			caseInvestigations[i].Status__c = 'New';
			caseInvestigations[i].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
			caseInvestigations[i].NetworkMilestoneCurrentTier__c = 1;
			caseInvestigations[i].NetworkMilestonesViolated__c = null;
		}

		//assigning network to case investigations
		//so email is populated from network record
		for (Integer i = 100; i < 150 ; i++) {
			caseInvestigations[i].Status__c = 'New';
			caseInvestigations[i].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
			caseInvestigations[i].NetworkMilestoneCurrentTier__c = 1;
			caseInvestigations[i].NetworkMilestonesViolated__c = 1;
			caseInvestigations[i].Network__r = networks[0];
		}

		//assigning no network to case investigations
		//so case investigations are assigned to the owner
		for (Integer i = 150; i < 200 ; i++) {
			caseInvestigations[i].Status__c = 'New';
			caseInvestigations[i].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
			caseInvestigations[i].NetworkMilestoneCurrentTier__c = 1;
			caseInvestigations[i].NetworkMilestonesViolated__c = 1;
		}

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector vSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(vSelector.selectNetworkMilestoneViolatedOpenCaseInvestigations((Datetime)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(Database.getQueryLocator([SELECT Id FROM CaseInvestigation__c LIMIT 1]));
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		STCIMilestoneViolationCheckerBatch vBatch = new STCIMilestoneViolationCheckerBatch();
		vBatch.execute(null, caseInvestigations);
		vBatch.execute(null);
		Test.stopTest();

		//assert the batch job to be completed
		List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob];
		System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');

		//verify that selector is called once with expected arguments to get the query locator
		((CaseInvestigationsSelector) MockUtility.Mocks.verify(vSelector, MockUtility.Mocks.times(1))).selectNetworkMilestoneViolatedOpenCaseInvestigations((Datetime)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify that updates has been done
		((ApplicationDatabase) MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) fflib_Match.anyList(), (Boolean) fflib_Match.anyBoolean());
	}

	/**
	 * @description Test the end to end functionality of the batch job by performing DML.
	 */
	@IsTest
	private static void testBatchJobEndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================
		//insert custom settings to disable triggers.
		insert new SystemSwitch__c(SetupOwnerId=UserInfo.getOrganizationId(),
		DisableTriggers__c=true, ObjectTriggersToBeDisabled__c= 'Case,CaseInvestigation__c,Network__c,Article__c');
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(5, false);
		insert articles;

		List<Case> cases = ApplicationTestDataFactory.getCases(5, false);
		for (Case c: cases) {
			c.RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		}
		insert cases;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';
		networks[0].Contact_Facility__c = 'MyNetwork';
		insert networks;


		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[0].Id, false));
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[2].Id, articles[2], networks[0].Id, false));
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[3].Id, articles[3], networks[0].Id, false));
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[4].Id, articles[4], networks[0].Id, false));

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName().get('StarTrack_MyNetwork').getRecordTypeId();

		for (CaseInvestigation__c ci : caseInvestigations) {
			ci.NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
			ci.NetworkMilestoneCurrentTier__c = 1;
			ci.RecordTypeId = stCaseInvestigationRecordTypeId;
		}
		insert caseInvestigations;

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCIMilestoneViolationCheckerBatch vBatch = new STCIMilestoneViolationCheckerBatch(20);
		// run the scheduler
		vBatch.execute(null);

		Test.stopTest();

		//asserting tier value updated by the batch.
		List<CaseInvestigation__c> updatedCaseInvestigations = CaseInvestigationsSelector.newInstance().selectById(new Map<Id,CaseInvestigation__c>(caseInvestigations).keySet()).values();
		for (CaseInvestigation__c ci: updatedCaseInvestigations) {
			System.assertEquals(2, ci.NetworkMilestoneCurrentTier__c, 'Expected current network tier to be updated');
			System.assertNotEquals(null, ci.NetworkMilestonesViolated__c, 'Expected network milestones to be updated');
		}
	}
}