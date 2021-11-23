/**
 ** Description: Test Class for StarTrackScanEventsSidePanel_ControllerX class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: DEC.1.2015
 ** History:--------------------------------------------
 **         DEC.1.2015 David Catindoy - Created
 **         FEB.22.2015 Patrick James Franco - Added Scan Events callout test methods
 **/
@isTest
private class StarTrackScanEventsSidePanel_ConX_Test {

     @testSetup static void testSetup(){
        
        List<Consignment_Search_Settings__c> cssList = new List<Consignment_Search_Settings__c>();        
        cssList.add(new Consignment_Search_Settings__c(Name = 'Search Scan Event Timeout', Field_Name__c = 'Search Scan Event Timeout', Date_Type__c = true));
        INSERT cssList;

        Id orgAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();

        Account testAccount = new Account();
        testAccount.RecordTypeId = orgAccRecTypeId;
        testAccount.Name = 'Test Account A';
        testAccount.Type = 'Small Business';
        INSERT testAccount;

        Entitlement testEntitlement = new Entitlement();
        testEntitlement.Name = 'Test Entitlement';
        testEntitlement.AccountId = testAccount.Id;
        INSERT testEntitlement;

        StarTrack_Settings__c stSettings = new StarTrack_Settings__c();
        stSettings.Use_Continuation_for_Consignment_Search__c = true;
        stSettings.Get_Latest_Scan_Events_On_Load__c = true;
        stSettings.Get_Latest_Scan_Events__c = true;
        stSettings.Case_Entitlement__c = testEntitlement.Id;
        stSettings.StarTrack_ConSearch_Authentication_Level__c = 1;
        stSettings.StarTrack_ConSearch_BA_Password__c = 'U0ZVc2VyVGVzdDE6U0ZVc2VyVGVzdDEh';
        stSettings.StarTrack_ConSearch_Client_Cert__c = 'StarTrack_ConSearch';
        INSERT stSettings;

        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;

        Article__c testCon = TestDataProvider.createTestArticle();
        testCon.Network__c = testNetwork.Id;
        INSERT testCon;

        List<EventMessage__c> conEvents = TestDataProvider.createEventMessages(5, testCon, 'Consignment');
        INSERT conEvents;

        List<Article__c> listOfCon = TestDataProvider.createArticle('Test', 10, null);
        for(Article__c con : listOfCon){
            con.Consignment__c = testCon.Id;
            con.Network__c = testNetwork.Id;
        }
        INSERT listOfCon;

        List<EventMessage__c> labelEvents = new List<EventMessage__c>();
        Integer counter = 1;
        for(Article__c con : listOfCon){
            //don't set label events for the last 3 articles
            if (counter < listOfCon.size() - 3) {
                labelEvents.addAll(TestDataProvider.createEventMessages(3, con, 'Label'));
            }
            counter++;
        }
        INSERT labelEvents;

        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'Email';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Credit Dispute Claim').getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ArticleTest__c = testCon.Id;
        INSERT testCase;
    }

    @isTest static void testScanEvents(){
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
        Test.stopTest();

        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.labelEvents.size()>0);
        System.assert(ctrl.consignmentEvents.size()==5);
        System.assert(ctrl.labelEvents.size()==10);
    }
    
    @isTest 
    public static void testSearchEventMessagesContinuation(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = true,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Log_For__c = 'ALL USER'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            //ctrl.searchLocalEventMessages();
        
        // Invoke the continuation by calling the action method
        Continuation conti = ctrl.searchEventMessages();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_eventsResp());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(ctrl, conti);
        
        Test.stopTest();

        System.debug(ctrl);
    }

    @isTest 
    public static void testSearchEventMessagesContinuation2(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = true,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Log_For__c = 'ALL USER'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            //ctrl.searchLocalEventMessages();
        
        // Invoke the continuation by calling the action method
        Continuation conti = ctrl.searchEventMessages();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_eventsResp());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(ctrl, conti);
        
        Test.stopTest();

        System.debug(ctrl);
    }
    
    @isTest 
    public static void testSearchEventMessages_std(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Log_For__c = 'ALL USER'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            ctrl.searchEventMessages();
        Test.stopTest();

        System.debug(ctrl);        
    }
    
    @isTest 
    public static void testSearchEventMessages_std_ex(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Log_For__c = 'ALL USER'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            StartrackWebSvcCalloutMockEx mock = new StartrackWebSvcCalloutMockEx();
            mock.isDml = false;
            mock.errorMessage = 'Time out';
            Test.setMock(WebServiceMock.class, mock);
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            ctrl.searchEventMessages();
            ctrl.logTime();

            StarTrackScanEventsSidePanel_ControllerX.SortWrapper sw = new StarTrackScanEventsSidePanel_ControllerX.SortWrapper(ctrl.labelEvents[0], ctrl.labelSortBy, ctrl.labelOrder);
            ctrl.labelEvents[0].ActualDateTime__c = ctrl.labelEvents[0].ActualDateTime__c.addDays(1);
            StarTrackScanEventsSidePanel_ControllerX.SortWrapper sw2 = new StarTrackScanEventsSidePanel_ControllerX.SortWrapper(ctrl.labelEvents[0], ctrl.labelSortBy, ctrl.labelOrder);

            sw.compareTo(sw2);

        Test.stopTest();

        System.debug(ctrl);        
    }

    @isTest 
    public static void testSearchEventMessages_std_ex2(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Error__c = 'error'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            StartrackWebSvcCalloutMockEx mock = new StartrackWebSvcCalloutMockEx();
            mock.isDml = false;
            mock.errorMessage = 'Time out';
            Test.setMock(WebServiceMock.class, mock);
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            ctrl.searchEventMessages();
        Test.stopTest();

        System.debug(ctrl);        
    }

    @isTest 
    public static void testSearchEventMessages_std_ex3(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Client_Cert_Error__c = 'error'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            StartrackWebSvcCalloutMockEx mock = new StartrackWebSvcCalloutMockEx();
            mock.isDml = false;
            mock.errorMessage = 'Time out';
            Test.setMock(WebServiceMock.class, mock);
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            ctrl.searchEventMessages();
        Test.stopTest();

        System.debug(ctrl);        
    }

    @isTest 
    public static void testSearchEventMessages_std_onload(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        Log_For__c = 'ALL USER',
        Get_Latest_Scan_Events_On_Load__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            ctrl.searchEventMessagesOnLoad();
        Test.stopTest();

        System.debug(ctrl);
        
    }

    @isTest 
    public static void testSearchEventMessages_std_onload_ex(){
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Get_Latest_Scan_Events__c = true,
        Log_For__c = 'ALL USER',
        Get_Latest_Scan_Events_On_Load__c = true,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        StarTrack_ConSearch_Client_Cert__c = 'cert'
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.ArticleID__c FROM Case WHERE Subject = 'Test Case'];
        Test.setCurrentPage(Page.StarTrackScanEventsSidePanel);

        Test.startTest();
            StartrackWebSvcCalloutMockEx mock = new StartrackWebSvcCalloutMockEx();
            mock.isDml = false;
            mock.errorMessage = '';
            Test.setMock(WebServiceMock.class, mock);
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
            StarTrackScanEventsSidePanel_ControllerX ctrl = new StarTrackScanEventsSidePanel_ControllerX(sc);
            ctrl.searchEventMessagesOnLoad();
        Test.stopTest();

        System.debug(ctrl);
        
    }
}