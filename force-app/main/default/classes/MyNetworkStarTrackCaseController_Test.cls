/**
 * @File Name			: MyNetworkStarTrackCaseController_Test.cls
 * @Description			: Test class for MyNetworkStarTrackCaseController
 * @Author				: Mahesh Parvathaneni
 * @changelog
 * 2022-12-12 - Mahesh Parvathaneni - added new test methods
 * 2023-01-17 - Mahesh Parvathaneni - added tests to set the StarTrack MyNetwork record type for Case Investigation
 * 2023-03-10 - Mahesh Parvathaneni - SF-889 - Updated test method testGetArticlesByCase
 * 2023-04-03 - Mahesh Parvathaneni - Added test method testGetCaseTypeBlankError
 * 2023-05-12 - Mahesh Parvathaneni - SF-946 - Added tests to submit case investigations when no AP network scans
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
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Case c = ApplicationTestDataFactory.getCases(1, true)[0];
		c.ReferenceID__c = consignment.ArticleID__c;
		c.ArticleTest__c = consignment.Id;
		c.Call_Purpose__c = 'Pickup';
		c.Enquiry_Type__c = 'Driver ETA - Pickup'; 
		consignment = (Article__c)ApplicationTestDataFactory.setUnwritableFields(consignment, new Map<String, Object>{'RecordType.Name' => 'Consignment'});

		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.Consignment__c = consignment.Id;
		EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		eventMessage.Post_Office_Code__c = '1234';

		Network__c network = ApplicationTestDataFactory.getNetworks(1, true)[0];
		network.Org_ID__c = '1234';

		//associating articles with consignment.
		consignment = (Article__c)ApplicationTestDataFactory.setChildRelationships(consignment, new Map<String, List<SObject>>{'Articles__r' => new List<SObject>{article}});

		//associating event messages with articles.
		article = (Article__c)ApplicationTestDataFactory.setChildRelationships(article, new Map<String, List<SObject>>{'Event_Messages__r' => new List<SObject>{eventMessage}});
		MyNetworkStarTrackCaseController.EventMessage em = new MyNetworkStarTrackCaseController.EventMessage();
		em.eventMessage = eventMessage;
		em.network = network;
		MyNetworkStarTrackCaseController.ArticleDetails mockDetails = new MyNetworkStarTrackCaseController.ArticleDetails();
		mockDetails.article = article;
		mockDetails.eventMessages = new List<MyNetworkStarTrackCaseController.EventMessage>{em};
		MyNetworkStarTrackCaseController.ArticleResponseWrapper mockWrapper = new MyNetworkStarTrackCaseController.ArticleResponseWrapper();
		mockWrapper.articleDetails = new List<MyNetworkStarTrackCaseController.ArticleDetails>{mockDetails};

		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		NetworksSelector mockNetworksSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{c.Id => c});
		MockUtility.Mocks.when(mockArticlesSelector.selectById(new Set<Id>{consignment.Id}, new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES})).thenReturn(new Map<Id, Article__c>{consignment.Id => consignment});
		MockUtility.Mocks.when(mockArticlesSelector.selectById(new Set<Id>{article.Id}, new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_DESC_ORDER})).thenReturn(new Map<Id, Article__c>{article.Id => article});
		MockUtility.Mocks.when(mockNetworksSelector.selectByOrgId(new Set<String>{eventMessage.Post_Office_Code__c}, new Set<Object>{NetworksSelector.Options.FILTER_AP_NETWORK})).thenReturn(new Map<Id, Network__c>{network.Id => network});
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
		System.Savepoint sSavePoint = Database.setSavepoint();

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(sSavePoint);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectOpenCaseInvestigationsByCaseArticleNetworkId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{existingCaseInvestigations[0].Id => existingCaseInvestigations[0]});
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
	 * Scenario: Testing to save the case investigation records exception scenario
	 */
	@IsTest
	private static void testSaveCaseInvestigationsException() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		List<CaseInvestigation__c> existingCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[1], networks[1].Id, true);
		String stJson = '{"success":true,"id":"1234"}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
		List<Database.SaveResult> svResultList = new List<Database.SaveResult>{sr};
		System.Savepoint sSavePoint = Database.setSavepoint();
		MyNetworkStarTrackCaseController.SaveResult saveResult;

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(sSavePoint);
		MockUtility.Mocks.when(mockDatabase.dmlRollback(sSavePoint)).thenReturn(true);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectOpenCaseInvestigationsByCaseArticleNetworkId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{existingCaseInvestigations[0].Id => existingCaseInvestigations[0]});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			saveResult = MyNetworkStarTrackCaseController.saveCaseInvestigations(caseInvestigations, 'Posting to Chatter feed');
		} catch (AuraHandledException ex) {
			//expected
			System.assertNotEquals(null, ex.getMessage(), 'Expected exception for creation of case investigation record');
		}

		Test.stopTest();	

		//Make sure Roll back was called once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlRollback(sSavePoint);
	}

	/**
	 * Scenario: Testing to save the case investigation records that already exists related to same article and network
	 */
	@IsTest
	private static void testSaveDuplicateCaseInvestigations() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		insert cases;
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Contact_Facility__c = 'MyNetwork';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;
		insert networks;
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		caseInvestigations[0].RecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName().get('StarTrack_MyNetwork').getRecordTypeId();
		insert caseInvestigations;
		List<CaseInvestigation__c> caseInvestigationsToSave = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);


		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyNetworkStarTrackCaseController.SaveResult saveResult = MyNetworkStarTrackCaseController.saveCaseInvestigations(caseInvestigationsToSave, 'Posting to Chatter feed');

		Test.stopTest();

		System.assertNotEquals(MyNetworkStarTrackCaseController.Status.SUCCESSFUL.name(), saveResult.status, 'Expected error creation of case investigation record');
	}

	/**
	 * Scenario: Testing to get the chatter feed items for save
	 */
	@IsTest
	private static void testGetChatterFeedItems() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		String stJson = '{"success":true,"id":' +'"'+ caseInvestigations[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
		List<Database.SaveResult> svResultList = new List<Database.SaveResult>{sr};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<FeedItem> feedItems = MyNetworkStarTrackCaseController.getChatterFeedItems(svResultList, 'Posting to chatter');

		Test.stopTest();

		System.assertEquals(1, feedItems.size(), 'Expected feed items to return');
		System.assertEquals(caseInvestigations[0].Id, feedItems[0].ParentId, 'Invalid parent id for the feed item');
		System.assertEquals('Posting to chatter', feedItems[0].Body, 'Invalid body for the feed item');
	}

	/**
	 * Scenario: Testing to get the critical incidents knowledge articles
	 */
	@IsTest
	private static void testGetCriticalIncidents() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, true);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';

		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector mockCriticalIncidentsSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCriticalIncidentsSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject())).thenReturn(new List<Knowledge__kav>{criticalIncidents[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<MyNetworkStarTrackCaseController.CriticalIncidentWrapper> ciWrapper = MyNetworkStarTrackCaseController.getCriticalIncidents();

		Test.stopTest();
		((KnowledgeArticleVersionsSelector)MockUtility.Mocks.verify(mockCriticalIncidentsSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject());
		System.assertNotEquals(null, ciWrapper, 'Expected critical incidents wrapper to return');
		System.assertEquals(1, ciWrapper[0].criticalIncidentList.size(), 'Expected critical incidents knowledge articles to return');

	}

	/**
	 * Scenario: Testing to set the StarTrack MyNetwork record type for case investigations
	 */
	@IsTest
	private static void testSetStarTrackRecordType() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		Id starTrackRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName().get(MyNetworkStarTrackCaseController.ST_MYNETWORK_RECORD_TYPE).getRecordTypeId();

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyNetworkStarTrackCaseController.setStarTrackRecordType(caseInvestigations);

		Test.stopTest();

		System.assertEquals(caseInvestigations[0].RecordTypeId, starTrackRecordTypeId, 'Expected StarTrack MyNetwork record type');

	}

	/**
	 * Scenario: Testing to get error message when case type is blank on case
	 */
	@IsTest
	private static void testGetCaseTypeBlankError() {

		// =====================================
		// Data Preparation
		// =====================================
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Case c = ApplicationTestDataFactory.getCases(1, true)[0];
		c.ReferenceID__c = consignment.ArticleID__c;
		c.ArticleTest__c = consignment.Id;

		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{c.Id => c});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyNetworkStarTrackCaseController.ArticleResponseWrapper wrapper = MyNetworkStarTrackCaseController.getArticlesByCase(c.Id);

		Test.stopTest();

		Assert.areEqual(true, wrapper.hasCaseTypeBlankOnCase, 'Expected true as case type is blank on case');
		Assert.isNull(wrapper.articleDetails, 'Expected article details as null as case type is blank');
	}

	/**
	 * Scenario: Testing to get networks related to postcode/suburb/locality
	 */
	@IsTest
	private static void testGetNetworksRelatedToPostcodeSuburb() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(3, true);
		networks[0].Org_ID__c = '1234';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;
		networks[0] = (Network__c)ApplicationTestDataFactory.setUnwritableFields(networks[0], new Map<String, Object>{'RecordType.DeveloperName' => 'Delivery'});
		networks[1].Org_ID__c = '4567';
		networks[1].Contact_Facility__c = 'MyNetwork';
		networks[1].Status__c = 'NULL';
		networks[1].Parcel__c = true;
		networks[1] = (Network__c)ApplicationTestDataFactory.setUnwritableFields(networks[1], new Map<String, Object>{'RecordType.DeveloperName' => 'Delivery'});
		networks[2].Org_ID__c = '1234';
		networks[2].Contact_Facility__c = 'MyNetwork';
		networks[2].Status__c = 'NULL';
		networks[2].Parcel__c = true;

		List<Postcode__c> postcodes = ApplicationTestDataFactory.getPostcodes(1, true);
		postcodes[0].Locality_Postcode_ID__c = '1234';

		List<PostcodeMapping__c> postcodeMappings = ApplicationTestDataFactory.getPostcodeMappings(1, postcodes[0].Id, networks[0].Id, true);
		postcodeMappings.addAll(ApplicationTestDataFactory.getPostcodeMappings(1, postcodes[0].Id, networks[1].Id, true));
		postcodeMappings[0] = (PostcodeMapping__c)ApplicationTestDataFactory.setUnwritableFields(postcodeMappings[0], new Map<String, Object>{'Network__r' => networks[0]});
		postcodeMappings[1] = (PostcodeMapping__c)ApplicationTestDataFactory.setUnwritableFields(postcodeMappings[1], new Map<String, Object>{'Network__r' => networks[1]});
		
		//associating postcode mappings with postcode.
		postcodes[0] = (Postcode__c)ApplicationTestDataFactory.setChildRelationships(postcodes[0], new Map<String, List<SObject>>{'Postcode_Mappings__r' => postcodeMappings}); 

		List<FacilityByPass__c> networkBypasses = ApplicationTestDataFactory.getNetworkBypasses(1, networks[0].Id, networks[2].Id, false);

		// =====================================
		// Stubbing
		// =====================================
		PostcodesSelector mockPostcodesSelector = (PostcodesSelector)MockUtility.mockSelector(PostcodesSelector.class);
		NetworksSelector mockNetworksSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class);
		NetworkBypassesSelector mockNetworkBypasssesSelector = (NetworkBypassesSelector)MockUtility.mockSelector(NetworkBypassesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPostcodesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(postcodes);
		MockUtility.Mocks.when(mockNetworkBypasssesSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkBypasses);
		MockUtility.Mocks.when(mockNetworksSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Network__c>{networks[1].Id => networks[1], networks[2].Id => networks[2]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<MyNetworkStarTrackCaseController.NetworkWrapper> wrapper = MyNetworkStarTrackCaseController.getNetworksRelatedToPostcodeSuburbLocality('Melbourne', '3000', '12345');

		Test.stopTest();

		// make sure that our search method was called
		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((PostcodesSelector)MockUtility.Mocks.verify(mockPostcodesSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		Assert.areEqual('3000', searchParams.get('postcodes'), 'Expected 3000 as postcodes searchParms');
		Assert.areEqual('Melbourne', searchParams.get('suburbs'), 'Expected Melbourne as suburbs searchParms');
		Assert.areEqual('12345', searchParams.get('localityIds'), 'Expected 12345 as localityIds searchParms');

		// verify Networks selector was called
		fflib_ArgumentCaptor networkIdsCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((NetworksSelector)MockUtility.Mocks.verify(mockNetworksSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)networkIdsCaptor.capture(), (Set<Object>)fflib_Match.anyObject());

		Set<Id> networkIdParams = (Set<Id>)networkIdsCaptor.getValue();
		Assert.areEqual(networks[0].Id, new List<Id>(networkIdParams)[0], 'Incorrect network id returned');
		Assert.areEqual(networks[2].Id, new List<Id>(networkIdParams)[2], 'Bypass network not added to the search selector');
		Assert.areEqual(2, wrapper.size(), 'Expected two network records to be returned');
	}

	/**
	 * Scenario: Testing to get Postcode record related to postcode/suburb
	 */
	@IsTest
	private static void testGetPostcode() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Postcode__c> postcodes = ApplicationTestDataFactory.getPostcodes(1, true);
		postcodes[0].Locality_Postcode_ID__c = '1234'; 

		// =====================================
		// Stubbing
		// =====================================
		PostcodesSelector mockPostcodesSelector = (PostcodesSelector)MockUtility.mockSelector(PostcodesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPostcodesSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(postcodes);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Postcode__c postcode = MyNetworkStarTrackCaseController.getPostcode('3000', 'Melbourne');

		Test.stopTest();

		// make sure that our search method was called
		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((PostcodesSelector)MockUtility.Mocks.verify(mockPostcodesSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		Assert.areEqual('3000', searchParams.get('postcodes'), 'Expected 3000 as postcodes searchParms');
		Assert.areEqual('Melbourne', searchParams.get('suburbs'), 'Expected Melbourne as suburbs searchParms');

		Assert.isNotNull(postcode, 'Expected postcode record to be returned');
		Assert.isNotNull(postcode.Locality_Postcode_ID__c, 'Expected Locality Id to be returned');
	}

	/**
	 * Scenario: Testing to get networks related to facility name
	 */
	@IsTest
	private static void testGetNetworksRelatedToFacilityName() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;
		networks[0].Contact_Facility__c = 'MyNetwork';
		networks[0].Name = 'Donnybrook DC';

		// =====================================
		// Stubbing
		// =====================================
		NetworksSelector mockNetworksSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockNetworksSelector.selectByNetworkNamePartial((String)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(networks);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<MyNetworkStarTrackCaseController.NetworkWrapper> wrapper = MyNetworkStarTrackCaseController.getNetworksRelatedToFacilityName('Don');

		Test.stopTest();

		// verify Networks selector was called
		fflib_ArgumentCaptor networkNameCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((NetworksSelector)MockUtility.Mocks.verify(mockNetworksSelector, MockUtility.Mocks.times(1))).selectByNetworkNamePartial((String)networkNameCaptor.capture(), (Set<Object>)fflib_Match.anyObject());

		String networkNameCaptured = (String) networkNameCaptor.getValue();
		Assert.areEqual('Don', networkNameCaptured, 'Incorrect network name returned');
		Assert.areEqual(1, wrapper.size(), 'Expected one network record to be returned');

	}

}