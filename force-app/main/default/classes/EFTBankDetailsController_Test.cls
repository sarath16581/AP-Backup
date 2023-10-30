/**
* @author Dishan Egodawela
* @date 2018-09-09
* @group Compensation
* @tag Controller
* @tag Compensation__c
* @domain Case Details Page
* @description This class contains unit tests for validating the behavior of Apex contraller EFTBankDetailsController
* 2018-09-09 - dilshan.egodawela@auspost.com.au  Created
* 2020-08-07 - dheeraj.mandavilli@auspost.com.au Added Logic to accomodate Load & Go Record Type Tests
* 2020-08-21 - dheeraj.mandavilli@auspost.com.au Removed Logic associated with Load & Go Record Type.
* 2021-08-25 - phap.mai@auspost.com.au Added test method for compensation email checkbox
* 2023-07-25 - Hasantha.Liyanage@auspost.com.au Added test method for new compensation custom permission validations
*/

@isTest
public with sharing class EFTBankDetailsController_Test {
    @TestSetup
    static void setupData() {
        Test.startTest();
        // Creating users in async context to avoid mix DML issues
        // create a compensation user: allows to create compensation records but not allowed to create dupes or update bank account details
        List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
        TestDataFactory.UserDTO agent = new TestDataFactory.UserDTO();
        agent.profileName = 'SSSW - Service Agent';
        agent.permissionSetNames = new Set<String>{'CC_Compensation_User'};
        agent.userName = 'agent123';
        agent.role = 'CEO/Reporting';
        userDTOs.add(agent);

        // create a super user: allows to create compensation records, update bank account details, create multiple compensations, send emails
        TestDataFactory.UserDTO superAgent = new TestDataFactory.UserDTO();
        superAgent.profileName = 'SSSW - Service Agent';
        superAgent.permissionSetNames = new Set<String>{'CC_Compensation_Supervisor'};
        superAgent.userName = 'Superagent';
        superAgent.role = 'CEO/Reporting';
        userDTOs.add(superAgent);

        // user with SSSW agent profile and without any permission sets assigned
        TestDataFactory.UserDTO normalUser = new TestDataFactory.UserDTO();
        normalUser.profileName = 'SSSW - Service Agent';
        normalUser.permissionSetNames = null;
        normalUser.userName = 'normalUser';
        normalUser.role = 'CEO/Reporting';
        userDTOs.add(normalUser);

        TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
        System.enqueueJob(queueable);

        Test.stopTest();
    }
	/********************************************
	Scenario:
	Test the bank details save method.
	*********************************************/
    @IsTest
    static void testSaveMethod() {
        //create test data
        // by pass the validation rules when run as a user with a SSSW Agent profile
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        Insert comp;

        EFTBankDetailsController ext;
        Test.startTest();
        // admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            ext = new EFTBankDetailsController(stdCtl);

            //enter banking details.
            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;
            //save
            ext.saveMethod();
        }
        Test.stopTest();

        System.assertEquals(true,ext.showEditButton,'check edit button visibility');
        System.assertEquals(false,ext.showEditScreen,'check edit screen visibility');
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.Confirm),'check edit button visibility');
    }

    @IsTest
    static void testSaveMethodAgentEditChangeRoute() {
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Bank_Detail_Provided_By_Customer__c = true, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '', Account_Number__c = '' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        Insert comp;

        Test.startTest();
        // admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

            //enter banking details.
            ext.accountNumber = '1234';
            ext.accountBSB = '123456';
            ext.accountName = 'Phap';
            ext.privacyCheck = true;
            ext.confirmDetails = true;
            //save
            ext.saveMethod();
        }
        Test.stopTest();

        comp = [SELECT Bank_Detail_Provided_By_Customer__c, Account_Name__c, Account_Number__c, BSB__c FROM Compensation__c WHERE Id = :comp.Id];

        System.assert(String.isNotEmpty(comp.Account_Name__c), 'testSaveMethod_AgentEdit failed: account name is not saved');
        System.assert(comp.Bank_Detail_Provided_By_Customer__c == false, 'testSaveMethod_AgentEdit failed: checkbox is not cleared');
    }

    @IsTest
    static void testAwaitBankDetailsNotification() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover', Bank_Detail_Provided_By_Customer__c = true);
        Insert comp;

        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

        //enter banking details.
        // ext.accountNumber = '11111111';
        // ext.accountBSB = '111111';
        // ext.accountName = 'New Account';
        // ext.privacyCheck = true;
        // ext.confirmDetails = true;
        //save
        // ext.saveMethod();
        Test.stopTest();

        System.assertEquals(true,ext.showEditButton,'check edit button visibility');
    }

    /********************************************
	Scenario:
	Test the cancel method
	*********************************************/
    @IsTest
    static void testCancelMethod() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        Insert comp;

        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

        ext.accountNumber = '11111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;

        ext.cancelMethod();
        Test.stopTest();
        //screen should return back to view screen.
        System.assertEquals(true,ext.showEditButton,'check edit button visibility');
        System.assertEquals(false,ext.showEditScreen,'check edit screen visibility');
    }

    	/********************************************
	Scenario:
	Test creating a compensation.
	*********************************************/
    @IsTest
    static void testInsertMethod() {
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');

        Test.startTest();
        //insert compensation
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            //enter bank details
            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;
            ext.insertMethod();
        }
        Test.stopTest();

        //query the compensation to verify creation
        Compensation__c c = [select Id,Name,Batch_ID__c from Compensation__c][0];
        //check the batch Id returned vs inserted.
        System.assertEquals(1,c.Batch_ID__c,'compensation creation');
    }

    @IsTest
    static void testInsertMethodCompensationChecked() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            //enter bank details
            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;
            ext.compensationEmail = true;
            //insert compensation
            ext.insertMethod();
        }

        Test.stopTest();

        //query the compensation to verify creation
        Compensation__c c = [select Id,Name,Batch_ID__c,Account_Number__c from Compensation__c][0];
        System.assert(String.isEmpty(c.Account_Number__c));
    }

    /********************************************
	Scenario:
	Test the validation that check empty bank details.
	*********************************************/
    @IsTest
    static void testValidateEmptyBankNo() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id, Batch_ID__c = 1, Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345', RecordTypeId = recordTypeId);

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            //exclude account number field.
            //ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;

            ext.insertMethod();
        }
        Test.stopTest();

		System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Bank Details cannot be empty.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /********************************************
	Scenario:
	Test the validation that checks non-numeric values
	*********************************************/
    @IsTest
    static void testValidateNumberCheck() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

            ext.accountNumber = '11111111';
            //enter non numaric value for BSB.
            ext.accountBSB = '1111gg';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;

            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Account Number and BSB should be numbers only.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /********************************************
	Scenario:
	Test the validation that checks values BSB larger than 6 digits
	*********************************************/
    @IsTest
    static void testValidateLengthBSB() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

            ext.accountNumber = '11111111';
            //enter a number larger than 6 digits
            ext.accountBSB = '1111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;

            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('BSB should be 6 digits',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /********************************************
	Scenario:
	Test the validation that checks account numbers larger than 9 digits.
	*********************************************/
    @IsTest
    static void testValidateLengthAccNo() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

            //enter a account number larger than 9 digits.
            ext.accountNumber = '11111111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;

            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Account Number should not exceed beyond 9 digits',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /********************************************
	Scenario:
	Test the validation that ensures the privacy check has been done.
	*********************************************/
    @IsTest
    static void testValidatePrivacyCheck() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            //uncheck the privacy check
            ext.privacyCheck = false;
            ext.confirmDetails = true;

            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Please ensure that data compliance statement has been read to the customer.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /********************************************
	Scenario:
	Test the validation that check whether the agent has verified the details before saving.
	*********************************************/
    @IsTest
    static void testValidateDetailsConfirmation() {
        //create test data
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        // by pass the validation rules when run as a user with a SSSW Agent profile
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;

        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(Contact__c = contact.Id, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;

        Test.startTest();
        //admin user will not be able to create the record without custom permission set, hence need a run as
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);

            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            //uncheck the confirm details
            ext.confirmDetails = false;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Please confirm Bank Details with the customer.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /**
     * Compensation user permission is not allowed to update bank details
     */
    @IsTest
    static void testValidateCompensationUserPermissionBankDetailNoPermission() {
        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent123'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id,
                Batch_ID__c = 1,
                Status__c = 'Pending',
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333', Account_Number__c = '123234345', RecordTypeId = recordTypeId, Cover_Type__c = 'ACL');

        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{
                comp
        });

        Test.startTest();
        String message = '';
        System.runAs(agentUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;
            try {
                ext.insertMethod();
            } catch (Exception e) {
                message = e.getMessage();
            }
        }
        Test.stopTest();
        System.assertEquals(
                Label.CompensationMsgUserCannotUpdateBankDetails,
                ApexPages.getMessages()[0].getSummary(),
                'testValidateCompensationUserPermissionBankDetailNoPermission: You do not have privilege to manually enter the bank account details'
        );
    }

    /**
      * Compensation Supervisor user permission is allowed to update bank details
      */
    @IsTest
    static void testValidateCompensationUserPermissionBankDetailWithPermission() {
        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id,
                Batch_ID__c = 1,
                Status__c = 'Pending',
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345',
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL');
        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{
                comp
        });

        Test.startTest();
        System.runAs(superUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.accountNumber = '11111111';
            ext.accountBSB = '111111';
            ext.accountName = 'New Account';
            ext.privacyCheck = true;
            ext.confirmDetails = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                0,
                ApexPages.getMessages().size(),
                'testValidateCompensationUserPermissionBankDetailWithPermission: Super user should have privilege to manually enter the bank account details'
        );
    }

    /**
    * Normal user permission is NOT allowed to send email
    */
    @IsTest
    static void testValidateCompensationSendEmailNoPermission() {
        User normalUser = [SELECT Id FROM User WHERE FirstName = 'normalUser'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id,
                Batch_ID__c = 1,
                Status__c = 'Pending',
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345',
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );
        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{
                comp
        });

        Test.startTest();
        System.runAs(normalUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.compensationEmail = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                Label.CompensationMsgUserIsNotAllowedToSendEmail,
                ApexPages.getMessages()[0].getSummary(),
                'testValidateCompensationSendEmailNoPermission: You do not have privilege to send email to customer'
        );
    }

    /**
    * Users with permission is allowed to send email
    */
    @IsTest
    static void testValidateCompensationSendEmailNormalUser() {
        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent123'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id,
                Batch_ID__c = 1,
                Status__c = 'Pending',
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345',
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );
        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{
                comp
        });

        Test.startTest();
        System.runAs(agentUser) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.compensationEmail = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                0,
                ApexPages.getMessages().size(),
                'testValidateCompensationSendEmailNormalUser: User should have privilege to send email to customer'
        );
    }

    /**
    * Check on privilege to create compensation records as an agent user with permissions
    */
    @IsTest
    static void validateOnLoadCreateUpdateWithAgentPermission() {
        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent123'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Test.startTest();
        System.runAs(agentUser) {
            Compensation__c comp = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id,
                    Batch_ID__c = 1,
                    Status__c = 'Pending',
                    Compensation_Amount__c = 150,
                    CostCentreCode__c = 'test',
                    RecordTypeId = recordTypeId,
                    Cover_Type__c = 'ACL'
            );
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.compensationEmail = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                0,
                ApexPages.getMessages().size(),
                'validateOnLoadCreateUpdateWithAgentPermission: User should have privilege to create/update compensation records.'
        );
    }

    /**
    * Check on privilege to create compensation records as a normal user without permissions and with EFT record type
    */
    @IsTest
    static void validateOnLoadCreateUpdateWithoutPermission() {
        User normalUser = [SELECT Id FROM User WHERE FirstName = 'normalUser'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF001';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Test.startTest();
        System.runAs(normalUser) {
            Compensation__c comp = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id,
                    Batch_ID__c = 1,
                    Status__c = 'Pending',
                    Compensation_Amount__c = 150,
                    CostCentreCode__c = 'test',
                    RecordTypeId = recordTypeId,
                    Cover_Type__c = 'ACL'
            );

            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        }
        Test.stopTest();

        System.assertEquals(
                Label.CompensationMsgNoPrivilege,
                ApexPages.getMessages()[0].getSummary(),
                'validateOnLoadCreateUpdateWithoutPermission: User do not have privilege to create/update compensation records.'
        );
    }

    /**
     * User should not be able to create a duplicate compensation record per Reference ID
     */
    @IsTest
    static void validateOnLoadCreateDuplicateCompensationWithoutPermission() {
        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent123'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF01';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id,
                Batch_ID__c = 1,
                Status__c = 'Pending',
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345',
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );
        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{
                comp
        });

        Test.startTest();
        System.runAs(agentUser) {
            Compensation__c comp2 = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id,
                    Batch_ID__c = 1,
                    Status__c = 'Pending',
                    Compensation_Amount__c = 150,
                    CostCentreCode__c = 'test',
                    RecordTypeId = recordTypeId,
                    Cover_Type__c = 'ACL'
            );
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp2);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.compensationEmail = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                Label.CompensationMsgMoreThanOnePerCaseReference,
                ApexPages.getMessages()[0].getSummary(),
                'validateOnLoadCreateDuplicateCompensationWithoutPermission: User should not be able to create another compensation record'
        );
    }

    /**
     * Only supervisor user should be able to create duplicate compensation records
     */
    @IsTest
    static void validateOnLoadCreateDuplicateCompensationWithPermission() {
        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c = 'REF01';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id,
                Batch_ID__c = 1,
                Status__c = 'Pending',
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345',
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );

        Test.startTest();
        System.runAs(superagent) {
            EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
            context.upsertRecords(new List<SObject>{
                    comp
            });
            Compensation__c comp2 = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id,
                    Batch_ID__c = 1,
                    Status__c = 'Pending',
                    Compensation_Amount__c = 150,
                    CostCentreCode__c = 'test',
                    RecordTypeId = recordTypeId,
                    Cover_Type__c = 'ACL'
            );
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp2);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.compensationEmail = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                0,
                ApexPages.getMessages().size(),
                'validateOnLoadCreateDuplicateCompensationWithPermission: Only supervisor user should be able to create duplicate compensation records'
        );
    }

    /**
    * Testing on agent user trying to create a compensation record with a case which has the reference Id as blank
    */
    @IsTest
    static void validateOnLoadCreateCompensationWithoutCaseReference() {
        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent123'];
        //create test data
        Contact contact = TestDataProvider.createContact('test', null, 'Contact');
        insert contact;
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Test.startTest();
        System.runAs(agentUser) {
            Compensation__c comp = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id,
                    Batch_ID__c = 1,
                    Status__c = 'Pending',
                    Compensation_Amount__c = 150,
                    CostCentreCode__c = 'test',
                    RecordTypeId = recordTypeId,
                    Cover_Type__c = 'ACL'
            );

            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        }
        Test.stopTest();

        System.assertEquals(
                Label.CompensationMsgCaseMustHaveReference,
                ApexPages.getMessages()[0].getSummary(),
                'validateOnLoadCreateCompensationWithoutCaseReference: User should not have privilege to create compensation record without a reference in the case.'
        );
    }
}