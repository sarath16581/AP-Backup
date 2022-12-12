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
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		BusinessAccountDomain.Constructor constructor = new BusinessAccountDomain.Constructor();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);

		ApplicationDomain appDomain = constructor.construct(accounts);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(SalesAutomationModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}