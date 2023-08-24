/**
* @author Disha Kariya
* @date 2020-05-12
* @group Tests
* @tag Selector
* @tag Asset SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-05-12 - Disha Kariya - Created
* 2023-08-24 - Mahesh Parvathaneni - Added tests for search method
*/
@IsTest
private with sharing class AssetsSelector_Test {
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

        AssetsSelector selector = AssetsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom asset\\b').matcher(soql).find(), 'Resulting query does not select from Asset');

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

        AssetsSelector selector = AssetsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{AssetsSelector.Options.WITH_RECORDTYPE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom asset\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

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

        Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert acc;

		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, false)[0];
		insert con;

        List<Product2> prod = ApplicationTestDataFactory.getPSRProducts(2, false);
        insert prod;
        List<Asset> assetList = new List<Asset>();
        Asset assetTrans = ApplicationTestDataFactory.getPSRTransactionalAssets(1, acc.Id, prod[0].Id, false,'Inactive', false)[0];
		assetTrans.ContactId = con.Id;
        assetList.add(assetTrans);
        Asset assetAssigned = ApplicationTestDataFactory.getPSRAssignedAssets(1, acc.Id, prod[0].Id, true, Date.today(), Date.today().addDays(14), 'Active', false)[0];
		assetAssigned.ContactId = con.Id;
        assetList.add(assetAssigned);
        insert assetList;

        Map<Id, Asset> mappedAssets = new Map<Id, Asset>(assetList);
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        AssetsSelector selector = AssetsSelector.newInstance(2);
        Map<Id, Asset> results = selector.selectById(mappedAssets.keySet());
        System.assertEquals(2, results.size(), 'Expected result size of 2');

        results = selector.selectById(mappedAssets.keySet(), new Set<Object>{AssetsSelector.Options.WITH_RECORDTYPE});
        System.assertEquals(2, results.size(), 'Expected result size of 2');

//        results = selector.selectByAccount(new Set<Id> {contacts[0].AccountId}, new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE, ContactsSelector.Options.WITH_OWNER, ContactsSelector.Options.WITH_ACCOUNT});
//        System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = new Map<Id, Asset>(selector.search(new Map<String, Object>{'contactIds' => con.Id}, true));
		System.assertEquals(2, results.size(), 'Expected result size of 2');


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

		AssetsSelector selector = AssetsSelector.newInstance();

		searchParams = new Map<String, Object>{
			'contactIds' => new Set<Id>{'003000000000000'},
			'assetNames' => new Set<String>{'PSRTandC'}
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bContactId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit ContactId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bName\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Name');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'contactIds' => new Set<Id>{'003000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bContactId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit ContactId');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bName\\s+In\\b').matcher(soql).find(), 'Resulting query limits Name... it should not');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'assetNames' => new Set<String>{'PSRTandC'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bContactId\\s+In\\b').matcher(soql).find(), 'Resulting query limits ContactId... it should not');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bName\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Name');
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'contactIds' => new Set<Id>{'003000000000000'},
			'assetNames' => new Set<String>{'PSRTandC'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Asset\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by OR');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, false);

		Test.stopTest();

	}
}