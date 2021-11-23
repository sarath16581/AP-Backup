/**
* @author Disha Kariya
* @date 2020-05-13
* @group Tests
* @tag Selector
* @tag Active Band History SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-05-12 - Disha Kariya - Created
*/
@IsTest
private with sharing class ActiveBandHistoriesSelector_Test {
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        ActiveBandHistoriesSelector selector = ActiveBandHistoriesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom active_band_history__c\\b').matcher(soql).find(), 'Resulting query does not select from Active Band History');

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        ActiveBandHistoriesSelector selector = ActiveBandHistoriesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ActiveBandHistoriesSelector.Options.WITH_ACCOUNT});
        String soql = qb.toSoqlString();
        System.debug('soql--->'+soql);
        System.assertEquals(true, Pattern.compile('(?is)organisation__r\\..*?\\bfrom active_band_history__c\\b').matcher(soql).find(), 'Resulting query does not select Organisation fields');

        Test.stopTest();

    }

    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    private static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert acc;

        List<Product2> prod = ApplicationTestDataFactory.getPSRProducts(1, false);
        insert prod;
        List<Active_Band_History__c> listABH = ApplicationTestDataFactory.getActiveBandHistories(2, acc.Id, prod[0].Id, 'Transactional', false);
        insert listABH;

        Map<Id, Active_Band_History__c> mappedActiveBandHistories = new Map<Id, Active_Band_History__c>(listABH);
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        ActiveBandHistoriesSelector selector = ActiveBandHistoriesSelector.newInstance(2);
        Map<Id, Active_Band_History__c> results = selector.selectById(mappedActiveBandHistories.keySet());
        System.assertEquals(2, results.size(), 'Expected result size of 2');

        results = selector.selectActiveBandHistoriesByAccountIds(new Set<Id> {acc.Id});
        System.assertEquals(2, results.size(), 'Expected result size of 2');


        results = selector.selectById(mappedActiveBandHistories.keySet(), new Set<Object>{ActiveBandHistoriesSelector.Options.WITH_ACCOUNT});
        System.assertEquals(2, results.size(), 'Expected result size of 2');

        Test.stopTest();

    }
}