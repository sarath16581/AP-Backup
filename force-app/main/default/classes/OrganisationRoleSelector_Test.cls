/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag ProposaltSelector
 * @domain Core
 * @description Test Class covering OrganisationRoleSelector
 * @changelog
 * 2020-10-06 - Shashwat.Nath@austpost.com.au - Created
 * 2023-10-30 - Ranjeewa Silva - Updated to cover new select methods.
 */
@IsTest
private class OrganisationRoleSelector_Test{

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

		OrganisationRoleSelector selector = OrganisationRoleSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Organisation_Role__c\\b').matcher(soql).find(), 'Resulting query does not select from Organisation Role');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
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

		OrganisationRoleSelector selector = OrganisationRoleSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{OrganisationRoleSelector.Options.WITH_OWNER,OrganisationRoleSelector.Options.WITH_RECORDTYPE,OrganisationRoleSelector.Options.FILTER_PROSPECT_KNOWN});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)owner\\..*?\\bfrom Organisation_Role__c\\b').matcher(soql).find(), 'Resulting query does not select owner field');
		System.assertEquals(true, Pattern.compile('(?ism)recordtype\\..*?\\bfrom Organisation_Role__c\\b').matcher(soql).find(), 'Resulting query does not select recordtype field');
		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

		OrganisationRoleSelector selector = OrganisationRoleSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Organisation_Role__c.SObjectType => new Set<SObjectField>{Organisation_Role__c.Name}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ChargeAccountRequestSelector.Options.WITH_OWNER, AccountsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom Organisation_Role__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

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

		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;

		List<Organisation_Role__c> orgRoleList = new List<Organisation_Role__c>();
		Organisation_Role__c orgRole = new Organisation_Role__c();
		orgRole.Organisation__c = accountRecord.id;
		orgRole.Role_Type__c = 'Prospect';
		orgRoleList.add(orgRole);
		insert orgRoleList;

		Map<Id, Organisation_Role__c> mappedOrgRole = new Map<Id, Organisation_Role__c>(orgRoleList);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		OrganisationRoleSelector selector = OrganisationRoleSelector.newInstance(1, new Set<SObjectField>());
		Map<Id, Organisation_Role__c> results = selector.selectById(mappedOrgRole.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		List<Organisation_Role__c> rolesList = selector.selectByOrganisationId(new Set<Id>{accountRecord.Id});
		Assert.areEqual(1, rolesList.size());

		Test.stopTest();

	}
}