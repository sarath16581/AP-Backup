/**
 * Test class covering CustomsSettingsSelector.
 * @date 2022-09-21
 * @group Tests
 * @tag Selector
 * @tag CustomSetting SObject
 * @description Test Class covering CustomsSettingsSelector
 * 2022-09-21 - Swati Mogadala - Created
 * 2024-02-20 - Naveen Rajanna - REQ3445775
 */
@IsTest
public with sharing class CustomsSettingsSelector_Test {

	@TestSetup
	static void testDataSetup() {
		insert new TransactionSecurityPolicySetting__c(SetupOwnerId = UserInfo.getOrganizationId());
	}

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// =====================================
		// Stubbing
		// =====================================
		// None!
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Set<SObjectField> fields = new Set<SObjectField>{TransactionSecurityPolicySetting__c.Id, TransactionSecurityPolicySetting__c.Name};
		CustomsSettingsSelector selector = CustomsSettingsSelector.newInstance(TransactionSecurityPolicySetting__c.SObjectType, fields);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom TransactionSecurityPolicySetting__c\\b').matcher(soql).find(), 'Resulting query does not select from Custom settings');
		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectBySetupOwnerId() {

		// =====================================
		// Data Preparation
		// =====================================
		// =====================================
		// Stubbing
		// =====================================
		// None!
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Set<SObjectField> fields = new Set<SObjectField>{TransactionSecurityPolicySetting__c.Id, TransactionSecurityPolicySetting__c.Name};
		CustomsSettingsSelector selector = CustomsSettingsSelector.newInstance(TransactionSecurityPolicySetting__c.SObjectType, fields);
		TransactionSecurityPolicySetting__c setting = [SELECT Id, Name, SetupOwnerId FROM TransactionSecurityPolicySetting__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()];
		List<SObject> results = (List<SObject>) selector.selectBySetupOwnerId(new Set<Id>{setting.SetupOwnerId});
		System.assertEquals(1, results.size());
		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectByNames() {

		// =====================================
		// Data Preparation
		// =====================================
		// =====================================
		// Stubbing
		// =====================================
		// None!
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Set<SObjectField> fields = new Set<SObjectField>{TransactionSecurityPolicySetting__c.Id, TransactionSecurityPolicySetting__c.Name, TransactionSecurityPolicySetting__c.SetupOwnerId};
		CustomsSettingsSelector selector = CustomsSettingsSelector.newInstance(TransactionSecurityPolicySetting__c.SObjectType, fields);
		TransactionSecurityPolicySetting__c setting = [SELECT Id, Name, SetupOwnerId FROM TransactionSecurityPolicySetting__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()];
		Map<String, SObject> results = (Map<String, SObject>) selector.selectByNames(new Set<String>{setting.Name});
		System.assertEquals(1, results.size());
		Test.stopTest();
	}
}