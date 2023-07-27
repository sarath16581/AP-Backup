/***
 * @author
 * @date
 * @domain UI
 * @description Test class for CompensationResendButtonExtension
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Modified: added validateOnResendEmail<###> tests
 */
@isTest
private with sharing class CompensationResendButtonExtensionTest
{
    @TestSetup
    private static void setUpCampFire()
    {
        // setting
        Consumer_Help_and_Support__c hs = new Consumer_Help_and_Support__c();
        hs.Encoded_Crypto_Key__c = 'testcryptokey/testcryptokey/testcryptokey/+=';
        hs.Compensation_Max_Attemps__c = 5;
        insert hs;
        // account
        Account a = TestDataProvider.createAccount('Account', 1)[0];
        insert a;

        // contact
        Contact c = TestDataProvider.createContact('Contact', a.Id, null);
        insert c;

        // case
        Case iCase = TestDataProvider.createCase('subject', 'description', null);
        iCase.ContactId = c.Id;
        insert iCase;

        // EFT record type
        RecordType rc = [SELECT Id FROM RecordType WHERE DeveloperName = 'EFT' AND SobjectType = 'Compensation__c'];

        // compensation
        Compensation__c compensation = new Compensation__c();
        compensation.Contact__c = c.Id;
        compensation.RecordTypeId = rc.Id;
        compensation.Case__c = iCase.Id;
        compensation.Compensation_Amount__c = 50;
        compensation.Cover_Type__c = 'T&C Cover	';
        insert compensation;

        // set the status to Approved Awaiting Customer
        compensation = [SELECT Status__c, Bank_Detail_Provided_By_Customer__c FROM Compensation__c WHERE Id = :compensation.Id];
        compensation.Status__c = SSSWConstants.STATUS_APPROVED_AWAITING_CUSTOMER;
        compensation.Bank_Detail_Provided_By_Customer__c = true;
        update compensation;

        Test.startTest();
        list<PermissionSetAssignment> permissionSetAssignmentList = new list<PermissionSetAssignment>();
        // create a user
        TestDataFactory.insertUserFuture('SSSW - Service Agent',new Set<String>{'CC_Compensation_Supervisor'},'Superagent','CEO/Reporting');
        TestDataFactory.insertUserFuture('SSSW - Service Agent',null,'normalUser','CEO/Reporting');
        Test.stopTest();
    }

    @isTest
    private static void resendCompensationEmail_HappyPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', compensation.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(compensation);
        CompensationResendButtonExtension extension = new CompensationResendButtonExtension(controller);
        extension.resendCompensationEmail();
        System.assertEquals(1, System.Limits.getEmailInvocations(), 'resendCompensationEmail_HappyPath failed: no email sent');
        Test.stopTest();
    }
    
    @isTest
    private static void resendCompensationEmail_ErrorPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        compensation.Bank_Detail_Provided_By_Customer__c = false;
        update compensation;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', compensation.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(compensation);
        CompensationResendButtonExtension extension = new CompensationResendButtonExtension(controller);
        try {
            extension.resendCompensationEmail();
        } catch (Exception e)
        {
            System.assert(extension.compensationEmailResendResult != 'Compensation email has been sent', 'resendCompensationEmail_ErrorPath failed: resend result is not error');
        }
        System.assertEquals(0, System.Limits.getEmailInvocations(), 'resendCompensationEmail_ErrorPath failed: email sent');
        Test.stopTest();
    }

    static testMethod void validateOnResendEmail_001() {

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
            CompensationResendButtonExtension ext = new CompensationResendButtonExtension(stdCtl);
            System.assertEquals(
                    false,
                    ext.isAllowedToCreateCompensation,
                    'validateOnResendEmail_001: User do not have privilege to resend email'
            );
        }
        Test.stopTest();
    }

    static testMethod void validateOnResendEmail_002() {

        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];

        Contact contact = TestDataProvider.createContact('test',null,'Contact');
        insert contact;
        //create test data
        Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;

        Test.startTest();
        System.runAs(superagent) {
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
            CompensationResendButtonExtension ext = new CompensationResendButtonExtension(stdCtl);
            System.assertEquals(
                    true,
                    ext.isAllowedToCreateCompensation,
                    'validateOnResendEmail_001: User should have privilege to resend email'
            );
        }
        Test.stopTest();
    }
}