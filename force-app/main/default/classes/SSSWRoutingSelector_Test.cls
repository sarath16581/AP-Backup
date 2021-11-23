/**
* @author Seth Heang
* @date 2020-11-06
* @group Tests
* @tag Selector
* @tag SSSWRouting__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-12-18 - Seth Heang - Created
*/
@IsTest
private with sharing class SSSWRoutingSelector_Test {
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

        SSSWRoutingSelector selector = SSSWRoutingSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom SSSWRouting__c\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

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
        MockUtility.disableTriggerExecution();

        Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SSSWRouting__c', new Set<String>{'Credit_DSR_Routing'}).values()[0].Id;
        SSSWRouting__c ssswCreditDSR = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, 'M12', 'seth@test.com', 'Legal Recovery Team', 'Credit Person Code', false)[0];
        insert ssswCreditDSR;
        
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        SSSWRoutingSelector selector = SSSWRoutingSelector.newInstance(1);
        Map<Id, SSSWRouting__c> results = selector.selectByRecordTypeId(new Set<id>{recTypeId});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }

}