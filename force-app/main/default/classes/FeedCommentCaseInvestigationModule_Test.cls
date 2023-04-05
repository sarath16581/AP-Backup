/**
 * @description			: Test class for STCINetworkMilestoneViolationModule
 * @author				: Mahesh Parvathaneni
 * @domain				: Case Investigation
 * @changelog
 * 2023-04-04 - Mahesh Parvathaneni - created
 **/

 @IsTest
private class FeedCommentCaseInvestigationModule_Test {
	
	/**
	 * Test: Ensure that the case investigations are updated when feed comment is created by the startrack support user
	 */
	@IsTest
	public static void testEnsureOnAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(1, caseInvestigations[0].Id, true);
		feedItems.addAll(ApplicationTestDataFactory.getChatterFeeds(1, caseInvestigations[1].Id, true));
		List<FeedComment> feedComments = ApplicationTestDataFactory.getFeedComments(1, caseInvestigations[0].Id, feedItems[0].Id, true);
		feedComments.addAll(ApplicationTestDataFactory.getFeedComments(1, caseInvestigations[1].Id, feedItems[1].Id, true));

		Id profileId = Application.Cache.profileIds.get('StarTrack Support');
		//query StarTrack Support user
		User userRec = [Select id from user where ProfileId=:profileId AND isActive = true LIMIT 1];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		System.runAs(userRec){

			Test.startTest();

			FeedCommentCaseInvestigationModule module = FeedCommentCaseInvestigationModule.newInstance();
			module.onAfterInsert(feedComments, mockUow);

			Test.stopTest();

			//verifying registerDirty is CALLED
			((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>) fflib_Match.anyObject());

			// PMD by-pass
			System.assert(true, 'PMD by-pass');
		}
	}

	/**
	 * Test: Performing test by inserting records in database in the context of Contact Centre user.
	 * Expected: FeedComment record is inserted and CaseInvestigation record is updated.
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

		insert networks;

		Id profileId = Application.Cache.profileIds.get('StarTrack Support');
		
		//query contact user
		User userRec = [Select id from user where ProfileId=:profileId AND isActive = true LIMIT 1];

		List<CaseInvestigation__c> caseInvestigations;
		System.runAs(userRec) {
			List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
			cases[0].ArticleTest__c = articles[0].Id;
			cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
			insert cases;

			caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
			insert caseInvestigations;
		}

		// =====================================
		// Stubbing
		// =====================================
		// NONE

		// =====================================
		// Testing
		// =====================================
		List<FeedComment> feedComments;

		Test.startTest();

		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(1, caseInvestigations[0].Id, false);
		feedItems[0].Body = 'test feed';
		insert feedItems;
		
		System.runAs(userRec){
			feedComments = ApplicationTestDataFactory.getFeedComments(1, caseInvestigations[0].Id, feedItems[0].Id, false);
			feedComments[0].CommentBody = 'test comment';
			insert feedComments;
		}

		Test.stopTest();

		//asserting CaseInvestigation record is updated upon insertion of FeedComment by Contact Centre users.
		List<CaseInvestigation__c> cIRecords = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{feedComments[0].ParentId}).values();
		System.assertNotEquals(null, cIRecords[0].LastContactCentreUpdate__c, 'Expected LastContactCentreUpdate__c to be populated but returned null');
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, cIRecords[0].Status__c, 'Expected case investigation status to be In Progress');
		System.assertEquals(false, cIRecords[0].RequireMoreInformation__c, 'Expected Require More Information value to be false');
	}
}