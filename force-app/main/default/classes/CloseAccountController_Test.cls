@IsTest
private class CloseAccountController_Test {
	@IsTest
	private static void testCloseAccountController() {
		String baseUrl = CloseAccountController.getBaseUrl();

		MockUtility.disableTriggerExecution();
		Account account = ApplicationTestDataFactory.getAccounts(1, true).get(0);
		account.APCN__c = '1234';

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{account.Id=>account});
		MockUtility.Mocks.stopStubbing();

		String finalUrl = baseUrl + CloseAccountController.getAPCN(account.Id);

		System.assert(finalUrl != null, 'Failed to compose the full url.');
		System.assert(finalUrl.contains(account.APCN__c), 'Failed to locate the correct Account record.');
	}
}