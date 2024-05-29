@istest
public with sharing class KnowledgeArticleVersionServiceTest {
	@istest
	public static void testKnowledgeWithDataCategories() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		insert criticalIncidents;

		List<Knowledge__DataCategorySelection> dataCategories = ApplicationTestDataFactoryKnowledge.getDataCatogories(3, false, criticalIncidents[0].Id);
		List<String> dataCategoryTypes = new List<String>{ 'Critical_Incident', 'How_To', 'Manager' };
		for (Integer indx = 0; indx < 3; indx++) {
			dataCategories[indx].DataCategoryName = dataCategoryTypes[indx];
			dataCategories[indx].DataCategoryGroupName = 'Article_Type';
		}

		insert dataCategories;
		// =====================================
		// Stubbing
		// =====================================
		KnowledgeDataCategorySelectionsSelector kavSelector = (KnowledgeDataCategorySelectionsSelector) MockUtility.mockSelector(KnowledgeDataCategorySelectionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>) fflib_Match.anyObject())).thenReturn(dataCategories);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		KnowledgeArticleVersionService knowledgeService = KnowledgeArticleVersionService.getInstance();
		knowledgeService.createDataCategorySelection(criticalIncidents, mockUow);

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		KnowledgeArticleVersionService.AsyncCreateDataCategoryWorker dataCategoryWorker = ((KnowledgeArticleVersionService.AsyncCreateDataCategoryWorker) stagedWorker.params);
		System.assertEquals(dataCategoryWorker.articles, criticalIncidents, 'Knowledge records passed in parameters');
		Test.stopTest();
	}

	@istest
	public static void testKnowledgeWithOutDatacategories() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		insert criticalIncidents;

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		KnowledgeArticleVersionService knowledgeService = KnowledgeArticleVersionService.getInstance();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		knowledgeService.createDataCategorySelection(criticalIncidents, mockUow);

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		KnowledgeArticleVersionService.AsyncCreateDataCategoryWorker dataCategoryWorker = ((KnowledgeArticleVersionService.AsyncCreateDataCategoryWorker) stagedWorker.params);
		System.assertEquals(dataCategoryWorker.articles, criticalIncidents, 'Knowledge records passed in parameters');
		Test.stopTest();
	}

	@istest
	public static void testKnowledgeWithDataCategoriesToDelete() {
		// =====================================
		// Data Preparation
		// =====================================
		KnowledgeArticleVersionService knowledgeService = KnowledgeArticleVersionService.getInstance();
		Map<String, String> dataCategoriesMap = knowledgeService.getDataCategoryNamesByGroup('Article_Type');

		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		insert criticalIncidents;

		List<Knowledge__DataCategorySelection> dataCategories = ApplicationTestDataFactoryKnowledge.getDataCatogories(3, false, criticalIncidents[0].Id);
		List<String> dataCategoryTypes = new List<String>{ 'How_To', 'Manager', 'Product' };
		for (Integer indx = 0; indx < 3; indx++) {
			dataCategories[indx].DataCategoryName = dataCategoryTypes[indx];
			dataCategories[indx].DataCategoryGroupName = 'Article_Type';
		}

		insert dataCategories;
		// =====================================
		// Stubbing
		// =====================================
		KnowledgeDataCategorySelectionsSelector kavSelector = (KnowledgeDataCategorySelectionsSelector) MockUtility.mockSelector(KnowledgeDataCategorySelectionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>) fflib_Match.anyObject())).thenReturn(dataCategories);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		knowledgeService.processDataCategories(criticalIncidents, mockUow);
		Test.stopTest();
		Knowledge__DataCategorySelection newDataCategory = new Knowledge__DataCategorySelection(
			ParentId = criticalIncidents[0].Id,
			DataCategoryGroupName = 'Article_Type',
			DataCategoryName = dataCategoriesMap.get('Critical Incident')
		);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDeleted((List<Knowledge__DataCategorySelection>) fflib_Match.eq(dataCategories));
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1)))
			.registerNew((List<Knowledge__DataCategorySelection>) fflib_Match.eq(new List<Knowledge__DataCategorySelection>{ newDataCategory }));
	}
}