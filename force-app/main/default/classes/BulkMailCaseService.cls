/**
 * @description Servive class for bulk mail case
 * @author Thang Nguyen
 * @date 05/04/2024
 * @changelog
 * 08/05/2024  Boris Bachovski - Add Entitlement and Milestone constnats
 */

 public inherited sharing class BulkMailCaseService {

	//constants
	public static final String BULK_MAIL_ENTITLEMENT = 'Bulk Mail Standard Entitlement';
	public static final String BULK_MAIL_FIRST_RESPONSE_MILESTONE = 'Bulk Mail - First Response';
	public static final String CASE_BULK_MAIL_RT = 'Bulk_Mail_Onboarding';
	public static final String BULK_MAIL_ENTITLEMENT_ACCOUNT = 'Bulk Mail Entitlements';
	public static final String NEW_EMAIL_RECEIVED = 'New Email Received';
	public static final String CLOSED_STATUS = 'Closed';
	public static final String REOPENNED_STATUS = 'Reopened';
	public static final String IN_PROGRESS_STATUS = 'In Progress';
	public static final String CASE_TYPE = 'Bulk Mail';
	public static final String INTERNAL_EMAIL_DOMAIN = 'auspost.com.au';
	public static final String INTERNAL_CUSTOMER_SOURCE = 'Internal Customer';
	public static final String CUSTOMER_SOURCE = 'Customer';
	public static final String BULK_MAIL_QUEUE = 'Bulk_Mail_Onboarding_Queue';

	private static Id bulkMailEntitlementId;
	private static Id bulkMailRecordTypeId;
	private static Id bulkMailQueueId;

	/**
	* Grabs a new instance of this class
	* Using Application.Utilities allows us to override this interface with a mock class for unit testing
	*/
	public static BulkMailCaseService getInstance() {
		return (BulkMailCaseService)Application.Utilities.getInstance(BulkMailCaseService.class);
	}

	// Funtion to get the bulk mail entitlement record id
	public Id getBulkMailEntitlementId() {
		if (bulkMailEntitlementId == null) {
			List<Entitlement> entitlements = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{BULK_MAIL_ENTITLEMENT}, new Set<String>{BULK_MAIL_ENTITLEMENT_ACCOUNT});
			if (!entitlements.isEmpty()) {
				bulkMailEntitlementId = entitlements[0].Id;
			}
		}
		return bulkMailEntitlementId;
	}

	//Function to get the bulk mail record type ids
	public Id getBulkMailRecordTypeId() {
		if (bulkMailRecordTypeId == null) {
			List<RecordType> recordTypes = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{CASE_BULK_MAIL_RT}).values();
			if (!recordTypes.isEmpty()) {
				bulkMailRecordTypeId = recordTypes[0].Id;
			}
		}
		return bulkMailRecordTypeId;
	}

	//Function to get the bulk mail queue id
	public Id getBulkMailQueueId() {
		if (bulkMailQueueId == null) {
			List<Group> groupRecords = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{BULK_MAIL_QUEUE}).values();
			if (!groupRecords.isEmpty()) {
				bulkMailQueueId = groupRecords[0].Id;
			}
		}
		return bulkMailQueueId;
	}	
}