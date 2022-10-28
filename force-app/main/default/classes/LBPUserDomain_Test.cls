/**
* @description Test class for LBPUserDomain
* @author Nathan Franklin
* @date 2022-08-24
* @changelog
*/
@IsTest
private class LBPUserDomain_Test {

	@IsTest
	private static void testMethods() {
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(contacts.keySet()), false);
		users[0].ProfileId = profileId;

		LBPUserDomain domain = LBPUserDomain.newInstance(users);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(profileId, ((User)domain.records[0]).ProfileId, 'Expected LPO community user record');
	}

}