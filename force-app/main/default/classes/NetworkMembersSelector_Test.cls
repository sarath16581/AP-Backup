/**
 * @description Test Class covering NetworkMembersSelector
 * @author Mahesh Parvathaneni
 * @date 2023-08-04
 * @changelog
 */

@IsTest
private class NetworkMembersSelector_Test {
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

		NetworkMembersSelector selector = NetworkMembersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom NetworkMember\\b').matcher(soql).find(), 'Resulting query does not select from NetworkMember: ' + soql);

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

		NetworkMembersSelector selector = NetworkMembersSelector.newInstance(0);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)MemberId.*?\\bfrom NetworkMember\\b').matcher(soql).find(), 'Resulting query does not select MemberId: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)NetworkId.*?\\bfrom NetworkMember\\b').matcher(soql).find(), 'Resulting query does not select MemberId: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure that the query actually runs. There will be no data returned, however this ensure that the query does not error
	 */
	@IsTest
	private static void testSelectorSearchAllIntegrationValidationOfQueryOnly() {

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

		NetworkMembersSelector selector = NetworkMembersSelector.newInstance();
		List<NetworkMember> results = selector.selectById(new Set<Id>{'0DO000000000000000'});
		System.assertEquals(0, results.size());

		selector = NetworkMembersSelector.newInstance();
		results = selector.search(new Map<String, Object>{'memberIds' => new Set<Id>{'005000000000000000'}}, true);
		System.assertEquals(0, results.size());

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

		NetworkMembersSelector selector = NetworkMembersSelector.newInstance(1);

		searchParams = new Map<String, Object>{
			'memberIds' => new Set<Id>{'005000000000000'},
			'networkIds' => new Set<Id>{'0DB000000000000'}
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bNetworkId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit NetworkId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bMemberId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit MemberId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'memberIds' => new Set<Id>{'005000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bMemberId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit MemberId');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bNetworkId\\s+In\\b').matcher(soql).find(), 'Resulting query limits NetworkId... it should not');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'networkIds' => new Set<Id>{'0DB000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bMemberId\\s+In\\b').matcher(soql).find(), 'Resulting query limits MemberId... it should not');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bNetworkId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit NetworkId');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'memberIds' => new Set<Id>{'005000000000000'},
			'networkIds' => new Set<Id>{'0DB000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from NetworkMember\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, false);

		Test.stopTest();

	}
}