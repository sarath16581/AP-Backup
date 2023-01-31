/* @author Ranjeewa Silva
 * @group Tests
 * @tag Selector
 * @tag Account
 * @domain Core
 * @description Test Class covering BusinessAccountsSelector
 * @changelog
 * 2022-01-09 - Ranjeewa Silva - Created
 */

@IsTest
private class BusinessAccountsSelector_Test {

	/**
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
		BusinessAccountsSelector selector = BusinessAccountsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');

		// make sure returned records are filtered by 'Business_Account' record type.
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom account\\b.*?RecordType.DeveloperName = \'Business_Account\'').matcher(soql).find(), 'Resulting query does not contain business account filter');

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

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, false);
		parentAccounts[0].LEGACY_ID__c = '60000000';
		parentAccounts[1].LEGACY_ID__c = '60000002';
		insert(parentAccounts);

		List<Billing_Account__c> billingAccounts =  new List<Billing_Account__c>();
		for (Account parentAccount: parentAccounts) {
			billingAccounts.add(ApplicationTestDataFactory.getBillingAccounts(1, parentAccount.Id, 'SAP CRM', false)[0]);
		}
		insert (billingAccounts);

		List<APR__c> aprs = new List<APR__c>();
		for (Billing_Account__c billingAccount: billingAccounts) {
			List<APR__c> aprsForAccount = ApplicationTestDataFactory.getAPRs(1, billingAccount.Id, null, false);
			for (APR__c apr: aprsForAccount) {
				apr.Legal_Entity_Name_LookUp__c = billingAccount.Organisation__c;
			}
			aprs.addAll(aprsForAccount);
		}
		insert(aprs);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		BusinessAccountsSelector selector = BusinessAccountsSelector.newInstance(0);
		List<Account> results = selector.selectByIdWithChildRecords(new Set<Id>{parentAccounts[0].Id}, new Map<SObjectType, String>{APR__c.getSObjectType() => 'aprs__r'});
		System.assertEquals(1, results.size(), 'only the specified account should be retrieved');
		System.assertEquals(parentAccounts[0].Id, results[0].Id, 'only the specified account should be retrieved');
		System.assert(results[0].APRs__r != null, 'child records not returned for the specified child relationship - APRs__r');
		System.assertEquals(1, results[0].APRs__r.size(), 'Expected number of child records not returned for the specified child relationship type - APRs__r');
		System.assert(results[0].APRs__r[0].Id != null, 'Id field must be populated on the child records');

		// verify behaviour when using field overrides
		selector = BusinessAccountsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				APR__c.getSObjectType() => new Set<SObjectField>{APR__c.Legal_Entity_Name_LookUp__c, APR__c.Id}
		});

		results = selector.selectByIdWithChildRecords(new Set<Id>{parentAccounts[0].Id}, new Map<SObjectType, String>{APR__c.getSObjectType() => 'aprs__r'});
		System.assertEquals(1, results.size(), 'only the specified account should be retrieved');
		System.assertEquals(parentAccounts[0].Id, results[0].Id, 'only the specified account should be retrieved');
		System.assert(results[0].APRs__r != null, 'child records not returned for the specified child relationship - APRs__r');
		System.assertEquals(1, results[0].APRs__r.size(), 'Expected number of child records not returned for the specified child relationship type - APRs__r');
		System.assertEquals(aprs[0].Id, results[0].APRs__r[0].Id, 'Field specified in field override is not populated');
		System.assertEquals(aprs[0].Legal_Entity_Name_LookUp__c, results[0].APRs__r[0].Legal_Entity_Name_LookUp__c, 'Field specified in field override is not populated');

		Test.stopTest();
	}
}