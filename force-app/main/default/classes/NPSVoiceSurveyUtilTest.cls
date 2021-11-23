/**********************************************************************************
Description: Test class to cover NPSVoiceSurveyUtil functionality.
History:
27-02-2019  disha.kariya@auspost.com.au Modified Test class to use different contact on Task.
***********************************************************************************/
@isTest
private class NPSVoiceSurveyUtilTest {

    private static Integer TOTAL_CASE = 20;
    private static Integer TOTAL_CONTACT = 20;

    /**********************************************************************
    *  Scenario:
    *      Check MH_Action flag set to true and SMSError__c is blank
    ***********************************************************************/
    @isTest static void testSendTaskForNPSPositive() {
        Test.startTest();
        // Set mock callout class
        setMock(NPSVoiceSurveyUtil.MOCK_ENDPOINT, 'POST', 'Content-Type',
                'application/json', '{"example":"test"}', true, 200, 400);
        
        ID rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName = 'SSSWCall' LIMIT 1].Id;

        //Create a Task.
        List<Case> caseList = [SELECT Id, ContactId FROM Case];
        List<Contact> contactList = [SELECT Id FROM Contact];
        System.assertEquals(TOTAL_CASE, caseList.size());
        
        List<Task> taskList = new List<Task>();
        for (Integer i = 0; i < caseList.size(); i++) {
            Integer j= TOTAL_CASE-1; // Counter to use different Contact for Task than Case Contact
            Task testTask = TestDataProvider.createTask(caseList[0].Id, contactList[j].Id , NPSVoiceSurveyUtil.RECORDTYPE_SSSW_CALL);
                testTask.RecordTypeID = rtId;
                testTask.Subject = 'Test';
                testTask.CallType = NPSVoiceSurveyUtil.CALLTYPE_INBOUND;
                testTask.Queue__c = '10297389123';
                
            taskList.add(testTask);
            j--;
        }
        
        insert taskList;
        Test.stopTest();
        
        //List<Task> updatedTaskList = [SELECT Id, MH_Action__c FROM Task];
        for (Task tsk : [SELECT Id, MH_Action__c, SMSError__c FROM Task]) {
            System.assertEquals(true, tsk.MH_Action__c); // Check if Task has been actioned
            System.assertEquals(true, String.isBlank(tsk.SMSError__c)); // Check if there is error message for Negative Testing
        }
    }

    /**********************************************************************
    *  Scenario:
    *      Check MH_Action flag set to true and SMSError__c is NOT blank
    ***********************************************************************/
    @isTest static void testSendTaskForNPSNegative() {
        Test.startTest();
        // Set mock callout class
        setMock(NPSVoiceSurveyUtil.MOCK_ENDPOINT, 'POST', 'Content-Type',
                'application/json', '{"example":"test"}', false, 200, 400);

        ID rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName = 'SSSWCall' LIMIT 1].Id;

        //Create a Task.
        List<Case> caseList = [SELECT Id, ContactId FROM Case];
        System.assertEquals(TOTAL_CASE, caseList.size());
        List<Contact> contactList = [SELECT Id FROM Contact];

        List<Task> taskList = new List<Task>();
        for (Integer i = 0 ; i < caseList.size() ; i++) {
            Integer j= TOTAL_CASE - 1; // Counter to use different Contact for Task than Case Contact
            Task testTask = TestDataProvider.createTask(caseList[0].Id, contactList[j].Id, NPSVoiceSurveyUtil.RECORDTYPE_SSSW_CALL);
            testTask.RecordTypeID = rtId;
            testTask.Subject = 'Test';
            testTask.CallType = NPSVoiceSurveyUtil.CALLTYPE_OUTBOUND;
            testTask.Queue__c = '15798';

            taskList.add(testTask);
            j--;
        }

        insert taskList;
        Test.stopTest();

        //List<Task> updatedTaskList = [SELECT Id, MH_Action__c FROM Task];
        for (Task tsk : [SELECT Id, MH_Action__c, SMSError__c FROM Task]) {
            System.assertEquals(true, tsk.MH_Action__c); // Check if Task has been actioned
            System.assertEquals(true, String.isNotBlank(tsk.SMSError__c)); // Check if there is error message for Negative Testing
        }
    }

    static void setMock(String pEndpoint, String pMethod, String pHeaderType,
            String pHeaderContext, String pBody, Boolean pSuccess, Integer pSuccessCode, Integer pErrorCode) {
        HttpResponseMockGenerator dynaMockGen = new HttpResponseMockGenerator();
        dynaMockGen.xEndpoint = pEndpoint;
        dynaMockGen.xMethod = pMethod;
        dynaMockGen.xHeaderType = pHeaderType;
        dynaMockGen.xHeaderContext = pHeaderContext;
        dynaMockGen.xBody = pBody;
        dynaMockGen.success = pSuccess;
        dynaMockGen.successCode = pSuccessCode;
        dynaMockGen.errorCode = pErrorCode;
        Test.setMock(HttpCalloutMock.class, dynaMockGen);
    }
    
    @testSetup static void setup() {
        //Create an Account.
        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        accounts[0].ServiceSLA__c = 'Consumer';
        insert accounts;
        
        //Create a Contact
        List<Contact> testConList = new List<Contact>();
        for (Integer i = 0 ; i < TOTAL_CONTACT ; i++) {
            Contact cont = TestDataProvider.createTestContact();
                cont.MobilePhone = '1234' + i;
                cont.Email = 'test' + i + '@testemail.com';
            testConList.add(cont);
        }
        insert testConList;
        
        //Create an Case
        List<Case> testCaseList = new List<Case>();
        for (Integer i = 0 ; i < TOTAL_CASE ; i++) {
            Case testCase = TestDataProvider.createCase('Test' + i, 'test description' + i, 'SSSW General Enquiry');
            //testCase.Customer_Type__c = NPSSurveyHandler.CUSTOMER_TYPE_ENTERPRISE;
            //testCase.Origin = NPSSurveyHandler.CASE_ORIGIN_HLC;
            testCase.IsCR__c = false;
            testCase.IsHLC__c = false;
            testCase.ContactId = testConList[i].Id;
            testCase.AccountId = accounts[0].Id;
            testCaseList.add(testCase);
        }
        insert testCaseList;
    }
}