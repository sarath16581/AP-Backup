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
*/

@isTest
public with sharing class EFTBankDetailsController_Test {
    
	
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
}