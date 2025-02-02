/***
 * @author Disha kariya
 * @date 2020-08-24
 * @group Tests
 * @tag Selector
 * @tag Network SObject
 * @domain Core
 * @description Test Class covering NetworksSelector
 * @changelog
 * 2020-08-24 - Disha Kariya - Created
 * 2020-09-23 - Disha Kariya - Updated for select by Org Id method
 * 2021-03-15 - Seth Heang - Add code coverage for selectByNameAndOrgId(), selectByNetworkNameAndOrgIdAndNotID
 * 2021-07-20 - seth.heang@auspost.com.au - Add code coverage for selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING()
 * 2021-07-27 - naveen.rajanna@auspost.com.au - Add code coverage for selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE()
 * 2022-03-23 - Ranjeewa Silva - Added tests for select by name
 * 2023-03-10 - Mahesh Parvathaneni - Added test for WITH_EVENTMESSAGES_DESC_ORDER options
 * 2023-05-11 - Mahesh Parvathaneni - Added tests for FILTER_MYNETWORK, FILTER_IS_PARCEL, FILTER_STATUS_NOT_CLOSED
 */
@IsTest
public with sharing class NetworksSelector_Test {

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

		NetworksSelector selector = NetworksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		// make sure there is RecordType.DeveloperName condition
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom network__c\\b').matcher(soql).find(), 'Resulting query does not select from Network');

		selector = NetworksSelector.newInstance();
		qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();

		// make sure there is Owner
		System.assertEquals(true, Pattern.compile('(?ism)Owner.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select from Owner');

		selector = NetworksSelector.newInstance();
		qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_RECORDTYPE});
		soql = qb.toSoqlString();

		// make sure there is RecordType
		System.assertEquals(true, Pattern.compile('(?ism)RecordType.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select from RecordType');

		//Test for field override
		selector = NetworksSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Network__c.SObjectType => new Set<SObjectField>{Network__c.Network_Manager__c, Network__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Network_Manager__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Network_Manager__c field: ' + soql);

		selector = NetworksSelector.newInstance(0, new Set<SObjectField>{Network__c.Network_Manager__c, Network__c.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Network_Manager__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Network_Manager__c field: ' + soql);

		selector = NetworksSelector.newInstance(new Set<SObjectField>{Network__c.Network_Manager__c, Network__c.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Network_Manager__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Network_Manager__c field: ' + soql);

		selector = NetworksSelector.newInstance();
		qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.FILTER_MYNETWORK, NetworksSelector.Options.FILTER_IS_PARCEL, NetworksSelector.Options.FILTER_STATUS_NOT_CLOSED});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Network__c\\b.*Contact_Facility__c\\s*=\\s*\'MyNetwork\'').matcher(soql).find(), 'Resulting query does not limit Contact facility of MyNetwork');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Network__c\\b.*Parcel__c\\s*=\\s*true').matcher(soql).find(), 'Resulting query does not limit Is Parcel is true records');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Network__c\\b.*Status__c\\s*!=\\s*\'Closed\'').matcher(soql).find(), 'Resulting query does not limit Status of Not Closed networks');

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

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		NetworksSelector selector = NetworksSelector.newInstance(20);
		Map<Id, Network__c> results = selector.selectById(new Set<Id>{networks[0].Id, networks[1].Id, networks[2].Id});
		Map<Id, Network__c> orgIdResults = selector.selectByOrgId(new Set<String>{'12345'});
		System.assertEquals(3, results.size(), 'Expected result size of 3');
		System.assertEquals(1, orgIdResults.size(), 'Expected result size of 1');

		Map<Id, Network__c> resultNameAndOrgId = selector.selectByNameAndOrgId(new Set<String>{networks[0].Name}, new Set<String>{networks[0].Org_ID__c});
		Map<Id, Network__c> resultNameAndOrgUnitCodeAndNotID = selector.selectByNetworkNameAndOrgIdAndNotID(networks[0].Name, new Set<String>{networks[0].Org_Unit_Type__c}, new Set<String>{networks[1].Id, networks[2].Id});
		Map<Id, Network__c> resultNameAndOrgUnitCodeAndNotID_OR_DWS = selector.selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING(networks[1].Name, new Set<String>{networks[1].Org_Unit_Type__c}, new Set<String>{networks[0].Id,networks[2].Id}, 'DWS');
		Map<Id, Network__c> resultNameAndOrgUnitCodeAndNotID_OR_DWS_OR_WORKCENTRE = selector.selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(networks[1].Org_ID__c, new Set<String>{networks[1].Org_Unit_Type__c}, new Set<String>{networks[0].Id}, 'DWS');
		System.assertEquals(1, resultNameAndOrgId.size(), 'Expected result size of 1');
		System.assertEquals(1, resultNameAndOrgUnitCodeAndNotID.size(), 'Expected result size of 1');
		System.assertEquals(1, resultNameAndOrgUnitCodeAndNotID_OR_DWS.size(), 'Expected result size of 1');
		System.assertEquals(1, resultNameAndOrgUnitCodeAndNotID_OR_DWS_OR_WORKCENTRE.size(), 'Expected result size of 1');

		List<Network__c> selectedNetworks = selector.selectByName(new Set<String>{'Melbourne'});
		System.assertEquals(1, selectedNetworks.size(), 'Expected result size of 1 for exact match based on name');

		Set<String> stNetworkRecordTypes = NetworksSelector.ST_NETWORK_RECORD_TYPES;
		System.assertEquals(4, stNetworkRecordTypes.size(), 'Expected result size of 4 for exact match based on record types');
		System.assertEquals(true, stNetworkRecordTypes.contains(StarTrack_Constants.RECORDTYPE_DEPOT_AGENT), 'Expected Agent record type');
		System.assertEquals(true, stNetworkRecordTypes.contains(StarTrack_Constants.RECORDTYPE_DEPOT_CARE_AGENT), 'Expected Care Agent record type');
		System.assertEquals(true, stNetworkRecordTypes.contains(StarTrack_Constants.RECORDTYPE_DEPOT_METRO), 'Expected Metro record type');
		System.assertEquals(true, stNetworkRecordTypes.contains(StarTrack_Constants.RECORDTYPE_DEPOT_REGIONAL), 'Expected Regional record type');

		Map<Id, Network__c> resultsAPNetwork = selector.selectById(new Set<Id>{networks[0].Id, networks[1].Id, networks[2].Id}, new Set<Object>{NetworksSelector.Options.FILTER_AP_NETWORK});
		System.assertEquals(3, resultsAPNetwork.size(), 'Expected result size of 3');

		Map<Id, Network__c> filterNetworkResults = selector.selectById(new Set<Id>{networks[0].Id, networks[1].Id, networks[2].Id}, new Set<Object>{NetworksSelector.Options.FILTER_MYNETWORK, NetworksSelector.Options.FILTER_IS_PARCEL});
		System.assertEquals(1, filterNetworkResults.size(), 'Expected result size of 1');

		List<Network__c> filteredNetworks = selector.selectByNetworkNamePartial('Mel');
		System.assertEquals(2, filteredNetworks.size(), 'Expected result size of 2 for partial match based on name');


		Test.stopTest();

	}
}