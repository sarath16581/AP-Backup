/**************************************************
Type:       ContactHeaderPanelComponentCont_v2_Test
History:
--------------------------------------------------
Jun-2018:  TDO-69 : hector.huang@coroma.com.au Unit tests re-written with scenario based tests.
**************************************************/
@isTest
private class ContactHeaderPanelComponentCont_v2_Test {

    @testSetup
    static void testSetup() {

        // create an organisation account for testing total actual revenue
        Account orgAccount = TestDataProvider.createTestAccount();
        insert orgAccount;

        // create a target and revenue linked to the above account
        Budget_and_Revenue__c revenue = new Budget_and_Revenue__c();
        revenue.Total_Revenue_Amount__c = 1000;
        revenue.Organisation__c = orgAccount.Id;
 		revenue.Current_Year__c = true;
        insert revenue;

        // create a contact prepared for initializing ContactHeaderPanelComponent
        Contact contact = TestDataProvider.createTestContact();
        contact.AccountId = orgAccount.Id;
        insert contact;

        // create a person account prepared for initializing ContactHeaderPanelComponent
        Account personAccount = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com',
                MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert personAccount;

        // create a case prepared for initializing ContactHeaderPanelComponent
        Case newCase = TestDataProvider.createTestCase();
        Account account = [SELECT PersonContactId FROM Account WHERE Id = :personAccount.Id LIMIT 1];
        newCase.ContactId = account.PersonContactId;
        insert newCase;

        // create a compensation linked to the above person account's contactId
        Compensation__c compensation = new Compensation__c(Case__c = newCase.Id);
        compensation.Case__r = newCase;
        compensation.recordtypeid = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('International Accounting').getRecordTypeId();
        compensation.Compensation_Amount__c = 1000;
        compensation.Service_Value__c = 500;
        compensation.Other__c = 200;
        insert compensation;

        // create a legacy account in order to create billing account according to the billing account trigger
        Account legAccount = new Account(Name = 'legacy');
        legAccount.LEGACY_ID__c = '60000000';
        insert legAccount;

        // create both true and false credit status billing accounts linked to the above contact
        Billing_Account__c positiveCreditBillingAccount = new Billing_Account__c(Organisation__c = personAccount.Id);
        positiveCreditBillingAccount.PAYER_ACCOUNT_ID__c = null;
        positiveCreditBillingAccount.Credit_Status__c = true;
        insert positiveCreditBillingAccount;

        Billing_Account__c negativeCreditBillingAccount = new Billing_Account__c(Organisation__c = personAccount.Id);
        negativeCreditBillingAccount.PAYER_ACCOUNT_ID__c = null;
        negativeCreditBillingAccount.Credit_Status__c = false;
        insert negativeCreditBillingAccount;

        // create NPS surveys prepared to be calculated the average score in the header panel component
        NPSSurvey__c highSurvey = new NPSSurvey__c();
        highSurvey.Contact__c = account.PersonContactId;
        highSurvey.Answer1__c = '100';
        insert highSurvey;

        NPSSurvey__c lowSurvey = new NPSSurvey__c();
        lowSurvey.Contact__c = account.PersonContactId;
        lowSurvey.Answer1__c = '20';
        insert lowSurvey;

        // create a customer header settings to be leveraged in the header panel component
        CustomerHeaderSettings__c headerSettings = new CustomerHeaderSettings__c();
        headerSettings.ActivitiesReportID__c = 'Activity';
        headerSettings.CasesReportID__c = 'Case';
        headerSettings.CompensationReportID__c = 'Compensation';
        headerSettings.CreditStatusReportID__c = 'Credit_Status';
        insert headerSettings;

        // create LOA settings prepared to be calculated minimum value in the header panel component
        LOA_Settings__c lowLoaSettings = new LOA_Settings__c(Name = 'low');
        lowLoaSettings.LOA_Value__c = 1;
        insert lowLoaSettings;

        LOA_Settings__c highLoaSettings = NEW LOA_Settings__c(Name = 'high');
        highLoaSettings.LOA_Value__c = 2;
        insert highLoaSettings;

    }

    @isTest
    /**
     * SCENARIO: ContactHeaderPanelComponent is initialized by an account id
     **/
    static void ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized() {
        // get the account inserted during test setup
        Account personAccount = [SELECT Id FROM Account WHERE FirstName = 'test acc' LIMIT 1];

        Test.startTest();

        ContactHeaderPanelComponentCont_v2 headerComponent = new ContactHeaderPanelComponentCont_v2();
        headerComponent.recId = personAccount.Id;

        // verify the total compensation after the component sums up
        System.assertEquals(1700, headerComponent.compensationTotal,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the compensation is not equal to the total number');

        // verify the minimum LOA of the component
        System.assertEquals(1, headerComponent.minLOA,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the minimum LOA is not the lowest in records');

        // verify the positive credit total
        System.assertEquals(1, headerComponent.creditStatusTrueCount,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the total of positive credit is not 1');

        // verify the negative credit total
        System.assertEquals(1, headerComponent.creditStatusFalseCount,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the total of negative credit is not 1');

        // verify if the component contains personal account
        System.assertEquals(true, headerComponent.isPersonAccount,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the account of the component is not a person account');

        // verify the average NPS score
        System.assertEquals(60, headerComponent.npsResponse,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the average NPS score is not (100+20) / 2');

        Test.stopTest();
    }

    @isTest
    /**
     * SCENARIO: ContactHeaderPanelComponent is initialized by a contact id
     **/
    static void ContactHeaderPanelComponentCont_v2_Test_createComponentByContact_initialized() {
        // get the contact inserted during test setup
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];

        Test.startTest();

        ContactHeaderPanelComponentCont_v2 headerComponent = new ContactHeaderPanelComponentCont_v2();

        headerComponent.recId = contact.Id;

        // verify the total revenue for current FY
        System.assertEquals(0, headerComponent.revenueForCurrentFY,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByAccount_initialized: the total of revenue for current FY does not exist');

        // verify the minimum LOA of the component
        System.assertEquals(1, headerComponent.minLOA,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByContact_initialized: the minimum LOA is not the lowest in records');

        // verify the activity report ID
        System.assertEquals('Activity', headerComponent.activitiesReportID,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByContact_initialized: the activity report ID is not as the preset');

        // verify the case report ID
        System.assertEquals('Case', headerComponent.casesReportID,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByContact_initialized: the case report ID is not as the preset');

        // verify the compensation report ID
        System.assertEquals('Compensation', headerComponent.compensationReportID,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByContact_initialized: the compensation report ID is not as the preset');

        // verify the credit status report ID
        System.assertEquals('Credit_Status', headerComponent.creditStatusReportID,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByContact_initialized: the credit status report ID is not as the preset');

        Test.stopTest();
    }

    @isTest
    /**
     * SCENARIO: ContactHeaderPanelComponent is initialized by a case id
     **/
    static void ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized() {
        // get the case inserted during test setup
        Case newCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();

        ContactHeaderPanelComponentCont_v2 headerComponent = new ContactHeaderPanelComponentCont_v2();

        headerComponent.recId = newCase.Id;

        // verify the total compensation after the component sums up
        System.assertEquals(1700, headerComponent.compensationTotal,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized: the compensation is not equal to the total number');

        // verify the minimum LOA of the component
        System.assertEquals(1, headerComponent.minLOA,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized: the minimum LOA is not the lowest in records');

        // verify the positive credit total
        System.assertEquals(1, headerComponent.creditStatusTrueCount,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized: the total of positive credit is not 1');

        // verify the negative credit total
        System.assertEquals(1, headerComponent.creditStatusFalseCount,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized the total of negative credit is not 1');

        // verify if the component contains personal account
        System.assertEquals(true, headerComponent.isPersonAccount,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized: the account of the component is not a person account');

        // verify the average NPS score
        System.assertEquals(60, headerComponent.npsResponse,
                'ContactHeaderPanelComponentCont_v2_Test_createComponentByCase_initialized: the average NPS score is not (100+20) / 2');

        Test.stopTest();
    }

}