/**
 * @description Test Class covering PostcodesSelector
 * @author Mahesh Parvathaneni
 * @date 2023-05-11
 * @changelog
 */
@IsTest
private class PostcodesSelector_Test {
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

		PostcodesSelector selector = PostcodesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Postcode__c\\b').matcher(soql).find(), 'Resulting query does not select from Postcode__c: ' + soql);

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
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PostcodesSelector selector = PostcodesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PostcodesSelector.Options.WITH_POSTCODE_MAPPING});
		String soql = qb.toSoqlString();
		System.assertEquals(true, 
		Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Postcode_Mappings__r\\b.*?\\).*?\\bfrom Postcode__c\\b').matcher(soql).find(),
			'Resulting query does not select PostcodeMappings records: ' + soql);

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

		PostcodesSelector selector = PostcodesSelector.newInstance(0, new Set<SObjectField>{Postcode__c.Name});

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Postcode__c.Name) + '\\b').matcher(soql).find(), 'Resulting query does not select Name fields: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(Postcode__c.Suburb__c) + '\\b').matcher(soql).find(), 'Resulting query selects Suburb__c but should not: ' + soql);

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
		List<Postcode__c> postcodes = ApplicationTestDataFactory.getPostcodes(1, false);
		postcodes[0].Name = '3000';
		postcodes[0].Suburb__c = 'Melbourne';
		postcodes[0].Locality_Postcode_ID__c = '1234';
		insert postcodes;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PostcodesSelector selector = PostcodesSelector.newInstance();
		List<Postcode__c> results = selector.selectById(new Set<Id>{postcodes[0].Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Map<String, Object> params = new Map<String, Object>{
			'postcodes' => new Set<String>{postcodes[0].Name},
			'suburbs' => new Set<String>{postcodes[0].Suburb__c},
			'localityIds' => new Set<String>{postcodes[0].Locality_Postcode_ID__c}
		};
		selector = PostcodesSelector.newInstance();
		results = selector.search(params, true);
		System.assertNotEquals(0, results.size(), 'Expected post code record to be returned');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {

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

		Map<String, Object> searchParams;

		PostcodesSelector selector = PostcodesSelector.newInstance(1);

		searchParams = new Map<String, Object>{
			'postcodes' => '3000',
			'suburbs' => 'Melbourne',
			'localityIds' => '1234'
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bName\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Name: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bSuburb__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Suburb__c: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bLocality_Postcode_ID__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Locality_Postcode_ID__c: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'postcodes' => new Set<String>{'3000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bName\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Name: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bSuburb__c\\s+In\\b').matcher(soql).find(), 'Resulting query limits Suburb__c... it should not:' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bLocality_Postcode_ID__c\\s+In\\b').matcher(soql).find(), 'Resulting query does limits Locality_Postcode_ID__c... it should not: ' + soql);

		searchParams = new Map<String, Object>{
			'postcodes' => '3000',
			'suburbs' => 'Melbourne',
			'localityIds' => '1234'
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Postcode__c\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY: ' + soql);

		Test.stopTest();

	}
}