@IsTest
private class ChangeOfAddressController_Test {
	/**
	 * Test:
	 *  Ensures that the old or new address view is displayed based on conditions
	 */
	@IsTest
	private static void testDisplayOldOrNewChangeAddress() {
		// =====================================
		// Data Preparation
		// =====================================
		User owner = ApplicationTestDataFactory.getUsers(1, true)[0];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		accounts[0].Sales_Segment__c = 'Holding Sales Team';
		accounts[0] = (Account) ApplicationTestDataFactory.setUnwritableFields(accounts[0], new Map<String, Object>{
				'Role_Type_Roll_Up__c' => 'Customer'
		});


		accounts[0].Owner = owner;
		accounts[0].OwnerId = owner.Id;
		List<Profile> bgBase = [SELECT Id, Name FROM Profile WHERE Name = 'BG Base'];
		List<UserRole> userRoles = ApplicationTestDataFactory.getUserRoles(2, true);
		userRoles[0].DeveloperName = 'Sales_Specialists_NSW_1_SR';
		userRoles[1].DeveloperName = 'Medium_Business_NSW_1_SR';
		owner.UserRoleId = userRoles[1].Id;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector accountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ProfilesSelector profilesSelector = (ProfilesSelector) MockUtility.mockSelector(ProfilesSelector.class);
		UserRolesSelector userRolesSelector = (UserRolesSelector) MockUtility.mockSelector(UserRolesSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
		MockUtility.Mocks.when(profilesSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, Profile>(bgBase));
		MockUtility.Mocks.when(userRolesSelector.selectById(new Set<Id>{System.UserInfo.getUserRoleId()})).thenReturn(new Map<Id, UserRole>{userRoles[0].Id => userRoles[0]});
		MockUtility.Mocks.when(userRolesSelector.selectById(new Set<Id>{accounts[0].Owner.UserRoleId})).thenReturn(new Map<Id, UserRole>{userRoles[1].Id => userRoles[1]});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String result = ChangeOfAddressController.displayOldOrNewChangeAddress(accounts[0].Id);

		System.assertEquals('new', result, 'Expected new');
		Test.stopTest();
	}
}