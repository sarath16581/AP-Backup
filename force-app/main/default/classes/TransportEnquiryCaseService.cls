/**
 * @description Servive class for transport enquiry case
 * @author Mahesh Parvathaneni
 * @date 02/06/2023
 */

public inherited sharing class TransportEnquiryCaseService {

	//constants
	public static final String TRANSPORT_ENQUIRY_ENTITLEMENT = 'Transport Enquiry Standard Entitlement';
	public static final String CASE_TRANSPORT_ENQUIRY_RT = 'Transport_Enquiry';

	private static Id transportEnquiryEntitlementId;
	private static Id transportEnquiryRecordTypeId;


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
			Entitlement entitlement = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{TRANSPORT_ENQUIRY_ENTITLEMENT}, new Set<String>{SSSWConstants.ENTITLEMENT_ACC})[0];
			if (entitlement != null) {
				transportEnquiryEntitlementId = entitlement.Id;
			}
		}
		return transportEnquiryEntitlementId;
	}

	//Function to get the transport enquiry record type ids
	public Id getTransportEnquiryRecordTypeId() {
		if (transportEnquiryRecordTypeId == null) {
			transportEnquiryRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{CASE_TRANSPORT_ENQUIRY_RT}).values()[0].Id;
		}
		return transportEnquiryRecordTypeId;
	}
}