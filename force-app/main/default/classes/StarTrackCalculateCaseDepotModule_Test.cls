/**
 * @description
 * Test class for StarTrackCalculateCaseDepotModule
 * @author Madhusudhan
 * @date 2021-06-17
 * @group Tests
 * @domain StarTrack
 * @changelog
 */
@IsTest
private class StarTrackCalculateCaseDepotModule_Test {
	/**
	 * Test:
	 *  When a case is inserted with Article/Network, the before insert method will update case Network with Article's Network.
	 *  Also it updates BusinessHoursId with Network's business hours if it's not null,
	 *  Else updates from Startrack Custom settings
	 */
	@IsTest
	private static void testEnsureBeforeInsertPopulatesNetworkAndBusinessHoursIds() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);

		Set<Id> articlesIds = new Set<Id>{ articles[0].Id, articles[1].Id };
		Set<Id> networksIds = new Set<Id>{ networks[0].Id, networks[1].Id };

		// update network on article records
		articles[0].Network__c = networks[0].Id;
		articles[1].Network__c = networks[1].Id;

		// update network, article and recordtype
		cases[0].ArticleTest__c = articles[0].Id;
		cases[1].ArticleTest__c = articles[1].Id;
		cases[1].Network__c = networks[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		NetworksSelector mockNetworksSelector = (NetworksSelector) MockUtility.mockSelector(NetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectById((Set<Id>) articlesIds))
			.thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockNetworksSelector.selectById((Set<Id>) networksIds))
			.thenReturn(new Map<Id, Network__c>(networks));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackCalculateCaseDepotModule module = StarTrackCalculateCaseDepotModule.newInstance();

		module.onBeforeInsert(cases, uow);

		// make sure the method behaved
		((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(articlesIds);
		((NetworksSelector) MockUtility.Mocks.verify(mockNetworksSelector, 1)).selectById(networksIds);

		// make sure fields were updated correctly
		System.assertEquals(articles[0].Id, cases[0].ArticleTest__c, 'Expected Article Id field to be set on case');
		System.assertEquals(networks[0].Id, cases[0].Network__c, 'Expected Network ID field to be set on case');

		System.assertEquals(
			cases[0].Network__c,
			articles[0].Network__c,
			'Expected Case Network to be same as Article\'s Network'
		);
		System.assertEquals(
			cases[1].Network__c,
			networks[1].Id,
			'Expected Case Network to be same as Article\'s Network'
		);

		System.assertEquals(
			cases[0].BusinessHoursId,
			StarTrack_Settings__c.getInstance().StarTrack_Default_Business_Hour__c,
			'Expected business hours Id to be same as default business hours Id'
		);
		System.assertEquals(
			cases[1].BusinessHoursId,
			StarTrack_Settings__c.getInstance().StarTrack_Default_Business_Hour__c,
			'Expected business hours Id to be same as default business hours Id'
		);
		Test.stopTest();
	}

	/**
	 * Test:
	 *  When Article and Network are changed on cases, the before update method will update case Network with Article's Network.
	 *  Also it updates BusinessHoursId with Network's business hours if it's not null,
	 *  Else updates from Startrack Custom settings
	 */

	@IsTest
	private static void testEnsureBeforeUpdatePopulatesNetworkAndBusinessHoursIds() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, null, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(3, true);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Case> oldCases = new List<Case>{ cases[0].clone(true), cases[1].clone(true) };

		// set the network value on the article
		articles[0].Network__c = networks[0].Id;
		articles[1].Network__c = networks[1].Id;

		// on case0, Article id was changed from article0 to article1
		// on case1, Article id was changed from article2 to article3
		cases[0].ArticleTest__c = articles[1].Id;
		cases[0].Network__c = networks[0].Id;
		oldCases[0].ArticleTest__c = articles[2].Id;
		oldCases[0].Network__c = networks[2].Id;

		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		NetworksSelector mockNetworksSelector = (NetworksSelector) MockUtility.mockSelector(NetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectById(new Set<Id>{ articles[1].Id }))
			.thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockNetworksSelector.selectById(new Set<Id>{ networks[1].Id }))
			.thenReturn(new Map<Id, Network__c>(networks));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackCalculateCaseDepotModule module = StarTrackCalculateCaseDepotModule.newInstance();

		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);
		Test.stopTest();

		// make sure the method behaved
		((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(new Set<Id>{ articles[1].Id });
		((NetworksSelector) MockUtility.Mocks.verify(mockNetworksSelector, 1))
			.selectById(new Set<Id>{ networks[1].Id });

		// make sure fields updated correctly
		System.assertEquals(articles[1].Id, cases[0].ArticleTest__c, 'Expected Article Id field to be set on case');
		System.assertEquals(
			cases[0].Network__c,
			networks[1].Id,
			'Expected Case Network to be same as Article\'s Network'
		);
		System.assertEquals(
			cases[0].BusinessHoursId,
			StarTrack_Settings__c.getInstance().StarTrack_Default_Business_Hour__c,
			'Expected business hours Id to be same as default business hours Id'
		);
	}

	/**
	 *	Scenario: Integration Scenario
	 */
	@IsTest
	public static void testEnsureNetworkAndBusinessHoursIdsPopulatedIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, false);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, false);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);

		insert networks;
        
		// update network on article records		
        articles[0].Network__c = networks[0].Id;
        
        // Consignment Next Flight
        articles[0].Product_Group__c = 'Next Flight';
		insert articles;
        
		// update network, article and recordtype
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
        
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
        insert cases;
        
		List<Case> updatedCases = [SELECT Id, ArticleTest__c, Network__c, BusinessHoursId FROM Case WHERE Id =: cases[0].Id]; 
		// make sure fields were updated correctly
		System.assertEquals(articles[0].Id, updatedCases[0].ArticleTest__c, 'Expected Article Id field to be set on case');
		System.assertEquals(articles[0].Network__c, updatedCases[0].Network__c, 'Expected Network ID field to be set on case');
		
		updatedCases[0].Network__c = networks[1].Id;
		updatedCases[0].ArticleTest__c = articles[1].Id;
		
        update updatedCases;
		Test.stopTest();

	}
}