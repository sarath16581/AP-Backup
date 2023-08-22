/**
 * @author Hasantha Liyanage
 * @date 2023-08-17
 * @group Test
 * @domain BSP
 * @description Controller apex test class the BSP Credit Claim component
 * @changelog
 * 2023-08-17 - Hasantha Liyanage - Created
 */

@IsTest
private class BSPCreditClaimController_Test {
    @TestSetup
    static void testBehavior() {
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
        contact.FirstName = 'bspuser';
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
     * This test is to check a successful creation of a case with a valid billing account number and disputed items
     */
    @IsTest
    static void createCreditClaimSuccessTest() {
        // =====================================
        // Data Preparation
        // =====================================
        // get a bsp context user
        User bspUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
        // creating a custom setting for error message
        BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
        errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
        errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';
        // creating a case, Id is created as we need to use this for reference in after save
        Case cse = ApplicationTestDataFactory.getCases(1, true)[0];
        // billing account for the user
        Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        accountForBillingAccount.Id = bspUser.Contact.AccountId;
        // contact to check billing account for user
        Contact contact = ApplicationTestDataFactory.getContacts(1, accountForBillingAccount.Id, false)[0];
        contact.Id = bspUser.ContactId;
        cse.ContactId = contact.Id;
        cse.AccountId = accountForBillingAccount.Id;
        Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{
                'Enterprise_Credit_Dispute_Claim'
        }).values()[0].Id;
        cse.RecordTypeId = creditDisputeCaseRecordTypeId;
        cse.Billing_Number__c = '123456';
        // related billing accounts
        List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
        billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountForBillingAccount.Id, 'SAP ERP', true)[0]);
        billingAccountRecords[0].Organisation__c = accountForBillingAccount.Id;
        billingAccountRecords[0].Legacy_ID__c = '123456';
        // disputed items to be created with the case
        List<Disputed_Item__c> disputedItems = ApplicationTestDataFactory.getDisputedItems(3, cse.Id, true);
        Map<Id, Disputed_Item__c> disputedItemsByIds = new Map<Id, Disputed_Item__c>();
        for (Disputed_Item__c disputedItem : disputedItems) {
            disputedItemsByIds.put(disputedItem.Id, disputedItem);
        }

        // =====================================
        // Stubbing
        // =====================================
        AssignmentRulesSelector mockAssignmentRulesSelector = (AssignmentRulesSelector) MockUtility.mockSelector(AssignmentRulesSelector.class);
        AssignmentRule ar = ApplicationTestDataFactory.getAssignmentRules(1, 'Case', true)[0];
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
        BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockAssignmentRulesSelector.selectActiveRulesBySObjectType('Case')).thenReturn(new Map<Id, AssignmentRule>{
                ar.Id => ar
        });
        MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
                .thenReturn(new Map<String, BSPErrorMessages__c>{
                        'Invalid Billing Account Credit Claim' => errorMessagesSettings
                });
        MockUtility.Mocks.when(mockBillingAccountsSelector.selectByOrgId(
                new Set<Id>{
                        accountForBillingAccount.Id
                })).thenReturn(
                new Map<Id, Billing_Account__c>{
                        billingAccountRecords[0].Id => billingAccountRecords[0]
                }
        );
        String stJson = '{"success":true,"id":' +'"'+ cse.Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cse.Id => cse});
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

        // make sure the dml is performed
        List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 2);

        for (List<SObject> obj : insertedRecords) {
            if (Case.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertNotEquals(
                        null,
                        obj[0].get('Id'),
                        'createCreditClaimSuccessTest : Case Id should be populated as it is created'
                );

                System.assertEquals(
                        billingAccountRecords[0].Id,
                        obj[0].get('Related_Billing_Account__c'),
                        'createCreditClaimSuccessTest : Related billing account Id should be populated'
                );
            }

            if (Disputed_Item__c.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        cse.Id,
                        obj[0].get('Case__c'),
                        'createCreditClaimSuccessTest : Disputed Items should be created against the case record'
                );
            }
        }
    }

    @IsTest
    static void createCreditClaimFailedTest() {
        // =====================================
        // Data Preparation
        // =====================================
        // get a bsp context user
        User bspUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
        // creating a custom setting for error message
        BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
        errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
        errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';
        // creating a case, Id is created as we need to use this for reference in after save
        Case cse = ApplicationTestDataFactory.getCases(1, true)[0];
        // billing account for the user
        Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        accountForBillingAccount.Id = bspUser.Contact.AccountId;
        // contact to check billing account for user
        Contact contact = ApplicationTestDataFactory.getContacts(1, accountForBillingAccount.Id, false)[0];
        contact.Id = bspUser.ContactId;
        cse.ContactId = contact.Id;
        cse.AccountId = accountForBillingAccount.Id;
        Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{
                'Enterprise_Credit_Dispute_Claim'
        }).values()[0].Id;
        cse.RecordTypeId = creditDisputeCaseRecordTypeId;
        cse.Billing_Number__c = '12345612323'; // invalid billing account
        // related billing accounts
        List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
        billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountForBillingAccount.Id, 'SAP ERP', true)[0]);
        billingAccountRecords[0].Organisation__c = accountForBillingAccount.Id;
        billingAccountRecords[0].Legacy_ID__c = '123456';


        // =====================================
        // Stubbing
        // =====================================
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
        BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
                .thenReturn(new Map<String, BSPErrorMessages__c>{
                        'Invalid Billing Account Credit Claim' => errorMessagesSettings
                });
        MockUtility.Mocks.when(mockBillingAccountsSelector.selectByOrgId(
                new Set<Id>{
                        accountForBillingAccount.Id
                })).thenReturn(
                new Map<Id, Billing_Account__c>{
                        billingAccountRecords[0].Id => billingAccountRecords[0]
                }
        );


        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        BSPCreditClaimController.CreditClaimResponseWrapper wrapper;
        System.runAs(bspUser) {
            wrapper = BSPCreditClaimController.createCreditClaim(cse, null, null);
        }
        Test.stopTest();
        System.assertEquals('error', wrapper.Status, 'Expected Status of the case to be populated as error.');
    }
}