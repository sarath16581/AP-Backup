/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Account SObject
 * @domain Core
 * @description Test Class covering SSSWAccountsSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2024-03-07 - Mahesh Parvathaneni - Added tests for newInstance methd
 */
@IsTest
public with sharing class SSSWAccountsSelector_Test {

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Account> personAccounts = ApplicationTestDataFactory.getPersonAccounts(2, false);
		personAccounts[0].APCN__pc = '123456789';
		personAccounts[1].APCN__pc = '987654321';
		insert personAccounts;

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SSSWAccountsSelector selector = SSSWAccountsSelector.newInstance(2);
		Map<Id, Account> results = selector.selectByAPCN(new Set<String>{personAccounts[0].APCN__pc});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectById(new Set<Id>{accounts[0].Id}, new Set<Object>{SSSWAccountsSelector.Options.FILTER_PERSON_ACCOUNT_ONLY});
		System.assertEquals(0, results.size(), 'Expected only Person Accounts');

		selector = SSSWAccountsSelector.newInstance(true);
		results = selector.selectByAPCN(new Set<String>{personAccounts[0].APCN__pc});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		Test.stopTest();
	}
}