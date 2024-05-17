/**
 * @description Servive class for transport enquiry case
 * @author Mahesh Parvathaneni
 * @date 02/06/2023
 * @changelog
 * 29/06/2023 - Mahesh Parvathaneni - Added method getEmailFullMatch
 */

public inherited sharing class TransportEnquiryCaseService {

	//constants
	public static final String TRANSPORT_ENQUIRY_ENTITLEMENT = 'Transport Enquiry Standard Entitlement';
	public static final String CASE_TRANSPORT_ENQUIRY_RT = 'Transport_Enquiry';
	public static final String TRANSPORT_ENQUIRY_ENTITLEMENT_ACCOUNT = 'Transport Enquiry Entitlements';
	public static final String NEW_EMAIL_RECEIVED = 'New Email Received';
	public static final String CLOSED_STATUS = 'Closed';
	public static final String NEW_STATUS = 'New';

	private static Id transportEnquiryEntitlementId;
	private static Id transportEnquiryRecordTypeId;
	private static Map<String,Pattern> compiledPatternsMap;

	/**
	* Grabs a new instance of this class
	* Using Application.Utilities allows us to override this interface with a mock class for unit testing
	*/
	public static TransportEnquiryCaseService getInstance() {
		return (TransportEnquiryCaseService)Application.Utilities.getInstance(TransportEnquiryCaseService.class);
	}

	// Funtion to get the transport enquiry entitlement record id
	public Id getTransportEnquiryEntitlementId() {
		if (transportEnquiryEntitlementId == null) {
			List<Entitlement> entitlements = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{TRANSPORT_ENQUIRY_ENTITLEMENT}, new Set<String>{TRANSPORT_ENQUIRY_ENTITLEMENT_ACCOUNT});
			if (!entitlements.isEmpty()) {
				transportEnquiryEntitlementId = entitlements[0].Id;
			}
		}
		return transportEnquiryEntitlementId;
	}

	//Function to get the transport enquiry record type ids
	public Id getTransportEnquiryRecordTypeId() {
		if (transportEnquiryRecordTypeId == null) {
			List<RecordType> recordTypes = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{CASE_TRANSPORT_ENQUIRY_RT}).values();
			if (!recordTypes.isEmpty()) {
				transportEnquiryRecordTypeId = recordTypes[0].Id;
			}
		}
		return transportEnquiryRecordTypeId;
	}
}