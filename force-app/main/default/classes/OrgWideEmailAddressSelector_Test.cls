/**
* @author Seth Heang
* @date 2020-12-08
* @group Tests
* @tag Selector
* @tag OrgWideEmailAddress SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-12-18 - Seth Heang - Created
*/
@IsTest
private with sharing class OrgWideEmailAddressSelector_Test {
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

        OrgWideEmailAddressSelector selector = OrgWideEmailAddressSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom OrgWideEmailAddress\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

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

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        OrgWideEmailAddressSelector selector = OrgWideEmailAddressSelector.newInstance(1);
        
        // OrgWideEmailAddress cannot be inserted for testing, as it will throw error: 'DML operation Insert not allowed on OrgWideEmailAddress'
        // However, it can be accessed within the unit test without setting (SeeAllData=true) tag
        Map<Id, OrgWideEmailAddress> results = selector.selectByAddress('noreply@auspost.com.au');
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }

}