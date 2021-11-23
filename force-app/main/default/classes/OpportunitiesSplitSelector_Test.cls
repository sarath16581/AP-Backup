/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag OpportunitySplits
 * @domain Core
 * @description Test Class covering OpportunitiesSplitSelector
 * @changelog
 * 2020-10-06 - arjun.singh@austpost.com.au - Created
 */
 @IsTest
public with sharing class OpportunitiesSplitSelector_Test {
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

	OpportunitiesSplitSelector selector = OpportunitiesSplitSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom opportunitySplit\\b').matcher(soql).find(), 'Resulting query does not select from opportunitySplit');

	Test.stopTest();
    }
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

	OpportunitiesSplitSelector selector = OpportunitiesSplitSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{OpportunitiesSplitSelector.Options.WITH_OWNER});
	String soql = qb.toSoqlString();
	System.assertEquals(true, Pattern.compile('(?ism)SplitOwner\\..*?\\bfrom opportunitySplit\\b').matcher(soql).find(), 'Resulting query does not select SplitOwner fields');

	qb = selector.newQueryBuilder(new Set<Object>{OpportunitiesSplitSelector.Options.WITH_OWNER});
	soql = qb.toSoqlString();
    System.assertEquals(true, Pattern.compile('(?ism)SplitOwner\\..*?\\bfrom opportunitySplit\\b').matcher(soql).find(), 'Resulting query does not select SplitOwner fields');

	Test.stopTest();

    }  
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
        // =====================================
	// Data Preparation
	// =====================================
	MockUtility.disableTriggerExecution();

        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;

        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert opportunityRecord;  

        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;

        OpportunitySplit opportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord.Id, ApplicationTestDataFactory.directContributionOverlayType,'Direct Contribution' , false)[0];
        insert opportunitySplitRecord;  

        Set<Id> splitIds = new Set<Id>{opportunitySplitRecord.Id};

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
            OpportunitiesSplitSelector selector = OpportunitiesSplitSelector.newInstance(1);
            Map<Id, OpportunitySplit> results = selector.selectById(splitIds);            
	        System.assertEquals(1, results.size(), 'Expected result size of 1');
            results = selector.selectById(splitIds, new Set<Object>{OpportunitiesSplitSelector.Options.WITH_OWNER});
	        System.assertEquals(1, results.size(), 'Expected result size of 1');
        Test.stopTest();
    }
}