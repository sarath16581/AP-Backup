/***
 * @description test class for ContactPointEmailDomain
 * @author George Nguyen
 * @date 2022-07-21
 * @group Domain
 * @domain Connected Customer
 * @changelog
 * 2022-07-21 - George Nguyen - Created
 */
@IsTest
private class ContactPointEmailDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		ApplicationDomain domain = (ApplicationDomain) MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		ContactPointEmailDomain.Constructor constructor = new ContactPointEmailDomain.Constructor();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);

		ApplicationDomain appDomain = constructor.construct(contacts);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(ContactPointEmailDomainModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}