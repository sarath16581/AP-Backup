/**
 * Created by hasan on 17/08/2023.
 */

@IsTest
private class BSPCreditClaimController_Test {
    @TestSetup
    static void testBehavior() {
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
        insert contact;
        List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
        TestDataFactory.UserDTO bspUser = new TestDataFactory.UserDTO();
        bspUser.profileName = 'Merchant Portal Community User';
        bspUser.permissionSetNames = new Set<String>{'BSP_Community_Access'};
        bspUser.userName = 'BSPUserForCreditClaim';
        bspUser.role = '';
        bspUser.contactId = contact.Id;
        userDTOs.add(bspUser);

        TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
        System.enqueueJob(queueable);
    }

    /**
     * Testing of dispute case creation as a community user
     */
    @IsTest
    static void createCreditClaimTest() {
        // =====================================
        // Data Preparation
        // =====================================
        User bspUser = [SELECT Id FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
        BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
        errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
        errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';
        Case cse = ApplicationTestDataFactory.getCases(1, false)[0];
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        cse.ContactId = contact.Id;
        cse.AccountId = accountForBillingAccount.Id;
        Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'Enterprise_Credit_Dispute_Claim'}).values()[0].Id;
        cse.RecordTypeId = creditDisputeCaseRecordTypeId;
        cse.Billing_Number__c = '123456';


        List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
        billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountForBillingAccount.Id, 'SAP ERP', true)[0]);
        billingAccountRecords[0].Organisation__c = accountForBillingAccount.Id;
        billingAccountRecords[0].Legacy_ID__c = '123456';


        List<Disputed_Item__c> disputedItems = ApplicationTestDataFactory.getDisputedItems(3, cse.Id, true);
        Map<Id,Disputed_Item__c> disputedItemsByIds = new Map<Id,Disputed_Item__c>();
        for(Disputed_Item__c disputedItem: disputedItems) {
            disputedItemsByIds.put(disputedItem.Id, disputedItem);
        }
        // =====================================
        // Stubbing
        // =====================================
        AssignmentRulesSelector mockAssignmentRulesSelector = (AssignmentRulesSelector)MockUtility.mockSelector(AssignmentRulesSelector.class);
        DisputedItemsSelector mockDisputedItemsSelector = (DisputedItemsSelector)MockUtility.mockSelector(DisputedItemsSelector.class);
        AssignmentRule ar = ApplicationTestDataFactory.getAssignmentRules(1, 'Case', true)[0];
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
        BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockAssignmentRulesSelector.selectActiveRulesBySObjectType('Case')).thenReturn(new Map<Id, AssignmentRule>{ar.Id => ar});
        MockUtility.Mocks.when(mockDisputedItemsSelector.selectByCaseId(new Set<Id>{cse.Id})).thenReturn(disputedItemsByIds);
        MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
                .thenReturn(new Map<String, BSPErrorMessages__c>{
                        'Invalid Billing Account Credit Claim' => errorMessagesSettings
                });
        MockUtility.Mocks.when(mockBillingAccountsSelector.selectByOrgId(
                (Set<Id>)fflib_Match.eq(new Set<Id>{accountForBillingAccount.Id}))).thenReturn(
                new Map<Id,Billing_Account__c>(billingAccountRecords));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        BSPCreditClaimController.CreditClaimResponseWrapper wrapper;
        System.runAs(bspUser) {
            wrapper = BSPCreditClaimController.createCreditClaim(cse, null, disputedItems);
        }
        Test.stopTest();

        System.assertNotEquals('ok', wrapper.Status, 'Expected Status of the case to be populated as ok.');
        system.debug('HASANTHA MSG '+wrapper.message);
    }

}