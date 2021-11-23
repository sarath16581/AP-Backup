/*************************************************************************************************
Description:    Test class to cover CaseManagerProcessHelper functionality
History:
---------------------------------------------------------------------------------------
2016-02-01  kalpita.talwadekar@auspost.com.au  Created
2016-08-31  snigdha.sahu@auspost.com.au  ETA Call APT_TestUtils for Agreement test data.
2018-06-22  TDO-65 rahul.kapoor@coroma.com.au  Refactored comments and indentation,
            added assertEquals and assertNotEquals, tests with all input parameters as true/false.
2019-03-15  nathan.franklin@auspost.com.au Fixed failing test
2020-02-04  seth.p.heang@accenture.com Increase code coverage by including check on APT_Product_Group__c
13/10/2020  seth.p.heang@accenture.com   Decommissioned    This class and the flow 'CaseManagerAllocationFlow' which calls this class,
															the entire functionality of 'Deal Enablement Centre' Case implementation is decommissioned 
															and to be replaced with a new DSR implementation with 'Deal Enablement Centre' record type
**************************************************************************************************/
@isTest
private class CaseManagerProcessHelper_Test {

    /*****************************************************************************************
    *  Scenario:
    *      Setup method to create test data
    ******************************************************************************************/
    /*@testSetup 
    static void testDataCreation() {
        //Create Contact
        Contact testContact = APT_TestUtils.createContact();
        Database.insert(testContact);

        //Call the Apttus Test Utility for creating agreement
        Apttus__APTS_Agreement__c  testAptsAgreement = APT_TestUtils.createAgreement(testContact.Id);
        Database.insert(testAptsAgreement);

        //Create Case
        Case testCase = new Case();
        testCase.RecordTypeId = [SELECT Id
                                 FROM RecordType
                                 WHERE DeveloperName = 'Data_Quality_Management'
                                 AND SobjectType='Case'
                                 LIMIT 1].Id;
        testCase.Type = 'Feedback';
        testCase.Subject = 'Newsdd';
        testCase.Status = 'Network Responded';
        testCase.ProductCategory__c = 'Travel & ID';
        testCase.EnquirySubType__c = 'Product Support';
        testCase.EnquirySubType__c = 'KeyPass';
        testCase.EnquirySubType__c = 'Article carded - no card left';
        testCase.DateofIncident__c = date.today();
        testCase.ReferenceId__c = 'SSSWCase';
        testCase.APT_Contract__c = testAptsAgreement.Id;
        testCase.APT_Contract_Owner__c =userinfo.getuserid();
        insert testCase;

        //Create Attachment for Case
        Attachment testAttachment = Util.createAttachment('test attachment', 'ajgskdjgausgdhagsud', 'image', testCase.Id);
        insert testAttachment;

        //Create CaseComment for case
        CaseComment testCaseComment = new CaseComment(ParentId = testCase.Id,IsPublished = true);
        Database.insert(testCaseComment);
    }*/

    /*****************************************************************************************
    *  Scenario:
    *      Test the flow class setup and function with isInsert as true
    ******************************************************************************************/
    static testMethod void testCaseManagerWithInsertTrue() {
        //Fetch case data
        //Case testCase = [SELECT Id FROM Case LIMIT 1];
    
        //Create test conversion
        CaseManagerProcessHelper aLeadPlugin = new CaseManagerProcessHelper();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();

        //inputParams.put('Id',testCase.ID);
        inputParams.put('isInsert', true);
        inputParams.put('eparcelStandard', true);
        inputParams.put('newCashAccount', false);
        inputParams.put('newChargeAccount', false);
        inputParams.put('newSubAccount', false);

        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = aLeadPlugin.invoke(request);

        Process.PluginDescribeResult describe = aLeadPlugin.describe();
        /*System.assertNotEquals(null,result,
                'CaseManagerProcessHelper_Test_testCaseManagerWithInsertTrue : Result should be retrieved');*/
        
    }

    /*****************************************************************************************
    *  Scenario:
    *      Test the flow class setup and function with isInsert as false
    ******************************************************************************************/
    /*static testMethod void testCaseManagerWithInsertFalse() {
        //Create case data
        Case testCase = [SELECT Id,Status,Work_Type__c FROM Case LIMIT 1];
        testCase.Status = 'Closed';
        testCase.Work_Type__c = 'New Sub Account';
        update testCase;
        
        //Create test conversion
        CaseManagerProcessHelper aLeadPlugin = new CaseManagerProcessHelper();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
        Process.PluginDescribeResult descr = aLeadPlugin.describe();
        inputParams.put('Id',testCase.ID);
        inputParams.put('isInsert', false);
        inputParams.put('eparcelStandard', false);
        inputParams.put('newCashAccount', false);
        inputParams.put('newChargeAccount', false);
        inputParams.put('newSubAccount', true);

        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = aLeadPlugin.invoke(request);

        System.assertNotEquals(null,result,
                'CaseManagerProcessHelper_Test_testCaseManagerWithInsertFalse : Result should be retrieved');
    }*/

    /*****************************************************************************************
    *  Scenario:
    *      Test the flow class setup and function with all input parameters as false.
    ******************************************************************************************/
    /*static testMethod void testCaseManagerWithInputParamsFalse() {

        Test.startTest();

        //Fetch case data
        Case testCase = [SELECT Id,Status,Work_Type__c FROM Case LIMIT 1];
        testCase.Status = 'Closed';
        testCase.Work_Type__c = 'New Sub Account';
        update testCase;
        
        //Create test conversion
        CaseManagerProcessHelper aLeadPlugin = new CaseManagerProcessHelper();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
        Process.PluginDescribeResult descr = aLeadPlugin.describe();
        inputParams.put('Id',testCase.ID);
        inputParams.put('isInsert', false);
        inputParams.put('eparcelStandard', false);
        inputParams.put('newCashAccount', false);
        inputParams.put('newChargeAccount', false);
        inputParams.put('newSubAccount', false);

        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = aLeadPlugin.invoke(request);

        Test.stopTest();

        System.assertNotEquals(null,result,
                'CaseManagerProcessHelper_Test_testCaseManagerWithInputParamsFalse : Result should be retrieved');
    }*/

    /*****************************************************************************************
    *  Scenario:
    *      Test the flow class setup and function with all input parameters as true.
    ******************************************************************************************/
    /*static testMethod void testCaseManagerWithInsertTrueInputParams() {
        //Fetch case data
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        //testCase.APT_Contract_Owner__c='0050l000001Nw12340';
        // add product group
        testCase.APT_Product_Group__c = 'Local Pickup and Delivery Services';
        update testCase;

        //Create test conversion
        CaseManagerProcessHelper aLeadPlugin = new CaseManagerProcessHelper();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();

        inputParams.put('Id',testCase.ID);
        inputParams.put('isInsert', true);
        inputParams.put('eparcelStandard', true);
        inputParams.put('newCashAccount', true);
        inputParams.put('newChargeAccount', true);
        inputParams.put('newSubAccount', true);
        inputParams.put('newSubAccount', true);

        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = aLeadPlugin.invoke(request);

        System.assertNotEquals(null,result,
                'CaseManagerProcessHelper_Test_testCaseManagerWithInsertTrueInputParams : Result should be retrieved');

    }*/
    
}