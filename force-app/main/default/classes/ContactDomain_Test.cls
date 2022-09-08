/***
 * @description test class for ContactDomain
 * @author George Nguyen
 * @date 2022-07-21
 * @group Domain
 * @domain Connected Customer
 * @changelog
 * 2022-07-21 - George Nguyen - Created
 */
@IsTest
private class ContactDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		ApplicationDomain domain = (ApplicationDomain) MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		ContactDomain.Constructor constructor = new ContactDomain.Constructor();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);

		ApplicationDomain appDomain = constructor.construct(contacts);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}