/***
 * @description test class for STAgentWorkDomain
 * @author George Nguyen
 * @group Domain
 * @domain AgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - Created
 */
@IsTest
private class STAgentWorkDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		STAgentWorkDomain.Constructor constructor = new STAgentWorkDomain.Constructor();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);

		ApplicationDomain appDomain = constructor.construct(contacts);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(STAgentWorkCallbackReminderModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}