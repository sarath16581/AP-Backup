/**
 * @author Harry Wang
 * @date 2023-10-27
 * @group Tests
 * @tag Controller
 * @tag CSP
 * @description Test class for FollowerOffspringRequestController
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
@IsTest
private class FollowerOffspringRequestController_Test {
	/**
	 * Test:
	 *  Ensures that the followers and sub accounts are retrieved
	 */
	@IsTest
	static void testGetFollowersAndGetSubAccounts() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<APT_Sub_Account__c> billingSubAccounts = ApplicationTestDataFactory.getSubAccountRequest(1, 'Test sub billing account', true);
		List<APT_Sub_Account__c> chargeSubAccounts = ApplicationTestDataFactory.getSubAccountRequest(1, 'Test sub charge account', true);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Billing_Account__c> billingAccounts = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'TEAM', true);

		// =====================================
		// Stubbing
		// =====================================
		SubAccountRequestsSelector selector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector bSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(selector.selectByBillingAccountId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(billingSubAccounts);
		MockUtility.Mocks.when(bSelector.selectByLeaderAccountId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(billingAccounts);
		MockUtility.Mocks.when(selector.selectByChargeAccountId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(chargeSubAccounts);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		FollowerOffspringRequestController.FollowerAccount followerAccount = FollowerOffspringRequestController.getFollowers(billingSubAccounts[0].Id, true);
		System.assertEquals(billingSubAccounts[0].Id, followerAccount.subAccountFollowers[0].Id, 'Id not matched');
		System.assertEquals(billingAccounts[0].Id, followerAccount.billingAccountFollowers[0].Id, 'Id not matched');

		followerAccount = FollowerOffspringRequestController.getFollowers(chargeSubAccounts[0].Id, false);
		System.assertEquals(chargeSubAccounts[0].Id, followerAccount.subAccountFollowers[0].Id, 'Id not matched');

		List<APT_Sub_Account__c> subAccounts = FollowerOffspringRequestController.getSubAccounts(billingSubAccounts[0].Id, true);
		System.assertEquals(billingSubAccounts[0].Id, subAccounts[0].Id, 'Id not matched');

		subAccounts = FollowerOffspringRequestController.getSubAccounts(chargeSubAccounts[0].Id, false);
		System.assertEquals(chargeSubAccounts[0].Id, subAccounts[0].Id, 'Id not matched');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that list view columns are retrieved
	 */
	@IsTest
	static void testRetrieveListViewColumns() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		// =====================================
		// Stubbing
		// =====================================
		// None!
		// =====================================
		// Testing
		// =====================================
		List<FollowerOffspringRequestController.DataTableColumn> columns = FollowerOffspringRequestController.retrieveListViewColumns();
		List<Schema.FieldSetMember> fields = SObjectType.APT_Sub_Account__c.fieldSets.Sub_Accounts_in_Follower_Offspring_List.getFields();
		System.assertEquals(fields.size(), columns.size(), 'size not matched');
	}

	/**
	 * Test:
	 *  Ensures that sub accounts are finalised
	 */
	@IsTest
	static void testFinaliseSubAccounts() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',false)[0];
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
		insert subAccountRequest;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException('mock exception message'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		try {
			FollowerOffspringRequestController.finaliseSubAccounts(new List<APT_Sub_Account__c>{subAccountRequest});
		} catch (Exception e) {
			System.assert(e.getMessage() != null, 'Expecting exception message');
		}
	}
	private class MockException extends Exception{}
}