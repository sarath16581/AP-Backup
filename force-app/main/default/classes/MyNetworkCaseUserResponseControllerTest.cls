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
private class MyNetworkCaseUserResponseControllerTest {
	
	
	/**
	 * @desc test if method creates chatter feed record for a case investigation record.
	 */
	@IsTest
	public static void test_postCaseInvestigationChatterFeed() {
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
		
		// =====================================
        // Stubbing
        // =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();
		MyNetworkCaseUserResponseController.postCaseInvestigationChatterFeed('Sample Feed Comments', caseInvestigations[0].Id);
		Test.stopTest();

		fflib_ArgumentCaptor insertableRecordsCaptor = fflib_ArgumentCaptor.forClass(List<FeedItem>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<FeedItem>) insertableRecordsCaptor.capture());

		List<FeedItem> insertedRecords = (List<FeedItem>) insertableRecordsCaptor.getValue();
		system.assertEquals(1, insertedRecords.size());

		system.assertEquals('Sample Feed Comments', insertedRecords[0].Body);

	}

	/**
	 * @desc test if method returns chatter feed for a case investigation record.
	 */
	@IsTest
	public static void test_getCaseInvestigationChatterFeeds() {

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
		caseInvestigations[0].Status__c = 'Open';

		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);

		
        // =====================================
        // Stubbing
        // =====================================
        FeedItemsSelector mockSelector = (FeedItemsSelector)MockUtility.mockSelector(FeedItemsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectByTextPostParentIds(new Set<Id>{caseInvestigations[0].Id}, new Set<Object>{FeedItemsSelector.Options.WITH_CREATEDBY})).thenReturn(new Map<Id, FeedItem>(feedItems));
		
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//calling method to get all feeditems against parent id.
		MyNetworkCaseUserResponseController.getCaseInvestigationChatterFeeds(caseInvestigations[0].Id);

		Test.stopTest();

		//verify that method is called once with expected list of feeditems
        ((FeedItemsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByTextPostParentIds((Set<Id>)fflib_Match.eq(new Set<Id>{caseInvestigations[0].Id}),
																															(Set<Object>) fflib_Match.eq( new Set<Object>{FeedItemsSelector.Options.WITH_CREATEDBY}));
	}
}
