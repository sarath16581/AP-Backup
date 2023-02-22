/**
 * @description Test class for FeedItemCaseInvestigationModule
 * @author Dattaraj Deshmukh
 * @date 2022-07-25
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
 * 2022-02-21 - Dattaraj Deshmukh - Fixed 'testEndToEndTriggerIntegrationForInsert' method.
  */
@IsTest
 private class FeedItemCaseInvestigationModule_Test {

	
	/**
	 * Test: Ensure that CaseInvestigation__c.LastContactCentreUpdate__c is not updated when users having
	 * profile other than 'StarTrack Support' adds a chatter feed.
	 * Expected: CaseInvestigation record is NOT UPDATED when a feed item is added in test method. (which will run in running user context)
	 */
	@IsTest
	public static void testEnsureOnAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(FeedItemTriggerHandler2.getUnitOfWorkSObjectTypes());

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, null, null, true);
		
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemCaseInvestigationModule module = FeedItemCaseInvestigationModule.newInstance();

		module.onAfterInsert(new List<FeedItem>{feedItems[0]}, uow);

		Test.stopTest();

		//verifying registerDirty is NOT CALLED as criteria of updating case investigations will not meet.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDirty((List<CaseInvestigation__c>)fflib_Match.eqList(new List<CaseInvestigation__c>{caseInvestigations[0]}));

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

	/**
	 * Test: Ensure that CaseInvestigation__c.LastContactCentreUpdate__c is updated when 'StarTrack Support' profile user adds a chatter feed.
	 * Expected: CaseInvestigation record is updated when a feed item is added in test method.
	 */
	@IsTest
	public static void testUpdateCaseInvestigations() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);
		Id profileId = Application.Cache.profileIds.get('StarTrack Support');


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemCaseInvestigationModule module = FeedItemCaseInvestigationModule.newInstance();

		module.updateCaseInvestigations(profileId, new List<FeedItem>{feedItems[0]}, mockUow);

		Test.stopTest();

		// NOTE: Following arguments cannnot be matched as logic assigns timestamps to field. 
		// When fflib_Match executes it cannot match to timestamp executed by module logic and hence it fails to verify registerDirty() method call.
		// ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<CaseInvestigation__c>) fflib_Match.eqList(new List<CaseInvestigation__c>{new CaseInvestigation__c(Id = feedItems[0].ParentId, LastContactCentreUpdate__c = System.now())}));
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>) fflib_Match.anyObject());
	
		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
	

	/**
	 * Test: Performing test by inserting records in database in the context of Contact Centre user.
	 * Expected: FeedItem record is inserted and CaseInvestigation record is updated.
	 */
	@IsTest
	static void testEndToEndTriggerIntegrationForInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';

		insert networks;

		Id profileId = Application.Cache.profileIds.get('StarTrack Support');
		
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

			List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
			cases[0].ArticleTest__c = articles[0].Id;
			cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
			insert cases;

			List<CaseInvestigation__c>  caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
			insert caseInvestigations;

			List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, false);
			feedItems[0].Body = 'test feed'; feedItems[1].Body = 'test feed 2';

			Test.startTest();
			insert(feedItems);
			Test.stopTest();

			//asserting feeditem record is successfully inserted.
			List<FeedItem> createdFeedItems = FeedItemsSelector.newInstance().selectById(new Set<Id>{feedItems[0].Id}, new Set<Object>()).values();
			system.assertNotEquals(null, createdFeedItems);

			//asserting CaseInvestigation record is updated upon insertion of feeditem by Contact Centre users.
			List<CaseInvestigation__c> cIRecords = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{createdFeedItems[0].ParentId}).values();
			system.assertNotEquals(null, cIRecords[0].LastContactCentreUpdate__c);

		}
	}
	
 }