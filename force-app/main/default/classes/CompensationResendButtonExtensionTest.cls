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
        iCase.ReferenceID__c = 'REF001';
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
        //Creating users in future to avoid mix DML issues
        // create a super user: allows to create compensation records, update bank account details, create multiple compensations, send emails
        List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
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

    @isTest
    private static void resendCompensationEmailHappyPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', compensation.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(compensation);
        CompensationResendButtonExtension extension = new CompensationResendButtonExtension(controller);
        extension.resendCompensationEmail();
        System.assertEquals(1, System.Limits.getEmailInvocations(), 'resendCompensationEmailHappyPath failed: no email sent');
        Test.stopTest();
    }
    
    @isTest
    private static void resendCompensationEmailErrorPath()
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
            System.assert(extension.compensationEmailResendResult != 'Compensation email has been sent', 'resendCompensationEmailErrorPath failed: resend result is not error');
        }
        System.assertEquals(0, System.Limits.getEmailInvocations(), 'resendCompensationEmailErrorPath failed: email sent');
        Test.stopTest();
    }

    /**
     * Testing of a normal agent user without any permission sets assigned,
     * should not allow the user to re send email
     * isAllowedToCreateCompensation is used to render the visualforce UI buttons based on the value
     */
    @isTest
    static void validateOnResendEmailUserWithoutPrivilege() {
        // =====================================
        // Data Preparation
        // =====================================
        // this user needs to be inserted as the controller's constructor determines the value of the isAllowedToCreateCompensation based on the,
        // custom permissionset assignment
        User superagent = [SELECT Id FROM User WHERE FirstName = 'normalUser'];
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        CompensationResendButtonExtension ext;
        System.runAs(superagent) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(compensations[0]);
            ext = new CompensationResendButtonExtension(stdCtl);
        }
        Test.stopTest();
        System.assertEquals(
                false,
                ext.isAllowedToCreateCompensation,
                'validateOnResendEmailUserWithoutPrivilege: User should not have privilege to resend email'
        );

    }

    /**
     * Testing of an agent user with any custom permissions of Is_Compensation_User or Is_Compensation_Supervisor assigned,
     * should allow the user to re send email
     * isAllowedToCreateCompensation is used to render the visualforce UI buttons based on the value
    */
    @IsTest
    static void validateOnResendEmailUserWithPrivilege() {
        // =====================================
        // Data Preparation
        // =====================================
        // this user needs to be inserted as the controller's constructor determines the value of the isAllowedToCreateCompensation based on the,
        // custom permissionset assignment
        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        CompensationResendButtonExtension ext;
        System.runAs(superagent) {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(compensations[0]);
            ext = new CompensationResendButtonExtension(stdCtl);
        }
        Test.stopTest();

        System.assertEquals(
                true,
                ext.isAllowedToCreateCompensation,
                'validateOnResendEmailUserWithPrivilege: User should have privilege to resend email'
        );

    }
}