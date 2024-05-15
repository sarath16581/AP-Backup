/**
 * @description Test class for BulkMailCaseService
 * @author Boris Bachovski
 * @date 15/05/2024 
 * @changelog
*/

@IsTest
private class BulkMailCaseService_Test {
	/**
	 * Scenario: Test to ensure the bulk mail enquiry entitlement id is returned
	 */
	@IsTest
	static void testGetBulkMailEntitlementId() {
		// =====================================
		// Data Preparation
		// =====================================
		List <Account> orgAaccounts = ApplicationTestDataFactory.getAccounts(1, true);
		List <Entitlement> entitlements = ApplicationTestDataFactory.getEntitlements(1, true, BulkMailCaseService.BULK_MAIL_ENTITLEMENT, null, orgAaccounts[0].Id);

		// =====================================
		// Stubbing
		// =====================================
		EntitlementsSelector mockEntitlementsSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementsSelector.selectByNameAndAccountName(new Set<String>{BulkMailCaseService.BULK_MAIL_ENTITLEMENT}, new Set<String>{BulkMailCaseService.BULK_MAIL_ENTITLEMENT_ACCOUNT})).thenReturn(entitlements);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Id entitlementId = BulkMailCaseService.getInstance().getBulkMailEntitlementId();

		// Make sure the entitlement id has been returned
		Assert.areNotEqual(null, entitlementId, 'Expected bulk mail entitlement id to be returned');

		Test.stopTest();
	}

	/**
	 * Scenario: Test to ensure the transport enquiry recordtype id is returned
	 */
	@IsTest
	static void testGetBulkMailRecordTypeId() {
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
		Test.startTest();

		Id recordTypeId = BulkMailCaseService.getInstance().getBulkMailRecordTypeId();

		// Make sure the recordtype id has been returned
		Assert.areNotEqual(null, recordTypeId, 'Expected bulk mail recordtype id to be returned');

		Test.stopTest();
	}

	/**
	 * Scenario: Test to ensure the bulk mail queue Idis returned
	 */
	@IsTest
	static void testGetBulkMailQueueId() {
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
		Test.startTest();

		Id queueId = BulkMailCaseService.getInstance().getBulkMailQueueId();

		// Make sure the recordtype id has been returned
		Assert.areNotEqual(null, queueId, 'Expected bulk mail queue id to be returned');

		Test.stopTest();
	}
}