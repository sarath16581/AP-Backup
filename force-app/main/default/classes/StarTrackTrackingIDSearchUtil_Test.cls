@IsTest
private class StarTrackTrackingIDSearchUtil_Test {
    @testSetup
    static void testSetup(){
        MockUtility.disableTriggerExecution();

        List<sobject> ls = TestDataProvider.createStartrackErrorMessagesData();

        List<StarTrack_Transfer_Case_Rule__c> transferCaseRules = new List<StarTrack_Transfer_Case_Rule__c>();
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'StarTrack Next Flight Queue', Product_Group__c = 'Next Flight', Order__c = 1, Business_Solutions_Customer__c = true));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.TRANSFER_QUEUE, Case_Purpose__c = 'Other' , Order__c = 2));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.ETA_QUEUE, Case_RecordType__c = 'Pickup Booking Enquiry', Case_Purpose__c = 'Pickup ETA', Order__c = 4));
        Database.insert(transferCaseRules);

        List<Account> lst_account = TestDataProvider.createAccount('test', 1);
        lst_account[0].Transfer_Case_Queue__c = 'Delivery Queue';
        lst_account[0].Business_Solutions_Customer__c = true;
        Database.insert(lst_account);
        System.debug('lst_account: ' + lst_account);

        lst_account[0].Legacy_Id__c = '60000000';
        Database.Update(lst_account[0]);

        List<Network__c> lst_network = TestDataProvider.createNetwork('Test network', 1);

        User u = TestDataProvider.createTestUsers();
        Database.insert(u);
        for(Network__c n : lst_network){
            n.ownerid = u.id;
        }
        Database.insert(lst_network);

        List<Billing_Account__c> lst_billingAccount = new List<Billing_Account__c>();
        Billing_Account__c testBillingAcc = new Billing_Account__c(Name = 'TestBillingAccTest',Organisation__c = lst_account[0].Id, LEGACY_ID__c = '12345');
        lst_billingAccount.add(testBillingAcc);
        Database.insert(lst_billingAccount);

        List<Article__c> lst_article = TestDataProvider.createArticle('Subject', 1, lst_billingAccount);
        lst_article[0].Network__c = lst_network[0].Id;
        lst_article[0].Billing_Account__c = lst_billingAccount[0].Id;
        Database.insert(lst_article);

        List<case> lst_cases = TestDataProvider.createCases('Subject', 1, lst_article);
        lst_cases[0].AccountId = lst_account[0].Id;
        lst_cases[0].Related_Billing_Account__c = lst_billingAccount[0].Id;
        lst_cases[0].Origin = StarTrack_Constants.CASE_ORIGIN_WEB;
        lst_cases[0].ReferenceID__c = 'XYZ';
        lst_cases[0].RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        lst_cases[0].CHASEnquiryType__c = STHSConstants.TRACKING_ENQUIRY_TRACK_TRACE;
        lst_cases[0].Recent_Caller_Type__c = STHSConstants.CASE_CONTYPE_SENDER;

        Database.insert(lst_cases);
        System.debug('lst_cases: ' + lst_cases);


        User usr = [Select id from User where Id = :UserInfo.getUserId()];

        System.runAs(usr) {

            List<Group> testQueues = new List<Group>();
            testQueues.add(new Group(Name='StarTrack Next Flight Queue',  Type='Queue'));
            testQueues.add(new Group(Name=StarTrack_Constants.ETA_QUEUE,  Type='Queue'));
            testQueues.add(new Group(Name=StarTrack_Constants.WEB_BOOKINGS_QUEUE,  Type='Queue'));
            testQueues.add(new Group(Name='Controlled Returns Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Sorry We Missed You',  Type='Queue'));
            testQueues.add(new Group(Name='Delivery Queue',  Type='Queue'));
            Database.insert(testQueues);


            List<QueuesObject> queueAssignments = new List<QueueSObject>();
            queueAssignments.add(new QueuesObject(QueueID = testQueues[0].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[1].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[2].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[3].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[4].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[5].Id, SObjectType = 'Case'));
            Database.insert(queueAssignments);
        }

        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.Next_Flight_Case_Consignment__c = 'StarTrack Next Flight Queue';
        customSetting.PBE_ETA_Enquiry__c = StarTrack_Constants.ETA_QUEUE;
        customSetting.PBE_Missed_Futile_Enquiry__c = StarTrack_Constants.WEB_BOOKINGS_QUEUE;
        customSetting.PBE_Controlled_Returns__c = 'Controlled Returns Queue';
        customSetting.Redelivery_Redirection_Enquiry__c = 'Sorry We Missed You';
        customSetting.SetupOwnerId = UserInfo.getOrganizationId();
        customSetting.Get_All_Consignment_Details__c = true;
        customSetting.EMS_Endpoint__c = 'testendpt';
        customSetting.Web_Service_Callout_Timeout__c = 10;
        customSetting.Use_Continuation_for_Consignment_Search__c = true;
        customSetting.XML_Logging__c = true;
        customSetting.Logging__c = true;
        customSetting.Log_For__c = 'ALL USER';
        customSetting.StarTrack_ConSearch_Authentication_Level__c = 2;
        customSetting.StarTrack_ConSearch_Client_Cert__c = 'cert';
        customSetting.Sync_Web_Service_Callout_Timeout__c = 5;
        Database.insert(customSetting);
    }

    @isTest
    static void testCaseTransferForBusinessSolutionsPositiveNetworkOwner() {
        Account testAccount = [SELECT Id, Business_Solutions_Customer__c 
                                FROM Account 
                                LIMIT 1];
        testAccount.Business_Solutions_Customer__c = false;
        Database.Update(testAccount);

        Case testCase = [
                SELECT Id,
                        Call_Purpose__c,
                        RecordTypeId,
                        Enquiry_Type__c,
                        Business_Solutions_Customer__c,
                        Initial_Caller_Type__c,
                        Status,
                        OwnerId,
                        Article_Service_Type__c,
                        ReferenceID__c,
                        Origin,
                        ArticleTest__c,
                        ArticleTest__r.Product_Group__c,
                        RecordType.Name,
                        Network__r.OwnerId,
                        Network__r.Name,
                        Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c,
                        Account.StarTrack_Customer_Stream__c
                FROM
                        Case
                LIMIT 1
        ];

        System.debug('testCase: ' + testCase);

        Test.startTest();
        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();


        // mock database, set response for DML update
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenReturn(true);

        MockUtility.Mocks.stopStubbing();

        //process the case transfer
        System.enqueueJob(new StarTrackTrackingIDSearchUtil.TransferCaseQueueable(testCase));

        Test.stopTest();

        // Check if the Case record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());


    }


    @isTest static void testCaseTransferForBusinessSolutionsPositive() {

        Case testCase = [
                SELECT Id,
                        Call_Purpose__c,
                        RecordTypeId,
                        Enquiry_Type__c,
                        Business_Solutions_Customer__c,
                        Initial_Caller_Type__c,
                        Status,
                        OwnerId,
                        Article_Service_Type__c,
                        ReferenceID__c,
                        Origin,
                        ArticleTest__c,
                        ArticleTest__r.Product_Group__c,
                        RecordType.Name,
                        Network__r.OwnerId,
                        Network__r.Name,
                        Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c,
                        Account.StarTrack_Customer_Stream__c
                FROM
                        Case
                LIMIT 1
        ];

        Test.startTest();
        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();


        // mock database, set response for DML update
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenReturn(true);

        MockUtility.Mocks.stopStubbing();

        //process the case transfer
        System.enqueueJob(new StarTrackTrackingIDSearchUtil.TransferCaseQueueable(testCase));

        Test.stopTest();

        // Check if the Case record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @isTest static void testCaseTransferForBusinessSolutionsNoQueueNegative() {

        Account testAccount = [SELECT Id, Transfer_Case_Queue__c 
                                FROM Account 
                                LIMIT 1];
        testAccount.Transfer_Case_Queue__c = 'WRONG_QUEUE_NAME';
        Database.Update(testAccount);       

        Case testCase = [
                        SELECT
                                Id,
                                Call_Purpose__c, 
                                RecordTypeId, 
                                Enquiry_Type__c, 
                                Business_Solutions_Customer__c, 
                                Initial_Caller_Type__c,
                                Status, 
                                OwnerId, 
                                Article_Service_Type__c, 
                                ReferenceID__c, 
                                Origin, 
                                ArticleTest__c, 
                                ArticleTest__r.Product_Group__c,
                                RecordType.Name, 
                                Network__r.OwnerId, 
                                Network__r.Name, 
                                Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c,
                                Account.StarTrack_Customer_Stream__c,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c
                        FROM
                                Case
                        LIMIT 1
                        ];

        Test.startTest();
        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();


        // mock database, set response for DML update
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenReturn(true);

        MockUtility.Mocks.stopStubbing();

        //process the case transfer
        System.enqueueJob(new StarTrackTrackingIDSearchUtil.TransferCaseQueueable(testCase));

        Test.stopTest();

        // Check if the Case record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @IsTest
    private static void testValidateBeforeCaseUpdate_success() {

        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        articles[0].Name = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00001';
        articles[0].RecordTypeId = ApplicationTestDataFactory.articleArticleRecordType.Id;
        articles[0].Source_System__c = 'TEAM';
        Id RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        Case testCase = [
                SELECT Id,
                        ArticleTest__c,
                        RecordTypeId,
                        ReferenceID__c,
                        Origin,
                        Enquiry_Type__c
                FROM
                        Case
                WHERE
                        RecordTypeId =: RecordTypeId
                LIMIT 1
        ];


        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,'0', articles);

        Test.startTest();
        StarTrackTrackingIDSearchUtil util = StarTrackTrackingIDSearchUtil.getInstance();
        Boolean result = util.validate(articles, testCase.Id, conWrap, 1);
        List<CaseComment> comments = [SELECT CommentBody, ParentId FROM CaseComment WHERE ParentId = :testCase.Id];

        System.assertEquals(0, comments.size(), 'testValidateBeforeCaseUpdate_success: Expected an success in response with no case comments');
        System.assertEquals(true, result, 'testValidateBeforeCaseUpdate_success: Expected an success in response');
        Test.stopTest();
    }
    @IsTest
    private static void testValidateBeforeCaseUpdate_error_in_response() {

        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        articles[0].Name = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00001';
        articles[0].RecordTypeId = ApplicationTestDataFactory.articleArticleRecordType.Id;
        articles[0].Source_System__c = 'TEAM';
        Id RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        Case testCase = [
                SELECT Id,
                        ArticleTest__c,
                        RecordTypeId,
                        ReferenceID__c,
                        Origin,
                        Enquiry_Type__c
                FROM
                        Case
                WHERE
                        RecordTypeId =: RecordTypeId
                LIMIT 1
        ];


        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,'1', articles);

        Test.startTest();
        StarTrackTrackingIDSearchUtil util = StarTrackTrackingIDSearchUtil.getInstance();
        Boolean result = util.validate(articles, testCase.Id, conWrap, 1);
        List<CaseComment> comments = [SELECT CommentBody, ParentId FROM CaseComment WHERE ParentId = :testCase.Id];

        System.assertEquals(System.Label.STHSIDSearchCommentsTimeoutTechError, comments[0].CommentBody, 'testValidateBeforeCaseUpdate_error_in_response: Expected an error in response with case comments');
        System.assertEquals(false, result, 'testValidateBeforeCaseUpdate_error_in_response: Expected an error in response');
        Test.stopTest();
    }

    @IsTest
    private static void testValidateBeforeCaseUpdate_error_in_response_no_articles() {

        Id RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        Case testCase = [
                SELECT Id,
                        ArticleTest__c,
                        RecordTypeId,
                        ReferenceID__c,
                        Origin,
                        Enquiry_Type__c
                FROM
                        Case
                WHERE
                        RecordTypeId =: RecordTypeId
                LIMIT 1
        ];


        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,StarTrack_Constants.ERR_CODE_ART_NOT_FOUND, null);

        Test.startTest();
        StarTrackTrackingIDSearchUtil util = StarTrackTrackingIDSearchUtil.getInstance();
        conWrap.errorCode = StarTrack_Constants.ERR_CODE_ART_NOT_FOUND;
        Boolean result = util.validate(null, testCase.Id, conWrap, 1);
        List<CaseComment> comments = [SELECT CommentBody, ParentId FROM CaseComment WHERE ParentId = :testCase.Id];

        System.assertEquals(System.Label.STHSIDSearchCommentsNoConsignment, comments[0].CommentBody, 'testValidateBeforeCaseUpdate_error_in_response_no_articles: Expected an error in response with case comments');
        System.assertEquals(false, result, 'testValidateBeforeCaseUpdate_error_in_response_no_articles: Expected an error in response for no articles found');
        Test.stopTest();
    }

    @IsTest
    private static void testValidateBeforeCaseUpdate_error_in_response_isDupe() {

        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
        articles[0].Name = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00001';
        articles[0].RecordTypeId = ApplicationTestDataFactory.articleArticleRecordType.Id;
        articles[0].Source_System__c = 'TEAM';
        articles[1].Name = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00001';
        articles[1].RecordTypeId = ApplicationTestDataFactory.articleArticleRecordType.Id;
        articles[1].Source_System__c = 'TEAM';

        Id RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        Case testCase = [
                SELECT Id,
                        ArticleTest__c,
                        RecordTypeId,
                        ReferenceID__c,
                        Origin,
                        Enquiry_Type__c
                FROM
                        Case
                WHERE
                        RecordTypeId =: RecordTypeId
                LIMIT 1
        ];


        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,'0', articles);

        Test.startTest();
        StarTrackTrackingIDSearchUtil util = StarTrackTrackingIDSearchUtil.getInstance();
        Boolean result = util.validate(articles, testCase.Id, conWrap, 1);
        List<CaseComment> comments = [SELECT CommentBody, ParentId FROM CaseComment WHERE ParentId = :testCase.Id];

        System.assertEquals(System.Label.STHSIDSearchCommentsDuplicateConsignment, comments[0].CommentBody, 'testValidateBeforeCaseUpdate_error_in_response: Expected an error in response with case comments');
        System.assertEquals(false, result, 'testValidateBeforeCaseUpdate_error_in_response: Expected an error in response for duplicates');
        Test.stopTest();
    }

    @IsTest
    private static void testAssignAndUpdateCase_success() {

        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        articles[0].Name = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00001';
        articles[0].RecordTypeId = ApplicationTestDataFactory.articleArticleRecordType.Id;
        articles[0].Source_System__c = 'TEAM';
        Id RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        Case testCase = [
                SELECT Id,
                        ArticleTest__c,
                        RecordTypeId,
                        ReferenceID__c,
                        Origin,
                        Enquiry_Type__c,
                        LastModifiedDate,
                        Connote_number__c
                FROM
                        Case
                WHERE
                        RecordTypeId =: RecordTypeId
                LIMIT 1
        ];


        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,'0', articles);

        Test.startTest();
        StarTrackTrackingIDSearchUtil util = StarTrackTrackingIDSearchUtil.getInstance();
        util.assignAndUpdateCase(articles[0],testCase);
        Test.stopTest();

        Case testCase1 = [
                SELECT Id,
                        LastModifiedDate,
                        Connote_number__c
                FROM
                        Case
                WHERE
                        Id =: testCase.Id
                LIMIT 1
        ];

        System.assertNotEquals(articles[0].Name, testCase.Connote_number__c, 'testAssignAndUpdateCase_success: Expected the case to be updated');
    }

    @isTest
    public static void testConsignSearch_queable_coverage_only() {
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;

        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'web';
        testCase.RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ReferenceID__c = 'OSTZ00000275EXP00002';
        INSERT testCase;

        List<Consignment_Search_Settings__c> cssList = new List<Consignment_Search_Settings__c>();

        cssList.add(new Consignment_Search_Settings__c(Name = 'Consignment No.', Callout_Search_Type__c = 'CONSIGNMENT', Date_Type__c = false, Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Name', Exact_Search__c = true, Article_Case_field__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of character error', Field_Name__c = 'Number of character error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of search characters', Field_Name__c = '20'));
        insert cssList;

        Test.startTest();
        // mocking and stubbing common data
        ApplicationDatabase mockDatabase = mockTestData();

        Test.setMock(WebServiceMock.class, new StartrackWebServiceCalloutMock());

        System.enqueueJob(new StarTrackTrackingIDSearchUtil.TrackingSearchQueueable(testCase));
        Test.stopTest();

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
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, consignment.Id, true);
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


    @IsTest
    private static void testValidateBeforeCaseUpdate_error_in_response_Invalid_consignment() {

        Id RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        Case testCase = [
                SELECT Id,
                        ArticleTest__c,
                        RecordTypeId,
                        ReferenceID__c,
                        Origin,
                        Enquiry_Type__c
                FROM
                        Case
                WHERE
                        RecordTypeId =: RecordTypeId
                LIMIT 1
        ];

        List<Article__c> articles = new List<Article__c>();
        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,'0', null);

        Test.startTest();
        StarTrackTrackingIDSearchUtil util = StarTrackTrackingIDSearchUtil.getInstance();
        Boolean result = util.validate(articles, testCase.Id, conWrap, null);
        List<CaseComment> comments = [SELECT CommentBody, ParentId FROM CaseComment WHERE ParentId = :testCase.Id];
        system.debug(' CASE COM HAS '+comments);
        System.assertEquals(0, comments.size(), 'testValidateBeforeCaseUpdate_error_in_response_Invalid_consignment: No case comment should get generated generated');
        System.assertEquals(false, result, 'testValidateBeforeCaseUpdate_error_in_response_Invalid_consignment: Expected an error in response for no invalid consignment found');
        Test.stopTest();
    }
}