/**
 * @description Test Class covering PostcodeMappingsSelector
 * @author Mahesh Parvathaneni
 * @date 2023-05-11
 * @changelog
 */

@IsTest
private class PostcodeMappingsSelector_Test {

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

		PostcodeMappingsSelector selector = PostcodeMappingsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom PostcodeMapping__c\\b').matcher(soql).find(), 'Resulting query does not select from PostcodeMapping__c: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{PostcodeMappingsSelector.Options.WITH_NETWORK});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Network__r.*?\\bfrom PostcodeMapping__c\\b').matcher(soql).find(), 'Resulting query does not select from Network');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

		PostcodeMappingsSelector selector = PostcodeMappingsSelector.newInstance(0, new Set<SObjectField>{PostcodeMapping__c.Network__c});

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PostcodeMapping__c.Network__c) + '\\b').matcher(soql).find(), 'Resulting query does not select Network__c fields: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(PostcodeMapping__c.Postcode__c) + '\\b').matcher(soql).find(), 'Resulting query selects Postcode__c but should not: ' + soql);

		selector = PostcodeMappingsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
			PostcodeMapping__c.SObjectType => new Set<SObjectField>{PostcodeMapping__c.Postcode__c}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PostcodeMapping__c.Postcode__c) + '\\b').matcher(soql).find(), 'Resulting query does not select Postcode__c fields: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(PostcodeMapping__c.Network__c) + '\\b').matcher(soql).find(), 'Resulting query selects Network__c but should not: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';
		networks[0].Contact_Facility__c = 'MyNetwork';
		insert networks;

		List<Postcode__c> postcodes = ApplicationTestDataFactory.getPostcodes(1, false);
		postcodes[0].Locality_Postcode_ID__c = '1234';
		insert postcodes;

		List<PostcodeMapping__c> postcodeMappings = ApplicationTestDataFactory.getPostcodeMappings(1, postcodes[0].Id, networks[0].Id, false);
		insert postcodeMappings;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PostcodeMappingsSelector selector = PostcodeMappingsSelector.newInstance();
		List<PostcodeMapping__c> results = selector.selectById(new Set<Id>{postcodeMappings[0].Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = PostcodeMappingsSelector.newInstance();
		List<PostcodeMapping__c> resultsList = selector.selectById(new Set<Id>{postcodeMappings[0].Id}, new Set<Object>{PostcodeMappingsSelector.Options.WITH_NETWORK});
		System.assertEquals(1, resultsList.size(), 'Expected result size of 1');
		System.assertNotEquals(null, resultsList[0].Network__r, 'Expected network object');

		Test.stopTest();
	}
}