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
		dataCategoryWorker.processDataCategories(dataCategoryWorker.parentIds);

		System.assertEquals(dataCategoryWorker.parentIds.contains(criticalIncidents[0].Id), true, 'Knowledge Id is passed in parameters');
		System.assertEquals(dataCategoryWorker.parentIdAndCategoryMap.get(criticalIncidents[0].Id), 'Critical_Incident', 'Id is mapped to its specific article type');
		System.assertEquals(dataCategoryWorker.deleteDataCategorySelections.size(), 2, 'Both how_to and Manager records should be added to delete');
		System.assertEquals(dataCategoryWorker.insertDataCategorySelections.size(), 0, 'No need to insert record as there is already an existing one');
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
		dataCategoryWorker.processDataCategories(dataCategoryWorker.parentIds);

		System.assertEquals(dataCategoryWorker.parentIds.contains(criticalIncidents[0].Id), true, 'Knowledge Id is passed in parameters');
		System.assertEquals(dataCategoryWorker.parentIdAndCategoryMap.get(criticalIncidents[0].Id), 'Critical_Incident', 'Id is mapped to its specific article type');
		System.assertEquals(dataCategoryWorker.deleteDataCategorySelections.size(), 0, 'There are no existing records to delete');
		System.assertEquals(dataCategoryWorker.insertDataCategorySelections.size(), 1, 'Creating a new record that matches to its record type');
		System.assertEquals(dataCategoryWorker.insertDataCategorySelections[0].DataCategoryName, 'Critical_Incident', 'new records DataCategoryName matches to knowledge record type');
		Test.stopTest();
	}
}