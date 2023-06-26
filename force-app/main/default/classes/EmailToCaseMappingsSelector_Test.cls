/**
 * @description Test class for EmailToCaseMappingsSelector
 * @author Mahesh Parvathaneni
 * @date 2023-05-30
 * @changelog
*/

@IsTest
private class EmailToCaseMappingsSelector_Test {
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

		EmailToCaseMappingsSelector selector = EmailToCaseMappingsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		Assert.areEqual(true, Pattern.compile('(?ism)\\bfrom EmailToCaseMapping__mdt\\b').matcher(soql).find(), 'Resulting query does not select from EmailToCaseMapping__mdt');

		qb = selector.newQueryBuilder(new Set<Object>{EmailToCaseMappingsSelector.Options.FILTER_ACTIVE});
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)\\bfrom EmailToCaseMapping__mdt\\b.*IsActive__c\\s*=\\s+true').matcher(soql).find(), 'Resulting query does not limit active records');

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual data
	 */
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		EmailToCaseMapping__mdt mapping = [SELECT DeveloperName, EmailToCaseAddress__c FROM EmailToCaseMapping__mdt WHERE EmailToCaseAddress__c != null LIMIT 1];
		String emailToCaseAddress = mapping.EmailToCaseAddress__c;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EmailToCaseMappingsSelector selector = EmailToCaseMappingsSelector.newInstance(1);
		List<EmailToCaseMapping__mdt> results = selector.selectAll();
		Assert.areEqual(1, results.size(), 'Result count was wrong');

		results = selector.selectByEmailToCaseAddress(new Set<String>{emailToCaseAddress});
		Assert.areEqual(1, results.size(), 'Result count was wrong');

		Test.stopTest();

	}

}