/***************************************************************************************************
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Test class for SSSWDefaultTemplateLoader

History:
-----------------------------------------------------------------------------------------
March 1, 2016   David Catindoy - Created
13-06-2018      kalpita.talwadekar@auspost.com.au
***************************************************************************************************/

@IsTest
public class SSSWDefaultTemplateLoader_Test{
    
    @testSetup 
    static void  testSetup(){
        //insert ST custom setting
        List<StarTrack_Default_Email_Template__c> defaultTemplateList = new List<StarTrack_Default_Email_Template__c>();
        defaultTemplateList.add(new StarTrack_Default_Email_Template__c(Name = 'Voice of Customer Enquiry', Email_Template_Name__c = ''));
        defaultTemplateList.add(new StarTrack_Default_Email_Template__c(Name = 'Business Solutions Communications', Email_Template_Name__c = ''));
        defaultTemplateList.add(new StarTrack_Default_Email_Template__c(Name = 'SSSW', Email_Template_Name__c = 'SSSW_Default'));
        defaultTemplateList.add(new StarTrack_Default_Email_Template__c(Name = 'StarTrack', Email_Template_Name__c = 'StarTrack_Default'));
        defaultTemplateList.add(new StarTrack_Default_Email_Template__c(Name = 'Delivery Enquiry', Email_Template_Name__c = 'StarTrack_Default'));
        defaultTemplateList.add(new StarTrack_Default_Email_Template__c(Name = 'General Enquiry', Email_Template_Name__c = 'Star_Track_Default'));
        insert defaultTemplateList;

        //update settings on ST custom setting
        StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();
        customSetting.Number_of_Hours_per_Business_Days__c = 10;
        customSetting.Number_of_Business_Days__c = 10;
        customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        upsert customSetting;
        
        //insert test network
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        insert testNetwork;

        //insert test article
        Article__c testArticle = new Article__c(ArticleID__c='TR2_66a94898-0927-450e-abfa-defa36972669', Source_System__c = 'TRACK & TRACE');
        insert testArticle;

        //insert POD
        Proof_of_Delivery__c testPOD = new Proof_of_Delivery__c(Name = 'testPOD', Consignment__c = testArticle.Id);
        insert testPOD;

        //insert test caase
        Case testCase = new Case();
        testCase.Status = 'New';
        testCase.Type = 'Delivery Enquiry';
        testCase.Subject = 'Sample Case';
        testCase.ProductCategory__c = 'Domestic Parcels';
        testCase.Origin = 'Email';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ArticleTest__c = testArticle.Id;
        insert testCase;

        //insert attachment for above case
        List<Attachment> att = new List<Attachment>();
        att.add(new Attachment(ParentId = testPOD.Id, Body = Blob.valueOf('test'), Name = 'testAtt'));
        att.add(new Attachment(ParentId = testCase.Id, Body = Blob.valueOf('test'), Name = 'testAtt'));
        insert att;
    }
    
    /**********************************************************************
     *  Scenario:
     *      test default template load
     ********************************************************************/
    @isTest
    static void testTemplateLoader(){
        Id recType1, recType2;
        Id template1, template2;

        //query for case record types SSSW and non-SSSW
        for(RecordType rt : [ SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType='Case' ]){

            if(rt.Name.contains('SSSW')){

                recType1 = rt.Id;
            } else if(rt.Name.contains('ULD Allocation')){

                recType2 = rt.Id;
            }

            if(recType1 != null && recType2 != null){
                break;
            }
        }

        //create SSSW Case
        Case caseRec1 = new Case(
                Status = 'New',
                Type = 'General Enquiry',
                Subject = 'abc',
                ProductCategory__c = 'Domestic Parcels',
                RecordTypeId = recType1
        );
        insert caseRec1;

        caseRec1 = [SELECT Id, CaseNumber, StarTrack_From_Address__c, RecordType.Name, RecordType.DeveloperName FROM Case WHERE Id =:caseRec1.Id];

        //create Non-SSSW Case
        Case caseRec2 = new Case(
                Status = 'New',
                Type = 'General Enquiry',
                Subject = 'abd',
                ProductCategory__c = 'Domestic Parcels',
                RecordTypeId = recType2
        );
        insert caseRec2;

        caseRec2 = [SELECT Id, CaseNumber, StarTrack_From_Address__c, RecordType.Name, RecordType.DeveloperName FROM Case WHERE Id =:caseRec2.Id];
        
        Test.startTest();
            //set standard controller for case 
            SSSWDefaultTemplateLoader templateLoader = new SSSWDefaultTemplateLoader();
            //call template loading methods
            template1 = templateLoader.getTemplateId(caseRec1);
            template2 = templateLoader.getTemplateId(caseRec2);
        Test.stopTest();
        
        System.assertNotEquals(null, template1,
                            'SSSWDefaultTemplateLoader_Test_testTemplateLoader: template is generated for SSSW case');

        System.assertEquals(null, template2,
                            'SSSWDefaultTemplateLoader_Test_testTemplateLoader: template is generated for Non-SSSW case');
    }

    /**********************************************************************
     *  Scenario:
     *      test template load for Startrack case
     ********************************************************************/
    @isTest
    static void  testStarTrackTemplates(){
        //insert test account
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        INSERT testAccount;
        testAccount.Legacy_Id__c = '60000000';
        UPDATE testAccount;

        //insert a billing account
        Billing_Account__c testBillingAcc = TestDataProvider.createBillingAccount('', 1,new List<Account>{testAccount})[0];
        testBillingAcc.Depot_Collection__c = 'No';
        testBillingAcc.Redirection__c = 'No';
        testBillingAcc.Redelivery__c = 'No';
        INSERT testBillingAcc;
        
        //retreive the case record types for StarTrack
        Id sales = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        Id cdc = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Credit Dispute Claim').getRecordTypeId();
        Id pbe = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Id general = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
        Id transit = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Transit Warranty Claim').getRecordTypeId();
        Id voc = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Voice of Customer Enquiry').getRecordTypeId();
        Id bsc = Schema.SObjectType.Case.getRecordTypeInfosByName().get('StarTrack Business Solutions Communications').getRecordTypeId();
        
        Test.startTest();
            //create a ST test case
            Case testSales = new Case();
            testSales.RecordTypeId = sales;
            testSales.Recent_Caller_First_Name__c = 'David';
            testSales.Recent_Caller_Last_Name__c = 'Catindoy';
            testSales.Call_Purpose__c = 'Other';
            testSales.Recent_Caller_Email__c = 'david.catindoy@cloudsherpas.com';
            testSales.Recent_Caller_Phone_Number__c = '09126893944';
            testSales.Related_Billing_Account__c = testBillingAcc.Id;
            testSales.Recent_Contact_Mobile_Number__c= '0412345678';
            testSales.Recent_Caller_Type__c='Sender';
            insert testSales;

            testSales = [
                 SELECT
                     Id, CaseNumber, StarTrack_From_Address__c,
                     RecordType.Name, RecordType.DeveloperName
                 FROM
                    Case
                 WHERE
                    Id =: testSales.Id
            ];
            
            SSSWDefaultTemplateLoader templateLoader = new SSSWDefaultTemplateLoader();
            Test.stopTest();

        System.assertNotEquals(null, templateLoader.getTemplateId(testSales),
                                'SSSWDefaultTemplateLoader_Test_testStarTrackTemplates :template loader returns a template');
    }
    
    /**********************************************************************
     *  Scenario:
     *      test class for email feed quick action
     ********************************************************************/
    @isTest
    static void  testCaseEmailFeed() {
        //Create test data here
        Exception failureDuringExecution = null;
        Case queryCase = [ SELECT Id FROM Case LIMIT 1];

        //create map of default settings as quick action for email
        List<Map<String, Object>> defaultSettingAsObject =
                new List<Map<String, Object>> {
                        new Map<String, Object>{
                                'targetSObject' => new EmailMessage(),
                                'actionType' => 'Email',
                                'contextId' => queryCase.Id,
                                'actionName' => 'Case.Email',
                                'fromAddressList' => new List<String>{
                                        'salesforce@test.com'
                                }
                        }
                };
        //serialize quick action setting
        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject),
                                                                                                                           List<QuickAction.SendEmailQuickActionDefaults>.class);
    
        Test.startTest();
            try { 
                //initialize the default template loader
                (new SSSWDefaultTemplateLoader()).onInitDefaults(defaultsSettings);
            } catch(Exception failure) {
                failureDuringExecution = failure;
            }
        Test.stopTest();

        System.assertEquals(null, failureDuringExecution, 
                            'SSSWDefaultTemplateLoader_Test_testCaseEmailFeed :There was an exception thrown during the test!');
    }
}