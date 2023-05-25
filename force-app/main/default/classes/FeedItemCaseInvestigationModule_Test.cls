/**
 * @description Test class for FeedItemCaseInvestigationModule
 * @author Dattaraj Deshmukh
 * @date 2022-07-25
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
 * 2022-02-21 - Dattaraj Deshmukh - Fixed 'testEndToEndTriggerIntegrationForInsert' method.
 * 2023-03-21 - Mahesh Parvathaneni - Updated tests for 'testEndToEndTriggerIntegrationForInsert' method.
 * 2023-05-03 - Mahesh Parvathaneni - updated tests to use the service class
 * 2023-05-22 - Mahesh Parvathaneni - SF-961 - Added filter for the network lookup field
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
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, null, null, true);
		
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		STCaseInvestigationFeedService mockService = (STCaseInvestigationFeedService)MockUtility.mockUtility(STCaseInvestigationFeedService.class);

		MockUtility.Mocks.startStubbing();
		((STCaseInvestigationFeedService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).updateCaseInvestigationsRelatedToFeed((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemCaseInvestigationModule module = FeedItemCaseInvestigationModule.newInstance();

		module.onAfterInsert(new List<FeedItem>{feedItems[0]}, mockUow);

		Test.stopTest();

		// should not have called STCaseInvestigationFeedService methods
		((STCaseInvestigationFeedService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(0))).updateCaseInvestigationsRelatedToFeed((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());

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
		STCaseInvestigationFeedService mockService = (STCaseInvestigationFeedService)MockUtility.mockUtility(STCaseInvestigationFeedService.class);


		// set up our responses
		MockUtility.Mocks.startStubbing();
		((STCaseInvestigationFeedService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).updateCaseInvestigationsRelatedToFeed((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemCaseInvestigationModule module = FeedItemCaseInvestigationModule.newInstance();

		module.updateCaseInvestigations(profileId, new List<FeedItem>{feedItems[0]}, mockUow);

		Test.stopTest();

		// should have called STCaseInvestigationFeedService methods
		fflib_ArgumentCaptor sobjectIdCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((STCaseInvestigationFeedService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).updateCaseInvestigationsRelatedToFeed((Set<Id>)sobjectIdCapture.capture(), (ApplicationUnitOfWork)fflib_Match.eq(mockUow));

		Set<Id> sobjectIds = (Set<Id>)sobjectIdCapture.getValue();
		System.assertEquals(1, sobjectIds.size(), 'Expected one case investigation to be updated');
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
		networks[0].Contact_Facility__c = 'MyNetwork';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;

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
			System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_NEW_STATUS, cIRecords[0].Status__c, 'Expected case investigation status to be New');
			System.assertEquals(false, cIRecords[0].RequireMoreInformation__c, 'Expected Require More Information value to be false');

		}
	}
 }