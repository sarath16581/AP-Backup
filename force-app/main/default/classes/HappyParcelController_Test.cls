/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tags Happy Parcel, SAP-EM, Tests, Tibco
 * @domain SSSW
 * @description Test Scenarios for Happy Parcel Controller
 * @changelog
 * 2020-09-23 - Disha Kariya - Updated to cover get Network Method.
 * 2020-10-07 - Disha Kariya - Added methods for SafeDropEligibilityService
 * 2020-10-28 - Disha Kariya - Added mocking for getting transient attributes for ETA details
 * 2024-05-17 - Seth Heang - Added test methods to cover async callout to .NET API for retrieving StarTrack consignment/article details and mapping
 * 2024-05-21 - Seth Heang - Added new test method to handle force consignment search
 * 2024-06-12 - Raghav Ravipati - Added new test method to cover getCriticalIncidents
 * 2024-06-17 - Raghav Ravipati - added mocks to EnquiryMappingsSelector
 * 2024-06-25 - Seth Heang - Added new assertion in testSearchAsyncStarTrack due to new attributes mapping such as EDD and SourceSystem
 * 2024-07-15 - Seth Heang - Added test methods to cover duplicate consignments scenario from .NET API Callout
 */
@IsTest
private class HappyParcelController_Test {
	@TestSetup
	private static void setup() {
		AusPostSettings__c oa = new AusPostSettings__c();
		oa.Password__c = 'testing';
		oa.Username__c = 'sssw_sts';
		oa.URL3__c = 'https://test.com/auth/token';
		oa.URL2__c = 'https://test/qac/pobLease/';
		oa.Name = 'SAPEMCustomerArticles';
		insert oa;

		AusPostSettings__c digitalRepoSettings = new AusPostSettings__c();
		digitalRepoSettings.URL__c = 'http://callout:test/documents';
		digitalRepoSettings.Name = 'DigitalRepositoryDocumentsAPIv2';
		insert digitalRepoSettings;

		DigitalRepositoryAPIV2Settings__c repositorySettings = new DigitalRepositoryAPIV2Settings__c();
		repositorySettings.Name = 'DefaultConfigurations';
		repositorySettings.BlurImage__c = false;
		repositorySettings.BucketName__c = 'DefaultBucket';
		repositorySettings.Default__c = true;
		repositorySettings.FileExtensionType__c = '.jpg';
		repositorySettings.ResizePercentage__c = 40;
		repositorySettings.ResizeThreshold__c = 1000;

		insert repositorySettings;
		StarTrack_Settings__c starTrackSetting = new StarTrack_Settings__c(
			Web_Service_Callout_Timeout__c = 45
		);
		insert starTrackSetting;

		Database.insert(new StarTrackConsignmentProductIDs__c(Name = '002'));
	}

	/**
	 * Scenario: Tests a request sent to query track events which returns a single article response
	 */
	@IsTest
	private static void testQueryTrackingApiSingleArticleWithSuccessfulResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// insert an entry into the clearview codes mapping table so we test the mappings
		List<MiniCaseFieldMapping__c> mappings = ApplicationTestDataFactoryCase.getEnquiryTypeMappings(false);
		mappings[0].mappingModel__c = 'Classic';
		mappings[0].SAPProductCategory__c = 'eParcel';
		mappings[0].ProductCategory__c = 'eParcel';
		mappings[0].SAPProductSubcategory__c = 'eParcel Standard';
		mappings[0].ProductSubcategory__c = 'eParcel - Standard';
		mappings[0].Type__c = 'General Enquiry';
		insert mappings;
		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService) MockUtility.mockUtility(TIBCOArticleService.class);
		EnquiryMappingsSelector enquirySelector = (EnquiryMappingsSelector) MockUtility.mockSelector(EnquiryMappingsSelector.class);
		List<String> trackingIds = new List<String>{ 'auysgdagsd' };
		AnswerSearchArticle mockSearchResult = new AnswerSearchArticle();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		// Database
		MockUtility.Mocks.when(enquirySelector.selectBySAPKeyAndMappingModel((Set<String>)fflib_Match.eq(new Set<String>{ 'eParceleParcel Standard' }), (Set<String>)fflib_Match.eq(new Set<String>{ 'Classic' })))
			.thenReturn(new List<MiniCaseFieldMapping__c>{mappings[0]});
		
		MockUtility.Mocks.when(mockArticleService.searchByArticleIdsInSAP((List<String>) fflib_Match.eqList(trackingIds))).thenAnswer(mockSearchResult);
		MockUtility.Mocks.when(mockArticleService.processTIBCOSearchResults(
				(List<String>) fflib_Match.eqList(trackingIds),
				(TIBCOSearchResult) fflib_Match.anyObject(),
				(Boolean)fflib_Match.eqBoolean(false),
				(Boolean)fflib_Match.eqBoolean(true)
		)).thenAnswer(mockSearchResult);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelController.TrackingResult result = HappyParcelController.queryTrackingApi('auysgdagsd', false, null);

		Test.stopTest();

		System.assertEquals(0, result.errors.size(), 'Expected no errors but instead received: ' + String.join(result.errors, '\n'));
		System.assertEquals(1, result.articles.size(), 'Expected articles but instead got nothing');
		System.assertEquals('auysgdagsd', result.articles[0].trackingId, 'Expected tracking id "auysgdagsd", but instead got: ' + result.articles[0].trackingId);
		System.assertEquals('eParcel', result.articles[0].caseProductCategory, 'Expected "eParcel" but instead got: ' + result.articles[0].caseProductCategory);
		System.assertEquals('eParcel - Standard', result.articles[0].caseProductSubCategory, 'Expected "eParcel - Standard" but instead got: ' + result.articles[0].caseProductSubCategory);
		System.assertEquals('General Enquiry', result.articles[0].caseTypeMapping, 'Expected "General Enquiry" but instead got: ' + result.articles[0].caseTypeMapping);
		System.assertEquals(3, result.articles[0].events.size(), 'Expected result size of 3');
		//((EnquiryMappingsSelector) MockUtility.Mocks.verify(enquirySelector, MockUtility.Mocks.times(1)))
		//	.selectBySAPKeyAndMappingModel((Set<String>) fflib_Match.eq(new Set<String>{ 'eParceleParcel Standard' }), (Set<String>) fflib_Match.eq(new Set<String>{ 'Classic' }));
	}

	/**
	 * Scenario: Tests a request sent to query track events which returns a consignment search response
	 */
	@IsTest
	private static void testQueryTrackingApiConsignmentWithSuccessfulResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService) MockUtility.mockUtility(TIBCOArticleService.class);

		List<String> trackingIds = new List<String>{ 'asjkd12jkjasjkd' };
		AnswerSearchArticle mockSearchResult = new AnswerSearchArticle();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleService.searchByArticleIdsInSAP((List<String>) fflib_Match.eqList(trackingIds))).thenAnswer(mockSearchResult);
		MockUtility.Mocks.when(mockArticleService.processTIBCOSearchResults(
				(List<String>) fflib_Match.eqList(trackingIds),
				(TIBCOSearchResult) fflib_Match.anyObject(),
				(Boolean)fflib_Match.eqBoolean(false),
				(Boolean)fflib_Match.eqBoolean(true)
		)).thenAnswer(mockSearchResult);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelController.TrackingResult result = HappyParcelController.queryTrackingApi('asjkd12jkjasjkd', false, null);

		Test.stopTest();

		System.assertEquals(0, result.errors.size(), 'Expected no errors but instead received: ' + String.join(result.errors, '\n'));
		System.assertEquals(1, result.articles.size(), 'Expected articles but instead got nothing');
		System.assertNotEquals(null, result.consignment, 'Expected a consignment to be returned but instead got nothing');
		System.assertEquals('asjkd12jkjasjkd', result.consignment.trackingId, 'Expected "asjkd12jkjasjkd" but instead got: ' + result.consignment.trackingId);
		System.assertEquals('auysgdagsd', result.articles[0].trackingId, 'Expected "auysgdagsd" but instead got: ' + result.articles[0].trackingId);
		System.assertEquals(3, result.articles[0].events.size(), 'Expected result size of 3 but instead got: ' + result.articles[0].events.size());
		// verify attribute mappings
		Assert.areEqual(102, result.consignment.article.ConsignmentParcelCount__c, 'Expected parcel count of 102 but instead got: ' + result.consignment.article.ConsignmentParcelCount__c);
		Assert.areEqual(true, result.consignment.article.SignatureRequiredFlag__c, 'Expected signature required as TRUE but instead got: ' + result.consignment.article.SignatureRequiredFlag__c);
		Assert.areEqual('eParcel', result.articles[0].article.ProductCategory__c, 'Expected "eParcel" but instead got: ' + result.articles[0].article.ProductCategory__c);
		Assert.areEqual('eParcel Standard', result.articles[0].article.SubProduct__c, 'Expected "eParcel Standard" but instead got: ' + result.articles[0].article.SubProduct__c);
		Assert.areEqual(
			'Send package to 111 Bourke St, Melbourne VIC 3000',
			result.consignment.article.DeliveryInstructions__c,
			'Expected "Send package to 111 Bourke St, Melbourne VIC 3000" but instead got: ' + result.consignment.article.DeliveryInstructions__c
		);
		Assert.areEqual('1 / 1', result.totalArticlesDelivered, 'Expected "1 / 1" but instead got: ' + result.totalArticlesDelivered);
	}

	/**
	 * Scenario: Testing to ensure correct configuration values are returned.
	 */
	@IsTest
	private static void testConfig() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Map<String, Object> config = HappyParcelController.loadConfig();

		System.assertNotEquals(null, config.get('articleFields'));
		System.assertNotEquals(0, ((List<HappyParcelController.FieldConfigItem>) config.get('articleFields')).size(), 'Expected some article fields');

		System.assertNotEquals(null, config.get('consignmentFields'));
		System.assertNotEquals(0, ((List<HappyParcelController.FieldConfigItem>) config.get('consignmentFields')).size(), 'Expected some consignment fields');

		System.assertNotEquals(null, config.get('eventMessageFields'));
		System.assertNotEquals(0, ((List<HappyParcelController.FieldConfigItem>) config.get('eventMessageFields')).size(), 'Expected some event message fields');

		System.assertNotEquals(null, config.get('eventMessageTypeDefinitions'));
		System.assertNotEquals(0, ((Map<String, List<EventMessageTypeMapping__mdt>>) config.get('eventMessageTypeDefinitions')).size(), 'Expected event message type definitions');

		System.assertNotEquals(null, config.get('articleTypes'));
		System.assertNotEquals(0, ((Map<String, ArticleTypeMapping__mdt>) config.get('articleTypes')).size(), 'Expected article type definitions');

		System.assertNotEquals(null, config.get('eventMessageOverflowFields'));
		System.assertNotEquals(0, ((List<HappyParcelController.FieldConfigItem>) config.get('eventMessageOverflowFields')).size(), 'Expected some event message overflow fields');
		System.assertNotEquals(null, config.get('eventMessageFeaturedOverflowFields'));
		System.assertNotEquals(0, ((List<HappyParcelController.FieldConfigItem>) config.get('eventMessageFeaturedOverflowFields')).size(), 'Expected some event message overflow fields');
	}

	/**
	 *	Scenario: Api call to Safe Drop is made and returns a successful response.
	 */
	@IsTest
	private static void testRetrieveSafeDropImageSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		Continuation cont = (Continuation) HappyParcelController.getArticleImage('TEST', 'ARTICLE_IMAGE_TO_X');

		// setup the continuation mock provider
		String requestLabel = new List<String>(cont.getRequests().keySet())[0];
		DigitalRepositoryService_Test.setSuccessContinuationResponse(requestLabel);
		DigitalRepositoryService.DocumentApiResponse response = (DigitalRepositoryService.DocumentApiResponse) HappyParcelController.safeDropImageCallback(new List<String>{ requestLabel }, null);

		Test.stopTest();

		System.assertEquals(false, response.isError, 'Expected no errors but instead got: ' + JSON.serialize(response));
		System.assertNotEquals('', response.getDocumentContent(), 'Expected en image body but instead got nothing');
	}

	/**
	 *	Scenario: Api call to Safe Drop is made and returns a successful response.
	 */
	@IsTest
	private static void testRetrieveSafeDropImageFailedResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		Continuation cont = (Continuation) HappyParcelController.getArticleImage('TEST', 'ARTICLE_IMAGE_TO_X');

		// setup the continuation mock provider
		String requestLabel = new List<String>(cont.getRequests().keySet())[0];
		DigitalRepositoryService_Test.setErrorContinuationResponse(requestLabel);
		DigitalRepositoryService.DocumentApiResponse response = (DigitalRepositoryService.DocumentApiResponse) HappyParcelController.safeDropImageCallback(new List<String>{ requestLabel }, null);

		Test.stopTest();

		System.assertEquals(true, response.isError, 'Expected an error but instead got: ' + JSON.serialize(response));
		System.assertNotEquals('', response.getErrorMessage(), 'Expected an error message but instead got: ' + JSON.serialize(response));
		System.assertEquals(null, response.document, 'Expected no image body but instead got: ' + JSON.serialize(response));
	}

	/**
	 *	Scenario: Network Search based on WCC
	 */
	@IsTest
	private static void testNetworkSearchSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c network = ApplicationTestDataFactory.getNetworks(1, true)[0];
		network.Org_ID__c = '12345';

		// =====================================
		// Stubbing
		// =====================================
		NetworksSelector mockSelector = (NetworksSelector) MockUtility.mockSelector(NetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByOrgId((Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Network__c>{ network.Id => network });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		HappyParcelController.NetworkDetailsWrapper result = HappyParcelController.getNetwork('12345');
		Test.stopTest();

		System.assertNotEquals(null, result.network, 'Expected a network but instead got error.');
	}

	/**
	 *	Scenario: get critical incidents based on the network org Id
	 */
	@IsTest
	private static void testGetCriticalIncidents() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(2, false);
		criticalIncidents[0].networkOrgId__c = '12345';
		
		insert criticalIncidents;
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('recordTypeNames', new Set<String>{ 'Critical_Incident' });
		searchParams.put('IsLatestVersion', true);
		searchParams.put('statuses', new Set<String>{ 'Online' });
		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>)fflib_Match.eq(searchParams), (Boolean)fflib_Match.eq(true)))
			.thenReturn(criticalIncidents);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(HappyParcelController.getCriticalIncidents());
		List<Object> resultLst = (List<Object>) result.get('12345');
		Set<Id> criticalIncidentIds = new Set<Id>();
		for(Object obj : resultLst){
			Map<String, Object> knowledgeMap = (Map<String, Object>)obj;
			criticalIncidentIds.add((Id) knowledgeMap.get('Id'));
		}
		Test.stopTest();
		((KnowledgeArticleVersionsSelector)MockUtility.Mocks.verify(kavSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.eq(searchParams), (Boolean)fflib_Match.eq(true));
		System.assertEquals(1, result.Values().size(), 'Map updated with network ids and knowledge articles');
		System.assert(criticalIncidentIds.contains(criticalIncidents[0].Id), 'one record matches with the given network org Id');
	}

	/**
	 *	Scenario: Network Search based on WCC
	 */
	@IsTest
	private static void testNetworkSearchErrorResponseIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c network = ApplicationTestDataFactory.getNetworks(1, false)[0];
		network.Org_ID__c = '12355';
		insert network;

		// =====================================
		// Stubbing
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		HappyParcelController.NetworkDetailsWrapper result = HappyParcelController.getNetwork('12345');
		Test.stopTest();

		System.assertEquals(null, result.network, 'Expected no network found.');
		System.assertNotEquals('', result.error, 'Expected an error.');
	}

	/**
	 *	Scenario: Get delivery proof pdf content for download
	 */
	@IsTest
	private static void testGetDeliveryProofPdfBlobResponses() {
		// =====================================
		// Data Preparation
		// =====================================
		//None!

		// =====================================
		// Stubbing
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String result = HappyParcelController.getDeliveryProofPdfBlob('HJJKJ5465ELIGIBLE');
		Test.stopTest();

		System.assertEquals(EncodingUtil.base64Decode(result), Blob.valueOf('Test'), 'The pdf content in test scenario');
	}
	/**
	 *	Scenario: Get safe drop eligibility status
	 */
	@IsTest
	private static void testGetSafeDropEligibilityStatusResponses() {
		// =====================================
		// Data Preparation
		// =====================================
		//None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new SafeDropEligibilityService_Test.MyPostHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SafeDropEligibilityService.EligibilityResponse result = HappyParcelController.getSafeDropStatus('HJJKJ5465ELIGIBLE');
		Test.stopTest();

		System.assertEquals(true, result.status.showStatus, 'Show status should be true');
		System.assertEquals(true, result.status.isSafeDropSettable, 'Safe drop settable is true for eligible articles.');
		System.assertEquals('Eligible', result.status.statusValue, 'Safe drop status is Eligible');
	}

	/**
	 *	Scenario: Submit safe drop eligibility
	 */
	@IsTest
	private static void testSubmitSafeDropEligibilityStatusResponses() {
		// =====================================
		// Data Preparation
		// =====================================
		//None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new SafeDropEligibilityService_Test.MyPostHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String result = HappyParcelController.setSafeDropToEligible('HJJKJ5465SET');
		Test.stopTest();

		System.assertEquals('Submitted successfully.', result, 'Show status should be true');
	}

	/**
	 *	Scenario: Delete safe drop eligibility
	 */
	@IsTest
	private static void testDeleteSafeDropEligibilityStatusResponses() {
		// =====================================
		// Data Preparation
		// =====================================
		//None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new SafeDropEligibilityService_Test.MyPostHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String result = HappyParcelController.unsetSafeDropEligibility('HJJKJ5465UNSET');
		Test.stopTest();

		System.assertEquals('Submitted successfully.', result, 'Show status should be true');
	}

	public class AnswerSearchArticle implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			TIBCOSearchResult searchResult = new TIBCOSearchResult();
			List<String> trackingIds = (List<String>) invocation.getArgument(0);

			if (trackingIds[0] == 'auysgdagsd') {
				searchResult.success = true;
				searchResult.trackResults = new List<TIBCOTrackingResultWrapper>();

				AuspostQueryTrackEventsSchema.TrackingResults tr1 = new AuspostQueryTrackEventsSchema.TrackingResults();
				tr1.ArticleDetails = TIBCO_Test.createArticleDetailElement();

				TIBCOTrackingResultWrapper testWrapper = new TIBCOTrackingResultWrapper(tr1);
				testWrapper.returnCode = 'ESB-BUS-DATA-100';
				searchResult.trackResults.add(testWrapper);
			} else if (trackingIds[0] == 'asjkd12jkjasjkd') {
				searchResult.success = true;
				searchResult.trackResults = new List<TIBCOTrackingResultWrapper>();

				AuspostQueryTrackEventsSchema.TrackingResults tr2 = new AuspostQueryTrackEventsSchema.TrackingResults();
				tr2.ConsignmentDetails = TIBCO_Test.createConsignmentElement();
				tr2.ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope = new List<AuspostQueryTrackEventsSchema.ArticleEnvelope>{ TIBCO_Test.createArticleEnvelope() };
				TIBCOTrackingResultWrapper testWrapper3 = new TIBCOTrackingResultWrapper(tr2);
				testWrapper3.returnCode = 'ESB-BUS-DATA-100';

				searchResult.trackResults.add(testWrapper3);
			}
			return searchResult;
		}
	}

	/**
	 * Scenario: Testing to ensure distance between the locations are returned.
	 */
	@IsTest
	private static void testGetDistanceBetweenLocations() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		Double distance = HappyParcelController.getDistanceBetweenLocations(28.635308, 77.22496, 37.7749295, -122.4194155);

		Test.stopTest();

		System.assertEquals(12352.481223068238, distance, 'Incorrect distance between locations');
	}

	/**
	 * Test: When the SAP callout is made for an article which has a parent consignment, and a forceConsignmentSearch flag is set to TRUE,
	 *		validate that additional callout is made using the consignment ID and the response returns consignment details including all related article details
	 */
	@IsTest
	private static void testForceConsignmentSearchWhenSearchingArticleId() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		String articleId = 'auysgdagsd';
		String parentConsignmentId = 'asjkd12jkjasjkd';
		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService) MockUtility.mockUtility(TIBCOArticleService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleService.searchByArticleIdsInSAP((List<String>) fflib_Match.anyList())).thenAnswer(new AnswerSearchArticle());
		MockUtility.Mocks.when(
				mockArticleService.search((List<String>) fflib_Match.anyList(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean())
			)
			.thenAnswer(new AnswerSearchArticle());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelController.TrackingResult searchResult = HappyParcelController.queryTrackingApi(articleId, true, null);
		Test.stopTest();


		Assert.areNotEqual(null, searchResult.consignment, 'Consignment data should not be null');
		Assert.areEqual(0, searchResult.errors.size(), 'There should be no errors');
		Assert.areNotEqual(null, searchResult.consignment.article, 'Child Article should not be empty');
		Assert.areEqual(parentConsignmentId, searchResult.consignment.trackingId, 'Tracking Id searched should match parent consignment Id');
		Assert.areEqual(articleId, searchResult.articles[0].trackingId, 'Article Tracking Id should match initial tracking Id');
	}

	/**
	 * Test: When the SAP callout is made and a consignment record is dml inserted,
	 *		validate that the StarTrack async callout can be made and relevant attributes are mapped and updated on the same article that inserted in SAP callout
	 */
	@IsTest
	static void testSearchAsyncStarTrack() {
		String trackingId = '2AT71923';
		// Assume that SAP callout is made, and a consignment record has been inserted
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];
		insert consignment;

		// Prepare wrapper class to pass to the StarTrack Callout
		HappyParcelController.TrackingArticle trackingResult = (HappyParcelController.TrackingArticle) System.JSON.deserialize(
			HappyParcelService_Test.getTrackingArticleOnlyMock(),
			HappyParcelController.TrackingArticle.class
		);
		trackingResult.article.Id = consignment.Id;
		trackingResult.article.ArticleID__c = trackingId;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// make async callout to StarTrack dotNet API
		Continuation conti = (Continuation) HappyParcelController.queryTrackingApiForStarTrack(trackingId, JSON.serialize(trackingResult));
		// Verify that the continuation has the proper requests
		Map<String, HttpRequest> requests = conti.getRequests();
		System.assertEquals(requests.size(), 1);

		// Prepare mock response
		HttpResponse response = new HttpResponse();
		response.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());

		// Set the fake response for the continuation
		String requestLabel = requests.keyset().iterator().next();
		Test.setContinuationResponse(requestLabel, response);

		// Invoke callback method
		Object result = Test.invokeContinuationMethod(new HappyParcelController(), conti);
		Test.stopTest();

		Assert.areNotEqual(null, result, 'StarTrack callout result should not be null');
		// Verify the return wrapper class has the new attributes mapped correctly
		HappyParcelController.TrackingArticle resultWrapper = (HappyParcelController.TrackingArticle) result;
		Assert.areEqual('D05 1, E05 1', resultWrapper.article.FurtherReferences__c, 'Further References do not match');
		Assert.areEqual(Date.newInstance(2024,1,21), resultWrapper.article.ExpectedDeliveryDate__c, 'Expected Delivery Date should match but was not');
		Assert.areEqual('TEAM', resultWrapper.article.Source_System__c, 'Source System should be TEAM but instead was ' + resultWrapper.article.Source_System__c);

		// Verify that the consignment record of type Article__c has been updated 1 time
		fflib_ArgumentCaptor updatableConsignmentCaptor = fflib_ArgumentCaptor.forClass(List<Article__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) updatableConsignmentCaptor.capture());

		// Verify that the consignment records has the new attributes mapped and updated correctly
		List<Article__c> resArticle = (List<Article__c>) updatableConsignmentCaptor.getValue();
		Assert.areEqual(1, resArticle.size(), 'Only one article should be updated and returned back');
		Assert.areEqual('D05 1, E05 1', resArticle.get(0).FurtherReferences__c, 'Further References do not match');
		Assert.areEqual(Date.newInstance(2024,1,21), resArticle.get(0).ExpectedDeliveryDate__c, 'Expected Delivery Date should match but was not');
		Assert.areEqual('TEAM', resArticle.get(0).Source_System__c, 'Source System should be TEAM but instead was ' + resArticle.get(0).Source_System__c);
	}

	/**
	 * Test: When the SAP callout is made and a TIBCOSearchResult is returned,
	 *		validate that the requireAdditionalQueryForStarTrack is set to TRUE if the productId belongs to StarTrack ProductID
	 */
	@IsTest
	static void testRequireAdditionalStarTrackCalloutFlag() {
		TIBCOSearchResult trackingResult = (TIBCOSearchResult) System.JSON.deserialize(HappyParcelService_Test.getTrackingResultMock(), TIBCOSearchResult.class);
		trackingResult.trackResults.get(0).consignmentDetails.articles.get(0).proxyArticle.ProductID__c = '002'; // StarTrack productId
		// =====================================
		// Stubbing
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		HappyParcelController.TrackingResult result = new HappyParcelController.TrackingResult(trackingResult);
		Test.stopTest();
		Assert.areEqual(result.requireAdditionalQueryForStarTrack, true, 'Additional query flag should be true');
	}

	/**
	 * Test: When the .NET callout returns duplicate consignment
	 *		validate that an additional callout is made when below criteria is met:
	 *		- a single consignment is returned after filtering older than 6 months consignments
	 */
	@IsTest
	static void testSearchAsyncStarTrackWithDuplicatesButOneConsignmentIsValid() {
		String trackingId = '2AT71923';
		// Assume that SAP callout is made, and a consignment record has been inserted
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];
		insert consignment;

		// Prepare wrapper class to pass to the StarTrack Callout
		HappyParcelController.TrackingArticle trackingResult = (HappyParcelController.TrackingArticle) System.JSON.deserialize(
				HappyParcelService_Test.getTrackingArticleOnlyMock(),
				HappyParcelController.TrackingArticle.class
		);
		trackingResult.article.Id = consignment.Id;
		trackingResult.article.ArticleID__c = trackingId;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// make async callout to StarTrack dotNet API
		Continuation conti = (Continuation) HappyParcelController.queryTrackingApiForStarTrack(trackingId, JSON.serialize(trackingResult));
		// Verify that the continuation has the proper requests
		Map<String, HttpRequest> requests = conti.getRequests();
		System.assertEquals(requests.size(), 1);

		// Prepare mock responses
		HttpResponse response1 = new HttpResponse();
		response1.setBody(StarTrackContinuationCalloutMock.getResponse_multiConsignWithOneConsignmentWithinLast6Months());
		// Prepare mock response
		HttpResponse response2 = new HttpResponse();
		response2.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());

		// Set the mock first response for the continuation
		Test.setContinuationResponse(requests.keyset().iterator().next(), response1);
		// Invoke the first continuation method
		Continuation conChained = (Continuation) Test.invokeContinuationMethod(new HappyParcelController(), conti);

		// Set the mock second response for the chained continuation
		requests = conChained.getRequests();
		Test.setContinuationResponse(requests.keyset().iterator().next(), response2);
		// Invoke the second continuation method
		Object result = Test.invokeContinuationMethod(
				new HappyParcelController(),
				conChained
		);
		Test.stopTest();

		Assert.areNotEqual(null, result, 'StarTrack callout result should not be null');
		// Verify the return wrapper class has the new attributes mapped correctly
		HappyParcelController.TrackingArticle resultWrapper = (HappyParcelController.TrackingArticle) result;
		Assert.areEqual('D05 1, E05 1', resultWrapper.article.FurtherReferences__c, 'Further References do not match');
		Assert.areEqual(Date.newInstance(2024,1,21), resultWrapper.article.ExpectedDeliveryDate__c, 'Expected Delivery Date should match but was not');
		Assert.areEqual('TEAM', resultWrapper.article.Source_System__c, 'Source System should be TEAM but instead was ' + resultWrapper.article.Source_System__c);

		// Verify that the consignment record of type Article__c has been updated 1 time
		fflib_ArgumentCaptor updatableConsignmentCaptor = fflib_ArgumentCaptor.forClass(List<Article__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) updatableConsignmentCaptor.capture());

		// Verify that the consignment records has the new attributes mapped and updated correctly
		List<Article__c> resArticle = (List<Article__c>) updatableConsignmentCaptor.getValue();
		Assert.areEqual(1, resArticle.size(), 'Only one article should be updated and returned back');
		Assert.areEqual('D05 1, E05 1', resArticle.get(0).FurtherReferences__c, 'Further References do not match');
		Assert.areEqual(Date.newInstance(2024,1,21), resArticle.get(0).ExpectedDeliveryDate__c, 'Expected Delivery Date should match but was not');
		Assert.areEqual('TEAM', resArticle.get(0).Source_System__c, 'Source System should be TEAM but instead was ' + resArticle.get(0).Source_System__c);

	}

	/**
	 * Test: When the .NET callout returns duplicate consignment
	 *		validate that a warning message is displayed if:
	 *		- all consignment are within 6 month period
	 */
	@IsTest
	static void testSearchAsyncStarTrackWithDuplicatesAndAllAreInvalid() {
		String trackingId = '2AT71923';
		// Assume that SAP callout is made, and a consignment record has been inserted
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];
		insert consignment;

		// Prepare wrapper class to pass to the StarTrack Callout
		HappyParcelController.TrackingArticle trackingResult = (HappyParcelController.TrackingArticle) System.JSON.deserialize(
				HappyParcelService_Test.getTrackingArticleOnlyMock(),
				HappyParcelController.TrackingArticle.class
		);
		trackingResult.article.Id = consignment.Id;
		trackingResult.article.ArticleID__c = trackingId;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// make async callout to StarTrack dotNet API
		Continuation conti = (Continuation) HappyParcelController.queryTrackingApiForStarTrack(trackingId, JSON.serialize(trackingResult));
		// Verify that the continuation has the proper requests
		Map<String, HttpRequest> requests = conti.getRequests();
		System.assertEquals(requests.size(), 1);

		// Prepare mock response
		HttpResponse response = new HttpResponse();
		response.setBody(StarTrackContinuationCalloutMock.getResponse_multiConsignWhereAllConsignmentsWithinLast6Months());

		// Set the fake response for the continuation
		String requestLabel = requests.keyset().iterator().next();
		Test.setContinuationResponse(requestLabel, response);

		// Invoke callback method
		Object result = Test.invokeContinuationMethod(new HappyParcelController(), conti);
		Test.stopTest();

		// Assert that no DML update has been commited
		fflib_ArgumentCaptor updatableConsignmentCaptor = fflib_ArgumentCaptor.forClass(List<Article__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>) updatableConsignmentCaptor.capture());

		// Assert warning messages
		HappyParcelController.TrackingArticle resultWrapper = (HappyParcelController.TrackingArticle) result;
		Assert.areNotEqual(null, resultWrapper.warningMessages, 'Expected warning message to be populated but instead got null');
		Assert.areNotEqual(0, resultWrapper.warningMessages.size(), 'Expected a single warning message but instead got ' + resultWrapper.warningMessages.size());
		Assert.areEqual(System.Label.HappyParcelNETDuplicateConsignmentWarningText, resultWrapper.warningMessages.get(0), 'Expected warning message to match custom label but instead of ' + resultWrapper.warningMessages.get(0));
	}
}