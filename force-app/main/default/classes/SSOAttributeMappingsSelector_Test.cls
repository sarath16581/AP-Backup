/**
 * @description Test class for SSOAttributeMappingsSelector
 * @author Nathan Franklin
 * @date 2022-05-10
 * @changelog
*/
@IsTest
public with sharing class SSOAttributeMappingsSelector_Test {

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

		SSOAttributeMappingsSelector selector = SSOAttributeMappingsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom SSOAttributeMapping__mdt\\b').matcher(soql).find(), 'Resulting query does not select from SSOAttributeMapping__mdt');

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
		SSOAttributeMapping__mdt mapping = [SELECT DeveloperName, NetworkId__c FROM SSOAttributeMapping__mdt WHERE NetworkId__c != null LIMIT 1];
		String networkId = mapping.NetworkId__c;
		String name = mapping.DeveloperName;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SSOAttributeMappingsSelector selector = SSOAttributeMappingsSelector.newInstance(1);
		List<SSOAttributeMapping__mdt> results = selector.selectByNetworkIds(new Set<String>{networkId});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectByName(new Set<String>{name});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		Test.stopTest();

	}
}