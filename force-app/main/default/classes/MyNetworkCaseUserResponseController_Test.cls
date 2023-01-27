/**
 * @description Test class for MyNetworkCaseUserResponseController
 * @author Dattaraj Deshmukh
 * @date 2022-12-07
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
*/
@IsTest
private class MyNetworkCaseUserResponseController_Test {
	/**
	 * @desc: test if method creates chatter feed record for a case investigation record.
	 * When Portal user updates response on case investgiation record, chatter feed is created and case status
	 * is updated to 'Network Responsded'.
	 * Expected: Case status is updated to 'Network Responded'.
	 */
	@IsTest
	public static void testPostCaseInvestigationChatterFeed() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		
		//assigning child CI records to case.
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{caseInvestigations[0]}});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();
		MyNetworkCaseUserResponseController.postCaseInvestigationChatterFeed('Sample Feed Comments', caseInvestigations[0].Id, cases[0].Id);
		Test.stopTest();

		fflib_ArgumentCaptor insertableRecordsCaptor = fflib_ArgumentCaptor.forClass(List<FeedItem>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<FeedItem>) insertableRecordsCaptor.capture());

		List<FeedItem> insertedRecords = (List<FeedItem>) insertableRecordsCaptor.getValue();

		//asserting feeditem is inserted with expected comments.
		system.assertEquals(1, insertedRecords.size());
		system.assertEquals('Sample Feed Comments', insertedRecords[0].Body);


		fflib_ArgumentCaptor updatableRecordsCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) updatableRecordsCaptor.capture());

		List<Case> updatedCase = (List<Case>)updatableRecordsCaptor.getValue();

		//asserting case status is updated
		system.assertEquals(MyNetworkConstants.CASE_STATUS_NETWORK_RESPONDED, updatedCase[0].Status);

	}
}