@isTest
public with sharing class DigitalRepositoryV2SettingsSelectorTest {
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

		DigitalRepositoryV2SettingsSelector selector = DigitalRepositoryV2SettingsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom DigitalRepositoryV2Settings__mdt\\b').matcher(soql).find(), 'Resulting query does select from DigitalRepositoryV2Settings__mdt: ' + soql);

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
		//Fields to Query
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ DigitalRepositoryV2Settings__mdt.AttachmentType__c };

		DigitalRepositoryV2SettingsSelector selector = DigitalRepositoryV2SettingsSelector.newInstance(fieldOverrides);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)AttachmentType__c.*?\\bfrom DigitalRepositoryV2Settings__mdt\\b').matcher(soql).find(), 'Query returning DigitalRepositoryV2Settings__mdt fields' + soql);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryWithAttachmentType() {
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
		DigitalRepositoryV2SettingsSelector selector = DigitalRepositoryV2SettingsSelector.newInstance();
		List<DigitalRepositoryV2Settings__mdt> configRecords = selector.getAPIConfigurationsByAttachmentType(new Set<String>{ 'test' });
		System.assertEquals(0, configRecords.size(), 'No records found with the given attachment type');
		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureDefaultConfiguration() {
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
		DigitalRepositoryV2SettingsSelector selector = DigitalRepositoryV2SettingsSelector.newInstance();
		List<DigitalRepositoryV2Settings__mdt> configRecords = selector.getDefaultAPIConfiguration();
		System.assertEquals(1, configRecords.size(), 'Query return records');
		System.assertEquals(true, configRecords[0].Default__c, 'Default record found');
		Test.stopTest();
	}
}