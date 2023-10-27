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
	@IsTest
	static void testGetFollowerSubAccounts() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<APT_Sub_Account__c> billingSubAccounts = ApplicationTestDataFactory.getSubAccountRequest(1, 'Test sub billing account', true);
		List<APT_Sub_Account__c> chargeSubAccounts = ApplicationTestDataFactory.getSubAccountRequest(1, 'Test sub charge account', true);

		// =====================================
		// Stubbing
		// =====================================
		SubAccountRequestsSelector selector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(selector.selectByBillingAccountId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(billingSubAccounts);
		MockUtility.Mocks.when(selector.selectByChargeAccountId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(chargeSubAccounts);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<APT_Sub_Account__c> subAccounts = FollowerOffspringRequestController.getFollowerSubAccounts(billingSubAccounts[0].Id, true);
		System.assertEquals(billingSubAccounts[0].Id, subAccounts[0].Id, 'Id not matched');

		subAccounts = FollowerOffspringRequestController.getFollowerSubAccounts(chargeSubAccounts[0].Id, false);
		System.assertEquals(chargeSubAccounts[0].Id, subAccounts[0].Id, 'Id not matched');
		Test.stopTest();
	}

	@IsTest
	static void testGetFollowerBillingAccounts() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Billing_Account__c> billingSubAccounts = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'TEAM', true);

		// =====================================
		// Stubbing
		// =====================================
		BillingAccountsSelector selector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(selector.selectByLeaderAccountId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(billingSubAccounts);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<Billing_Account__c> subAccounts = FollowerOffspringRequestController.getFollowerBillingAccounts(billingSubAccounts[0].Id);
		System.assertEquals(billingSubAccounts[0].Id, subAccounts[0].Id, 'Id not matched');
		Test.stopTest();
	}
}