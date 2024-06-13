/**********************************************************************************
Description: Test class to cover AP_ConnectorController functionality.
History:
-----------------------------------------------------------------------------------
2017-03-07  kalpita.talwadekar@auspost.com.au Created
2018-06-08  TDO-41 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            added assertEquals and assertNotEquals, added new tests to handle
            bulk records, test for close task.
2022-02-11  REQ2723568: Text Class changes 
2022-02-11  REQ2723568: API version 52 upgrade
2024-06-13	Parveen Kaushik Added default value for mapping model on test data.
			See CSLU-470 (JIRA) for details.
***********************************************************************************/
@isTest
private class AP_ConnectorController_Test {

    @testSetup
    static void setupTestData() {
        //List to hold the Contacts to insert.
        list<Contact> testContactList = new list<Contact>();
        //Create Contacts in bulk.
        for(Integer j=1;j<=20;j++) {
            Contact testContact= APT_TestUtils.createContact();
            testContactList.add(testContact);
        }
        insert testContactList;

        //List to hold the Contacts to insert.
        list<Account> testAccountList = new list<Account>();
        //Create Contacts in bulk.
        for(Integer j=1;j<=20;j++) {
            Account testAccount = TestDataProvider.createBusinessAccount('Smith', 'Business_Account');
            testAccount.Phone = '1234';
            testAccountList.add(testAccount);
        }
        insert testAccountList;

        //Create a new MiniCaseFieldMapping__c record
        MiniCaseFieldMapping__c mp = new MiniCaseFieldMapping__c(ProductCategory__c = 'seg', ProductSubcategory__c = 'serTyp', Type__c = 'type', MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL);
        insert mp;

    }

    /********************************************************************
     *  Scenario:
     *      Test to find the contact record based on incoming phone call.
     ********************************************************************/
    static testMethod void findContactTest() {
        //Create a new contact.
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;

        Contact testContact = (Contact)AP_ConnectorController.findContact('Phone', '1234');

        System.assertNotEquals(null,testContact,
                'AP_ConnectorController_Test_findContactTest : Contact is found.');

        testContact = AP_ConnectorController.getContact(testContact.Id, null);

        System.assertNotEquals(null,testContact,
                'AP_ConnectorController_Test_findContactTest : Contact is found.');
    }

    /*************************************************************************
     *  Scenario:
     *      Test to find multiple contact record based on incoming phone call.
     *************************************************************************/
    static testMethod void findContactTestBulkify() {
        //Create multiple Contacts in bulk with Phone details.
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;

        Contact contact2 = new Contact(FirstName = 'Foo', LastName = 'Bar', Phone = '1234');
        insert contact2;

        Contact testContact = (Contact)AP_ConnectorController.findContact('Phone', '1234');

        System.assertEquals(null,testContact.Id,
                'AP_ConnectorController_Test_findContactTestBulkify : Contact is not found.');
    }


    /**********************************************************************************
     *  Scenario:
     *      Test to retrieve multiple existing Case from caseNumber from incoming call.
     *********************************************************************************/
    static testMethod void findCaseTest() {
        //List to hold the Cases to insert.
        list<Case> testCaseList = new list<Case>();
        //Create Cases in bulk.
        Integer count = 0;
        for(Integer j=1;j<=10;j++) {
            count = j;
            Case newCase = new Case(Subject = 'Test Subject'+count);
            insert newCase;
        }
        insert testCaseList;

        //Fetch the case number of the inserted case.
       	//Adding limit in the query
        testCaseList = [SELECT CaseNumber FROM Case limit 5];
        Case testCase = new Case();
        for(Case myCase : testCaseList){
            testCase  = AP_ConnectorController.findCase(myCase.CaseNumber);

            System.assertNotEquals(null,testCase,
                    'AP_ConnectorController_Test_findCaseTestBulkify : Case is found.');
        }
    }

    /****************************************************************************************
     *  Scenario:
     *      Test to close an existing or create new and mark same as completed on end of call.
     ****************************************************************************************/
    static testMethod void createTaskTest() {
        Map<String, String> taskMap = new Map<String, String>();
        //Create a new contact.
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;

        Contact testContact = (Contact)AP_ConnectorController.findContact('Phone', '1234');
        map<String,String> uData = new Map<String,String>();
        uData.put('RRequestedSkillCombination','test');
        uData.put('IWS_DNIS','test');
        uData.put('r_IWS_ServiceType','test');
        uData.put('r_IWS_CustomerSegment','test');
        uData.put('BusinessResultDisplay','test');
        uData.put('ENG_DimAttribute_2','test');
        uData.put('ENG_DimAttribute_1','test');
        uData.put('r_IWS_ServiceType','test');
        uData.put('r_IWS_ServiceSubType','test');
        uData.put('IWS_CallUuid','test');                                                                        
        uData.put('IW_CaseUid','test');

        //Create a new case.
        Case testCase = new Case(Subject='testCase Subject1');
        insert testCase;
    
        Task task = AP_ConnectorController.closeTask(testContact.Id, testContact.AccountId, 'a subject', 'a comment', uData, null, taskMap, 10,'Inbound','tets','test',contact.id,testCase.Id);

        System.assertNotEquals(null,task,
                'AP_ConnectorController_Test_createTaskTest : Task is found.');
    }

    /****************************************************************************************
     *  Scenario:
     *      Test to close an existing or create new and mark same as completed on end of call.
     ****************************************************************************************/
    static testMethod void closeTaskTest() {
        Map<String, String> taskMap = new Map<String, String>();
        //Create a new contact.
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;

        Contact testContact = (Contact)AP_ConnectorController.findContact('Phone', '1234');
        map<String,String> uData = new Map<String,String>();
        uData.put('RRequestedSkillCombination','test');
        uData.put('IWS_DNIS','test');
        uData.put('r_IWS_ServiceType','test');
        uData.put('r_IWS_CustomerSegment','test');
        uData.put('BusinessResultDisplay','test');
        uData.put('ENG_DimAttribute_2','test');
        uData.put('ENG_DimAttribute_1','test');
        uData.put('r_IWS_ServiceType','test');
        uData.put('r_IWS_ServiceSubType','test');
        uData.put('IWS_CallUuid','test');
        uData.put('IW_CaseUid','test');

        //Create a new case.
        Case testCase = new Case(Subject='testCase Subject2');
        insert testCase;

        //Create a new task.
        Task testTask = new Task (
                Status = 'In Progress',
                Subject = 'Test Subject5',
                WhoId = contact.Id,
                WhatId = testCase.Id
        );
        insert testTask;

        Task task = AP_ConnectorController.closeTask(testTask.Id, testContact.AccountId, 'a subject', 'a comment', uData, null, taskMap, 10,'Inbound','tets','test',contact.id,testCase.Id);

        System.assertNotEquals(null,task,
                'AP_ConnectorController_Test_createTaskTest : Task is found.');
    }

    /******************************************************************************
     *  Scenario:
     *      Test to create an automated case record based on incoming call details.
     ******************************************************************************/
    static testMethod void createCaseTest() {
        Map<String, String> caseMap = new Map<String, String>();
        //Create a new contact.
        Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
        insert contact;
        
        Case testCase = AP_ConnectorController.createCase(contact.Id, contact.AccountId, 'interaction', 'a subject', null, caseMap);

        System.assertNotEquals(null,testCase,
                'AP_ConnectorController_Test_createCaseTest : Case is found.');
    }

    /********************************************************************
     *  Scenario:
     *      Test to find the contact record based on incoming phone call.
     ********************************************************************/
    static testMethod void findContact_Acc() {
        //Create a new business account.
        Account testAccount = TestDataProvider.createBusinessAccount('Smith', 'Business_Account');
        testAccount.Phone = '1234';
        insert testAccount;

        Object testContact = AP_ConnectorController.findContact('','1234');

        System.assertNotEquals(null,testContact,
                'AP_ConnectorController_Test_findContact_Acc : Contact is found.');
    }

    /********************************************************************
     *  Scenario:
     *      Test to find the contact record based on incoming phone call.
     ********************************************************************/
    static testMethod void findContact_Acc_Bulkify() {
        Object testContact = AP_ConnectorController.findContact('','1234');

        System.assertNotEquals(null,testContact,
                'AP_ConnectorController_Test_findContact_Acc : Contact is found.');
    }

    /*****************************************************************************
     *  Scenario:
     *      Test to retrieve an existing contact from a task/activity when a user
     *      clicks on dial (number) from task screen.
     *****************************************************************************/
    static testMethod void getContactByTask() {
        //Create a new account.
        Account acc = new Account(Name = 'Smith', Phone = '1234');
        insert acc;
        //Create a new contact.
        Contact contact = new Contact(FirstName = 'Steve', LastName = 'Smith', Phone = '1234',accountId = acc.Id);
        insert contact;
        //Create a new case.
        Case cse = new Case(Subject='testCase Subject2');
        insert cse;
        //Create a new task.
        Task task = new Task (
            Status = 'In Progress',
            Subject = 'Test Subject5',
            WhoId = contact.Id,
            WhatId = cse.Id
        );
        insert task;
        
        Task testTask = AP_ConnectorController.getContactByTask(task.Id);

        System.assertNotEquals(null,testTask,
                'AP_ConnectorController_Test_findContact_Acc : Task is found.');

        AP_ConnectorController.createTask(acc.Id,acc.Id,'estSub',null,null);
        AP_ConnectorController ap = new AP_ConnectorController();
        ap.proxyCase = 'case';
        ap.txtRefID= '456789';
        ap.txtPhoneNumber='4566789';
    }

    /*****************************************************************************
     *  Scenario:
     *      Test to set the default - pre-populated clear view codes based on user
     *      selection in incoming call.
     *      this is just to get the code coverage, it is not required to assert result
     *****************************************************************************/
    static testMethod void defaultValues() {

        AP_ConnectorController.CTIDefaultValue result = AP_ConnectorController.defaultValues('seg','serTyp');

        // assert for the default values
        System.assertNotEquals(null,result,
                'AP_ConnectorController_Test_defaultValues : CTIDefaultValue shoud not be null');

        // just to get the coverage, passing the id to get 18 digits Id
        AP_ConnectorController.getFullID('01p0k000000DkXk');
        
    }
    
}