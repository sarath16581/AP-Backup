/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Tests
 * @tag Controller
 * @tag ICPS Service
 * @domain ICPS
 * @description Test class for ICPSServiceController
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
@IsTest
private class ICPSServiceController_Test {
	/**
	* Test:
	*  Ensures that 'getICPSCases' returns based on the search parameters passed in.
	*/
	@IsTest
	public static void testGetICPSCases() {
		// =====================================
		// Data Preparation
		// =====================================
		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(2, true);

		// =====================================
		// Stubbing
		// =====================================
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.search((Map<String, String>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(icpsList);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Map<String, String> searchParams = new Map<String, String>();
		searchParams.put('reference', '8888');
		searchParams.put('recipient_name', 'recipient name');

		Test.startTest();
		List<ICPS__c> icps = ICPSServiceController.getICPSCases(searchParams, true);
		System.assertEquals(2, icps.size(), 'Expected 2 found');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that cloned record is returned on successful clone.
	*/
	@IsTest
	public static void testCloneICPS() {
		// =====================================
		// Data Preparation
		// =====================================
		ICPS__c icps = ICPSTestDataFactory.getICPS(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ICPS__c>{icps});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// Test normal clone
		ICPS__c clonedICPS = ICPSServiceController.cloneICPS(icps.Id);

		Test.stopTest();

		System.assert(clonedICPS != null, 'Expected ICPS cloned');
		System.assertNotEquals(icps.Id, clonedICPS.Id, 'Expected ids to be different');
	}

	/**
	* Test:
	*  Ensures that an exception is thrown on dml error inserting cloned record.
	*/
	@IsTest
	public static void testCloneICPSOnDMLError() {
		// =====================================
		// Data Preparation
		// =====================================
		ICPS__c icps = ICPSTestDataFactory.getICPS(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ICPS__c>{icps});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			ICPSServiceController.cloneICPS(icps.Id);
			System.assert(false, 'Expected an exception to be thrown - but was not thrown.');
		} catch (Exception ex) {
			//expected
		}
		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that search ICPS and upserting ICPS articles are working as expected.
	*/
	@IsTest
	public static void testGetSearchAndAddICPSArticles() {
		// =====================================
		// Data Preparation
		// =====================================
		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(1, true);
		List<ICPSArticle__c> articles = ICPSTestDataFactory.getICPSArticles(icpsList[0].Id, 2, true);

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleService.search((List<String>)fflib_Match.anyList(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean())).thenAnswer(new AnswerSearchArticle());
		MockUtility.Mocks.when(mockSelector.selectById((set<Id>) fflib_Match.anyObject(), (set<Object>) fflib_Match.anyObject())).thenReturn(icpsList);
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>)fflib_Match.anyObject(), (SObjectField)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPS__c icps = ICPSServiceController.getICPSWithArticles(icpsList[0].Id);
		System.assert(icps != null, 'Expected ICPS found');

		ICPSServiceController.ICPSArticleTrackingResult searchResult = ICPSServiceController.searchICPSArticlesInSAP('auysgdagsd');

		System.assertEquals(1, searchResult.errors.size(), 'Expected errors received');
		System.assertEquals(3, searchResult.articles.size(), 'Expected 3 article received');

		try {
			ICPSServiceController.saveArticles(articles, icpsList[0]);
		} catch (Exception e) {
			System.assert(!String.isEmpty(e.getMessage()), 'Expected invalid ICPS Id exception caught');
		}

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that print label returns expected PDF stream
	*/
	@IsTest
	public static void testPrintLabel() {
		// =====================================
		// Data Preparation
		// =====================================
		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(1, true);

		// =====================================
		// Stubbing
		// =====================================
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);
		ICPSService service = (ICPSService)MockUtility.mockUtility(ICPSService.class);
		String mockStream = 'JVBERi0xLjcKCjEgMCBvYmogICUgZW50cnkgcG9pbnQKPDwKICAvVHlwZSAvQ2F0YWxvZwogIC9QYWdlcyAyIDAgUgo+PgplbmRvYmoKCjIgMCBvYmoKPDwKICAvVHlwZSAvUGFnZXMKICAvTWVkaWFCb3ggWyAwIDAgMjAwIDIwMCBdCiAgL0NvdW50IDEKICAvS2lkcyBbIDMgMCBSIF0KPj4KZW5kb2JqCgozIDAgb2JqCjw8CiAgL1R5cGUgL1BhZ2UKICAvUGFyZW50IDIgMCBSCiAgL1Jlc291cmNlcyA8PAogICAgL0ZvbnQgPDwKICAgICAgL0YxIDQgMCBSIAogICAgPj4KICA+PgogIC9Db250ZW50cyA1IDAgUgo+PgplbmRvYmoKCjQgMCBvYmoKPDwKICAvVHlwZSAvRm9udAogIC9TdWJ0eXBlIC9UeXBlMQogIC9CYXNlRm9udCAvVGltZXMtUm9tYW4KPj4KZW5kb2JqCgo1IDAgb2JqICAlIHBhZ2UgY29udGVudAo8PAogIC9MZW5ndGggNDQKPj4Kc3RyZWFtCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8sIHdvcmxkISkgVGoKRVQKZW5kc3RyZWFtCmVuZG9iagoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4gCjAwMDAwMDAwNzkgMDAwMDAgbiAKMDAwMDAwMDE3MyAwMDAwMCBuIAowMDAwMDAwMzAxIDAwMDAwIG4gCjAwMDAwMDAzODAgMDAwMDAgbiAKdHJhaWxlcgo8PAogIC9TaXplIDYKICAvUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKNDkyCiUlRU9G';

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((set<Id>) fflib_Match.anyObject())).thenReturn(icpsList);
		MockUtility.Mocks.when(service.retrieveBase64Labels((ICPS__c)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenReturn(mockStream);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPSServiceController.LabelPrintDetail detail = ICPSServiceController.printLabel(icpsList[0].Id);
		Test.stopTest();

		System.assertEquals(mockStream, detail.pdfStream);
	}

	public class AnswerSearchArticle implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			TIBCOSearchResult searchResult = new TIBCOSearchResult();
			List<String> trackingIds = (List<String>)invocation.getArgument(0);

			if(trackingIds[0] == 'auysgdagsd') {
				searchResult.success = true;
				searchResult.trackResults = new List<TIBCOTrackingResultWrapper>();

				AuspostQueryTrackEventsSchema.TrackingResults tr1 = new AuspostQueryTrackEventsSchema.TrackingResults();
				tr1.ArticleDetails = TIBCO_Test.createArticleDetailElement();
				TIBCOTrackingResultWrapper testWrapper = new TIBCOTrackingResultWrapper(tr1);
				testWrapper.returnCode = 'ESB-BUS-DATA-100';

				AuspostMailProductSchema.ArticleContentsItemType acit = new AuspostMailProductSchema.ArticleContentsItemType();
				acit.Description = 'test';
				acit.Value = '1';
				acit.Weight = '1';
				TIBCOArticleWrapper.ArticleContentItem contentItem = new TIBCOArticleWrapper.ArticleContentItem(acit);
				testWrapper.articleDetails.transientAttributes.contentItems = new List<TIBCOArticleWrapper.ArticleContentItem>{contentItem};
				searchResult.trackResults.add(testWrapper);

				AuspostQueryTrackEventsSchema.TrackingResults tr2 = new AuspostQueryTrackEventsSchema.TrackingResults();
				TIBCOTrackingResultWrapper testWrapper2 = new TIBCOTrackingResultWrapper(tr2);
				testWrapper2.returnCode = 'ESB-BUS-DATA-101';
				testWrapper2.resultDescription = 'error';
				searchResult.trackResults.add(testWrapper2);

				AuspostQueryTrackEventsSchema.TrackingResults tr3 = new AuspostQueryTrackEventsSchema.TrackingResults();
				tr3.ConsignmentDetails = TIBCO_Test.createConsignmentElement();
				TIBCOTrackingResultWrapper testWrapper3 = new TIBCOTrackingResultWrapper(tr3);
				testWrapper3.returnCode = 'ESB-BUS-DATA-100';
				searchResult.trackResults.add(testWrapper3);

			} else if(trackingIds[0] == 'asjkd12jkjasjkd') {
				searchResult.success = false;
				searchResult.trackResults = new List<TIBCOTrackingResultWrapper>();

				AuspostQueryTrackEventsSchema.TrackingResults tr1 = new AuspostQueryTrackEventsSchema.TrackingResults();
				tr1.ArticleDetails = TIBCO_Test.createArticleDetailElement();
				TIBCOTrackingResultWrapper testWrapper = new TIBCOTrackingResultWrapper(tr1);
				testWrapper.returnCode = 'ESB-BUS-DATA-100';
				searchResult.trackResults.add(testWrapper);
			}

			return searchResult;
		}
	}

	private class MockException extends Exception {}
}