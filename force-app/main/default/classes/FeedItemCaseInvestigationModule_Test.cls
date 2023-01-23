/**
 * @description Test class for FeedItemCaseInvestigationModule
 * @author Dattaraj Deshmukh
 * @date 2022-07-25
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
  */
  @IsTest
 private class FeedItemCaseInvestigationModule_Test {

	
	@IsTest
	public static void testEnsureOnAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(FeedItemTriggerHandler2.getUnitOfWorkSObjectTypes());

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemCaseInvestigationModule module = FeedItemCaseInvestigationModule.newInstance();

		module.onAfterInsert(new List<FeedItem>{feedItems[0]}, uow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableJobsCaptor = fflib_ArgumentCaptor.forClass(List<CaseInvestigation__c>.class);

		//verifying registerDirty is not called as criteria of updating case investigations will not meet.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDirty((List<CaseInvestigation__c>)fflib_Match.eqList(new List<CaseInvestigation__c>{caseInvestigations[0]}));

		List<CaseInvestigation__c> updatedCaseInvestigations = (List<CaseInvestigation__c>) updatableJobsCaptor.getValue();

		//asserting no case investigations are updated as criteria will not meet. 
		system.assertEquals(null, updatedCaseInvestigations);


	}

	@IsTest
	public static void testUpdateCaseInvestigations() {
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
		
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);
		Id profileId = Application.Cache.profileIds.get('SSSW - Service Agent');


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemCaseInvestigationModule module = FeedItemCaseInvestigationModule.newInstance();

		module.updateCaseInvestigations(profileId, new List<FeedItem>{feedItems[0]}, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableJobsCaptor = fflib_ArgumentCaptor.forClass(List<CaseInvestigation__c>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<CaseInvestigation__c>) updatableJobsCaptor.capture());

		List<CaseInvestigation__c> updatedCaseInvestigations = (List<CaseInvestigation__c>) updatableJobsCaptor.getValue();

		//asserting case investigations are updated
		system.assertEquals(System.now(), updatedCaseInvestigations[0].LastContactCentreUpdate__c);


	}
	


	@IsTest
	static void testEndToEndTriggerIntegrationForInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;

		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		insert cases;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';

		insert networks;

        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		insert caseInvestigations;

		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, false);
		feedItems[0].Body = 'test feed'; feedItems[1].Body = 'test feed 2';

		Id profileId = Application.Cache.profileIds.get('SSSW - Service Agent');
		
		//query contact user
		User userRec = [Select id from user where ProfileId=:profileId AND isActive = true LIMIT 1];


		// =====================================
		// Stubbing
		// =====================================
		//NONE

		// =====================================
		// Testing
		// =====================================
		System.runAs(userRec){
			Test.startTest();
			insert(feedItems);
			Test.stopTest();
		}
		List<FeedItem> createdFeedItems = FeedItemsSelector.newInstance().selectByTextPostParentIds(new Set<Id>{caseInvestigations[0].Id}, new Set<Object>()).values();
		system.assertNotEquals(null, createdFeedItems);
	}
    
 }