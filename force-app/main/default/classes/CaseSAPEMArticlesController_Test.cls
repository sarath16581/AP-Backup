/**
* @description This test class is for CaseSAPEMArticlesController.
* @author Frank Chen
* @created 2014-06-24
* @changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* 2018-05-28 : hasantha.liyanage@auspost.com.au : added tests for retrieveArticle() method just to get the coverage.
* 2020-05-10 - Nathan Franklin - rewrite with Mocks
* 2020-10-08 - Disha Kariya - Allow safe drop attachment for child case creation
* 2021-09-08 - seth.heang@auspost.com.au - Uplift SF API version to 52
* 2024-10-08 - George Nguyen - Included unified cases in search results
*/
@IsTest
private class CaseSAPEMArticlesController_Test {

    @IsTest
    private static void testProperties() {

        // =====================================
        // Data Preparation
        // =====================================
	    Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
        Case c = ApplicationTestDataFactory.getCases(1, true)[0];
	    c.ReferenceID__c = consignment.ArticleID__c;
	    c.ArticleTest__c = consignment.Id;
	    consignment = (Article__c)ApplicationTestDataFactory.setUnwritableFields(consignment, new Map<String, Object>{'RecordType.Name' => 'Consignment'});

		Map<String, Object> searchParams = new Map<String, Object> {
			'recordTypeDeveloperNames' => new Set<String>{
				SSSWConstants.CASE_RT_SSSW_DELIVERY,
				SSSWConstants.CASE_RT_SSSW_FAX,
				SSSWConstants.CASE_RT_SSSW_GENERAL_ENQUIRY,
				SSSWConstants.CASE_RT_SSSW_SERVICE,
				SSSWConstants.CASE_RT_SSSW_SOCIAL_RECORD_TYPE,
				SSSWConstants.CASE_RT_SSSW_NCCC_DIRECT_EMAIL,

				SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME,
				SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME
			},
			'caseIds' => new Set<Id>{c.id}
		};

		Set<Object> selectorOptions = new Set<Object>{
			CasesSelector.Options.WITH_ARTICLE
		};

		Boolean matchAll = true;

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Case.Id,
			Case.IsClosed,
			Case.ReferenceID__c
		};

        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.search(
												(Map<String, Object>)fflib_Match.eq(searchParams), 
												(Set<Object>)fflib_Match.eq(selectorOptions),
												(Boolean)fflib_Match.eq(true)
											)).thenReturn(new List<Case>{c});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.setCurrentPage(Page.CaseSAPEMArticles);

        ApexPages.StandardController standardController = new ApexPages.StandardController(c);
        CaseSAPEMArticlesController controller = new CaseSAPEMArticlesController(standardController);

        System.assertEquals(true, controller.happyParcelAttributes.contains('supportsExternalLinkHandling'), 'Expected supportsExternalLinkHandling');
        System.assertEquals(c.ReferenceID__c, controller.articleID);

    }

    /**
     * Scenario:
     * Current case is closed and the case is linked to a single article consignment
     **/
    @IsTest
    private static void testSubmitWhereCaseIsClosedAndSingleArticleConsignment() {

        // =====================================
        // Data Preparation
        // =====================================
        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
        Case c = ApplicationTestDataFactory.getCases(1, true)[0];
        c.ReferenceID__c = articles[0].ArticleID__c;
        c.ArticleTest__c = articles[0].Id;
        c.Status = 'Closed';
        c = (Case)ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{'IsClosed' => true});

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{c.Id => c});
        MockUtility.Mocks.when(mockArticlesSelector.selectByArticleIds((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>{articles[0].Id => articles[0]});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
	    String result = CaseSAPEMArticlesController.submit(c.Id, '["' + articles[0].ArticleID__c + '"]', 'Sender', true, '[]');
        System.assertEquals(false, result.contains('Error'), 'Result contains an error: ' + result);
        System.assertNotEquals(Id.valueOf(result), c.Id, 'Expected new case to be created');

        // should have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

    }

    /**
     * Scenario:
     * Current case is closed and the case is linked to a consignment with multiple articles which are selected
     **/
    @IsTest
    private static void testSubmitWhereCaseIsClosedAndLinkedToMultipleArticleConsignment() {

        // =====================================
        // Data Preparation
        // =====================================
        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
        Case c = ApplicationTestDataFactory.getCases(1, true)[0];
        c.ReferenceID__c = consignment.ArticleID__c;
        c.ArticleTest__c = consignment.Id;
        c.Status = 'Closed';
        c = (Case)ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{'IsClosed' => true});

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{c.Id => c});
        MockUtility.Mocks.when(mockArticlesSelector.selectByArticleIds((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>{articles[0].Id => articles[0], articles[1].Id => articles[1]});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
	    String result = CaseSAPEMArticlesController.submit(c.Id, '["' + articles[0].ArticleID__c + '","' + articles[1].ArticleID__c + '"]', 'Sender', false, '[]');
        System.assertEquals(false, result.contains('Error'), 'Result contains an error: ' + result);
        System.assertNotEquals(Id.valueOf(result), c.Id, 'Expected new case to be created');

        // should have inserted a new case and another insert for child cases
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>)fflib_Match.anyObject());

        // no updates
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

    }

    /**
     * Scenario:
     * Current case is open and the case is linked to a single article consignment
     **/
    @IsTest
    private static void testSubmitWhereCaseIsOpenAndSingleArticleConsignment() {

        // =====================================
        // Data Preparation
        // =====================================
        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
        Case c = ApplicationTestDataFactory.getCases(1, true)[0];
        c.ReferenceID__c = articles[0].ArticleID__c;
        c.ArticleTest__c = articles[0].Id;

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{c.Id => c});
        MockUtility.Mocks.when(mockArticlesSelector.selectByArticleIds((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>{articles[0].Id => articles[0]});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
	    String result = CaseSAPEMArticlesController.submit(c.Id, '["' + articles[0].ArticleID__c + '"]', 'Sender', true, '[]');
        System.assertEquals(false, result.contains('Error'), 'Result contains an error: ' + result);
        System.assertEquals(Id.valueOf(result), c.Id, 'Did not expect new case to be created');

        // not insert
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());

        // only update
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

    }

    /**
     * Scenario:
     * Current case is open and the case is linked to a consignment with multiple articles which are selected
     **/
    @IsTest
    private static void testSubmitWhereCaseIsOpenAndLinkedToMultipleArticleConsignment() {

        // =====================================
        // Data Preparation
        // =====================================
        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
        cases[0].ReferenceID__c = consignment.ArticleID__c;
        cases[0].ArticleTest__c = consignment.Id;

        cases[1].ParentId = cases[0].Id;
        cases[1].ReferenceID__c = articles[0].ArticleID__c;
        cases[1].ArticleTest__c = articles[0].Id;


        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cases[0].Id => cases[0]});
        MockUtility.Mocks.when(mockCasesSelector.selectChildCasesByParent((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cases[1].Id => cases[1]});
        MockUtility.Mocks.when(mockArticlesSelector.selectByArticleIds((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>{articles[0].Id => articles[0], articles[1].Id => articles[1]});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
	    String result = CaseSAPEMArticlesController.submit(cases[0].Id, '["' + articles[0].ArticleID__c + '","' + articles[1].ArticleID__c + '"]', 'Sender', false, '[]');
        System.assertEquals(false, result.contains('Error'), 'Result contains an error: ' + result);
        System.assertEquals(Id.valueOf(result), cases[0].Id, 'Did not expect a new case to be created');

        // should have inserted a new case and another insert for child cases
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());

        // no updates
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

    }

    /**
     * Scenario:
     * Current case is open and the case is linked to a consignment with multiple articles which are selected
     * Integration test where real DML is used
     **/
    @IsTest
    private static void testSubmitWhereCaseIsOpenAndLinkedToMultipleArticleConsignmentIntegration() {
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];
        insert consignment;

        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, false);
        insert articles;

        Case parentCase = ApplicationTestDataFactory.getCases(1, false)[0];
        parentCase.RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
        parentCase.ReferenceID__c = consignment.ArticleID__c;
        parentCase.ArticleTest__c = consignment.Id;
        insert parentCase;

        Case childCase = ApplicationTestDataFactory.getCases(1, false)[0];
        childCase.RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
        childCase.ParentId = parentCase.Id;
        childCase.ReferenceID__c = articles[0].ArticleID__c;
        childCase.ArticleTest__c = articles[0].Id;
        insert childCase;


        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

	    String result = CaseSAPEMArticlesController.submit(parentCase.Id, '["' + articles[0].ArticleID__c + '","' + articles[1].ArticleID__c + '"]', 'Sender', false, '[]');
        System.assertEquals(false, result.contains('Error'), 'Result contains an error: ' + result);

        // check for:
        // 1 x existing parent case
        // 1 x existing child case
        // 1 x cloned new child case (doesn't create 2 since 1 child case already existed)
        List<Case> caseResults = [Select Id, ReferenceID__c From Case];
        System.assertEquals(3, caseResults.size(), 'Expected only 3 case records');
        System.assertEquals(Id.valueOf(result), parentCase.Id, 'Did not expect a new case to be created');

        Test.stopTest();

    }

}