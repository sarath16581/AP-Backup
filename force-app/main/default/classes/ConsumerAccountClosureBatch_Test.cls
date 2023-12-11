/**
 * This apex class is test class for ConsumerAccountClosureBatch
 *
 *
 * @changelog:
 * 2023-11-27 Steve L - Created
*/

@IsTest
private class ConsumerAccountClosureBatch_Test {
	/**
	 * Test:
	 *  Ensures that testSelectArchivedAccountsByClosureDateLessThanEqualNMonthsAgo is returning expected results
	 */
	@IsTest
	public static void testSelectArchivedAccountsByClosureDateLessThanEqualNDaysAgo() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		insert accounts;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		Database.QueryLocator mockQueryLocator = Database.getQueryLocator('SELECT Id FROM Account');

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(accountsSelector.selectArchivedAccountsByClosureDateLessThanEqualNDaysAgo((Integer)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(mockQueryLocator);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		ConsumerAccountClosureBatch batch = new ConsumerAccountClosureBatch();
		Database.executeBatch(batch);

		Test.stopTest();

		List<AsyncApexJob> apexJobs = [SELECT Status FROM AsyncApexJob];
		System.assert(apexJobs.size() > 0, 'Batch failed to run');
	}
}