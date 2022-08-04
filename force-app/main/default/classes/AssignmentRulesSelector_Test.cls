/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering AssignmentRuleSelector
 */

@isTest
public with sharing class AssignmentRulesSelector_Test {
    /**
     * Test:
     * Ensures that the selectors QueryBuilder is generating the correct output
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

        AssignmentRulesSelector selector = AssignmentRulesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom AssignmentRule\\b').matcher(soql).find(), 'Resulting query does not select from AssignmentRule');

        Test.stopTest();

    }

    /**
     * Test:
     * Executes a query to ensure it returns expected results
     */
    @IsTest
    private static void testSelectorIntegration() {

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

        AssignmentRulesSelector selector = AssignmentRulesSelector.newInstance();
		Map<Id, AssignmentRule> results = selector.selectActiveRulesBySObjectType('Case');
		System.assert(results.size() >= 1, 'Expected result size of more than 1');

        AssignmentRulesSelector selectorLimit = AssignmentRulesSelector.newInstance(1);
		Map<Id, AssignmentRule> resultsLimit = selectorLimit.selectActiveRulesBySObjectType('Case');
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

        Test.stopTest();

    }
}
