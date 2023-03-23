/**
 * @description Test Class covering ThirdPartyAccountLinksSelector
 * @author Nathan Franklin
 * @date 2023-03-21
 * @changelog
 */
@IsTest
private class ThirdPartyAccountLinksSelector_Test {

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

		ThirdPartyAccountLinksSelector selector = ThirdPartyAccountLinksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query does not select from ThirdPartyAccountLink: ' + soql);

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

		ThirdPartyAccountLinksSelector selector = ThirdPartyAccountLinksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ThirdPartyAccountLinksSelector.Options.WITH_USER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)User\\..*?\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query does not select User fields: ' + soql);

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

		ThirdPartyAccountLinksSelector selector = ThirdPartyAccountLinksSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				ThirdPartyAccountLink.SObjectType => new Set<SObjectField>{ThirdPartyAccountLink.SsoProviderId},
				User.SObjectType => new Set<SObjectField>{User.Username}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ThirdPartyAccountLinksSelector.Options.WITH_USER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)User\\..*?\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query does not select User fields: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)User\\.Username.*?\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query does not select User.Username: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)User\\.Email.*?\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query selects User.Email but should not: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)SsoProviderId.*?\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query does not select SsoProviderId: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)SsoProviderName.*?\\bfrom ThirdPartyAccountLink\\b').matcher(soql).find(), 'Resulting query selects SsoProviderName but should not: ' + soql);

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

		ThirdPartyAccountLinksSelector selector = ThirdPartyAccountLinksSelector.newInstance();
		List<ThirdPartyAccountLink> results = selector.selectById(new Set<Id>{'0Jr000000000000001'});
		System.assertEquals(0, results.size());

		selector = ThirdPartyAccountLinksSelector.newInstance();
		results = selector.selectByUser(new Set<Id>{'005000000000000000'});
		System.assertEquals(0, results.size());

		selector = ThirdPartyAccountLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'userIds' => new Set<Id>{'005000000000000000'}}, true);
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

		ThirdPartyAccountLinksSelector selector = ThirdPartyAccountLinksSelector.newInstance(1);

		searchParams = new Map<String, Object>{
			'userIds' => new Set<Id>{'005000000000000'},
			'providerIds' => new Set<Id>{'0SO000000000000000'}
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bUserId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit UserId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bSsoProviderId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit SsoProviderId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'userIds' => new Set<Id>{'005000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bUserId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit UserId');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bSsoProviderId\\s+In\\b').matcher(soql).find(), 'Resulting query limits SsoProviderId... it should not');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'providerIds' => new Set<Id>{'0SO000000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bUserId\\s+In\\b').matcher(soql).find(), 'Resulting query limits UserId... it should not');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bSsoProviderId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit SsoProviderId');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'userIds' => new Set<Id>{'005000000000000'},
			'providerIds' => new Set<Id>{'0SO000000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from ThirdPartyAccountLink\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, false);

		Test.stopTest();

	}
}