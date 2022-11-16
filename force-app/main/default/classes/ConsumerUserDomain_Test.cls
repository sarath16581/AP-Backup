/**
 * @author Naveen Rajanna
 * @date 2022-10-28
 * @group Tests
 * @description Test class covering ConsumerUserDomain
 * @changelog
 */
@IsTest
private class ConsumerUserDomain_Test {
	@IsTest
	private static void testMethods() {
		Id profileId1 = [SELECT Id FROM Profile WHERE Profile.Name = 'DDC Consumer Community User'][0].Id;
		Id profileId2 = [SELECT Id FROM Profile WHERE Profile.Name = 'Consumer Community Temp Access User'][0].Id;
		Id profileId3 = [SELECT Id FROM Profile WHERE Profile.Name = 'Merchant Portal Community User'][0].Id;

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(3, acc.Id, true));
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(3, new List<Id>(contacts.keySet()), false);
		users[0].ProfileId = profileId1;
		users[1].ProfileId = profileId2;
		users[2].ProfileId = profileId3;

		ConsumerUserDomain domain = ConsumerUserDomain.newInstance(users);

		System.assertEquals(2, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(profileId1, ((User) domain.records[0]).ProfileId, 'Expected DDC Consumer Community User record');
		System.assertEquals(profileId2, ((User) domain.records[1]).ProfileId, 'Expected Consumer Community Temp Access User record');
	}
}
