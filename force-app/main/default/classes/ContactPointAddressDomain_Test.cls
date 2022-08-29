/***
 * @description test class for ContactPointAddressDomain
 * @author George Nguyen
 * @date 2022-07-21
 * @group Domain
 * @domain Connected Customer
 * @changelog
 * 2022-07-21 - George Nguyen - Created
 */
@IsTest
private class ContactPointAddressDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);
		ContactService mockService = (ContactService)MockUtility.mockUtility(ContactService.class);

		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockService.checkCurrentUserIsIntegrationUser(fflib_Match.anyString())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		ContactPointAddressDomain.Constructor constructor = new ContactPointAddressDomain.Constructor();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		List<SObject> contactPointAddresses = ApplicationTestDataFactory.getContactPointAddresses(1, contacts[0].Id, true);

		ApplicationDomain appDomain = constructor.construct(contactPointAddresses);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(ContactPointAddressContactSyncModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}
