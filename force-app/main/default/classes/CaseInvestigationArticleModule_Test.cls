/**
 * @description       : Test class for CaseInvestigationArticleModule
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 **/
@IsTest
private class CaseInvestigationArticleModule_Test {
	
	@IsTest
	static void onAfterInsert() {

		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		Case aCase = ApplicationTestDataFactory.getCases(1, true)[0];
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[0], null, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], null, true));

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		CaseInvestigationArticleModule.newInstance().onAfterInsert(records, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class); 
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();

		Set<String> actualReferenceIds = ((Set<String>) ((Map<String, Object>) stagedWorker.params).get('referenceIds'));
		System.assertEquals(2, actualReferenceIds.size(), 'Expected 2');
		System.assert(actualReferenceIds.contains(articles[0].Name), 'Should contain ' + articles[0].Name);
		System.assert(actualReferenceIds.contains(articles[1].Name), 'Should contain ' + articles[1].Name);
	}

	@IsTest
	static void onAfterUpdate() {
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		Case aCase = ApplicationTestDataFactory.getCases(1, true)[0];
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[0], null, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], null, true));

		Map<Id, CaseInvestigation__c> existingRecords = new Map<Id, CaseInvestigation__c>(records.deepClone(true, true, true));
		existingRecords.get(records[1].Id).ReferenceID__c = 'something diff';

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		CaseInvestigationArticleModule.newInstance().onAfterUpdate(records, existingRecords, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class); 
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();

		Set<String> actualReferenceIds = ((Set<String>) ((Map<String, Object>) stagedWorker.params).get('referenceIds'));
		System.assertEquals(1, actualReferenceIds.size(), 'Expected 1');
		System.assert(actualReferenceIds.contains(articles[0].Name) == false, 'Should Not contain ' + articles[0].Name);
		System.assert(actualReferenceIds.contains(articles[1].Name) == true, 'Should contain ' + articles[1].Name);
	}

	@IsTest
	static void testAsyncCaseInvestigationArticleWorker() {
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		TibcoArticleService mockTibcoArticleService = (TibcoArticleService)MockUtility.mockUtility(TibcoArticleService.class);
		TIBCODataTranslator mockTIBCODataTranslator = (TIBCODataTranslator)MockUtility.mockUtility(TIBCODataTranslator.class);

		Set<String> referenceIds = new Set<String>{'test1', 'test2'};

		Article__c a = ApplicationTestDataFactory.getArticles(1, true)[0];
		a.trackingID__c = 'test2';
		Map<String, List<Article__c>> consArticles = new Map<String, List<Article__c>>{
			a.trackingID__c => null
		};
		Map<Id, List<EventMessage__c>> articleToEventMessages = new Map<Id, List<EventMessage__c>>{
			a.id => ApplicationTestDataFactory.getEventMessages(2, a.id, true)
		};

		TIBCOSearchResult result = new TIBCOSearchResult();
		result.errors = new List<String>();
		result.success = true;
		result.trackResults = new List<TIBCOTrackingResultWrapper>{ new TIBCOTrackingResultWrapper(a, consArticles, articleToEventMessages)  };

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockArticlesSelector.selectByArticleNames(
														(Set<String>) fflib_Match.eq(referenceIds), 
														(Set<Object>)fflib_Match.eq(new Set<Object>())
													)).thenReturn(
														new List<Article__c>{ a }
													);

		MockUtility.Mocks.when(mockTibcoArticleService.searchByArticleIdsInSAP(
												(List<String>) fflib_Match.eq(new List<String>(referenceIds))
											)).thenReturn(
												result
											);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CaseInvestigationArticleModule.AsyncCaseInvestigationArticleWorker worker = new CaseInvestigationArticleModule.AsyncCaseInvestigationArticleWorker();

		System.assertEquals(worker.getClassType(), CaseInvestigationArticleModule.AsyncCaseInvestigationArticleWorker.class, 'Should be AsyncCaseInvestigationArticleWorker');
		System.assertEquals(worker.getSObjectTypeGroup(), CaseInvestigation__c.SObjectType, 'Should be CaseInvestigation__c.SObjectType');

		CaseInvestigationArticleModule.AsyncCaseInvestigationArticleWorkerParameters params = new CaseInvestigationArticleModule.AsyncCaseInvestigationArticleWorkerParameters();
		params.referenceIds = referenceIds;
		worker.deserialiseParams(JSON.serialize(params));
		System.assertEquals(worker.referenceIds.size(), 2, 'Should be 2');
		System.assert(worker.referenceIds.contains('test1'), 'Should contain test1');
		System.assert(worker.referenceIds.contains('test2'), 'Should contain test2');

		worker.execute(mockUow);

		Test.stopTest();

		((TIBCODataTranslator) MockUtility.Mocks.verify(mockTIBCODataTranslator, 1)).translate((List<TIBCOTrackingResultWrapper>) fflib_Match.eq(result.trackResults));
		((TIBCODataTranslator) MockUtility.Mocks.verify(mockTIBCODataTranslator, 1)).save(fflib_Match.eqBoolean(false), fflib_Match.eqBoolean(true));
	}
}
