/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 20/05/2016
  * @description  : Test class for generating PM26 form
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    20/12/2016          Dion Gunn        Modified to implement mock interface and correctly query ET Custom Settings.
                                        Ideally should be updated to do some actual testing, which it's not currently doing.
    13/02/2017          Dion Gunn       Modified to refer to new custom setting.
    14/05/2020          Swati Mogadala    Modified as per controller to make metods into getter setter methods #INC1579297
    22/10/2020          Neha Mehta        Modified as per controller #REQ2286193
*******************************  History ************************************************/
@isTest
private class SSSW_SendBulkEmailContr_Test{
    
    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_MYNETWORK_PROFILE = 'SSSW - MyNetwork';
    private static final Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_MYNETWORK_PROFILE LIMIT 1];
    
    @testSetup static void testDataCreation() {
        //insert article with Account's APCN
        Article__c testArticle1 = new Article__c();
        testArticle1.Name = 'testArticle1';
        testArticle1.ArticleID__c = 'testArticle1';
        testArticle1.ArticleLodgementDate__c = Date.today();
        testArticle1.SenderPostcode__c = '3000';
        testArticle1.ReceiverPostcode__c = '3006';
        testArticle1.ArticleType__c = 'Regular Parcel';
        //testArticle1.Receiver_APCN__c = 'abcd1234';
        insert testArticle1;
        
        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        insert nw;
        
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                        accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.Email = 'bruce@wayne.com';
        Database.insert(con);
        
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ArticleTest__c = testArticle1.Id;  
        csRec.Status = 'Awaiting Network Response';
        csRec.Network__c = nw.id;    
        csRec.EnquirySubType__c = 'Disputed Delivery';            
        //KPT 03-Nov-2017: Inactivated below since the clear-code mapping changed
        //csRec.ProductCategory__c = 'Domestic Parcels'; 
        csRec.ProductCategory__c = 'Web & Apps'; 
        csRec.caseOriginator__c ='Customer';//Added by Neha Mehta
        csRec.SLATargetDate__c = system.today()-2;    
        csRec.CreatedDate = system.today()-2;               
        Database.insert(csRec);
        String defaultRecTypeId = [Select Id from RecordType where developerName = 'Default_Taks'  limit 1].Id;
        Task tsk = new task(WhatId = csRec.Id,RecordTypeId = defaultRecTypeId,Type = 'Email', whoId = csRec.contact.Id,
                                Interaction_Type__c='Case Origin',Subject='task',
                               Status='Completed',CreatedDate = system.today()-2);
        insert tsk;
        
        Case csReec2 = csRec.clone();
        database.insert(csReec2);

        //ET Token Insert
        //13-02-2017 Dion Gunn: Modified the below to set batch size and refer to correct custom setting
        Exact_Target_LogIn__c etl = new Exact_Target_LogIn__c();
        etl.name = 'marketinglogin';
        etl.clientid__c = 'GdfGsdfsdfdsfHJ9a6lE9ukq';
        etl.clientsecret__c = 'secret stuff';
        etl.message_endpoint__c = 'http://messageendpoint.goes.here.com';
        etl.requestToken_endpoint__c = 'http://allaboutthattokenendpoint.com';
        etl.BulkSSSWBatchSize__c = 40;
        insert etl;
        
    }
    
    /**
      * @description       Method to test the send email functioanlity
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testScn1() {
           Case cse = [Select Id from Case limit 1];
           //insert email template
           Folder fld = [Select Id from Folder where DeveloperName='SSSW_CCC_Bulk_Email_Template' limit 1];
           EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',
                                            Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text', isActive = true);
           insert em;           ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
           SSSW_SendBulkEmailContr contr = new SSSW_SendBulkEmailContr(stdCon);
           contr.initialize();          
          // contr.getType();
          // contr.getStatus();
          List<SelectOption> Type= contr.Type;
          List<SelectOption> Status= contr.Status;
          List<SelectOption> Queue= contr.QueueNames;
          // contr.getEmailTemplates();
           
           //Folder fld = new Folder(Name='SSSW_CCC_Bulk_Email_Template' , DeveloperName='SSSW_CCC_Bulk_Email_Template');
           //insert fld;
           
           List<SelectOption> ProdCat= contr.ProdCat;
           List<SelectOption> ProdSubCat= contr.ProdSubCat;
           List<SelectOption> EnqySubType= contr.EnqySubType;
           //contr.getProdCat();
           //contr.getProdSubCat();
          // contr.getEnqySubType();
           contr.cse.SLATargetDate__c = system.today()-4;
           contr.Rangecse.CreatedDate =  system.today()-4;
           contr.cse.LastStatusUpdate__c = system.today()-4;
           contr.Rangecse.LastStatusUpdate__c = system.today()+2;
           contr.fOpList[0].operator = '>';
           contr.fOpList[1].operator = '>';
           contr.fOpList[2].operator = '>';
           contr.fOpList[3].operator = '>';
           contr.fOpList[4].operator = '>';
           contr.fOpList[5].operator = '<';
           contr.showNoTask = false;
          Test.setMock(HttpCalloutMock.class, new ETIntegrationMock('SendEmail'));
           test.startTest();
               contr.getCases();
               contr.sendEmail();
               contr.templateId = em.Id;
               contr.sendEmail();
               contr.getEmailTemplates();
           test.stopTest();
    }
    
    /**
      * @description       Method to test the send email functioanlity
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testScn2() {
           Case cse = [Select Id from Case limit 1];
           //insert email template
           Folder fld = [Select Id from Folder where DeveloperName='SSSW_CCC_Bulk_Email_Template' limit 1];
           EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',
                                            Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text', isActive = true);
           insert em;           ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
           SSSW_SendBulkEmailContr contr = new SSSW_SendBulkEmailContr(stdCon);
           contr.initialize();          
           //contr.getType();
           //contr.getStatus();
           //contr.getQueNames();
           List<SelectOption> Types= contr.Type;
           List<SelectOption> Status= contr.Status;
           List<SelectOption> Queue= contr.QueueNames;
           //contr.getEmailTemplates();
           
           //Folder fld = new Folder(Name='SSSW_CCC_Bulk_Email_Template' , DeveloperName='SSSW_CCC_Bulk_Email_Template');
           //insert fld;
          // contr.getEmailTemplates();
           List<SelectOption> ProdCat= contr.ProdCat;
           List<SelectOption> ProdSubCat= contr.ProdSubCat;
           List<SelectOption> EnqySubType= contr.EnqySubType;
           //contr.getProdCat();
           //contr.getProdSubCat();
           //contr.getEnqySubType();
           contr.cse.SLATargetDate__c = system.today()-4;
           contr.Rangecse.CreatedDate =  system.today()-4;
           contr.cse.LastStatusUpdate__c = system.today()-4;
           contr.Rangecse.LastStatusUpdate__c = system.today()+2;
           contr.fOpList[0].operator = '>';
           contr.fOpList[1].operator = '>';
           contr.fOpList[2].operator = '>';
           contr.fOpList[3].operator = '>';
           contr.fOpList[4].operator = '>';
           contr.fOpList[5].operator = '<';
           contr.showNoTask = true;
           Test.setMock(HttpCalloutMock.class, new ETIntegrationMock('SendEmail'));
           test.startTest();
               contr.getCases();
               contr.sendEmail();
               contr.templateId = em.Id;
               contr.sendEmail();
               contr.getEmailTemplates();
           test.stopTest();
    }

    public class ETIntegrationMock implements HttpCalloutMock {

        public String body;

        public ETIntegrationMock(String requestType) {
            if(requestType.equals('Token')) {
                this.body = '{"accessToken": "7RxKd99XIZuw7YhPKFHZ93Rd","expiresIn": 3479}';
            }
            if(requestType.equals('SendEmail')) {
                this.body = '{"requestId":"dd63978e-bca6-4eb8-b3ae-9e98949b8703","responses":[{"recipientSendId":"dd63978e-bca6-4eb8-b3ae-9e98949b8703","hasErrors":false,"messages":["Queued"]}]}';
            }
        }

        // Implement this interface method
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }
    }
    
}