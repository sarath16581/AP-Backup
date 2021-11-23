/* @author 
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag BillingAccount
 * @domain Core
 * @description test class for BillingAccountCreationEventHelper
 * @changelog
 * 2020-11-18 - Shashwat.Nath@austpost.com.au - Created
 */
@IsTest
public with sharing class BillingAccountCreationEventHelperTest {
    @IsTest
    private static void testBillingAccountCreationSuccessScenario() {
    // =====================================
    // Data Preparation
    // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
       
        
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;
       
        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount; 
        


    // =====================================
    // Stubbing
    // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);        
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );
        
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);
        
        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

        
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();
         
        Test.startTest(); 
            BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
            Request_Object_Id__c=dealSupportRequest.Id,
            Billing_Account_Number__c = 'SF-11224455',
            Billing_Account_Name__c ='Test Billing account Name',
            Organisation_Record_Id__c=account.Id,
            Transaction_Id__c = externalOnboardingRecord.Id,
            Source_System__c = 'SAP',
            Status__c = 'Success'
           );
           EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent1);

        Test.stopTest();
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is happening in Success scenario */
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }
    @IsTest
    private static void testBillingAccountCreationErrorScenario() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];


        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount;



        // =====================================
        // Stubbing
        // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();

        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);

        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Source_System__c = 'SAP',
                Status__c = 'Error'
        );
        EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Error'
        );
        EventBus.publish(newsEvent1);

        Test.stopTest();
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is happening in Success scenario */
        //((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
       // ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is not happening in Error scenario */
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());
   }

    @IsTest
    private static void testBillingAccountCreationSuccessScenarioTeam() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];


        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        //APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount;



        // =====================================
        // Stubbing
        // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();

        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);

        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'T-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Source_System__c = 'TEAM',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent);



        Test.stopTest();
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is happening in Success scenario */
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @IsTest
    private static void testBillingAccountCreationPartialSuccessScenario() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];


        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;


        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount;



        // =====================================
        // Stubbing
        // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();

        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);

        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Source_System__c = 'SAP',
                Status__c = 'Partial Success'
        );
        EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224454',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent1);

        Test.stopTest();
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is happening in Success scenario */
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @IsTest
    private static void testDSRCreationForAddContractRates() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];


        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Billing Account';
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount;



        // =====================================
        // Stubbing
        // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();

        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);

        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Source_System__c = 'SAP',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent1);

        Test.stopTest();
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is happening in Success scenario */
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @IsTest
    private static void testBillingAccountCreationPartialSuccessSubScenario() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];


        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount;



        // =====================================
        // Stubbing
        // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();

        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);

        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Source_System__c = 'SAP',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=dealSupportRequest.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Partial Success'
        );
        EventBus.publish(newsEvent1);

        Test.stopTest();
        /* Since using Selector Framework we are mocking the dml insert and not doing actual dml in the class , Not able to assert the actual record
           and instead using the below statement to confirm the Mock insert is happening in Success scenario */
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }
    
    @IsTest
    private static void testBillingAccountCreationSuccessScenarioBCAError() {
    // =====================================
    // Data Preparation
    // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
       
        
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
        
        APT_Credit_Assessment__c CA = ApplicationTestDataFactory.getApttusCreditsAssessment(1,null,true)[0];
        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;
       
        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount; 
        


    // =====================================
    // Stubbing
    // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);        
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );
        
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);
        
        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

        
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();
         
        Test.startTest(); 
            BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
            Request_Object_Id__c=CA.Id,
            Billing_Account_Number__c = 'SF-11224455',
            Billing_Account_Name__c ='Test Billing account Name',
            Organisation_Record_Id__c=account.Id,
            Transaction_Id__c = externalOnboardingRecord.Id,
            Source_System__c = 'SAP',
            Status__c = 'Error'
           );
           EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=CA.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Success'
        );
        EventBus.publish(newsEvent1);

        Test.stopTest();
     }
        
    @IsTest
    private static void testBillingAccountCreationSuccessScenarioBCASuccess() {
    // =====================================
    // Data Preparation
    // =====================================
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
       
        
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
        Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
        billingAccount.LEGACY_ID__c = 'SF-11224455';

        subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
        
        APT_Credit_Assessment__c CA = ApplicationTestDataFactory.getApttusCreditsAssessment(1,null,true)[0];
        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        //apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;
       
        Account tempAccount = new Account();
        tempAccount.name = 'TempBillingaccount';
        tempAccount.Legacy_Id__c = '60000000';
        insert tempAccount;
        tempAccount.Legacy_Id__c = '60000000';
        update tempAccount; 
        


    // =====================================
    // Stubbing
    // =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);        
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
        SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
        BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );
        
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(), new Set<object>{DealSupportRequestsSelector.Options.WITH_OWNER, DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT , DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST, DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT})).thenReturn(mockDsrMap);
        
        Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
        //MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
        MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

        Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
        MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

        Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
        system.debug('Mock Billing Account Map' +billAccountMap);
        system.debug('Mock Billing Account ' +billingAccount);
        //MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
        MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

        
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();
         
        Test.startTest(); 
            BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
            Request_Object_Id__c=CA.Id,
            Billing_Account_Number__c = 'SF-11224455',
            Billing_Account_Name__c ='Test Billing account Name',
            Organisation_Record_Id__c=account.Id,
            Transaction_Id__c = externalOnboardingRecord.Id,
            Source_System__c = 'SAP',
            Status__c = 'Success'
           );
           EventBus.publish(newsEvent);

        BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
                Request_Object_Id__c=CA.Id,
                Billing_Account_Number__c = 'SF-11224455',
                Billing_Account_Name__c ='Test Billing account Name',
                Organisation_Record_Id__c=account.Id,
                Transaction_Id__c = externalOnboardingRecord.Id,
                Parent_Account_Number__c = 'SF-11224455',
                Sub_Account_Request_Id__c = subAccountRequest.id,
                Source_System__c = 'SAP',
                Status__c = 'Error'
        );
        EventBus.publish(newsEvent1);

    Test.stopTest();
    
    }
}