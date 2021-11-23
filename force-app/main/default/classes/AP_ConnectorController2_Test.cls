/**************************************************
Description: Unit tests for class AP_ConnectorController2
--------------------------------------------------
2018-10-16  hasantha.liyanage@auspost.com.au    Created
**************************************************/
@isTest
public with sharing class AP_ConnectorController2_Test {

    @testSetup
    static void setupTestData() {
        //List to hold the Contacts to insert.
        list<Contact> testContactList = new list<Contact>();
        //Create Contacts in bulk.
        for(Integer j=1;j<=20;j++) {
            Contact testContact= APT_TestUtils.createContact();
            testContact.FirstName = 'John'+j;
            testContact.LastName = 'Smith'+j;
            testContact.MobilePhone = '1234';
            testContactList.add(testContact);
        }
        insert testContactList;

        //insert an account
        list<Account> testAccountList = TestDataProvider.createAccount('AccountName',1);
        //Create Contacts in bulk.
        for(Account account : testAccountList) {
            account.Phone = '049000000';
        }

        insert testAccountList;

        // insert a person account
        Account account = TestDataProvider.createPersonAccount('Tom',Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        account.PersonMobilePhone = '0491106927';
        insert account;

        //List to hold the Cases to insert.
        list<Case> testCaseList = new list<Case>();
        //Create Cases in bulk.
        Integer count = 0;
        for(Integer j=1;j<=10;j++) {
            count = j;
            Case newCase = new Case(
                    Subject = 'Test Subject'+count,
                    ReferenceID__c = 'ref',
                    RecordTypeid = [Select Id From RecordType Where sObjectType = 'Case' And DeveloperName = 'SSSWGeneralEnquiry'].Id,
                    Type = 'Feedback'
            );
            testCaseList.add(newCase);
        }
        insert testCaseList;

    }

    /********************************************************************
     *  Scenario:
     *      Test to find the contact record based on incoming phone call.
     ********************************************************************/
    static testMethod void findContactByPhone_test_ContactFound() {

        //Create a new contact for single contact test
        Contact con = new Contact(FirstName = 'John', LastName = 'Smith', MobilePhone = '12345678');
        insert con;

        // only one contact record found by the phone number
        sObject contact = (Contact)AP_ConnectorController2.findContactByPhone('12345678');

        System.assertNotEquals(null,contact,
                'AP_ConnectorController2_Test_findContactTest : Contact is not found.');

        // more than one contact found
        sObject contacts = (Contact)AP_ConnectorController2.findContactByPhone('1234');

        System.assertNotEquals(null,contacts,
                'AP_ConnectorController2_Test_findContactTest : Contact should be found.');

    }


    /********************************************************************
     *  Scenario:
     *      Test to find the Account record based on incoming phone call.
     ********************************************************************/
    static testMethod void findContactByPhone_test_findContactByField() {

        // contact record found by the phone number
        sObject contact = (Contact)AP_ConnectorController2.findContactByField('FirstName','John1');
        System.assertNotEquals(null,contact,
                'findContactByPhone_test_findContactByField : Account should be found.');


    }

    /**********************************************************************************
     *  Scenario:
     *      Test to retrieve multiple existing Case from caseNumber, case Id, reference id from incoming call.
     *********************************************************************************/
    static testMethod void findContactByPhone_test_getCase() {

        //Fetch the case number of the inserted case.
        list<Case> testCaseList = [SELECT CaseNumber FROM Case];

        Case testCase = new Case();

        // verify data
        for(Case myCase : testCaseList){
            testCase  = AP_ConnectorController2.getCaseByCaseNumber(myCase.CaseNumber);
            System.assertNotEquals(null,testCase,
                    'findContactByPhone_test_getCaseByCaseNumber : Case is not found.');

            testCase  = AP_ConnectorController2.getCaseById(myCase.Id);
            System.assertNotEquals(null,testCase,
                    'findContactByPhone_test_getCaseByIdr : Case is not found.');

        }

        testCaseList  = AP_ConnectorController2.getCaseByReferenceId('ref');
        System.assertNotEquals(0,testCaseList.size(),
                'findContactByPhone_test_getCaseByIdr : Case is not found.');
    }


    /****************************************************************************************
     *  Scenario:
     *      Test to close an existing or create new and task same as completed on end of call.
     ****************************************************************************************/
    static testMethod void createTask_test() {
        //Create a new contact.
        Contact contact = [SELECT id, AccountId FROM Contact WHERE MobilePhone = '0491106927' LIMIT 1];
        Map<String, String> taskMap = new Map<String, String>();
        Task task = AP_ConnectorController2.createTask(contact.Id, contact.AccountId, 'subject', null, taskMap);

        System.assertNotEquals(null,task,
                'AP_ConnectorController_Test_createTaskTest : Task is found.');
    }


    /****************************************************************************************
     *  Scenario:
     *      Test to close an existing task same as completed on end of call.
     ****************************************************************************************/
    static testMethod void closeTask_test() {
        //Create a new contact.
        Contact contact = [SELECT id, AccountId FROM Contact WHERE MobilePhone = '0491106927' LIMIT 1];
        Map<String, String> taskMap = new Map<String, String>();
        
        // tsting creaete task and will close this later
        Task task = AP_ConnectorController2.createTask(contact.Id, contact.AccountId, 'subject', null, taskMap);

        map<String,String> userData = new Map<String,String>();
        userData.put('RRequestedSkillCombination','test');
        userData.put('IWS_DNIS','test');
        userData.put('r_IWS_ServiceType','test');
        userData.put('r_IWS_CustomerSegment','test');
        userData.put('BusinessResultDisplay','test');
        userData.put('ENG_DimAttribute_2','test');
        userData.put('ENG_DimAttribute_1','test');
        userData.put('r_IWS_ServiceType','test');
        userData.put('r_IWS_ServiceSubType','test');
        userData.put('IWS_CallUuid','test');
        userData.put('IW_CaseUid','test');

        //String taskId, String whatId, String whoId, String subject, String comments, Map<String, String> userData,
        //String dispositionKVP, Map<String, String> taskMap, Integer callDuration, String interactionId, String callType
        task = AP_ConnectorController2.closeTask(task.Id, contact.AccountId, contact.Id, 'subject', 'comments', userData, 'IW_CaseUid', taskMap, 5, 'intid', null);

        System.assertEquals('Completed',task.Status,
                'AP_ConnectorController_Test_closeTask_test : Task must be completed');
    }

}