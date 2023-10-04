/**
 * Created by hasan on 3/10/2023.
 */

@IsTest
private class BAMContactApplicationsSelector_Test {
    @IsTest
    static void testBehavior() {
    }

    /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

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

        CasesSelector selector = CasesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom BAMContactApplication__c\\b').matcher(soql).find(), 'Resulting query does not select from BAMContactApplication__c');

        Test.stopTest();

    }

    
}