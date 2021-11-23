/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 20/05/2016
  * @description  : Test class for network response addition for any case - this is used by old SSSW - MyNetwork 
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    04.06.18     kalpita.talwadekar@auspost.com.au            updated code for test class failure fix and coding standards TDO
    
*******************************  History ************************************************/
@isTest
private class SSSW_PON_UpdateController_Test{
    
    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_MYNETWORK_PROFILE = 'SSSW - MyNetwork';
    private static final Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_MYNETWORK_PROFILE LIMIT 1];
    
    @testSetup 
    static void testDateCreation() {
        //insert article with Account's APCN
        Article__c testArticle1 = new Article__c();
        testArticle1.Name = 'testArticle1';
        testArticle1.ArticleID__c = 'testArticle1';
        testArticle1.ArticleLodgementDate__c = Date.today();
        testArticle1.SenderPostcode__c = '3000';
        testArticle1.ReceiverPostcode__c = '3006';
        testArticle1.ArticleType__c = 'Regular Parcel';
        testArticle1.Receiver_APCN__c = 'abcd1234';
        insert testArticle1;
        
        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        insert nw;
        
        //insert account
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                        accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        //insert contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.Email = 'bruce@wayne.com';
        Database.insert(con);
        
        //insert case
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        system.debug('csRec1 ' + csRec);
        csRec.ArticleTest__c = testArticle1.Id;  
        csRec.Status = 'Awaiting Network Response';
        csRec.Network__c = nw.id;   
        csRec.CaseOriginator__c = 'Addressee';      
        csRec.EnquirySubType__c = 'Disputed delivery scan';     
        system.debug('csRec2 ' + csRec);
        system.debug('csRec.CaseOriginator__c ' + csRec.CaseOriginator__c);
        Database.insert(csRec);
        
        //insert custom setting
        List<PON_Update_EmailTemplates__c> pmsList = new List<PON_Update_EmailTemplates__c>();
        PON_Update_EmailTemplates__c pms1 = new PON_Update_EmailTemplates__c(Name='1',CaseCondition__c='ResidentialCannot RecallFront Door',Template_API_Name__c='TestTemplate');
        PON_Update_EmailTemplates__c pms2 = new PON_Update_EmailTemplates__c(Name='2',Enquiry_Sub_Type__c='Disputed delivery scan',Field_Set_Name__c='Disputed_Delivery');        
        pmsList.add(pms1);pmsList.add(pms2);
        database.insert(pmsList);
        
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test network response screen for DDS cases
     **********************************************************************/
    @isTest
    static void PON_testResponse() {
        
        //insert template
        Folder fld = [Select Id from Folder where DeveloperName='SSSW_PON_Network_Templates' limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        system.runAs(new User(Id = UserInfo.getUserId())) { 
            Case cse = [Select Id from Case limit 1];//Disputed delivery scan case
            
            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_PON_UpdateController contr = new SSSW_PON_UpdateController (stdCon);
                contr.initialize();
                contr.nResp.Address_Type__c = 'Residential';
                contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';        
                contr.setDeliveryOptions();
                contr.nresp.More_Delivery_Information__c = 'Front Door';
                contr.nResp.Network_Comments__c = 'Standard Response'; 
                contr.nResp.Request_Hold_Case__c = true;
                contr.showEmailTemplate();
            test.stopTest();
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test with existing response - and adding new response to it
     **********************************************************************/
    @isTest
    static void PON_TestNewResponseWithExisting() {
        //insert template
        Folder fld = [Select Id from Folder where DeveloperName='SSSW_PON_Network_Templates' limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        Case cse;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            cse = [Select Id from Case limit 1]; //Disputed delivery scan case
            Network_Response__c nresp = new Network_Response__c();
            nresp.Address_Type__c = 'Residential';
            nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            nResp.Network_Comments__c = 'Standard Response';
            nResp.RelatedCase__c = cse.Id;
            nResp.RelatedCase__c = cse.Id;
            nresp.Request_Hold_Case__c = true;
            database.insert(nResp);
        }
        
        system.runAs(new User(Id = UserInfo.getUserId())) {
            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_PON_UpdateController contr = new SSSW_PON_UpdateController (stdCon);
                contr.initialize();
                contr.setDeliveryOptions();
                contr.nresp.More_Delivery_Information__c = 'Front Door';
                contr.nresp.Request_Hold_Case__c = false;
                contr.noAutoClose = true;           
                //contr.nResp.RelatedCase__c = cse.Id;
                contr.showEmailTemplate();
            test.stopTest();
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test the DDS case with email template
     **********************************************************************/
    @isTest
    static void PON_TestEmailTemplate() {
        //insert template
        Folder fld = [Select Id from Folder where DeveloperName='SSSW_PON_Network_Templates' limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        system.runAs(new User(Id = UserInfo.getUserId())) {
        test.startTest();
            Case cse = [Select Id from Case limit 1]; //Disputed delivery scan case
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_PON_UpdateController contr = new SSSW_PON_UpdateController (stdCon);
            
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';        
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nResp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
        test.stopTest();
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test Non-DDS case
     **********************************************************************/
    @isTest
    static void  PON_TestNonDDS() {
        //insert template
        Folder fld = [Select Id from Folder where DeveloperName='SSSW_PON_Network_Templates' limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        Case cse;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            cse = [Select Id from Case limit 1]; //non Disputed delivery scan case
            cse.EnquirySubType__c = 'Missing Item';
            database.update(cse);
        }
        
        system.runAs(new User(Id = UserInfo.getUserId())) {
        test.startTest();
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_PON_UpdateController contr = new SSSW_PON_UpdateController (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';      
            contr.nResp.Network_Comments__c = 'Standard Response';  
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            //contr.nResp.RelatedCase__c = cse.Id;
            
            contr.nResp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
            contr.updateRespoTemp();
            contr.goBack();
        test.stopTest();
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test DDS with email template
     **********************************************************************/
    @isTest
    static void testScn5() {
        //insert template
        Folder fld = [Select Id from Folder where DeveloperName='SSSW_PON_Network_Templates' limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        Case cse;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            cse = [Select Id from Case limit 1]; //non Disputed delivery scan case
            database.update(cse);
        }
        
        system.runAs(new User(Id = UserInfo.getUserId())) {
        test.startTest();
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_PON_UpdateController contr = new SSSW_PON_UpdateController (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';      
            contr.nResp.Network_Comments__c = 'Standard Response';  
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.noAutoClose = false;
            contr.nResp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
            contr.updateRespoTemp();
            contr.goBack();
        test.stopTest();
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test the existing network response for respond
     **********************************************************************/
    @isTest
    static void  testScn6() {
        //insert template
        Folder fld = [Select Id from Folder where DeveloperName='SSSW_PON_Network_Templates' limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                                            FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        Case cse;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            cse = [Select Id from Case limit 1]; //Disputed delivery scan case
            Network_Response__c nresp = new Network_Response__c();
            nresp.Address_Type__c = 'Residential';
            nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            nResp.Network_Comments__c = 'Standard Response';
            nResp.RelatedCase__c = cse.Id;
            nResp.RelatedCase__c = cse.Id;
            nresp.Request_Hold_Case__c = false;
            database.insert(nResp);
        }
        
        system.runAs(new User(Id = UserInfo.getUserId())) {
            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_PON_UpdateController contr = new SSSW_PON_UpdateController (stdCon);
                contr.initialize();
                contr.setDeliveryOptions();
                contr.nresp.More_Delivery_Information__c = 'Front Door';
                contr.nresp.Request_Hold_Case__c = false;
                contr.noAutoClose = true;           
                contr.showEmailTemplate();
            test.stopTest();
        }
    }
}