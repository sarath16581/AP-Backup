/**************************************************
Description:    Test class for  StarTrack Consignment Search Controller
History:
--------------------------------------------------
Mar 4 2016 Jen Karen Tan - Updated test class for code documentation and IVR cases coverage
21.06.2018 kalpita.talwadekar@auspost.com.au  Updated test class for code documentation and IVR cases coverage
10.06.2020 Lija Jawahar  Updated test class Omni-channel bug fix- removal of standard controller
14.05.2021 Naseer Abbasi  Removed references for User Support Queries RT
**************************************************/
@isTest
private class StarTrack_ConsignSearch_Controller_Test {
  
    @testSetup 
    static void testSetup(){

        List<Consignment_Search_Settings__c> cssList = new List<Consignment_Search_Settings__c>();
        cssList.add(new Consignment_Search_Settings__c(Name = 'Consignment No.', Callout_Search_Type__c = 'CONSIGNMENT', Date_Type__c = false, 
            Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Name', Exact_Search__c = true, Article_Case_field__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Billing Account No.', Callout_Search_Type__c = 'BILLINGACCOUNT', Date_Type__c = false, 
            Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Billing_Account__r.LEGACY_ID__c', Exact_Search__c = false, Article_Case_field__c = true,
            Show_Date_Field__c = true, Show_Suburb_Field__c = true));            
        cssList.add(new Consignment_Search_Settings__c(Name = 'Page title', Field_Name__c = 'Consignment Search'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Custom', Field_Name__c = 'Custom', Show_Date_Range__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Last Day', Field_Name__c = '1'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of search characters', Field_Name__c = '2'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'date diffrence', Field_Name__c = '30'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Special Characters', Field_Name__c = '*,%?\'[]{}'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Dispatch Date', Field_Name__c = 'Dispatch_Date__c', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Error on Consignment search', Field_Name__c = 'There was an error retrieving Consignment Data', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'No selected Consignment', Field_Name__c = 'No selected Consignment', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'No selected Call Purpose', Field_Name__c = 'No selected Call Purpose', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Case Create Timeout', Field_Name__c = 'Case Create Timeout', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Assign Consignment Timeout', Field_Name__c = 'Assign Consignment Timeout', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Error on Case update', Field_Name__c = 'Error on Case update', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Error on Case create', Field_Name__c = 'Error on Case create', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Enter dates', Field_Name__c = 'Enter dates', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'date validation', Field_Name__c = 'date validation', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'date duration error', Field_Name__c = 'date duration error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of character error', Field_Name__c = 'Number of character error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Suburb error', Field_Name__c = 'Suburb error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Invalid character error', Field_Name__c = 'Invalid character error', Date_Type__c = true));

        INSERT cssList;
        
        
    }

    
    @isTest static void testConsignSearch_valErr_noDate() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
      
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        

        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article == null);
    }

    @isTest static void testConsignSearch_valErr_invalidDates() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.datesFilter.Closed_Date__c = Date.today().addDays(1);
        cont.datesFilter.Action_Date__c = Date.today();
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article == null);
    }

    @isTest static void testConsignSearch_valErr_invalidDates2() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
         case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(), 
                                  Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.datesFilter.Closed_Date__c = Date.today();
        cont.datesFilter.Action_Date__c = Date.today().addDays(40);
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article == null);
    }    

    @isTest static void testConsignSearch_valErr_invalidSearchStr() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(), 
                                  Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.datesFilter.Closed_Date__c = Date.today();
        cont.datesFilter.Action_Date__c = Date.today();
        cont.searchString = '1';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article == null);
    }

    @isTest static void testConsignSearch_valErr_noSuburb() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.datesFilter.Closed_Date__c = Date.today();
        cont.datesFilter.Action_Date__c = Date.today();
        cont.searchString = '1WEFS';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = '';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article == null);
    }

    @isTest static void testConsignSearch_valErr_invalidSearchStr2() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.datesFilter.Closed_Date__c = Date.today();
        cont.datesFilter.Action_Date__c = Date.today();
        cont.searchString = '1/*&%%';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'suburb';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article == null);
    }
    
    @isTest static void testConsignSearch_std() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        
        cont.searchConsignment();
        cont.logTime();
        Test.stopTest();
        System.assert(cont.lst_article.size() > 0);
        System.assertNotEquals(cont.lst_article, null);        
    }
    
    @isTest static void testConsignSearch_std_excp() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = 'Custom';
        cont.datesFilter.Closed_Date__c = Date.today();
        cont.datesFilter.Action_Date__c = Date.today();
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article.size() == 0);
        System.assert(cont.lst_article.isEmpty());        
    }
    
    @isTest static void testConsignSearch_std_excp_to() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        cont.isConsole = false;

        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMockEx_TimeOut());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = '1';
//        cont.datesFilter.Closed_Date__c = Date.today();
//        cont.datesFilter.Action_Date__c = Date.today();
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article.size() == 0);
        System.assert(cont.lst_article.isEmpty());        
    }

    @isTest static void testConsignSearch_std_excp2() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Authentication_Error__c = 'Error',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        cont.isConsole = false;

        Test.startTest();
          StartrackWebSvcCalloutMockEx mockException = new StartrackWebSvcCalloutMockEx();
          mockException.errorMessage = 'Failed to get next element';
          mockException.isDml = false;
          Test.setMock(WebServiceMock.class, mockException);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.dateType = 'Dispatch_Date__c';
        cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article.size() == 0);
        System.assert(cont.lst_article.isEmpty());        
    }    

    @isTest static void testConsignSearch_std_excp3() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert_Error__c = 'Error',
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669', Name = 'testSearch');
        INSERT testArticle;
        
        Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        cont.isConsole = false;

        Test.startTest();
          StartrackWebSvcCalloutMockEx mockException = new StartrackWebSvcCalloutMockEx();
          mockException.errorMessage = 'Could not find client cert with dev name';
          mockException.isDml = false;
          Test.setMock(WebServiceMock.class, mockException);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        List<SelectOption> sO = cont.getItems;
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        //cont.isConsole = true;
        //cont.dateType = 'Dispatch_Date__c';
        //cont.fieldName = 'Billing_Account__r.LEGACY_ID__c';
        //cont.suburb = 'test';
        
        cont.searchConsignment();
        Test.stopTest();
        System.assert(cont.lst_article.size() == 0);
        System.assert(cont.lst_article.isEmpty());        
    }    
    
    @isTest static void testProceedCreateCase_std() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669', Freight_Amount__c = 1234, CID__c = '20170203');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.getCaseRecordType, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() > 0);
    }
    
    @isTest static void testProceedCreateCase_std_excp() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Time out';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = false;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testProceedCreateCase_std_excp2() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Authentication_Error__c = 'Error',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone2';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Failed to get next element';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testProceedCreateCase_std_excp3() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert_Error__c = 'Error',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone2';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Could not find client cert with dev name';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testProceedCreateCase_std_excp4() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 3,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone2';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = '';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }

    @isTest static void testProceedCreateCase_std_excp5() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 3,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone2';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.isDml = true;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testProceedCreateCase_std_excp_invalid() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        //c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Signature XString: data value too large';
          mockCalloutEx.isDml = false;
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.createCase();
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.createCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testAssignToCase_std() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();


        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.assignToCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() > 0);

    }
    
    @isTest static void testAssignToCase_std_excp() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        StarTrack_ConSearch_Client_Cert__c = 'cert',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = '';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = false;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.createCaseInd = true;
        
        cont.assignToCase();
        
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.assignToCase();
        
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testAssignToCase_std_excp2() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 2,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Time out';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.assignToCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testAssignToCase_std_excp3() {
        
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 3,
        StarTrack_ConSearch_Authentication_Error__c = 'Error',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Failed to get next element';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.assignToCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }
    
    @isTest static void testAssignToCase_std_excp4() {
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 3,
        StarTrack_ConSearch_Client_Cert_Error__c = 'Error',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.errorMessage = 'Could not find client cert with dev name';
          mockCalloutEx.isDml = false;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.assignToCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
    }

    @isTest static void testAssignToCase_std_excp5() {
        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = true,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = false,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 3,
        StarTrack_ConSearch_Client_Cert_Error__c = 'Error',
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
          StartrackWebSvcCalloutMockEx mockCalloutEx = new StartrackWebSvcCalloutMockEx();
          mockCalloutEx.isDml = true;
          Test.setMock(WebServiceMock.class, mockCalloutEx);
          System.assertNotEquals(cont.getDateTypes, null);
          System.assertNotEquals(cont.getDateRange, null);
          System.assertNotEquals(cont.pageTitle, null);
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        cont.assignToCase();
        Test.stopTest();
        List<Case> retrievedCase = new List<Case>([SELECT Id FROM Case WHERE Consignment_Unique_External_ID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669']);
        System.assert(retrievedCase.size() == 0);
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
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        Test.startTest();
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
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
        // check if there are article/s retrieved
        System.assert(cont.lst_article.size() == 1);
        
    }
    
    @isTest
    public static void testConsignSearch_multipleResponse() {

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = true,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
      Case testCase = new case (RecordtypeId =schema.SObjectType.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),Subject = 'test case');
        insert testCase;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',testCase.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Test.startTest();
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        // Invoke the continuation by calling the action method
        Continuation conti = cont.searchConsignment();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_multConsign());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);
        // check if there are article/s retrieved
        System.assert(cont.lst_article.size() > 1);
    }
    
    @isTest
    public static void testConsignSearch_proceedCreateCase() {

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = true,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone'; 
        insert c;
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        INSERT testArticle;
        
        Test.startTest();
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        // Invoke the continuation by calling the action method
        Continuation conti = cont.createCase();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_uniqueIdResp());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);

        // result is the return value of the callback
        System.assertEquals(null, result);
        // check if there are article/s retrieved
        
        Test.stopTest();
    }
    
    @isTest
    public static void testConsignSearch_assignToCase() {

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
        EMS_Endpoint__c = 'testendpt',
        Web_Service_Callout_Timeout__c = 10,
        Use_Continuation_for_Consignment_Search__c = true,
        XML_Logging__c = true,
        Logging__c = true,
        Log_For__c = 'ALL USER',
        StarTrack_ConSearch_Authentication_Level__c = 1,
        Sync_Web_Service_Callout_Timeout__c = 5
        );
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        // Invoke the continuation by calling the action method
        Continuation conti = cont.assignToCase();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_uniqueIdResp());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);

        // result is the return value of the callback
        System.assertEquals(null, result);
        // check if there are article/s retrieved
        
        Test.stopTest();
    }
    
    @isTest
    public static void testConsignSearch_assignToCase_clientCert() {

        INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Get_All_Consignment_Details__c = false,
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
        
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'Phone';
        insert c;
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();

        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669');
        //INSERT testArticle;
        
        Test.startTest();
        cont.dateRange = '1';
        cont.searchString = 'testSearch';
        cont.isConsole = true;
        cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
        cont.map_article = new Map<String, Article__c>();
        cont.map_article.put('TR2_66a94898-0927-450e-abfa-defa36972669', testArticle);
        cont.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
        cont.createCaseInd = true;
        
        // Invoke the continuation by calling the action method
        Continuation conti = cont.assignToCase();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_uniqueIdResp());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);

        // result is the return value of the callback
        System.assertEquals(null, result);
        // check if there are article/s retrieved
        
        Test.stopTest();
    }
    
    
      /**********************************************************************
     *  Scenario:
     *      test retreival of IVR cases
     ********************************************************************/
    @isTest
    static void testConsignSearch_IVRCases() {
        //create an IVR case for Startrack record type
        Case c = new Case();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        c.RecordTypeId = caseRecType;
        c.Call_Purpose__c = 'Track & Trace';
        c.Origin = 'IVR';
        database.insert(c);
        
        test.startTest();
        
        PageReference pageRef = Page.StarTrackConsignmentSearch;
        test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('caseId',c.Id);
        StarTrack_Case_ConsignSearch_ControllerX cont = new StarTrack_Case_ConsignSearch_ControllerX();
            //call the method to search for IVR cases from UI
            cont.getRelatedCasesIVR(); 
            cont.getCases();
            
            // result is the return value of the IVR case
            System.assertNotEquals(null, cont.lst_case_ivr);
            
        Test.stopTest();      
    }
}