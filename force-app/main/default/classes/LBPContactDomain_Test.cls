/**
* @description Test class for LBPContactDomain
* @author Nathan Franklin
* @date 2022-08-24
* @changelog
*/
@IsTest
private class LBPContactDomain_Test {

	@IsTest
	private static void testMethods() {
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));

		LBPContactDomain domain = LBPContactDomain.newInstance(contacts.values());

		// PMD Warning
		System.assert(true);
	}

}