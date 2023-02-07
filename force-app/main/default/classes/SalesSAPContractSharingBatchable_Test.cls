/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesSAPContractSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesSAPContractSharingBatchable_Test {
    /**
    * Test to ensure query locator returned is filtering based on the account ids supplied
    */
    @IsTest
    static void testGetQueryLocatorWithSpecificAccountIdFiltering() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);

        // =====================================
        // Stubbing
        // =====================================
        SAPContractsSelector mockSelector = (SAPContractsSelector) MockUtility.mockSelector(SAPContractsSelector.class);
        Database.QueryLocator mockQueryLocator = Database.getQueryLocator('Select Id from APT_SAP_Contracts__c');

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountOrderByAccountIdQueryLocator((Set<Id>) fflib_Match.anyObject(), (Set<Object>)fflib_Match.eq(new Set<Object>{SAPContractsSelector.Options.WITH_ORGANISATION}))).thenReturn(mockQueryLocator);
        MockUtility.Mocks.stopStubbing();


        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        new SalesSAPContractSharingBatchable(new Map<Id, Account>(parentAccounts).keySet()).getQueryLocator(new Map<SObjectType, Set<SObjectField>>());

        Test.stopTest();

        fflib_ArgumentCaptor accountIdsCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
        ((SAPContractsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByAccountOrderByAccountIdQueryLocator((Set<Id>)accountIdsCapture.capture(), (Set<Object>)fflib_Match.anyObject());

        Set<Id> parentAccountIdsCaptured = (Set<Id>) accountIdsCapture.getValue();
        System.assertEquals(parentAccounts.size(), parentAccountIdsCaptured.size(), 'All parent account Ids passed in to the constructor must be queried.');
        for (Account a: parentAccounts) {
            System.assert(parentAccountIdsCaptured.contains(a.Id), 'All parent account Ids passed in to the constructor must be queried');
        }
    }

    /**
	 * Test to ensure query locator returned is not filtering by account ids.
	 */
    @IsTest
    static void testGetQueryLocatorWithNoAccountIdFiltering() {
        // =====================================
        // Data Preparation
        // =====================================
        // None

        // =====================================
        // Stubbing
        // =====================================
        SAPContractsSelector mockSelector = (SAPContractsSelector) MockUtility.mockSelector(SAPContractsSelector.class);
        Database.QueryLocator mockQueryLocator = Database.getQueryLocator('Select Id from APT_SAP_Contracts__c');

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountOrderByAccountIdQueryLocator((Set<Id>) fflib_Match.anyObject(), (Set<Object>)fflib_Match.eq(new Set<Object>{SAPContractsSelector.Options.WITH_ORGANISATION}))).thenReturn(mockQueryLocator);
        MockUtility.Mocks.stopStubbing();


        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        new SalesSAPContractSharingBatchable().getQueryLocator(new Map<SObjectType, Set<SObjectField>>());

        Test.stopTest();

        fflib_ArgumentCaptor accountIdsCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
        ((SAPContractsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByAccountOrderByAccountIdQueryLocator((Set<Id>)accountIdsCapture.capture(), (Set<Object>)fflib_Match.anyObject());

        Set<Id> parentAccountIdsCaptured = (Set<Id>) accountIdsCapture.getValue();
        System.assertEquals(0, parentAccountIdsCaptured.size(), 'Expected to pass an empty account Ids set in to the selector when account ids are not specified on batch.');
    }
}