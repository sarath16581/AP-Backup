/**
 * Created by hasan on 11/12/2022.
 */

@IsTest
private class StarTrackTrackingIDSearchServiceTest {

    @isTest
    public static void testConsignSearch_singleResponse() {
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;

        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'Email';
        testCase.RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ReferenceID__c = 'OSTZ00000275EXP00002';
        INSERT testCase;

        List<Consignment_Search_Settings__c> cssList = new List<Consignment_Search_Settings__c>();

        cssList.add(new Consignment_Search_Settings__c(Name = 'Consignment No.', Callout_Search_Type__c = 'CONSIGNMENT', Date_Type__c = false, Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Name', Exact_Search__c = true, Article_Case_field__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of character error', Field_Name__c = 'Number of character error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of search characters', Field_Name__c = '20'));
        insert cssList;

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(),
                Get_All_Consignment_Details__c = true,
                EMS_Endpoint__c = 'testendpt',
                Web_Service_Callout_Timeout__c = 10,
                Use_Continuation_for_Consignment_Search__c = true,
                XML_Logging__c = true,
                Logging__c = true,
                Log_For__c = 'ALL USER',
                StarTrack_ConSearch_Authentication_Level__c = 2,
                StarTrack_ConSearch_Client_Cert__c = 'cert',
                Sync_Web_Service_Callout_Timeout__c = 5
        );


        Test.startTest();
        // mocking and stubbing common data
        ApplicationDatabase mockDatabase = mockTestData();

        Test.setMock(WebServiceMock.class, new StartrackWebServiceCalloutMock());

        StarTrackTrackingIDSearchService idSearchService = StarTrackTrackingIDSearchService.newInstance();
        //StarTrackTrackingIDSearchService idSearchService = new StarTrackTrackingIDSearchService();
        idSearchService.dateRange = '1';
        idSearchService.searchString = testCase.ReferenceID__c;
        idSearchService.isConsole = false;
        idSearchService.map_searchCustomSettings.get(idSearchService.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        idSearchService.searchConsignment();

        Test.stopTest();

        // result is the return value of the callback
        System.assertNotEquals(null, idSearchService.lst_article[0]);
    }


    private static ApplicationDatabase mockTestData() {
        // =====================================
        // Data Preparation
        // =====================================

        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
        consignment.Name = 'TM2_OSTZ00000275_0000';
        consignment.RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();
        consignment.Source_System__c = 'TEAM';
        //insert consignment;
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
        // set up billing account on articles
        articles[0].Name = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00002';
        articles[0].RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Article').getRecordTypeId();
        articles[0].Source_System__c = 'TEAM';

        ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{'Consignment__r' => consignment});
        //insert articles;
        articles.add(consignment);
        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        system.assertNotEquals(articles, null,'articles are NULL');
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockArticleSelector.selectByArticleNames(
                (Set<String>)fflib_Match.anyObject()
                , (String) fflib_Match.anyObject()
                , (Set<String>)fflib_Match.anyObject()
                , (Set<Object>)fflib_Match.anyObject())
        ).thenReturn(new Map<Id, Article__c>(articles));
        MockUtility.Mocks.stopStubbing();

        return mockDatabase;
    }
}