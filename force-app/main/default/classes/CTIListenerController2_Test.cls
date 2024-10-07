/*************************************************************************************
Description: Test class to cover CTIListenerController2 functionality.
History:
--------------------------------------------------------------------------------------
            No Created History found.
2018-06-18  TDO-59 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            added assertEquals and assertNotEquals, added new tests to create custom
            activity, tests to to load cases or contacts and to find Contact and Case.

2024-06-13	Parveen Kaushik Added default value for mapping model on test data. 
			See CSLU-470 (JIRA) for details.			
**************************************************************************************/
@isTest
private class CTIListenerController2_Test {

    @testSetup
    static void setupTestData() {

        //List to hold the Contacts to insert.
        list<Contact> testContactList = new list<Contact>();
        //Create Contacts in bulk.
        for(Integer j=1;j<=5;j++) {
            Contact testContact = new Contact(FirstName = 'test',
                                              LastName = 'test',
                                              Phone = '718273672',
                                              ReversePhoneFields__c = '276372817',
                                              Email = 'test@test.com',
                                              MailingCity = 'test city');
            testContactList.add(testContact);
        }
        insert testContactList;

        //List to hold the Accounts to insert.
        list<Account> testAccountList = new list<Account>();
        //Create Accounts in bulk.
        for(Integer j=1;j<=5;j++) {
            Account testAccount = new Account(FirstName = 'test acc',
                                              LastName = 'test acc',
                                              Phone = '718273672',
                                              Email__c = 'test@test.com',
                                              MailingAddress__pc = 'add',
                                              PersonEmail = 'test@test.com');
            testAccountList.add(testAccount);
        }
        insert testAccountList;

        //List to hold the Cases to insert.
        list<Case> testCaseList = new list<Case>();
        //Create Cases in bulk.
        for(Integer j=1;j<=5;j++) {
            Case testCase = new Case(subject = 'test subject',
                                     type = 'Fax',
                                     referenceId__c = 'SSSWCase',
                                     Phone__c = '718273672');
                testCase.AccountId = testAccountList[0].Id;
                testCase.ContactId = testContactList[0].Id;
            testCaseList.add(testCase);
        }

        insert testCaseList;

        //List to hold the MiniCaseFieldMapping__c to insert.
        list<MiniCaseFieldMapping__c> testMcfmList = new list<MiniCaseFieldMapping__c>();
        //Create MiniCaseFieldMapping__c in bulk.
        for(Integer j=1;j<=20;j++) {
            MiniCaseFieldMapping__c testMcfm = new MiniCaseFieldMapping__c();
                                    testMcfm.ProductCategory__c = 'test pc';
                                    testMcfm.ProductSubcategory__c = 'test psc';
                                    testMcfm.Type__c = 'Feedback';
									testMcfm.MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL;
            testMcfmList.add(testMcfm);
        }
        insert testMcfmList;
    }

    /**********************************************************************
    *  Scenario:
    *      Tests for create custom activity
    ***********************************************************************/
    static testMethod void testCreateCustomActivity() {
        //Fetch Contact
        Contact testContact = [SELECT Id,Phone FROM Contact LIMIT 1];

        //Fetch Account
        Account testAccount = [SELECT Id,Phone FROM Account LIMIT 1];

        //Fetch Case
        Case testCase = [SELECT Id,subject,casenumber,ContactId FROM Case LIMIT 1];

        //Fetch MiniCaseFieldMapping__c
        MiniCaseFieldMapping__c testMcfm = [SELECT Id,ProductCategory__c,ProductSubcategory__c,Type__c
                                            FROM MiniCaseFieldMapping__c
                                            LIMIT 1];

        Test.startTest();

        CTIListenerController2 instance = new CTIListenerController2();
        CTIListenerController2.CTIDefaultValue testdv = new CTIListenerController2.CTIDefaultValue();
        CTIListenerController2.CTIDefaultValue testdv2 = new CTIListenerController2.CTIDefaultValue(testMcfm);

        String fieldSet = instance.CTIFieldSetFieldPaths;
        List<String> excludedPhoneNumbersList = instance.excludedPhoneNumbers;
        instance.txtRefID= '456789';
        instance.txtPhoneNumber='4566789';

        //Fetch the record type Id
        CTIListenerController2.getRecordTypeId('{"Subject": "test subject"}');

        //Fetch the default values
        CTIListenerController2.defaultValues('test', 'cti');

        //Calling getFullID for code test coverage
        CTIListenerController2.getFullID('01p0k000000DkXk');

        //Calling createCustomActivity with WhoId as null and WhatId as Case Id
        CTIListenerController2.createCustomActivity(null,testCase.Id, 'subject', 'description', 'outcome', 'duration', 1000, testAccount.Id, '718273672', null, 'serviceType', 'test', null,'Inbound','','test','test','test','test','test','test',40);

        Task testTask1 = [SELECT Id,WhoId,WhatId FROM task LIMIT 1];

        //Calling createCustomActivity with WhoId as Account Id and WhatId as Case Id
        CTIListenerController2.createCustomActivity(testAccount.Id,testCase.Id, 'subject', 'description', 'outcome', 'duration', 1000, testAccount.Id, '718273672', null, 'serviceType', 'test', null,'Inbound','','test','test','test','test','test','test',40);

        Task testTask2 = [SELECT Id,WhoId,WhatId FROM task LIMIT 1];

        //Calling createCustomActivity with WhoId as Case Id and WhatId as Account Id
        CTIListenerController2.createCustomActivity(testCase.Id,testAccount.Id, 'subject', 'description', 'outcome', 'duration', 1000, testAccount.Id, '718273672', null, 'serviceType', 'test', null,'Inbound','','test','test','test','test','test','test',40);

        Test.stopTest();

        Task testTask3 = [SELECT Id,WhoId,WhatId FROM task LIMIT 1];

        System.assertNotEquals(null,testTask1.Id,
                'CTIListenerController2_Test_testCreateCustomActivity : Task should be created.');

        System.assertEquals(testCase.Id,testTask1.WhatId,
                'CTIListenerController2_Test_testCreateCustomActivity : Task should be created.');

        System.assertEquals(testContact.Id,testTask2.WhoId,
                'CTIListenerController2_Test_testCreateCustomActivity : Task should be created.');

        System.assertEquals(testCase.Id,testTask3.WhatId,
                'CTIListenerController2_Test_testCreateCustomActivity : Task should be created.');

    }

    /**********************************************************************
    *  Scenario:
    *      Tests to load case or contact and to find Contact and Case
    ***********************************************************************/
    static testMethod void testFindCaseAndContact() {
        CTIListenerController2 instance = new CTIListenerController2();

        String fieldSet = instance.CTIFieldSetFieldPaths;

        //Calling lookupByPhone for code test coverage
        CTIListenerController2.lookupByPhone('718273672');

        //Calling findObjectFromANI to find ANI returning account, contact, lead
        Object resultObject = CTIListenerController2.findObjectFromANI('718273672');

        System.assertNotEquals(null,resultObject,
                'CTIListenerController2_Test_testFindCaseAndContact : Object should be retrieved.');

        //Calling findObjectFromANI to find in phone fields and returning contact
        Object resultContact = CTIListenerController2.findContactFromANI('718273672');

        System.assertNotEquals(null,resultContact,
                'CTIListenerController2_Test_testFindCaseAndContact : Contact should be retrieved.');

        //Calling findObjectFromANI to find contact from email address
        Object resultContactEmail = CTIListenerController2.findContactFromEmailAddress('test@test.com');

        System.assertNotEquals(null,resultContactEmail,
                'CTIListenerController2_Test_testFindCaseAndContact : Contact should be retrieved.');

        //Calling findObjectFromANI to find contact from chat address
        Object resultContactChatAddress = CTIListenerController2.findContactFromChatAddress('test');

        System.assertEquals(null,resultContactChatAddress,
                'CTIListenerController2_Test_testFindCaseAndContact : Contact should not be retrieved.');

        //Calling findObjectFromANI to find contact from work item address
        Object resultContactWorkItem = CTIListenerController2.findContactFromWorkItemAddress('test');

        System.assertEquals(null,resultContactWorkItem,
                'CTIListenerController2_Test_testFindCaseAndContact : Contact should not be retrieved.');

        //Calling findObjectFromANI to find contact from open media address
        Object resultContactOpenMedia = CTIListenerController2.findContactFromOpenMediaAddress('test');

        System.assertEquals(null,resultContactOpenMedia,
                'CTIListenerController2_Test_testFindCaseAndContact : Contact should not be retrieved.');

    }

    /**********************************************************************
    *  Scenario:
    *      Tests to set and retrieve workspace connector information
    ***********************************************************************/
    static testMethod void testSetAndRetrieveWorkspaceConnector() {
        //Fetch Contacts
        list<Contact> testContactList = new list<Contact>();
        testContactList = [SELECT Id,Phone FROM Contact];

        //Fetch Accounts
        list<Account> testAccountList = new list<Account>();
        testAccountList = [SELECT Id,Phone FROM Account];

        //Fetch Cases
        list<Case> testCaseList = new list<Case>();
        testCaseList = [SELECT Id,subject,casenumber,AccountId FROM Case];

        CTIListenerController2 instance = new CTIListenerController2();

        String fieldSet = instance.CTIFieldSetFieldPaths;

        for(Case testCase : testCaseList) {
            //Calling setWorkspaceConnectorInfo to set Workspace Connector Info by passing Case Id
            String info = CTIListenerController2.setWorkspaceConnectorInfo(testCase.Id, null);

            System.assertNotEquals(null,info,
                    'CTIListenerController2_Test_testSetAndRetrieveWorkspaceConnector : Workspace Connector Info should be set.');
        }

        //Calling setWorkspaceConnectorInfo to retrieve Workspace Connector
        String result = CTIListenerController2.retrieveWorkspaceConnectorInfo(null);

        System.assertNotEquals(null,result,
                'CTIListenerController2_Test_testSetAndRetrieveWorkspaceConnector : Workspace Connector Info should be retrieved.');
    }

    /**********************************************************************
    *  Scenario:
    *      Tests to find Case from Number
    ***********************************************************************/
    static testMethod void testFindCaseFromNumber() {
        //Fetch Cases
        list<Case> testCaseList = new list<Case>();
        testCaseList = [SELECT Id,subject,casenumber,AccountId FROM Case];

        CTIListenerController2 instance = new CTIListenerController2();

        String fieldSet = instance.CTIFieldSetFieldPaths;

        Test.startTest();

        for(Case testCase : testCaseList) {
            Case foundCase = CTIListenerController2.findCaseFromNumber(testCase.CaseNumber);

            System.assertEquals(testCase.CaseNumber,foundCase.CaseNumber,
                    'CTIListenerController2_Test_testLoadCaseAndContact : Case should be found.');
        }

        Test.stopTest();
    }

    /**********************************************************************
    *  Scenario:
    *      Tests to load case or contact
    ***********************************************************************/
    static testMethod void testLoadCaseOrContact() {
        //Fetch Case
        Case testCase = [SELECT Id,subject,casenumber,AccountId FROM Case LIMIT 1];

        //Fetch Contact
        Contact testContact = [SELECT Id,Phone FROM Contact LIMIT 1];

        CTIListenerController2 instance = new CTIListenerController2();

        String fieldSet = instance.CTIFieldSetFieldPaths;

        //Required so SOSL will fire in Unit Tests Properly.
        Id [] fixedSearchResults= new Id[2];
        fixedSearchResults[0] = testCase.Id;
        fixedSearchResults[1] = testContact.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();

        CTIListenerController2.JSCaseContact caseContact = CTIListenerController2.loadCaseOrContact('SSSWCase', '718273672');

        Test.stopTest();

        System.assertEquals(testCase.Id,caseContact.caseId,
                'CTIListenerController2_Test_testLoadCaseOrContact : Case should be found.');

        System.assertEquals(testContact.Id,caseContact.contactId,
                'CTIListenerController2_Test_testLoadCaseOrContact : Contact should be found.');
    }

    /**********************************************************************
    *  Scenario:
    *      Test for create activity with Email IXN Type
    ***********************************************************************/
    static testMethod void testCreateActivityEmailIXNType() {
        Contact testContact = [SELECT Id,Phone FROM Contact LIMIT 1];

        Test.startTest();

        CTIListenerController2 instance = new CTIListenerController2();

        Map<String,String> activityMap = new Map<String,String>();
        activityMap.put('ANI', 'ANI');
        activityMap.put('LOOKUP', 'LOOKUP');
        activityMap.put('Call Duration', '12020591728');
        activityMap.put('IXN Type', 'Email');
        activityMap.put('Media Type', 'Media Type');
        activityMap.put('Comments', 'Comments');
        activityMap.put('Disposition', 'Disposition');
        activityMap.put('GenesysId', 'GenesysId');
        activityMap.put('DATE', '2014-06-12');
        activityMap.put('SFDC1field', 'Subject');
        activityMap.put('SFDC1value', 'test');
        activityMap.put('SFDC2field', 'type');
        activityMap.put('SFDC2value', 'call');
        activityMap.put('SFDC3field', 'Status');
        activityMap.put('SFDC3value', 'Completed');
        activityMap.put('SFDC4field', 'Description');
        activityMap.put('SFDC4value', 'Comments');
        activityMap.put('SFDC5field', 'CallDisposition');
        activityMap.put('SFDC5value', 'Disposition');

        activityMap.put('sfdc Object Id', testContact.Id);
        CTIListenerController2.createActivity(activityMap);

        Test.stopTest();

        Task testTask = [SELECT Id,Interaction_Type__c,Description
                         FROM task
                         WHERE Interaction_Type__c = 'Email'
                         AND CallDisposition ='Disposition'
                         AND CallObject='GenesysId'];

        System.assertNotEquals(null,testTask.Id,
                'CTIListenerController2_Test_testCreateActivityEmailIXNType : Task should be created.');

        System.assertEquals('Email',testTask.Interaction_Type__c,
                'CTIListenerController2_Test_testCreateActivityEmailIXNType : Email Interaction Type should be created.');

        System.assertEquals('Comments',testTask.Description,
                'CTIListenerController2_Test_testCreateActivityEmailIXNType : Description with Comments should be created.');

    }

    /**********************************************************************
    *  Scenario:
    *      Test for create activity with Chat IXN Type
    ***********************************************************************/
    static testMethod void testCreateActivityChatIXNType() {
        Contact testContact = [SELECT Id,Phone FROM Contact LIMIT 1];

        Test.startTest();

        CTIListenerController2 instance = new CTIListenerController2();

        Map<String,String> activityMap = new Map<String,String>();
        activityMap.put('ANI', 'ANI');
        activityMap.put('LOOKUP', 'LOOKUP');
        activityMap.put('Call Duration', '12020591728');
        activityMap.put('IXN Type', 'Chat');
        activityMap.put('Media Type', 'Media Type');
        activityMap.put('Comments', 'Comments');
        activityMap.put('Disposition', 'Disposition');
        activityMap.put('GenesysId', 'GenesysId');
        activityMap.put('DATE', '2014-06-12');
        activityMap.put('SFDC1field', 'Subject');
        activityMap.put('SFDC1value', 'test');
        activityMap.put('SFDC2field', 'type');
        activityMap.put('SFDC2value', 'call');
        activityMap.put('SFDC3field', 'Status');
        activityMap.put('SFDC3value', 'Completed');
        activityMap.put('SFDC4field', 'Description');
        activityMap.put('SFDC4value', 'Comments');
        activityMap.put('SFDC5field', 'CallDisposition');
        activityMap.put('SFDC5value', 'Disposition');

        activityMap.put('sfdc Object Id', testContact.Id);
        CTIListenerController2.createActivity(activityMap);

        Test.stopTest();

        Task testTask = [SELECT Id,Interaction_Type__c,Description
                         FROM task
                         WHERE Interaction_Type__c = 'Chat'
                         AND CallDisposition ='Disposition'
                         AND CallObject='GenesysId'];

        System.assertNotEquals(null,testTask.Id,
                'CTIListenerController2_Test_testCreateActivityChatIXNType : Task should be created.');

        System.assertEquals('Chat',testTask.Interaction_Type__c,
                'CTIListenerController2_Test_testCreateActivityChatIXNType : Chat Interaction Type should be created.');

        System.assertEquals('Comments',testTask.Description,
                'CTIListenerController2_Test_testCreateActivityChatIXNType : Description with Comments should be created.');

    }

    /**********************************************************************
    *  Scenario:
    *      Test for create activity with Interaction Work Item IXN Type
    ***********************************************************************/
    static testMethod void testCreateActivityInteractionWorkItemIXNType() {
        Contact testContact = [SELECT Id,Phone FROM Contact LIMIT 1];

        Test.startTest();

        CTIListenerController2 instance = new CTIListenerController2();

        Map<String,String> activityMap = new Map<String,String>();
        activityMap.put('ANI', 'ANI');
        activityMap.put('LOOKUP', 'LOOKUP');
        activityMap.put('Call Duration', '12020591728');
        activityMap.put('IXN Type', 'InteractionWorkItem');
        activityMap.put('Media Type', 'Media Type');
        activityMap.put('Comments', 'Comments');
        activityMap.put('Disposition', 'Disposition');
        activityMap.put('GenesysId', 'GenesysId');
        activityMap.put('DATE', '2014-06-12');
        activityMap.put('SFDC1field', 'Subject');
        activityMap.put('SFDC1value', 'test');
        activityMap.put('SFDC2field', 'type');
        activityMap.put('SFDC2value', 'call');
        activityMap.put('SFDC3field', 'Status');
        activityMap.put('SFDC3value', 'Completed');
        activityMap.put('SFDC4field', 'Description');
        activityMap.put('SFDC4value', 'Comments');
        activityMap.put('SFDC5field', 'CallDisposition');
        activityMap.put('SFDC5value', 'Disposition');

        activityMap.put('sfdc Object Id', testContact.Id);
        CTIListenerController2.createActivity(activityMap);

        Test.stopTest();

        Task testTask = [SELECT Id,Interaction_Type__c,Description
                         FROM task
                         WHERE Interaction_Type__c = 'InteractionWorkItem'
                         AND CallDisposition ='Disposition'
                         AND CallObject='GenesysId'];

        System.assertNotEquals(null,testTask.Id,
                'CTIListenerController2_Test_testCreateActivityInteractionWorkItemIXNType : Task should be created.');

        System.assertEquals('InteractionWorkItem',testTask.Interaction_Type__c,
                'CTIListenerController2_Test_testCreateActivityInteractionWorkItemIXNType : InteractionWorkItem Interaction Type should be created.');

        System.assertEquals('Comments',testTask.Description,
                'CTIListenerController2_Test_testCreateActivityInteractionWorkItemIXNType : Description with Comments should be created.');

    }

    /**********************************************************************
    *  Scenario:
    *      Test for create activity with Open Media IXN Type
    ***********************************************************************/
    static testMethod void testCreateActivityOpenMediaIXNType() {
        Contact testContact = [SELECT Id,Phone FROM Contact LIMIT 1];

        Test.startTest();

        CTIListenerController2 instance = new CTIListenerController2();

        Map<String,String> activityMap = new Map<String,String>();
        activityMap.put('ANI', 'ANI');
        activityMap.put('LOOKUP', 'LOOKUP');
        activityMap.put('Call Duration', '12020591728');
        activityMap.put('IXN Type', 'OpenMedia');
        activityMap.put('Media Type', 'Media Type');
        activityMap.put('Comments', 'Comments');
        activityMap.put('Disposition', 'Disposition');
        activityMap.put('GenesysId', 'GenesysId');
        activityMap.put('DATE', '2014-06-12');
        activityMap.put('SFDC1field', 'Subject');
        activityMap.put('SFDC1value', 'test');
        activityMap.put('SFDC2field', 'type');
        activityMap.put('SFDC2value', 'call');
        activityMap.put('SFDC3field', 'Status');
        activityMap.put('SFDC3value', 'Completed');
        activityMap.put('SFDC4field', 'Description');
        activityMap.put('SFDC4value', 'Comments');
        activityMap.put('SFDC5field', 'CallDisposition');
        activityMap.put('SFDC5value', 'Disposition');
        CTIListenerController2.createActivity(activityMap);

        activityMap.put('sfdc Object Id', testContact.Id);
        CTIListenerController2.createActivity(activityMap);

        Test.stopTest();

        Task testTask = [SELECT Id,Interaction_Type__c,Description
                         FROM task
                         WHERE Interaction_Type__c = 'OpenMedia'
                         AND CallDisposition ='Disposition'
                         AND CallObject='GenesysId'
                         LIMIT 1];

        System.assertNotEquals(null,testTask.Id,
                'CTIListenerController2_Test_testCreateActivityOpenMediaIXNType : Task should be created.');

        System.assertEquals('OpenMedia',testTask.Interaction_Type__c,
                'CTIListenerController2_Test_testCreateActivityOpenMediaIXNType : OpenMedia Interaction Type should be created.');

        System.assertEquals('Comments',testTask.Description,
                'CTIListenerController2_Test_testCreateActivityOpenMediaIXNType : Description with Comments should be created.');

    }

}