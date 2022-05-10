/* @author Ranjeewa Silva
 * @group Tests
 * @tag Selector
 * @tag Network__c
 * @domain PUD
 * @description Test Class covering PUDNetworksSelector
 * @changelog
 * 2022-03-23 - Ranjeewa Silva - Created
 */

@IsTest
public with sharing class PUDNetworksSelector_Test {

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

		PUDNetworksSelector selector = PUDNetworksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select from Network');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output with selector options and field overrides
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

		PUDNetworksSelector selector = PUDNetworksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{PUDNetworksSelector.Options.WITH_ROUTES});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Routes__r\\b.*?\\).*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Routes__r child records: '+soql);

		qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_RECORDTYPE, PUDNetworksSelector.Options.WITH_ROUTES});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Routes__r\\b.*?\\).*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Routes__r child records: '+soql);

		// Testing field overrides passing in field overrides for Network__c and for associated routes
		selector = PUDNetworksSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				Network__c.getSObjectType() => new Set<SObjectField>{Network__c.Integrated_Job_Dispatch_Enabled__c}
		});

		qb = selector.newQueryBuilder(new Set<Object>{PUDNetworksSelector.Options.WITH_ROUTES});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Integrated_Job_Dispatch_Enabled__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Integrated_Job_Dispatch_Enabled__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Org_ID__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting selects Org_ID__c but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides map with record limit
		selector = PUDNetworksSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Network__c.getSObjectType() => new Set<SObjectField>{Network__c.Integrated_Job_Dispatch_Enabled__c}
		});
		qb = selector.newQueryBuilder(new Set<Object>{PUDNetworksSelector.Options.WITH_ROUTES});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Integrated_Job_Dispatch_Enabled__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Integrated_Job_Dispatch_Enabled__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Org_ID__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting selects Org_ID__c but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides for Network__c with record limit
		selector = PUDNetworksSelector.newInstance(0, new Set<SObjectField>{Network__c.Integrated_Job_Dispatch_Enabled__c});
		qb = selector.newQueryBuilder(new Set<Object>{PUDNetworksSelector.Options.WITH_ROUTES});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Integrated_Job_Dispatch_Enabled__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Integrated_Job_Dispatch_Enabled__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Org_ID__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting selects Org_ID__c but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides for Network__c
		selector = PUDNetworksSelector.newInstance(new Set<SObjectField>{Network__c.Integrated_Job_Dispatch_Enabled__c});
		qb = selector.newQueryBuilder(new Set<Object>{PUDNetworksSelector.Options.WITH_ROUTES});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Integrated_Job_Dispatch_Enabled__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Integrated_Job_Dispatch_Enabled__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Org_ID__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting selects Org_ID__c but it shouldn\'t: ' + soql);

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

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, false);
		for (Network__c network: networks) {
			network.recordTypeId = PUDTestDataFactory.businessHubNetworkRecordType;
			network.ORG_UNIT_ADDR_2__c ='1 Main St';
			network.ORG_UNIT_ADDR_3__c ='Melbourne';
			network.State__c  ='VIC';
			network.Post_Code__c ='3121';
		}
		insert networks;


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		PUDNetworksSelector selector = PUDNetworksSelector.newInstance(0);

		List<Network__c> results = selector.selectByName(new Set<String>{'TestNetwork 1'});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(networks[0].Id, results[0].Id, 'Expected network record not returned.');

		Test.stopTest();
	}
}