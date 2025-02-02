/***
 * @author Alvin. Z
 * @date 2020-03-09
 * @group Tests
 * @tag Selector
 * @tag Account Team Member SObject
 * @domain Core
 * @description Test Class covering AccountTeamMembersSelector
 * @changelog
 * 2021-03-09 - Alvin. Z - Created
 * 2022-08-16 - Kamil - add test testSelectByTeamRoleAndAccountIdsWithUser, move data creation to setup method
 */
@IsTest
private class AccountTeamMembersSelector_Test {

	@TestSetup
	static void setup() {
		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, false));
		orgAaccounts[0].LEGACY_ID__c = '6000000';
		insert orgAaccounts;
		Contact testContact = new Contact(
				FirstName = 'Jame1',
				LastName = 'Test',
				MailingCity = 'Melbourne',
				MailingState = 'VIC',
				MailingStreet = '673 bourke street',
				MailingPostalCode = '3000',
				AccountId = orgAaccounts.get(0).Id,
				Email = 'example2@email.com');
		insert testContact;
		Profile p = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];
		User u1 = new User(Alias = 'tpo2x', Email = 'testlpo1x@auspost.com.au',
				EmailEncodingKey = 'UTF-8', LastName = 'x', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = p.Id, isActive = true, ContactId = testContact.Id,
				TimeZoneSidKey = 'America/Los_Angeles', UserName = 'AuspostTestuserexample4@auspost.com.au');
		insert u1;
		AccountTeamMember teamMember = new AccountTeamMember();
		teamMember.UserId = u1.Id;
		teamMember.TeamMemberRole = 'Post Office User';
		teamMember.AccountId = orgAaccounts.get(0).Id;
		insert teamMember;
	}

	@IsTest
	private static void testSelectByTeamRoleAndAccountIds() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		Test.startTest();
		List<AccountTeamMember> teamMembers = AccountTeamMembersSelector.newInstance().selectByTeamRoleAndAccountIds(
				'Post Office User', new Set<Id>{
						acc.Id
				}, new Set<Object>()).values();
		Test.stopTest();
		System.assertEquals(teamMembers.size(), 1);

	}
	@IsTest
	static void testSelectByTeamRoleAndAccountIdsWithUser() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE Email = 'testlpo1x@auspost.com.au' LIMIT 1];
		Test.startTest();
		List<AccountTeamMember> teamMembers = AccountTeamMembersSelector.newInstance().selectByTeamRoleAndAccountIds(
				'Post Office User', new Set<Id>{
						acc.Id
				}, new Set<Id>{
						testUser.Id
				}, new Set<Object>()).values();
		Test.stopTest();
		System.assertEquals(teamMembers.size(), 1);
	}

}