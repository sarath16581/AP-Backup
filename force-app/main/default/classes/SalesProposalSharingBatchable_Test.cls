/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesProposalSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesProposalSharingBatchable_Test {
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
        APT_ProposalObjectsSelector mockSelector = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
        Database.QueryLocator mockQueryLocator = Database.getQueryLocator('Select Id from Apttus_Proposal__Proposal__c');

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountOrderByAccountIdQueryLocator((Set<Id>) fflib_Match.anyObject(), (Set<Object>)fflib_Match.eq(new Set<Object>{APT_ProposalObjectsSelector.Options.WITH_ORGANISATION}))).thenReturn(mockQueryLocator);
        MockUtility.Mocks.stopStubbing();


        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        new SalesProposalSharingBatchable(new Map<Id, Account>(parentAccounts).keySet()).getQueryLocator(new Map<SObjectType, Set<SObjectField>>());

        Test.stopTest();

        fflib_ArgumentCaptor accountIdsCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
        ((APT_ProposalObjectsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByAccountOrderByAccountIdQueryLocator((Set<Id>)accountIdsCapture.capture(), (Set<Object>)fflib_Match.anyObject());

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
        APT_ProposalObjectsSelector mockSelector = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
        Database.QueryLocator mockQueryLocator = Database.getQueryLocator('Select Id from Apttus_Proposal__Proposal__c');

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountOrderByAccountIdQueryLocator((Set<Id>) fflib_Match.anyObject(), (Set<Object>)fflib_Match.eq(new Set<Object>{APT_ProposalObjectsSelector.Options.WITH_ORGANISATION}))).thenReturn(mockQueryLocator);
        MockUtility.Mocks.stopStubbing();


        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        new SalesProposalSharingBatchable().getQueryLocator(new Map<SObjectType, Set<SObjectField>>());

        Test.stopTest();

        fflib_ArgumentCaptor accountIdsCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
        ((APT_ProposalObjectsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByAccountOrderByAccountIdQueryLocator((Set<Id>)accountIdsCapture.capture(), (Set<Object>)fflib_Match.anyObject());

        Set<Id> parentAccountIdsCaptured = (Set<Id>) accountIdsCapture.getValue();
        System.assertEquals(0, parentAccountIdsCaptured.size(), 'Expected to pass an empty account Ids set in to the selector when account ids are not specified on batch.');
    }
}