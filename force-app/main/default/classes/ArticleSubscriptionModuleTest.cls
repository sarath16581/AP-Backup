/**
 * @description Test class covering ArticleSubscriptionModule
 * @changelog
 * 2024-09-12 - Seth Heang - Created
 * 2024-10-02 - Seth Heang - added negative test to ensure no article subscription is enqueued for closed parent case
 */
@IsTest
public class ArticleSubscriptionModuleTest {

	/**
	 * Test: AfterInsert Scenario, when new ImpactedArticles are created
	 * Verify that ImpactedArticles are partition into sublist of 100 batch size and
	 * Verify that AsyncArticleSubscriptionActionWorker is enqueued for each batch
	 */
	@IsTest
	static void testProcessArticleSubscriptionAndEnsureAsyncWorkerIsEnqueuedForEachBatch(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseTest.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(250, consignment.Id, true);
		List<ImpactedArticle__c> impactedArticles = new List<ImpactedArticle__c>();
		for(Article__c article : articles){
			ImpactedArticle__c impactedArticle = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, article.Id, true)[0];
			impactedArticle = (ImpactedArticle__c) ApplicationTestDataFactory.setUnwritableFields(
					impactedArticle,
					new Map<String, Object>{
							'Case__r' => caseTest,
							'Article__r' => article
					}
			);
			impactedArticles.add(impactedArticle);
		}

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector impactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(impactedArticlesSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
				.thenReturn(impactedArticles);
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ArticleSubscriptionModule module = new ArticleSubscriptionModule();
		module.onAfterInsert(impactedArticles, mockUow);
		Test.stopTest();

		// verify worker was enqueued for 3 times as 1st batch is 100, 2nd batch is 100 and 3rd batch is 50
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(List<ApplicationUnitOfWork.AsyncStagingWorker>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(3))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		ArticleSubscriptionModule.ArticleSubscriptionActionsParam articleSubscriptionActionWorkerParam = ((ArticleSubscriptionModule.ArticleSubscriptionActionsParam) stagedWorker.params);
		Assert.isNotNull(articleSubscriptionActionWorkerParam.impactedArticles, 'Impacted articles param should not be empty.');
		// we have no way to retrieving the 1st and 2nd batch async worker based on the current implement of ApplicationUnitOfWork.registerAsyncWork() as it does not take a List<AsyncStagingWorker>
		// verify the last batch size which is 50
		Assert.areEqual(50, articleSubscriptionActionWorkerParam.impactedArticles.size(), 'Impacted articles list size should be 50 but instead got: ' + articleSubscriptionActionWorkerParam.impactedArticles.size());
	}

	/**
	 * Test: AfterInsert Scenario, when new ImpactedArticles are created
	 * Verify that AsyncArticleSubscriptionActionWorker is not enqueued if parent case is closed
	 */
	@IsTest
	static void testProcessArticleSubscriptionAndEnsureNoAsyncWorkerIsEnqueuedDueToClosedCase(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseTest.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		caseTest = (Case) ApplicationTestDataFactory.setUnwritableFields(
				caseTest,
				new Map<String, Object>{
						'IsClosed' => true
				}
		);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(250, consignment.Id, true);
		List<ImpactedArticle__c> impactedArticles = new List<ImpactedArticle__c>();
		for(Article__c article : articles){
			ImpactedArticle__c impactedArticle = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, article.Id, true)[0];
			impactedArticle = (ImpactedArticle__c) ApplicationTestDataFactory.setUnwritableFields(
					impactedArticle,
					new Map<String, Object>{
							'Case__r' => caseTest,
							'Article__r' => article
					}
			);
			impactedArticles.add(impactedArticle);
		}

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector impactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(impactedArticlesSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
				.thenReturn(impactedArticles);
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ArticleSubscriptionModule module = new ArticleSubscriptionModule();
		module.onAfterInsert(impactedArticles, mockUow);
		Test.stopTest();

		// verify that no worker was enqueued as parent case is closed
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(List<ApplicationUnitOfWork.AsyncStagingWorker>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		Assert.isNull(stagedWorker, 'staged worker should be null');
	}

	/**
	 * Test: AfterInsert Scenario, when new ImpactedArticles are created and unexpected exception occurs
	 * Verify that No AsyncArticleSubscriptionActionWorker is enqueued
	 */
	@IsTest
	static void testProcessArticleSubscriptionWithException(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(250, consignment.Id, true);
		List<ImpactedArticle__c> impactedArticles = new List<ImpactedArticle__c>();
		for(Article__c article : articles){
			ImpactedArticle__c impactedArticle = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, article.Id, true)[0];
			impactedArticles.add(impactedArticle);
		}

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector impactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(impactedArticlesSelector.selectById((Set<Id>) fflib_Match.anyObject()))
				.thenReturn(new List<ImpactedArticle__c>());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ArticleSubscriptionModule module = new ArticleSubscriptionModule();
		module.onAfterInsert(impactedArticles, mockUow);
		Test.stopTest();

		// verify worker was enqueued for 0 times
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(List<ApplicationUnitOfWork.AsyncStagingWorker>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		Assert.isNull(stagedWorker, 'Async worker should be null but instead got: ' + stagedWorker);
	}

	/**
	 * Test: splitList() method
	 * And Verify that any list bigger than 100 will be partitioned into many sublist of the specified batch size
	 */
	@IsTest
	static void testEnsureBatchListPartitionerCreateSubListOfCorrectBatchSize(){
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Article__c article = ApplicationTestDataFactory.getArticles(1, consignment.Id, true)[0];
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(990, caseTest.Id, article.Id, true);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<List<SObject>> result = ArticleSubscriptionModule.splitList(impactedArticles, ArticleSubscriptionModule.ARTICLE_SUBSCRIPTION_BATCH_SIZE);
		Test.stopTest();

		// Assert
		Assert.areEqual(10, result.size(), 'The list should be split into 10 sublists.');
		Assert.areEqual(100, result[0].size(), 'The first sublist should contain 100 items.');
		Assert.areEqual(100, result[1].size(), 'The second sublist should contain 100 items.');
		Assert.areEqual(100, result[2].size(), 'The third sublist should contain 100 items.');
		Assert.areEqual(100, result[3].size(), 'The fourth sublist should contain 100 items.');
		Assert.areEqual(100, result[4].size(), 'The fifth sublist should contain 100 items.');
		Assert.areEqual(100, result[5].size(), 'The sixth sublist should contain 100 items.');
		Assert.areEqual(100, result[6].size(), 'The seventh sublist should contain 100 items.');
		Assert.areEqual(100, result[7].size(), 'The eighth sublist should contain 100 items.');
		Assert.areEqual(100, result[8].size(), 'The ninth sublist should contain 100 items.');
		Assert.areEqual(90, result[9].size(), 'The tenth sublist should contain 90 items.');
	}
}