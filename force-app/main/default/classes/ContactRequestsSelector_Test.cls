/**
 * @description Test Class covering ContactRequestsSelector
 * @author Ranjeewa Silva
 * @date 2024-07-15
 * @changelog
 * 2024-07-15 - Ranjeewa Silva - created
 * 2024-09-23 - Seth Heang - added test for FILTER_STATUS_NOT_ABANDONED
 * 2024-09-24 - George Nguyen - fixed test errors
 */
@IsTest
private class ContactRequestsSelector_Test {

	/**
	 * Ensures that the selectors QueryBuilder is generating the correct output
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

		ContactRequestsSelector selector = ContactRequestsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Assert.isTrue(Pattern.compile('(?ism)\\bfrom ContactRequest\\b').matcher(soql).find(), 'Resulting query does not select from ContactRequest: ' + soql);

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{ContactRequest.PreferredChannel};
		ContactRequestsSelector selector2 = ContactRequestsSelector.newInstance(1,fieldOverrides);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bPreferredChannel\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');

		Test.stopTest();

	}

	/**
	 * Ensures that the selectors QueryBuilder is generating the correct output when field overrides are in use
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

		ContactRequestsSelector selector = ContactRequestsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				ContactRequest.SObjectType => new Set<SObjectField>{ContactRequest.WhoId}
		});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)WhoId.*?\\bfrom ContactRequest\\b').matcher(soql).find(), 'Resulting query does not select WhoId: ' + soql);
		Assert.areEqual(false, Pattern.compile('(?ism)WhatId.*?\\bfrom ContactRequest\\b').matcher(soql).find(), 'Resulting query selects WhatId but should not: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ ContactRequestsSelector.Options.FILTER_STATUS_NOT_ABANDONED });
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)\\bfrom ContactRequest\\b.*Status\\s*!=\\s*\'?Abandoned\'?').matcher(soql).find(), 'Resulting query does not filter false Abandoned status: ' + soql);

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

		ContactRequestsSelector selector = ContactRequestsSelector.newInstance();
		List<ContactRequest> results = selector.search(new Map<String, Object>{'whatIds' => new Set<Id>{'500000000000000000'}}, true);
		Assert.areEqual(0, results.size());

		Test.stopTest();
	}

	/**
	 * Ensures that the selectors QueryBuilder is generating the correct output on search
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

		ContactRequestsSelector selector = ContactRequestsSelector.newInstance(1);

		searchParams = new Map<String, Object>{
				'whatIds' => new Set<Id>{'500000000000000'},
				'status' => 'test'
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bWhatId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter WhatId');
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bStatus\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter Status');
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
				'whatIds' => new Set<Id>{'500000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bWhatId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter WhatId');
		Assert.isFalse(Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bStatus\\s+In\\b').matcher(soql).find(), 'Resulting query filters Status, it should not');
		Assert.isFalse(Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query try to apply more than one filter, but it shouldn\'t');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
				'whatIds' => new Set<Id>{'500000000000000'},
				'status' => 'test'
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		Assert.areEqual(true, Pattern.compile('(?ism)\\s+from ContactRequest\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, false);

		// make sure an exception is thrown for invalid search parameters
		searchParams = new Map<String, Object>{
				'invalidParam' => new Set<String>{'somevalue'},
				'status' => 'test'
		};

		try {
			soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		} catch (Exception e) {
			// ensure correct type of exception thrown
			Assert.isInstanceOfType(e, ApplicationSelector.SelectorException.class);
		}

		Test.stopTest();

	}

	/**
	  * Executes a query to ensure it returns expected results with actual inserted data
	  */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Contact con = TestDataProvider.createTestContact();
        insert con;

		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		Insert cases;

		ContactRequest cr = new ContactRequest(
		WhoId = con.Id,
		WhatId = cases[0].id,
		RequestDescription = 'test call'
		);

		insert cr;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ContactRequestsSelector selector = ContactRequestsSelector.newInstance(2);
		List<ContactRequest> results = selector.selectByIds(new Set<Object>(), new Set<Id>{cr.Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}