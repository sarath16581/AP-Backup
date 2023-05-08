/**
 * @description Test class for STCaseInvestigationFeedService
 * @author Mahesh Parvathaneni
 * @date 02/05/2023
 * @changelog
 */

@IsTest
private class STCaseInvestigationFeedService_Test {

	/**
	 * Scenario: Test to ensure the case investigation records are updated with correct status and Sent to Network date when
	 * one of the case investigation is in closed status and other in responded status
	 */
	@IsTest
	static void testUpdateCaseInvestigationsRelatedToFeed() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';
		networks[0].Contact_Facility__c = 'MyNetwork';

		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'RecordTypeId' => ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType});
		cases[1].ArticleTest__c = articles[1].Id;
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'RecordTypeId' => ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType});

		List<CaseInvestigation__c>  caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[0].Id, true));
		caseInvestigations[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(caseInvestigations[0], new Map<String, Object>{'Status__c' => MyNetworkConstants.CASE_INVESTIGATION_CLOSED_STATUS});
		caseInvestigations[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(caseInvestigations[1], new Map<String, Object>{'Status__c' => MyNetworkConstants.CASE_INVESTIGATION_RESPONDED_STATUS});
		caseInvestigations[0].SentToNetworkDatetime__c = System.now().addDays(-1);
		caseInvestigations[1].SentToNetworkDatetime__c = System.now().addDays(-1);

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectById(new Set<Id>{caseInvestigations[0].Id, caseInvestigations[1].Id})).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0], caseInvestigations[1].Id => caseInvestigations[1]});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject(), (List<Schema.SObjectField>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(STCaseInvestigationFeedService.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationFeedService service = STCaseInvestigationFeedService.getInstance();
		service.updateCaseInvestigationsRelatedToFeed(new Set<Id>{caseInvestigations[0].Id, caseInvestigations[1].Id}, mockUow);
		Datetime dt = service.currentTime;

		Test.stopTest();

		//asserting CaseInvestigation records updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<CaseInvestigation__c>) fflib_Match.eq(new List<CaseInvestigation__c>{
				new CaseInvestigation__c(Id = caseInvestigations[0].Id, LastContactCentreUpdate__c = dt, RequireMoreInformation__c = false, Status__c = MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, SentToNetworkDatetime__c = dt),
				new CaseInvestigation__c(Id = caseInvestigations[1].Id, LastContactCentreUpdate__c = dt, RequireMoreInformation__c = false, Status__c = MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, SentToNetworkDatetime__c = caseInvestigations[1].SentToNetworkDatetime__c)
			}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ CaseInvestigation__c.LastContactCentreUpdate__c, CaseInvestigation__c.Status__c, CaseInvestigation__c.RequireMoreInformation__c, CaseInvestigation__c.SentToNetworkDatetime__c }),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(STCaseInvestigationFeedService.class.getName())
		);

		Assert.areEqual(2, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 2 case investigation record to be updated');
		Assert.areEqual(dt, ((CaseInvestigation__c)MockUtility.mockUnitOfWorkDMLs[0]).SentToNetworkDatetime__c, 'Expected sent to network date time to be updated');
		Assert.areEqual(caseInvestigations[1].SentToNetworkDatetime__c, ((CaseInvestigation__c)MockUtility.mockUnitOfWorkDMLs[1]).SentToNetworkDatetime__c, 'Expected sent to network date time not to be updated');
		Assert.areEqual(MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, ((CaseInvestigation__c)MockUtility.mockUnitOfWorkDMLs[0]).Status__c, 'Expected case investigation status to be In Progress');
		Assert.areEqual(MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, ((CaseInvestigation__c)MockUtility.mockUnitOfWorkDMLs[1]).Status__c, 'Expected case investigation status to be In Progress');
	}

	/**
	 * Test: Performing test by insert/update records in database.
	 * Assert the records are updated with correct data.
	 */
	@IsTest
	static void testEndToEndDMLForCaseInvestigations() {
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
			caseInvestigations[0].Status__c = MyNetworkConstants.CASE_INVESTIGATION_MORE_INFO_REQUIRED;
			insert caseInvestigations;
		}

		// =====================================
		// Stubbing
		// =====================================
		// NONE

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(1, caseInvestigations[0].Id, false);
		feedItems[0].Body = 'test feed';
		insert feedItems;

		List<FeedComment> feedComments;
		System.runAs(userRec){
			feedComments = ApplicationTestDataFactory.getFeedComments(1, caseInvestigations[0].Id, feedItems[0].Id, false);
			feedComments[0].CommentBody = 'test comment';
			insert feedComments;
		}

		Test.stopTest();

		//asserting CaseInvestigation record is updated upon insertion of FeedComment by Contact Centre users.
		List<CaseInvestigation__c> cIRecords = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{feedComments[0].ParentId}).values();
		Assert.isNotNull(cIRecords[0].LastContactCentreUpdate__c, 'Expected LastContactCentreUpdate__c to be updated but returned null');
		Assert.areEqual(MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, cIRecords[0].Status__c, 'Expected case investigation status to be In Progress');
		Assert.areEqual(false, cIRecords[0].RequireMoreInformation__c, 'Expected Require More Information value to be false');
		Assert.isNotNull(cIRecords[0].SentToNetworkDatetime__c, 'Expected SentToNetworkDatetime__c to be updated but returned null');
	}

}