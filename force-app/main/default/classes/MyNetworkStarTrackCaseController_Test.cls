/**
 * @File Name          : MyNetworkStarTrackCaseController_Test.cls
 * @Description        : Test class for MyNetworkStarTrackCaseController
 * @Author             : Mahesh Parvathaneni
 **/

@IsTest
public with sharing class MyNetworkStarTrackCaseController_Test {
    
    /**
	 * Scenario: Testing to get articles and event messages related to case
	 */
	@IsTest
	private static void testGetArticlesByCase() {

		// =====================================
		// Data Preparation
		// =====================================
        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
        EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
        Case c = ApplicationTestDataFactory.getCases(1, true)[0];
        article.Case__c = c.Id;
        //associating event messages with articles.
        article = (Article__c)ApplicationTestDataFactory.setChildRelationships(article, new Map<String, List<SObject>>{'Event_Messages__r' => new List<SObject>{eventMessage}});
        MyNetworkStarTrackCaseController.ArticleDetails mockDetails = new MyNetworkStarTrackCaseController.ArticleDetails(article);
        MyNetworkStarTrackCaseController.ArticleResponseWrapper mockWrapper = new MyNetworkStarTrackCaseController.ArticleResponseWrapper();
        mockWrapper.articleDetails = new List<MyNetworkStarTrackCaseController.ArticleDetails>{mockDetails};

		// =====================================
		// Stubbing
		// =====================================
        ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockArticlesSelector.selectByCaseIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>{article.Id => article});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        MyNetworkStarTrackCaseController.ArticleResponseWrapper wrapper = MyNetworkStarTrackCaseController.getArticlesByCase(c.Id);

        Test.stopTest();

        System.assertNotEquals(false, wrapper.hasPassedThroughAPNetwork, 'Expected true but instead returned false.');
        System.assertEquals(article.Id, wrapper.articleDetails[0].article.Id, 'Expected article details for the case');
        System.assertEquals(mockWrapper.articleDetails[0].eventMessages[0].eventMessage.Id, wrapper.articleDetails[0].eventMessages[0].eventMessage.Id, 'Article details are not returned correctly');
	}

    /**
	 * Scenario: Testing to save the case investigation records
	 */
	@IsTest
	private static void testSaveCaseInvestigations() {

		// =====================================
		// Data Preparation
		// =====================================
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
        List<CaseInvestigation__c> existingCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[1], networks[1].Id, true);
        String stJson = '{"success":true,"id":' +'"'+ caseInvestigations[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
        List<Database.SaveResult> svResultList = new List<Database.SaveResult>{sr};

		// =====================================
		// Stubbing
		// =====================================
        CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectOpenCaseInvestigationsByCaseArticleNetworkId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{existingCaseInvestigations[0].Id => existingCaseInvestigations[0]});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        MyNetworkStarTrackCaseController.SaveResult saveResult = MyNetworkStarTrackCaseController.saveCaseInvestigations(caseInvestigations, 'Posting to Chatter feed');

        Test.stopTest();

        System.assertNotEquals(MyNetworkStarTrackCaseController.Status.ERROR.name(), saveResult.status, 'Expected successful creation of case investigation record');
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}

    /**
	 * Scenario: Testing to save the case investigation records that already exists related to same article and network
	 */
	@IsTest
	private static void testSaveDuplicateCaseInvestigations() {

		// =====================================
		// Data Preparation
		// =====================================
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
        CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectOpenCaseInvestigationsByCaseArticleNetworkId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        MyNetworkStarTrackCaseController.SaveResult saveResult = MyNetworkStarTrackCaseController.saveCaseInvestigations(caseInvestigations, 'Posting to Chatter feed');

        Test.stopTest();

        System.assertNotEquals(MyNetworkStarTrackCaseController.Status.SUCCESSFUL.name(), saveResult.status, 'Expected error creation of case investigation record');
	}

}
