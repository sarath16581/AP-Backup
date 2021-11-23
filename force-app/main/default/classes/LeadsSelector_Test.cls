/**
* @author Seth Heang
* @date 2021-08-11
* @group Tests
* @tag Selector
* @tag Lead SObject
* @domain Core
* @description Test class for LeadsSelector class
* @changelog
* 2021-08-11 - Seth Heang - Created
*/
@IsTest
private with sharing class LeadsSelector_Test {
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

        LeadsSelector selector = LeadsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Lead\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

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

       	Lead leadrec = ApplicationTestDataFactory.getLeads(1, false)[0];
        insert leadrec;
        
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        LeadsSelector selector = LeadsSelector.newInstance(1);
        Map<Id, Lead> results = selector.selectById(new Set<id>{leadrec.Id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }

}