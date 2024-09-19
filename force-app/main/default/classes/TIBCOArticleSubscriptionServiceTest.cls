/**
 * @description Test class covering TIBCOArticleSubscriptionService
 * @changelog
 * 2024-09-12 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
public class TIBCOArticleSubscriptionServiceTest {

	/**
	 * Test Article Subscription with successful acknowledgement from TIBCO
	 * And Verify that Article__c.Subscribed flag is updated to true
	 * And Verify that no ExceptionLog__c is inserted
	 */
	@IsTest
	static void testArticleSubscriptionWithSuccessfulAcknowledgement(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Article__c article = ApplicationTestDataFactory.getArticles(1, consignment.Id, true)[0];
		article.Subscribed__c = false;
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, article.Id, true);
		impactedArticles[0] = (ImpactedArticle__c)ApplicationTestDataFactory.setUnwritableFields(
				impactedArticles[0],
				new Map<String, Object>{
						'Case__r' => caseTest,
						'Article__r' => article
				}
		);

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(WebServiceMock.class, new ArticleSubscriptionToSAPMockResponse(true));
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		TIBCOArticleSubscriptionService.newInstance().sendArticleSubscriptionNotifications(impactedArticles);
		Test.stopTest();

		// No ExceptionLog__c should be created
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<ExceptionLog__c>) fflib_Match.anyObject());

		// Assert updated impacted article
		fflib_ArgumentCaptor updatableSObjectCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) updatableSObjectCaptor.capture());
		List<SObject> updatableSObjects = new List<SObject>();
		for (Object objList : (List<Object>) updatableSObjectCaptor.getAllValues()) {
			updatableSObjects.addAll((List<SObject>) objList);
		}
		Article__c resultArticle;
		ImpactedArticle__c resultImpactedArticle;
		for (SObject obj : updatableSObjects) {
			if (obj instanceof Article__c) {
				resultArticle = (Article__c) obj;
			} else if (obj instanceof ImpactedArticle__c) {
				resultImpactedArticle = (ImpactedArticle__c) obj;
			}
		}

		Assert.isNotNull(resultArticle, 'Expected an update DML for article');
		Assert.areEqual(article.Id, resultArticle.Id, 'Impacted Article Ids should match but instead got: ' + resultArticle.Id);
		Assert.isTrue(resultArticle.Subscribed__c, 'Subscribed__c should be true but instead got: ' + resultArticle.Subscribed__c);


		Assert.isNotNull(resultImpactedArticle, 'Expected an update DML for impacted article');
		Assert.areEqual(impactedArticles[0].Id, resultImpactedArticle.Id, 'Impacted Article Ids should match but instead got: ' + resultImpactedArticle.Id);
		Assert.isTrue(resultImpactedArticle.Subscribed__c, 'Subscribed__c should be true but instead got: ' + resultImpactedArticle.Subscribed__c);
	}

	/**
	 * Test Article Subscription with failed acknowledgement from TIBCO
	 * And Verify that ImpactedArticle is updated with appropriate error message
	 * And Verify that ExceptionLog__c is inserted
	 */
	@IsTest
	static void testArticleSubscriptionWithFailedAcknowledgement(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Article__c article = ApplicationTestDataFactory.getArticles(1, consignment.Id, true)[0];
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, article.Id, true);
		impactedArticles[0] = (ImpactedArticle__c)ApplicationTestDataFactory.setUnwritableFields(impactedArticles[0], new Map<String, Object>{'Case__r' => caseTest});

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(WebServiceMock.class, new ArticleSubscriptionToSAPMockResponse(false));
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		TIBCOArticleSubscriptionService.newInstance().sendArticleSubscriptionNotifications(impactedArticles);
		Test.stopTest();

		// Assert on updated exception logs
		fflib_ArgumentCaptor updatableImpactedArticleCaptor = fflib_ArgumentCaptor.forClass(List<ImpactedArticle__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<ImpactedArticle__c>) updatableImpactedArticleCaptor.capture());
		List<ImpactedArticle__c> updatableImpactArticles = (List<ImpactedArticle__c>) updatableImpactedArticleCaptor.getValue();

		Assert.isNotNull(updatableImpactArticles[0], 'Expected an update DML for Article__c');
		Assert.isNotNull(updatableImpactArticles[0].SubscriptionErrorCode__c, 'SubscriptionErrorCode__c should not be null');
		Assert.areEqual(TIBCOArticleSubscriptionService.ARTICLE_SUBSCRIPTION_FAILURE, updatableImpactArticles[0].SubscriptionErrorCode__c, 'Expected error message to match but instead got: ' + updatableImpactArticles[0].SubscriptionErrorCode__c);

		// Assert on new exception logs
		fflib_ArgumentCaptor insertabledExceptionLogsCaptor = fflib_ArgumentCaptor.forClass(List<ExceptionLog__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<ExceptionLog__c>) insertabledExceptionLogsCaptor.capture(), fflib_Match.anyBoolean());
		List<ExceptionLog__c> insertabledExceptionLogs = (List<ExceptionLog__c>) insertabledExceptionLogsCaptor.getValue();

		Assert.isNotNull(insertabledExceptionLogs[0], 'Expected an insert DML for ExceptionLog__c');
		Assert.isTrue(insertabledExceptionLogs[0].ExceptionDetails__c.contains(TIBCOArticleSubscriptionService.ARTICLE_SUBSCRIPTION_FAILURE), 'Expected error message to contain information related to subscription failure');
	}

	/**
	 * Test Article Subscription with unexpected exception
	 * And Verify that ImpactedArticle is updated with appropriate error message
	 * And Verify that ExceptionLog__c is inserted
	 */
	@IsTest
	static void testArticleSubscriptionWithUnexpectedException(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Article__c article = ApplicationTestDataFactory.getArticles(1, consignment.Id, true)[0];
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, article.Id, true);

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(WebServiceMock.class, new ArticleSubscriptionToSAPMockResponse(null));
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		TIBCOArticleSubscriptionService.newInstance().sendArticleSubscriptionNotifications(impactedArticles);
		Test.stopTest();

		// Assert on updated exception logs
		fflib_ArgumentCaptor updatableImpactedArticleCaptor = fflib_ArgumentCaptor.forClass(List<ImpactedArticle__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<ImpactedArticle__c>) updatableImpactedArticleCaptor.capture());
		List<ImpactedArticle__c> updatableImpactArticles = (List<ImpactedArticle__c>) updatableImpactedArticleCaptor.getValue();

		Assert.isNotNull(updatableImpactArticles[0], 'Expected an update DML for Article__c');
		Assert.isNotNull(updatableImpactArticles[0].SubscriptionErrorCode__c, 'SubscriptionErrorCode__c should not be null');
		Assert.isTrue(updatableImpactArticles[0].SubscriptionErrorCode__c.contains('System.NullPointerException'), 'Expected error message to contain information related to subscription failure');

		// Assert on new exception logs
		fflib_ArgumentCaptor insertabledExceptionLogsCaptor = fflib_ArgumentCaptor.forClass(List<ExceptionLog__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<ExceptionLog__c>) insertabledExceptionLogsCaptor.capture(), fflib_Match.anyBoolean());
		List<ExceptionLog__c> insertabledExceptionLogs = (List<ExceptionLog__c>) insertabledExceptionLogsCaptor.getValue();

		Assert.isNotNull(insertabledExceptionLogs[0], 'Expected an insert DML for ExceptionLog__c');
		Assert.isTrue(insertabledExceptionLogs[0].ExceptionDetails__c.contains('System.NullPointerException'), 'Expected error message to contain information related to subscription failure');
	}

	/**
	 * @description	Mock webservice which simulates the response for article subscription
	 * @param	stub, request, response, endpoint, soapAction, requestName, responseNS, responseName, responseType
	 * @return	Void
	 * @throws	NA
	*/
	public class ArticleSubscriptionToSAPMockResponse implements WebServiceMock {
		public Boolean acknowledgementResult;

		public ArticleSubscriptionToSAPMockResponse(Boolean acknowledgementResult) {
			this.acknowledgementResult = acknowledgementResult;
		}

		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			// Creating a mock response
			TIBCOArticleSubscriptionSOAPService.notificationsResponse_element mockResponse = new TIBCOArticleSubscriptionSOAPService.notificationsResponse_element();

			mockResponse.Ack = this.acknowledgementResult; // Simulate an 'Ack' value of true for success
			response.put('response_x', mockResponse); // Populate the response map
		}
	}
}