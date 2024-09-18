/* @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Accounts
 * @domain Core
 * @description Test Class covering OpportunitySelector
 * @changelog
 * 2020-08-14 - Shashwat.Nath@austpost.com.au - Created
 * 2023-03-29 - Harry Wang - Added testing for WITH_CHILD_PROPOSALS option
 * 2023-07-17 - nasir jawed - Added testing for WITH_OWNER option
 */

 @IsTest
public with sharing class OpportunitySelector_Test {
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

	OpportunitySelector selector = OpportunitySelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select from opportunity');

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

	Set<Id> oppIds = new Set<Id>{opportunityRecord.Id};

	// =====================================
	// Stubbing
	// =====================================
	// None!

	// =====================================
	// Testing
	// =====================================
	Test.startTest();

	OpportunitySelector selector = OpportunitySelector.newInstance(1);
	Map<Id, opportunity> results = selector.selectById(oppIds);
	System.assertEquals(1, results.size(), 'Expected result size of 1');

	Set<SObjectField> opportunityField = new Set<SObjectField>{};
	OpportunitySelector selector2 = OpportunitySelector.newInstance(1,opportunityField);
	Map<Id, opportunity> results2 = selector2.selectById(oppIds, new Set<Object>{OpportunitySelector.Options.WITH_CHILD_PROPOSALS
	});
	System.assertEquals(1, results2.size(), 'Expected result size of 1');
	Map<Id, opportunity> results3 = selector2.selectById(oppIds, new Set<Object>{OpportunitySelector.Options.WITH_OWNER});
	System.assertEquals(1, results3.size(), 'Expected result size of 1');
	Test.stopTest();

	}
 }