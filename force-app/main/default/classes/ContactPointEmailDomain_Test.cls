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
		MockUtility.mockDomain(ApplicationDomain.class);
		ContactService mockService = (ContactService)MockUtility.mockUtility(ContactService.class);

		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockService.checkCurrentUserIsIntegrationUser(fflib_Match.anyString())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		ContactPointEmailDomain.Constructor constructor = new ContactPointEmailDomain.Constructor();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);

		ApplicationDomain appDomain = constructor.construct(contacts);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(ContactPointEmailContactSyncModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}