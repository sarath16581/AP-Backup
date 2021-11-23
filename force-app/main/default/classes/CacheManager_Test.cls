/**************************************************
Purpose:    Used to add session and eventually platform level caching
				to Salesforce to improve performance throughout the system
--------------------------------------------------
2017-09-27  nathan.franklin@auspost.com.au  Created
2017-10-30  nathan.franklin@auspost.com.au  Added Cache Key specific tests to ensure consistent results
**************************************************/
@isTest
public class CacheManager_Test {

	/**
	 * Scenario:
	 *  Ensure Cache is working as expected. NOTE: All cache keys MUST be defined in CacheKeySetting__mdt.
	 *  This will check the return values when the metadata keys are Enabled.
	 */
	public static testMethod void testCacheMetaDataKeyEnabled() {

		CacheManager.settings.CacheEnabled__c = true;

		// org cache (defined in UNITTEST_ORG_KEY)
		CacheManager.put('UNITTEST_ORG_KEY', 'Status1');
		System.assertEquals('Status1', CacheManager.get('UNITTEST_ORG_KEY'));

		// session cache (defined in UNITTEST_SESSION_KEY)
		CacheManager.put('UNITTEST_SESSION_KEY', 'suffix1', 'mysamplevalue1');
		System.assertEquals('mysamplevalue1', CacheManager.get('UNITTEST_SESSION_KEY', 'suffix1'));

		// ensure that cache is not used when it's disabled
		CacheManager.settings.CacheEnabled__c = false;

		CacheManager.put('UNITTEST_ORG_KEY', 'myvalue');
		System.assertEquals(null, CacheManager.get('UNITTEST_ORG_KEY'));
	}

	/**
	 * Scenario:
	 *  Ensure Cache is working as expected. NOTE: All cache keys MUST be defined in CacheKeySetting__mdt.
	 *  This will check the return values when the metadata keys are Disabled. (Regardless of cache being enabled)
	 */
	public static testMethod void testCacheMetaDataKeyDisabled() {

		CacheManager.settings.CacheEnabled__c = true;

		// org cache (defined in UNITTEST_ORG_KEY)
		CacheManager.put('UNITTEST_ORG_KEY_DISABLED', 'Status1');
		System.assertEquals(null, CacheManager.get('UNITTEST_ORG_KEY_DISABLED'));

		// session cache (defined in UNITTEST_SESSION_KEY)
		CacheManager.put('UNITTEST_SESSION_KEY_DISABLED', 'suffix1', 'mysamplevalue1');
		System.assertEquals(null, CacheManager.get('UNITTEST_SESSION_KEY_DISABLED', 'suffix1'));

		// ensure that cache is not used when it's disabled
		CacheManager.settings.CacheEnabled__c = false;

		CacheManager.put('UNITTEST_ORG_KEY_DISABLED', 'myvalue');
		System.assertEquals(null, CacheManager.get('UNITTEST_ORG_KEY_DISABLED'));
	}

	/**
	 * Scenario:
	 *  Ensure Cache is working as expected. NOTE: All cache keys MUST be defined in CacheKeySetting__mdt.
	 *  This will check the return values when the metadata keys are Disabled. (Regardless of cache being enabled)
	 */
	public static testMethod void testCacheSpecificKeys() {

		Contact con = TestDataProvider.createContact();
		insert con;

		// these are the recordtypes allowed to be used int he network search page
		List<SSSW_Facility_Search_Record_Types__c> allowedTypes = new List<SSSW_Facility_Search_Record_Types__c>();
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Business_Hub_3'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Delivery_1'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Digital_7'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'International_4'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Lockers_5'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Other_8'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Retail_2'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Street_Posting_Box_6'));
		insert allowedTypes;

		Network__c nwMelb4 = TestDataProvider.createTestNetwork();
		nwMelb4.Name = 'Melbourne4';
		nwMelb4.ORG_UNIT_ADDR_3__c = 'Melbourne';
		nwMelb4.Email__c = 'top@top.com';
		nwMelb4.Geolocation__Latitude__s = -37.814; // Melbourne
		nwMelb4.Geolocation__Longitude__s = 144.96332;
		nwMelb4.AlwaysShown__c = true;
		nwMelb4.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Other_8'].Id;
		insert nwMelb4;

		//COMMON_UTILS_API_NAMES
		CacheManager.settings.CacheEnabled__c = false;
		String objectNameNotCached = CommonUtils.getObjectAPINameByRecordId(con.Id);
		System.assertEquals('Contact', objectNameNotCached);

		CacheManager.settings.CacheEnabled__c = true;
		String objectName = CommonUtils.getObjectAPINameByRecordId(con.Id);
		System.assertEquals('Contact', objectName);
		System.assertEquals(objectName, objectNameNotCached);

		//NETWORK_SEARCH_ALWAYS_SHOW_NETWORKS
		FacilitySearchController search = new FacilitySearchController();
		CacheManager.settings.CacheEnabled__c = false;
		List<FacilitySearchController.NetworkWrapper> alwaysShownNetworksNotCached = search.getAlwaysShownNetworks();
		System.assertNotEquals(0, alwaysShownNetworksNotCached.size());

		CacheManager.settings.CacheEnabled__c = true;
		List<FacilitySearchController.NetworkWrapper> alwaysShownNetworks = search.getAlwaysShownNetworks();
		System.assertNotEquals(0, alwaysShownNetworksNotCached.size());
		System.assertEquals(alwaysShownNetworks.size(), alwaysShownNetworksNotCached.size());

		//NETWORK_SEARCH_BUSINESS_HOURS
		CacheManager.settings.CacheEnabled__c = false;
		search.populateBusinessHoursMap();
		System.assertNotEquals(0, search.displayBusinessHours.size());

		CacheManager.settings.CacheEnabled__c = true;
		search.populateBusinessHoursMap();
		System.assertNotEquals(0, search.displayBusinessHours.size());

		//NETWORK_SEARCH_SELECTABLE_FIELDS
		CacheManager.settings.CacheEnabled__c = false;
		String selectableFieldsNotCached = search.getSelectableFields();
		System.assertEquals(false, String.isEmpty(selectableFieldsNotCached));

		CacheManager.settings.CacheEnabled__c = true;
		String selectableFields = search.getSelectableFields();
		System.assertEquals(false, String.isEmpty(selectableFields));
		System.assertEquals(selectableFieldsNotCached, selectableFields);

		//UTILITY_GROUPS
		CacheManager.settings.CacheEnabled__c = false;
		Map<Id,Group> groupsNotCached = Utility.getGroups('QUEUE');
		System.assertNotEquals(0, groupsNotCached.size());

		CacheManager.settings.CacheEnabled__c = true;
		Map<Id,Group> groups = Utility.getGroups('QUEUE');
		System.assertNotEquals(0, groups.size());
		System.assertEquals(groupsNotCached.size(), groups.size());

		//UTILITY_OBJECT_RECORD_TYPES
		CacheManager.settings.CacheEnabled__c = false;
		Map<String,Id> recordTypesNotCached = Utility.getsObjectRecordTypes('Case');
		System.assertNotEquals(0, recordTypesNotCached.size());

		CacheManager.settings.CacheEnabled__c = true;
		Map<String,Id> recordTypes = Utility.getsObjectRecordTypes('Case');
		System.assertNotEquals(0, recordTypes.size());
		System.assertEquals(recordTypesNotCached.size(), recordTypes.size());

		//UTILITY_RECORD_TYPE_IDS
		CacheManager.settings.CacheEnabled__c = false;
		Set<Id> recordTypeIdsNotCached = Utility.getRecordTypeIds('Case', 'SSSW');
		System.assertNotEquals(0, recordTypeIdsNotCached.size());

		CacheManager.settings.CacheEnabled__c = true;
		Set<Id> recordTypeIds = Utility.getRecordTypeIds('Case', 'SSSW');
		System.assertNotEquals(0, recordTypeIds.size());
		System.assertEquals(recordTypeIdsNotCached.size(), recordTypeIds.size());

		//UTILITY_RECORD_TYPE_NAMES
		CacheManager.settings.CacheEnabled__c = false;
		Map<Id,String> recordTypeNamesNotCached = Utility.getsObjectRecordTypeNames('Case');
		System.assertNotEquals(0, recordTypeNamesNotCached.size());

		CacheManager.settings.CacheEnabled__c = true;
		Map<Id,String> recordTypeNames = Utility.getsObjectRecordTypeNames('Case');
		System.assertNotEquals(0, recordTypeNames.size());
		System.assertEquals(recordTypeNamesNotCached.size(), recordTypeNames.size());

		//CASE_CLOSED_STATUSES
		CacheManager.settings.CacheEnabled__c = false;
		Set<String> caseCloseStatusesNotCached = Utility.getCaseClosedStatus();
		System.assertNotEquals(0, caseCloseStatusesNotCached.size());

		CacheManager.settings.CacheEnabled__c = true;
		Set<String> caseCloseStatuses = Utility.getCaseClosedStatus();
		System.assertNotEquals(0, caseCloseStatuses.size());
		System.assertEquals(caseCloseStatusesNotCached.size(), caseCloseStatuses.size());

	}

}