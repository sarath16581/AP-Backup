/**
 ** Description: Test Class for StarTrackViewAllScanEvents_ControllerX class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: DEC.15.2015
 ** History:--------------------------------------------
 **         DEC.15.2015 David Catindoy - Created
 **/
@isTest
private class StarTrackViewAllScanEvents_ConX_Test {

    @testSetup static void testSetup(){

        List<Consignment_Search_Settings__c> cssList = new List<Consignment_Search_Settings__c>();        
        cssList.add(new Consignment_Search_Settings__c(Name = 'Search Scan Event Timeout', Field_Name__c = 'Search Scan Event Timeout', Date_Type__c = true));
        INSERT cssList;

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
        for(Article__c con : listOfCon){
            labelEvents.addAll(TestDataProvider.createEventMessages(3, con, 'Label'));
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
	@isTest static void testViewAllScanEvents(){
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        Test.setCurrentPage(Page.StarTrackViewAllScanEvents);
        
        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec.ArticleTest__r);
            StarTrackViewAllScanEvents_ControllerX ctrl = new StarTrackViewAllScanEvents_ControllerX(sc);
        Test.stopTest();
        
        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.childConsignments.size()>0);
        System.assert(ctrl.consignmentEvents.size()==5);
        System.assert(ctrl.childConsignments.size()==10);
        
        for(Article__c con : ctrl.childConsignments){
            System.assert(con.Event_Messages__r.size() > 0);
            System.assert(con.Event_Messages__r.size() == 3);
        }
	}
    @isTest static void testSearchLocalEventMessages(){
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        Test.setCurrentPage(Page.StarTrackViewAllScanEvents);
        
        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec.ArticleTest__r);
            StarTrackViewAllScanEvents_ControllerX ctrl = new StarTrackViewAllScanEvents_ControllerX(sc);
            ctrl.searchLocalEventMessages();
        Test.stopTest();
        
        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.childConsignments.size()>0);
        System.assert(ctrl.consignmentEvents.size()==5);
        System.assert(ctrl.childConsignments.size()==10);
        
        for(Article__c con : ctrl.childConsignments){
            System.assert(con.Event_Messages__r.size() > 0);
            System.assert(con.Event_Messages__r.size() == 3);
        }
    }
    
    @isTest static void testSearchEventMessagesWebSvc(){
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        Get_Latest_Scan_Events__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        Test.setCurrentPage(Page.StarTrackViewAllScanEvents);
        
        Test.startTest();
            Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec.ArticleTest__r);
            StarTrackViewAllScanEvents_ControllerX ctrl = new StarTrackViewAllScanEvents_ControllerX(sc);
            ctrl.searchEventMessagesCont();
        Test.stopTest();
        
        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.childConsignments.size()>0);
        System.assert(ctrl.consignmentEvents.size()==5);
        System.assert(ctrl.childConsignments.size()==10);
        
        for(Article__c con : ctrl.childConsignments){
            System.assert(con.Event_Messages__r.size() > 0);
            System.assert(con.Event_Messages__r.size() == 3);
        }
        
    }

    @isTest static void testSearchEventOnDemandMessagesWebSvc(){
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        Get_Latest_Scan_Events__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        GetArticleEventsOnDemand__c = true,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        Test.setCurrentPage(Page.StarTrackViewAllScanEvents);
        
        Test.startTest();
            Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec.ArticleTest__r);
            StarTrackViewAllScanEvents_ControllerX ctrl = new StarTrackViewAllScanEvents_ControllerX(sc);
            ctrl.articleId = caseRec.ArticleTest__r.Name;
            ctrl.searchEventMessagesOnDemand();
        Test.stopTest();
        
        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.childConsignments.size()>0);
        System.assert(ctrl.consignmentEvents.size()==5);
        System.assert(ctrl.childConsignments.size()==10);
        
        for(Article__c con : ctrl.childConsignments){
            System.assert(con.Event_Messages__r.size() > 0);
            System.assert(con.Event_Messages__r.size() == 3);
        }
        
    }

    @isTest static void testSearchEventOnDemandMessagesWebSvc2(){
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        Get_Latest_Scan_Events__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        StarTrack_ConSearch_BA_Password__c = 'cert',
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        GetArticleEventsOnDemand__c = true,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        Test.setCurrentPage(Page.StarTrackViewAllScanEvents);
        
        Test.startTest();
            Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec.ArticleTest__r);
            StarTrackViewAllScanEvents_ControllerX ctrl = new StarTrackViewAllScanEvents_ControllerX(sc);
            ctrl.articleId = caseRec.ArticleTest__r.Name;
            ctrl.searchEventMessagesOnDemand();
        Test.stopTest();
        
        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.childConsignments.size()>0);
        System.assert(ctrl.consignmentEvents.size()==5);
        System.assert(ctrl.childConsignments.size()==10);
        
        for(Article__c con : ctrl.childConsignments){
            System.assert(con.Event_Messages__r.size() > 0);
            System.assert(con.Event_Messages__r.size() == 3);
        }
        
    }

    @isTest static void testSearchEventMessagesWebSvc_ex(){
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        Get_Latest_Scan_Events__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        StarTrack_ConSearch_Authentication_Level__c = 1,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        Test.setCurrentPage(Page.StarTrackViewAllScanEvents);
        
        Test.startTest();
            StartrackWebSvcCalloutMockEx mock = new StartrackWebSvcCalloutMockEx();
            mock.isDml = false;
            mock.errorMessage = 'Time out';
            Test.setMock(WebServiceMock.class, mock);
            ApexPages.StandardController sc = new ApexPages.StandardController(caseRec.ArticleTest__r);
            StarTrackViewAllScanEvents_ControllerX ctrl = new StarTrackViewAllScanEvents_ControllerX(sc);
            ctrl.eventMessageId = '';
            ctrl.searchEventMessagesCont();
            ctrl.toEventPage();
        Test.stopTest();
        
        System.assert(ctrl.consignmentEvents.size()>0);
        System.assert(ctrl.childConsignments.size()>0);
        
    }

    @isTest
    public static void testConsignSearch_singleResponse() {

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
        
        Case caseRec = [SELECT Id, Network__c, ArticleTest__c, ArticleTest__r.Name FROM Case WHERE Subject = 'Test Case']; 
        List<Article__c> testArticle = new List<Article__c>([SELECT Id FROM Article__c WHERE Id =: caseRec.ArticleTest__c]);

        ApexPages.StandardController sc = new ApexPages.StandardController(testArticle[0]);
        StarTrackViewAllScanEvents_ControllerX cont = new StarTrackViewAllScanEvents_ControllerX(sc);

        Test.startTest();        
        cont.articleId = caseRec.ArticleTest__r.Name;
        // Invoke the continuation by calling the action method
        Continuation conti = cont.searchConsignment();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);
        // check if there are events retrieved
        System.assert(cont.consignmentEvents.size()>0);
        System.assert(cont.childConsignments.size()>0);
        
    }
}