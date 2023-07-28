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
        // create a super user
        TestDataFactory.insertUserFuture('SSSW - Service Agent',new Set<String>{'CC_Compensation_User'},'agent','CEO/Reporting');
        TestDataFactory.insertUserFuture('SSSW - Service Agent',new Set<String>{'CC_Compensation_Supervisor'},'Superagent','CEO/Reporting');
        TestDataFactory.insertUserFuture('SSSW - Service Agent',null,'normalUser','CEO/Reporting');
        Test.stopTest();
    }
	/********************************************
	Scenario:
	Test the bank details save method.
	*********************************************/
    static testMethod void testSaveMethod() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        Insert comp;
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        
        //enter banking details.
        ext.accountNumber = '11111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;
        //save
        ext.saveMethod();
        Test.stopTest();
        
        System.assertEquals(true,ext.showEditButton,'check edit button visibility');
        System.assertEquals(false,ext.showEditScreen,'check edit screen visibility');
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.Confirm),'check edit button visibility');
    }

    static testMethod void testSaveMethod_AgentEditChangeRoute() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Bank_Detail_Provided_By_Customer__c = true, Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '', Account_Number__c = '' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        Insert comp;
        
        Test.startTest();
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
        Test.stopTest();
        
        comp = [SELECT Bank_Detail_Provided_By_Customer__c, Account_Name__c, Account_Number__c, BSB__c FROM Compensation__c WHERE Id = :comp.Id];

        System.assert(String.isNotEmpty(comp.Account_Name__c), 'testSaveMethod_AgentEdit failed: account name is not saved');
        System.assert(comp.Bank_Detail_Provided_By_Customer__c == false, 'testSaveMethod_AgentEdit failed: checkbox is not cleared');
    }

    static testMethod void testAwaitBankDetailsNotification() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
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
    static testMethod void testCancelMethod() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
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
    static testMethod void testInsertMethod() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        //enter bank details
        ext.accountNumber = '11111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;
        //insert compensation
        ext.insertMethod();
        Test.stopTest();
        
        //query the compensation to verify creation
        Compensation__c c = [select Id,Name,Batch_ID__c from Compensation__c][0];
        //check the batch Id returned vs inserted.
        System.assertEquals(1,c.Batch_ID__c,'compensation creation');
    }

    static testMethod void testInsertMethod_CompensationChecked() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test' , RecordTypeId = recordTypeId, Cover_Type__c = 'T&C Cover');
        
        Test.startTest();
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
        Test.stopTest();
        
        //query the compensation to verify creation
        Compensation__c c = [select Id,Name,Batch_ID__c,Account_Number__c from Compensation__c][0];
        //check the batch Id returned vs inserted.
        // System.assertEquals(1,c.Batch_ID__c,'compensation creation');
        System.debug('------' + c.Account_Number__c);
        System.assert(String.isEmpty(c.Account_Number__c));
    }
    
    /********************************************
	Scenario:
	Test the validation that check empty bank details.
	*********************************************/
    static testMethod void testValidateEmptyBankNo() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;
        
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        
        Test.startTest();
		//exclude account number field.
        //ext.accountNumber = '11111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;
        
        ext.insertMethod();
        Test.stopTest();
    		
		System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Bank Details cannot be empty.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }
    
    /********************************************
	Scenario:
	Test the validation that checks non-numeric values
	*********************************************/
    static testMethod void testValidateNumberCheck() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        
        ext.accountNumber = '11111111';
        //enter non numaric value for BSB.
        ext.accountBSB = '1111gg';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;
        
        ext.insertMethod();
        Test.stopTest();
        
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Account Number and BSB should be numbers only.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }
    
    /********************************************
	Scenario:
	Test the validation that checks values BSB larger than 6 digits
	*********************************************/
    static testMethod void testValidateLengthBSB() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        
        ext.accountNumber = '11111111';
        //enter a number larger than 6 digits
        ext.accountBSB = '1111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;
        
        ext.insertMethod();
        Test.stopTest();
        
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('BSB should be 6 digits',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }
    
    /********************************************
	Scenario:
	Test the validation that checks account numbers larger than 9 digits.
	*********************************************/
    static testMethod void testValidateLengthAccNo() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        
        //enter a account number larger than 9 digits.
        ext.accountNumber = '11111111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        ext.confirmDetails = true;
        
        ext.insertMethod();
        Test.stopTest();
        
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Account Number should not exceed beyond 9 digits',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }
    
    /********************************************
	Scenario:
	Test the validation that ensures the privacy check has been done.
	*********************************************/
    static testMethod void testValidatePrivacyCheck() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
        
        ext.accountNumber = '11111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        //uncheck the privacy check
        ext.privacyCheck = false;
        ext.confirmDetails = true;
        
        ext.insertMethod();
        Test.stopTest();
        
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Please ensure that data compliance statement has been read to the customer.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }
    
    /********************************************
	Scenario:
	Test the validation that check whether the agent has verified the details before saving.
	*********************************************/
    static testMethod void testValidateDetailsConfirmation() {
    	//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        //Insert comp;
        
        Test.startTest();
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
        EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
    		
        ext.accountNumber = '11111111';
        ext.accountBSB = '111111';
        ext.accountName = 'New Account';
        ext.privacyCheck = true;
        //uncheck the confirm details
        ext.confirmDetails = false;
        
        ext.insertMethod();
        Test.stopTest();
        
        System.assertEquals(true,ApexPages.hasMessages(ApexPages.SEVERITY.ERROR),'check validation has fired');
		System.assertEquals('Please confirm Bank Details with the customer.',ApexPages.getMessages()[0].getSummary(),'check edit button visibility');
    }

    /**
     * Compensation user permission is not allowed to update bank details
     */
    static testMethod void testValidateCompensationUserPermission_bankDetail_001() {

        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent'];
        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id ,
                Batch_ID__c = 1 ,
                Status__c = 'Pending' ,
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'ACL');

        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{comp});

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
        system.debug('HASANTHA MSG'+message+ApexPages.getMessages());
        System.assertEquals(
                'You do not have privilege to manually enter the bank account details',
                ApexPages.getMessages()[0].getSummary(),
                'testValidateCompensationUserPermission_bankDetail_001: You do not have privilege to manually enter the bank account details'
        );
    }

    /**
  * Compensation Supervisor user permission is allowed to update bank details
  */
    static testMethod void testValidateCompensationUserPermission_bankDetail_002() {

        User superUser = [SELECT Id FROM User WHERE FirstName = 'Superagent'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id ,
                Batch_ID__c = 1 ,
                Status__c = 'Pending' ,
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId, Cover_Type__c = 'ACL');


        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{comp});

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
                'testValidateCompensationUserPermission_bankDetail_002: Super user should have privilege to manually enter the bank account details'
        );
    }

    /**
    * Normal user permission is NOT allowed to send email
    */
    static testMethod void testValidateCompensationSendEmail_001() {

        User normalUser = [SELECT Id FROM User WHERE FirstName = 'normalUser'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id ,
                Batch_ID__c = 1 ,
                Status__c = 'Pending' ,
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345' ,
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );


        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{comp});

        Test.startTest();
        System.runAs(normalUser) {

            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.compensationEmail = true;
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                'You do not have privilege to send email to customer',
                ApexPages.getMessages()[0].getSummary(),
                'testValidateCompensationSendEmail__001: You do not have privilege to send email to customer'
        );
    }

    /**
    * Users with permission is allowed to send email
    */
    static testMethod void testValidateCompensationSendEmail_002() {

        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id ,
                Batch_ID__c = 1 ,
                Status__c = 'Pending' ,
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345' ,
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );


        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{comp});

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
                'testValidateCompensationSendEmail_002: User should have privilege to send email to customer'
        );
    }

    /**
    * Check on privilege to create compensation records as an agent user with permissions
    */
    static testMethod void validateOnLoad_001() {

        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Test.startTest();
        System.runAs(agentUser) {
            Compensation__c comp = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id ,
                    Batch_ID__c = 1 ,
                    Status__c = 'Pending' ,
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
        system.debug('HASANTHA -- '+ApexPages.getMessages());
        System.assertEquals(
                0,
                ApexPages.getMessages().size(),
                'validateOnLoad_001: User should have privilege to create/update compensation records.'
        );
    }

    /**
    * Check on privilege to create compensation records as a normal user without permissions and with EFT record type
    */
    static testMethod void validateOnLoad_002() {

        User normalUser = [SELECT Id FROM User WHERE FirstName = 'normalUser'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Test.startTest();
        System.runAs(normalUser) {
            Compensation__c comp = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id ,
                    Batch_ID__c = 1 ,
                    Status__c = 'Pending' ,
                    Compensation_Amount__c = 150,
                    CostCentreCode__c = 'test',
                    BSB__c = '444333',
                    Account_Number__c = '123234345' ,
                    RecordTypeId = recordTypeId,
                    Cover_Type__c = 'ACL'
            );
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(comp);
            EFTBankDetailsController ext = new EFTBankDetailsController(stdCtl);
            ext.insertMethod();
        }
        Test.stopTest();

        System.assertEquals(
                'You do not have privilege to create/update compensation records.',
                ApexPages.getMessages()[0].getSummary(),
                'validateOnLoad_001: User do not have privilege to create/update compensation records.'
        );
    }

    /**
     * User should not be able to create a duplicate compensation record per Reference ID
     */
    static testMethod void validateOnLoad_003() {

        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c  = 'REF01';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id ,
                Batch_ID__c = 1 ,
                Status__c = 'Pending' ,
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345' ,
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );


        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{comp});
        Test.startTest();
        System.runAs(agentUser) {
            Compensation__c comp2 = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id ,
                    Batch_ID__c = 1 ,
                    Status__c = 'Pending' ,
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
                'The Reference ID already have a compensation record and only supervisor can create more than one.',
                ApexPages.getMessages()[0].getSummary(),
                'validateOnLoad_001: User should not be able to create another compensation record'
        );
    }

    /**
     * Only supervisor user should be able to create duplicate compensation records
     */
    static testMethod void validateOnLoad_004() {

        User Superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        testCase.ReferenceID__c  = 'REF01';
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        Compensation__c comp = new Compensation__c(
                Contact__c = contact.Id,
                Case__c = testCase.Id ,
                Batch_ID__c = 1 ,
                Status__c = 'Pending' ,
                Compensation_Amount__c = 150,
                CostCentreCode__c = 'test',
                BSB__c = '444333',
                Account_Number__c = '123234345' ,
                RecordTypeId = recordTypeId,
                Cover_Type__c = 'ACL'
        );


        EFTBankDetailsController.ElevatedSharingContext context = new EFTBankDetailsController.ElevatedSharingContext();
        context.upsertRecords(new List<SObject>{comp});
        Test.startTest();
        System.runAs(Superagent) {
            Compensation__c comp2 = new Compensation__c(
                    Contact__c = contact.Id,
                    Case__c = testCase.Id ,
                    Batch_ID__c = 1 ,
                    Status__c = 'Pending' ,
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
                'validateOnLoad_004: Only supervisor user should be able to create duplicate compensation records'
        );
    }

}