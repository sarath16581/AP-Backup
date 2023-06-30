/**
 * @description Test class for TransportEnquiryCaseService
 * @author Mahesh Parvathaneni
 * @date 2023-06-02
 * @changelog
 * 29/06/2023 - Mahesh Parvathaneni - Added tests for method getEmailFullMatch
*/

@IsTest
private class TransportEnquiryCaseService_Test {

	/**
	 * Scenario: Test to ensure the transport enquiry entitlement id is returned
	 */
	@IsTest
	static void testGetTransportEnquiryEntitlementId() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> orgAaccounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Entitlement> entitlements = ApplicationTestDataFactory.getEntitlements(1, true, TransportEnquiryCaseService.TRANSPORT_ENQUIRY_ENTITLEMENT, null, orgAaccounts[0].Id);

		// =====================================
		// Stubbing
		// =====================================
		EntitlementsSelector mockEntitlementsSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementsSelector.selectByNameAndAccountName(new Set<String>{TransportEnquiryCaseService.TRANSPORT_ENQUIRY_ENTITLEMENT}, new Set<String>{TransportEnquiryCaseService.TRANSPORT_ENQUIRY_ENTITLEMENT_ACCOUNT})).thenReturn(entitlements);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Id entitlementId = TransportEnquiryCaseService.getInstance().getTransportEnquiryEntitlementId();

		// make sure the entitlement id has been returned
		Assert.areNotEqual(null, entitlementId, 'Expected transport enquiry entitlement id to be returned');

		Test.stopTest();
	}

	/**
	 * Scenario: Test to ensure the transport enquiry recordtype id is returned
	 */
	@IsTest
	static void testGetTransportEnquiryRecordTypeId() {
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

		Id recordTypeId = TransportEnquiryCaseService.getInstance().getTransportEnquiryRecordTypeId();

		// make sure the recordtype id has been returned
		Assert.areNotEqual(null, recordTypeId, 'Expected transport enquiry recordtype id to be returned');

		Test.stopTest();
	}

	/**
	 * Scenario: Test to ensure the whole pattern match for email is returned from the string
	 */
	@IsTest
	static void testGetEmailFullMatch() {
		// =====================================
		// Data Preparation
		// =====================================
		String email1 = 'transportenquiry@auspost.com.au;5195231b-cd74-45a4-b576-9bc88ae35b48';
		String email2 = 'transportenquiry@auspost.com.au$5bsdfgedg ewrewt ewrtw4etert';
		String email3 = '$retert%transportenquiry@auspost.com.au$5bsdfgedg ewrewt ewrtw4etert';
		String email4 = '$retert%transportenquiryauspost.com.au$5bsdfgedg ewrewt ewrtw4etert';
		String result = 'transportenquiry@auspost.com.au';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TransportEnquiryCaseService service = TransportEnquiryCaseService.getInstance();

		// make sure the email has been returned
		Assert.areEqual(result, service.getEmailFullMatch(email1), 'Expected valid email to be returned');
		Assert.areEqual(result, service.getEmailFullMatch(email2), 'Expected valid email to be returned');
		Assert.areEqual(result, service.getEmailFullMatch(email3), 'Expected valid email to be returned');
		Assert.areNotEqual(result, service.getEmailFullMatch(email4), 'Expected no email to be returned');
		Assert.areEqual(null, service.getEmailFullMatch(null), 'Expected no email to be returned');
		Assert.areEqual(null, service.getEmailFullMatch('12132445'), 'Expected no email to be returned');
		Assert.areEqual(null, service.getEmailFullMatch('1213$auspost.com2445'), 'Expected no email to be returned');
		Assert.areEqual(null, service.getEmailFullMatch(''), 'Expected no email to be returned');
		Assert.areEqual(null, service.getEmailFullMatch(' '), 'Expected no email to be returned');
		Assert.areEqual(null, service.getEmailFullMatch('$retert%transportenquiry$123'), 'Expected no email to be returned');

		Test.stopTest();
	}

}