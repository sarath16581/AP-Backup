/**
 * @description Test Class covering NetworkBypassesSelector
 * @author Mahesh Parvathaneni
 * @date 2023-05-18
 * @changelog
 */
@IsTest
private class NetworkBypassesSelector_Test {
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

		NetworkBypassesSelector selector = NetworkBypassesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom FacilityByPass__c\\b').matcher(soql).find(), 'Resulting query does not select from FacilityByPass__c: ' + soql);

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

		NetworkBypassesSelector selector = NetworkBypassesSelector.newInstance(0, new Set<SObjectField>{FacilityByPass__c.Facility_By_Pass_From__c});

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(FacilityByPass__c.Facility_By_Pass_From__c) + '\\b').matcher(soql).find(), 'Resulting query does not select Facility_By_Pass_From__c fields: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(FacilityByPass__c.Facility_By_Pass_To__c) + '\\b').matcher(soql).find(), 'Resulting query selects Facility_By_Pass_To__c but should not: ' + soql);

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
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(3, false);
		networks[0].Org_ID__c = '12345';
		networks[0].Org_Unit_Type__c = 'LPO';
		networks[0].Name = 'Melbourne';

		networks[1].Org_ID__c = '55555';
		networks[1].Org_Unit_Type__c = 'ABC';
		networks[1].Name = 'Melbourne DWS';
		networks[1].Contact_Facility__c = 'MyNetwork';
		networks[1].Parcel__c = true;

		insert networks;

		List<FacilityByPass__c> networkBypasses = ApplicationTestDataFactory.getNetworkBypasses(1, networks[0].Id, networks[1].Id, false);
		networkBypasses.addAll(ApplicationTestDataFactory.getNetworkBypasses(1, networks[0].Id, networks[2].Id, false));

		insert networkBypasses;


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		NetworkBypassesSelector selector = NetworkBypassesSelector.newInstance();
		List<FacilityByPass__c> results = selector.selectById(new Set<Id>{networkBypasses[0].Id, networkBypasses[1].Id});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		Map<String, Object> params = new Map<String, Object>{
			'bypassFromIds' => new Set<Id>{networks[0].Id},
			'bypassToIds' => new Set<Id>{networks[1].Id}
		};
		selector = NetworkBypassesSelector.newInstance();
		results = selector.search(params, true);
		System.assertNotEquals(0, results.size(), 'Expected network bypass record to be returned');

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

		NetworkBypassesSelector selector = NetworkBypassesSelector.newInstance(1);

		searchParams = new Map<String, Object>{
			'bypassFromIds' => new Set<Id>{'a2KN00000067wCN'},
			'bypassToIds' => new Set<Id>{'a2KN00000067wCM'}
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from FacilityByPass__c\\s+where\\b.*?\\bFacility_By_Pass_From__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Facility_By_Pass_From__c: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from FacilityByPass__c\\s+where\\b.*?\\bFacility_By_Pass_To__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Facility_By_Pass_To__c: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'bypassFromIds' => new Set<Id>{'a2KN00000067wCN'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from FacilityByPass__c\\s+where\\b.*?\\bFacility_By_Pass_From__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Facility_By_Pass_From__c: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from FacilityByPass__c\\s+where\\b.*?\\bFacility_By_Pass_To__c\\s+In\\b').matcher(soql).find(), 'Resulting query limits Facility_By_Pass_To__c... it should not:' + soql);

		searchParams = new Map<String, Object>{
			'bypassFromIds' => new Set<Id>{'a2KN00000067wCN'},
			'bypassToIds' => new Set<Id>{'a2KN00000067wCM'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from FacilityByPass__c\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY: ' + soql);

		Test.stopTest();

	}
}