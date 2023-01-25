/***
 * @description test class for BusinessAccountDomain
 * @author Harry Wang
 * @date 2022-11-08
 * @group Domain
 * @domain Account
 * @changelog
 * 2022-11-08 - Harry Wang - Created
 */
@IsTest
private class BusinessAccountDomain_Test {

	@IsTest
	private static void testBusinessAccountDomain() {
		// =====================================
		// Data Preparation
		// =====================================
		Account businessAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================s

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BusinessAccountDomain domain = BusinessAccountDomain.newInstance(new List<Account>{businessAccount, personAccount});
		Test.stopTest();

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered to include only business accounts');
		System.assertEquals(businessAccount.Id, domain.records[0].Id, 'Records should have been filtered to include only business accounts');
	}
}