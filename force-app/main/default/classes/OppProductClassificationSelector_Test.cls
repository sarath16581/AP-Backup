/**
* @author Seth Heang
* @date 2020-11-06
* @group Tests
* @tag Selector
* @tag Asset SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-11-06 - Seth Heang - Created
*/
@IsTest
private with sharing class OppProductClassificationSelector_Test {
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

        OpportunityProductClassificationSelector selector = OpportunityProductClassificationSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Opp_Product_Classification__c\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

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

        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;
        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert oppRec;
        
        Opp_Product_Classification__c opc1 = ApplicationTestDataFactory.getOpportunityProductClassification(1, account.id, oppRec.id, false, '2020', false)[0];
        insert opc1;

        Set<Id> oppIds = new Set<Id>{oppRec.Id};
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        OpportunityProductClassificationSelector selector = OpportunityProductClassificationSelector.newInstance(1);
        Map<Id, Opp_Product_Classification__c> results = selector.selectByOpportunity(oppIds);
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }

}