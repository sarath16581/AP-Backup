/* @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Accounts
 * @domain Core
 * @description Test Class covering OpportunitiesSelector
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 * 2023-05-17 - Ranjeewa Silva - Updated tests to cover new selector option 'WITH_OVERLAY_SPLITS'
 */
 
@IsTest
public with sharing class OpportunitiesSelector_Test {
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

	OpportunitiesSelector selector = OpportunitiesSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select from opportunity');

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

	OpportunitiesSelector selector = OpportunitiesSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{OpportunitiesSelector.Options.WITH_RECORDTYPE});
	String soql = qb.toSoqlString();
	System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

	qb = selector.newQueryBuilder(new Set<Object>{OpportunitiesSelector.Options.WITH_OWNER});
	soql = qb.toSoqlString();
	System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

	qb = selector.newQueryBuilder(new Set<Object>{OpportunitiesSelector.Options.WITH_RECORDTYPE, OpportunitiesSelector.Options.WITH_OWNER, OpportunitiesSelector.Options.WITH_OVERLAY_SPLITS});
	soql = qb.toSoqlString();
	System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
	System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');
	System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom opportunitysplits\\b.*?\\).*?\\bfrom opportunity\\b').matcher(soql).find(),
			'Resulting query does not select OpportunitySplit child records: ' + soql);

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

	OpportunitiesSelector selector = OpportunitiesSelector.newInstance(1);
	Map<Id, opportunity> results = selector.selectById(oppIds);
	System.assertEquals(1, results.size(), 'Expected result size of 1');

	results = selector.selectById(oppIds, new Set<Object>{OpportunitiesSelector.Options.WITH_RECORDTYPE, OpportunitiesSelector.Options.WITH_OWNER});
	System.assertEquals(1, results.size(), 'Expected result size of 1');
	System.assertNotEquals(null, results.values()[0].RecordType, 'Results did not include RecordType object');
	
	Test.stopTest();

	}
}