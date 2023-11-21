/**
 * @description Utility class to define constants for bsp
 * Defines constants for the string literals and other constant values used for bsp
 *
 * @group BSP
 * @domain BSP
 * @tag BSP
 * @author Jen Karen Tan
 * @date 2016-08-19
 * @changelog
 * 19 Aug 2016 - Jen Karen Tan - Created
 * 06 Feb 2017 - David Catindoy - Added some constants
 * 22 Feb 2017 - Andrew Judd - Added Next Flight constant
 * 2019-04-28 - nathan.franklin - Added additional error messages for BAM
 * 2019-05-16 - nathan.franklin - added bsp profile name
 * 2019-06-01 - saiswetha.pingali - modified
 * 2020-04-18 - Nathan Franklin - Added additional properties to determine context of user and access to bsp
 * 2020-08-07   Jansi - added new value for status picklist PICKLIST_VALUE_DEFAULT_All_STATUS
 * 2021-10-13   prerna.rahangdale@auspost.com.au PARMSIm Dev fix.
 * 2021-01-17 Added new case categories for MPB
 * 2023-09-6 hasantha.liyanage@auspost.com.au Added CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME
*/
public class BspConstants{
	public static final String MPB_COMMUNITY_PROFILE_NAME = 'Mypost Business Help & Support Community User';
	public static final String BSP_COMMUNITY_PROFILE_NAME = 'BSP Community User';
	public static final String BSP_COMMUNITY_CUSTOM_PERMISSION_NAME = 'BSP_Community_Access';
	public static final String BSP_COMMUNITY_PERMISSIONSET_NAME = 'BSP_Community_Access';
	public static final String BSP_SOURCEID = 'StarTrack_BSP';
	public static final String BSP_MERCHANT = 'MERCHANT';
	public static final String URL_MPB_HSP_ENQUIRY = '/apex/MpbHspEnquiry';
	public static final String EXTERNAL_USER_USERTYPE = 'CspLitePortal';

	public static final String PAGE_SECTION_LANDING = 'landing';
	public static final String PAGE_SECTION_THANK_YOU = 'thankyou';
	public static final String PAGE_SECTION_ENQUIRY = 'enquiry';
	public static final String PAGE_SECTION_BULK_CASE_UPDATE = 'bulk update';

	public static final String ENQUIRY_FLAG_ALL = 'all';

	public static final String ENQUIRY_TYPE_ITEM_SEARCH = 'item search';
	public static final String ENQUIRY_TYPE_CALL_FOR_RETURN = 'call for return';
	public static final String ENQUIRY_TYPE_DAMAGED_REPORT = 'damaged report';
	public static final String ENQUIRY_TYPE_DELIVERY_ISSUE = 'delivery issue';
	public static final String ENQUIRY_TYPE_RTS = 'rts';
	public static final String ENQUIRY_TYPE_POD_REQUEST = 'pod request';
	public static final String ENQUIRY_TYPE_GENERAL_ENQUIRY = 'general enquiry';
	public static final String ENQUIRY_TYPE_FEEDBACK = 'feedback';
	public static final String ENQUIRY_TYPE_INVESTIGATION = 'investigation';
	public static final String ENQUIRY_TYPE_BULK_UPLOAD = 'bulk upload';
	public static final String ENQUIRY_TYPE_MAIL_REDIRECTION_HOLD = 'mail redirection/hold';
	public static final String ENQUIRY_TYPE_ADVICE_ON_SENDING_PARCELS = 'advice on sending parcels';
	public static final String ENQUIRY_TYPE_TECHNICAL_ENQUIRY= 'technical enquiry';

	// MPB ENQUIRY TYPES
	public static final String ENQUIRY_TYPE_MPB_DEL_ENQ= 'delivery enquiry';
	public static final String ENQUIRY_TYPE_MPB_LABEL_ENQ = 'label enquiry';
	public static final String ENQUIRY_TYPE_MPB_PICKUP_ENQ = 'pick up enquiry';
	public static final String ENQUIRY_TYPE_MPB_PRICING_ENQ = 'pricing enquiry';
	public static final String ENQUIRY_TYPE_MPB_OTHER_ENQ = 'other enquiry';

	public static final String ENQUIRY_TYPE_MPB_TECH_XHIST_ENQ= 'Transaction History Request';
	public static final String ENQUIRY_TYPE_MPB_TECH_ERROR_ENQ= 'Error Codes';
	public static final String ENQUIRY_TYPE_MPB_TECH_PLATINT_ENQ= 'Platform Partner Integration';
	public static final String ENQUIRY_TYPE_MPB_TECH_SYSTEM_ENQ= 'System Outage';


	public static final String ENQUIRY_TYPE_DELIVERY_ISSUE_LBL = 'Delivery Enquiry';
	public static final String ENQUIRY_TYPE_PCKUP_BOOKING_LBL = 'Pickup Booking Enquiry';
	public static final String ENQUIRY_TYPE_GENERAL_ENQUIRY_LBL = 'General Enquiry';

	public static final String ENQUIRY_SUBTYPE_MISSING_ITEM = 'Missing Item';
	public static final String ENQUIRY_SUBTYPE_DAMAGED_MISSING_CONTENTS = 'Damaged/Missing Contents';
	public static final String ENQUIRY_SUBTYPE_DELIVERY_COMPLAINT = 'Delivery Complaint';
	public static final String ENQUIRY_SUBTYPE_RTS_REQUEST = 'RTS Request';
	public static final String ENQUIRY_SUBTYPE_DISPUTED_DELIVERY = 'Disputed delivery';

	public static final String SELECT_OPTION_VALUE_ALL = '';
	public static final String SELECT_OPTION_LABEL_ALL_BILL_ACCOUNT = 'All billing account enquiries';
	public static final String SELECT_OPTION_LABEL_ALL_BILL_ACCOUNT_REPORTS = 'All';
	public static final String SELECT_OPTION_VALUE_YOU = 'you';
	public static final String SELECT_OPTION_LABEL_YOU = 'You';
	public static final String SELECT_OPTION_VALUE_DIFFERENT_SENDER = 'different';
	public static final String SELECT_OPTION_LABEL_DIFFERENT_SENDER = 'Different sender';
	public static final String SELECT_OPTION_VALUE_ALL_ORG_ENQ = 'all';
	public static final String SELECT_OPTION_LABEL_ALL_ORG_ENQ = 'All organisation enquiries';
	public static final String SELECT_OPTION_VALUE_ALL_ORG_OPEN_ENQ = 'all-org-open';
	public static final String SELECT_OPTION_LABEL_ALL_ORG_OPEN_ENQ = 'All organisation open enquiries';
	public static final String SELECT_OPTION_VALUE_MY_ENQ = 'my';
	public static final String SELECT_OPTION_LABEL_MY_ENQ = 'My enquiries';
	public static final String SELECT_OPTION_VALUE_5_ENQ = '5';
	public static final String SELECT_OPTION_LABEL_5_ENQ = '5 Enquiries';
	public static final String SELECT_OPTION_VALUE_10_ENQ = '10';
	public static final String SELECT_OPTION_LABEL_10_ENQ = '10 Enquiries';
	public static final String SELECT_OPTION_VALUE_15_ENQ = '15';
	public static final String SELECT_OPTION_LABEL_15_ENQ = '15 Enquiries';
	public static final String SELECT_OPTION_VALUE_20_ENQ = '20';
	public static final String SELECT_OPTION_LABEL_20_ENQ = '20 Enquiries';
	public static final String SELECT_OPTION_LABEL_ALL_TYPE_ENQ = 'All enquiry types';
	public static final String SELECT_OPTION_VALUE_ALL_TYPE_ENQ = 'all';

	/**
	 * New variables for filtering enquiries for last n days
	 */
	public static final String SELECT_OPTION_VALUE_LAST30DAYS_ENQ = '30';
	public static final String SELECT_OPTION_LABEL_LAST30DAYS_ENQ = 'Last 30 Days';
	public static final String SELECT_OPTION_VALUE_LAST60DAYS_ENQ = '60';
	public static final String SELECT_OPTION_LABEL_LAST60DAYS_ENQ = 'Last 60 Days';
	public static final String SELECT_OPTION_VALUE_LAST90DAYS_ENQ = '90';
	public static final String SELECT_OPTION_LABEL_LAST90DAYS_ENQ = 'Last 90 Days';
	public static final String SELECT_OPTION_VALUE_ALLDAYS_ENQ = 'all';
	public static final String SELECT_OPTION_LABEL_ALLDAYS_ENQ = 'All Days';

	public static final String SELECT_OPTION_DEFAULT_SELECT = 'Select';
	public static final String SELECT_OPTION_ACT = 'ACT';
	public static final String SELECT_OPTION_NSW = 'NSW';
	public static final String SELECT_OPTION_NT = 'NT';
	public static final String SELECT_OPTION_QLD = 'QLD';
	public static final String SELECT_OPTION_SA = 'SA';
	public static final String SELECT_OPTION_TAS = 'TAS';
	public static final String SELECT_OPTION_VIC = 'VIC';
	public static final String SELECT_OPTION_WA = 'WA';

	/** MPB Case Sub type Start**/
	public static final String SELECT_OPTION_MPB_LABEL_ENQ_REFUND = 'Request a refund';
	public static final String SELECT_OPTION_MPB_LABEL_ENQ_LABEL_SUPPORT = 'Label Support';

	public static final String SELECT_OPTION_MPB_PICKUP_ENQ_PICKUP_FAILURE = 'Pick Up Failure';
	public static final String SELECT_OPTION_MPB_PICKUP_ENQ_GENERAL = 'General';
	public static final String SELECT_OPTION_MPB_PICKUP_ENQ_CHANGE_REQUEST= 'Change Request';

	public static final String SELECT_OPTION_MPB_DEL_ENQ_TRACKING = 'Tracking status';
	public static final String SELECT_OPTION_MPB_DEL_ENQ_DISPUTE = 'Disputed Delivery';
	public static final String SELECT_OPTION_MPB_DEL_ENQ_MISSING = 'Missing item';
	public static final String SELECT_OPTION_MPB_DEL_ENQ_DAMAGED = 'Damaged item';
	public static final String SELECT_OPTION_MPB_DEL_ENQ_RETURN = 'Return to Sender';

	public static final String SELECT_OPTION_MPB_PRICING_ENQ_DISCOUNT = 'Band Discount Enquiry';
	public static final String SELECT_OPTION_MPB_PRICING_ENQ_SEND_VOL = 'Sending Volume Enquiry';
	public static final String SELECT_OPTION_MPB_PRICING_ENQ_DISPUTED = 'Disputed Payment';
	public static final String SELECT_OPTION_MPB_PRICING_ENQ_MORE_INFO = 'More Pricing Information';
	/** MPB Case Sub type End**/

	public static final String PICKLIST_VALUE_DEFAULT_PLEASE_SELECT = 'Please select';
	public static final String PICKLIST_VALUE_DEFAULT_ALL_STATUS = 'All Status';

	public static final String SOURCE_SYSTEM_TEAM = 'TEAM';
	public static final String SOURCE_SYSTEM_PEOPLESOFT = 'PeopleSoft';
	public static final String SOURCE_SYSTEM_SAP_ERP = 'SAP ERP';

	public static final String ACCOUNT_TYPE_STARTRACK = 'StarTrack';
	public static final String ACCOUNT_TYPE_AUSPOST = 'AusPost';
	public static final String ACCOUNT_TYPE_ALL = 'All';

	public static final String ENQUIRY_TYPE_AUPOST = 'Australia Post';
	public static final String ENQUIRY_TYPE_STARTRACK = 'StarTrack';
	public static final String ENQUIRY_TYPE_AP = 'auspost';
	public static final String ENQUIRY_TYPE_ST = 'startrack';

	public static final String CONSEARCH_TYPE_AUPOST = 'AusPost';
	public static final String CONSEARCH_TYPE_STARTRACK = 'StarTrack';

	public static final String AUTH_SCOPE_ALL = 'ALL';
	public static final String AUTH_SCOPE_ST = 'ST';
	public static final String AUTH_SCOPE_AP = 'AP';

	public static final String CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY = 'StarTrack Delivery Enquiry';
	public static final String CASE_RECORD_TYPE_DELIVERY_ENQUIRY = 'Delivery Enquiry';
	public static final String CASE_RECORD_TYPE_STARTRACK_GENERAL_ENQUIRY = 'StarTrack General Enquiry';
	public static final String CASE_RECORD_TYPE_GENERAL_ENQUIRY = 'General Enquiry';
	public static final String CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY = 'StarTrack Pickup Booking Enquiry';
	public static final String CASE_RECORD_TYPE_PICKUP_BOOKING_ENQUIRY = 'Pickup Booking Enquiry';
	public static final String CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME = 'Enterprise_Credit_Dispute_Claim';

	public static final String CASE_TYPE_INVESTIGATION = 'Investigation';

	public static final String CASE_RESOLUTION_CODE_CUSTOMER_SELF_SERVICE = 'Customer – Self service';

	public static final String CASE_PRODUCT_CATEGORY_INT_PARCELS = 'International Parcels';
	public static final String CASE_PRODUCT_CATEGORY_DOM_PARCELS = 'Domestic Parcels';
	public static final String CASE_PRODUCT_CATEGORY_INT_LETTERS = 'International Letters';
	public static final String CASE_PRODUCT_CATEGORY_DOM_LETTERS = 'Domestic Letters';

	public static final String CASE_ORIGIN_BSP = 'BSP';
	public static final String CASE_ORIGIN_MYPOST_BUSINESS = 'MyPost Business';
	public static final String CASE_ORIGIN_BSP_BULK_UPLOAD = 'BSP Bulk Upload';

	public static final String CASE_PRIORITY_LOW = 'Low';
	public static final String CASE_PRIORITY_MEDIUM = 'Medium';

	public static final String CASE_STATUS_INPROGRESS = 'In Progress';
	public static final String CASE_STATUS_ACTION = 'Action Required';
	public static final String CASE_STATUS_RESOLVED = 'Resolved';
	public static final String CASE_STATUS_CLOSED = 'Closed';
	public static final String CASE_STATUS_WAITINGONCUST = 'Waiting on customer';
	public static final String CASE_STATUS_AWAITINGCUSTRES = 'Awaiting Customer Response';
	public static final String APPROVAL_REMOVED = 'Removed';
	public static final String ASC_DIR = 'ASC';
	public static final String DESC_DIR = 'DESC';
	public static final String SORTBY_ARTNAME = 'ArticleName';
	public static final String SORTBY_SENDINGTO = 'SendingTo';
	public static final String SORTBY_STATUS = 'Status'; //added for REQ1496210
	public static final String SORTBY_CREATEDDATE = 'CreatedDate'; //added for REQ1496210
	public static final String SORTBY_ENQUIRY = 'Enquiry'; //added for REQ1496210

	public static final String CASE_CCU_SERVICE_USED_EPARCEL = 'eParcel';
	public static final String CASE_CCU_ENQUIRY_TYPE_BULK_UPLOAD = 'Bulk Upload';
	public static final String CASE_CCU_ENQUIRY_TYPE_ITEM_SEARCH = 'Item Search';

	public static final String FIELD_API_NAME_ENQUIRY_TYPE = 'MPB_BSP_Enquiry_Type__c';
	public static final String FIELD_API_NAME_TECH_ENQUIRY_TYPE = 'MPB_BSP_Tech_Enquiry_Type__c';
	public static final String FIELD_API_NAME_CCU_ENQUIRY_TYPE = 'CCUEnquiryType__c';
	public static final String FIELD_API_NAME_ARTICLE_TYPE = 'ArticleType__c';
	public static final String FIELD_API_NAME_CCU_SERVICE_USED = 'CCUServiceUsed__c';
	public static final String FIELD_API_NAME_CCU_ITEM_CONTENTS = 'CCUItemContents__c';

	public static final String KEYWORD_PARCEL = 'parcel';
	public static final String KEYWORD_INTERNATIONAL = 'international';
	public static final String KEYWORD_ECI = 'eci';
	public static final String KEYWORD_LETTER = 'letter';
	public static final String KEYWORD_ECONOMY = 'economy';
	public static final String KEYWORD_GLOBAL = 'global';

	public static final String ATTACHMENT_CONTENT_TYPE_CSV = 'csv';
	public static final String ATTACHMENT_NAME_BULK_UPLOAD_CSV = 'Bulk Upload.csv';

	public static final String LIMIT_ERROR = 'Limit Error';
	public static final String TECH_ERROR = 'Tech Error';
	public static final String COLUMN_ERROR = 'Column Error';
	public static final String CSV_ERROR = 'CSV Error';
	public static final String FILE_ERROR = 'File Error';
	public static final String NOFILE_ERROR = 'NoFile Error';

	public static final String ENQ_FLD_SUBJECT = 'Subject';
	public static final String ENQ_FLD_CON_NUM = 'Consignment Number';
	public static final String ENQ_FLD_DESC = 'Description';
	public static final String ENQ_FLD_PURPOSE = 'Purpose';
	public static final String ENQ_FLD_BILL_ACC_NO = 'Billing Account Number';
	public static final String ENQ_FLD_PCKUP_BKNG_REF_NO = 'Pickup Booking Reference Number';

	public static final String CON_SEARCH_TYPE_CONSIGNMENT = 'CONSIGNMENT';
	public static final String CON_SEARCH_TYPE_UNIQEXTID = 'UNIQUEEXTERNALID';

	public static final String RESP_ERR_CODE_CALLOUT_EXP = 'CalloutException';

	public static final String CON_NO_INVALID_CHAR_ERR = 'Invalid character entered in Consignment Number: ';
	public static final String CON_NO_INVALID_SIZE_ERR = 'Invalid Consignment Number length.';

	public static final String CASE_CLOSE_SELECT_MSG = 'Please select Case/s to Close.';
	public static final String CASE_UPDATE_SELECT_MSG = 'Please select Case/s to Update.';
	public static final String CASE_ADDCOMMENT_MSG = 'Please input comment.';
	public static final String CASE_ADDCOMMENT_SUCCESS_MSG = 'Comments successfully added!';

	public static final String PICKUP_BOOKING_QUEUE_NAME = 'StarTrack Pickup Booking';
	public static final String TYPE_QUEUE ='Queue';

	public static final String OBJ_CASE = 'Case';

	public static final String METHOD_PROCESS_DELIVERY_ENQ = 'processDeliveryEnquiryCreation';

	public static final String CREATE_ENQ_MSG_CON_NOT_FOUND = 'StarTrack-ConsignmentNotFound';
	public static final String CREATE_ENQ_MSG_MULT_CON = 'StarTrack-MultipleConsignment';
	//public static final String CREATE_ENQ_MSG_NOT_AUTH = 'StarTrackbsp-NotAutorized';
	public static final String CREATE_ENQ_MSG_NOT_AUTH = 'StarTrack-NotAutorized';

	public static final String MSG_KEY_CON_NUM = '<consignment_number>';

	public static final String NEXT_FLIGHT_PREM_EXPRESS = 'StarTrack (Next Flight Premium & Express)';
	public static final String PICKUPREFNUM_ERROR = 'Pickup Booking Reference Number should contain digits only. Minimum length is 7 and maximum length is 8.';
	public static final String TIBCO_ENDPOINTURL = 'TIBCO_EM';
	public static final String SUCCESS = 'Success';

	public static final String ERROR_NOT_AUTHORISED_PAGE = 'Not-Authorised-Page';
	public static final String ERROR_NO_RESULTS = 'No-Results';
	public static final String ERROR_NO_RESULTS_TRACKING_DETAILS = 'No-Results-Tracking-Id';
	public static final String ERROR_CREATE_ENQUIRY_INVALID_TRACKING_ENQUIRY_COMBO = 'Create-Enquiry-Combo-Invalid';
	public static final String ERROR_CREATE_ENQUIRY_NOT_AUTHORISED = 'Create-Enquiry-Not-Authorised';

	public static final String BSP_COMMUNITY_URL_PREFIX = 'bsp';
	public static final String BSP_PREMIUM_RETURN_EXPRESS = 'Returns Premium Express';
	public static final String BSP_PREMIUM_EXPRESS_RETURN_SIGNATURE = 'Returns Premium Express + Signature';
	public static final String BSP_PREMIUM_EXPRESS_SIGNATURE= 'Premium Express + Signature';
	public static final String BSP_PREMIUM_EXPRESS_PARCEL = 'Premium Express';

	/**
	 * @description A special custom permission that is set on users with the profile BSP Community User or users with the permission set 'BSP_Community_Access' to determine whether a user can access BSP or not
	 * Using a custom permission to check access allows us to catch both permission set and profile scenarios
	 */
	@TestVisible
	public static final Boolean CURRENT_USER_CAN_ACCESS_BSP {
		get {
			if(CURRENT_USER_CAN_ACCESS_BSP == null) {
				CURRENT_USER_CAN_ACCESS_BSP = FeatureManagement.checkPermission(BSP_COMMUNITY_CUSTOM_PERMISSION_NAME);
			}
			return CURRENT_USER_CAN_ACCESS_BSP;
		}
		private set;
	}

	/**
	 * @description Determines whether or not the current transaction occurring is in the context of the BSP Community or not
	 */
	@TestVisible
	public static Boolean CURRENT_USER_IS_VIEWING_BSP {
		get {
			if(CURRENT_USER_IS_VIEWING_BSP == null) {
				if(CCUSettings__c.getInstance().CommunityId__c != null) {
					CURRENT_USER_IS_VIEWING_BSP = Id.valueOf(CCUSettings__c.getInstance().CommunityId__c) == CURRENT_COMMUNITY_ID;
				} else {
					CURRENT_USER_IS_VIEWING_BSP = false;
				}
			}
			return CURRENT_USER_IS_VIEWING_BSP;
		}
		private set;
	}

	/**
	 * @description Determines whether the user is inside a community or not (irrespective of whether it's BSP or not)
	 * NOTE: This always return false if there is no community context (Network.getNetworkId() returns null)
	 */
	@TestVisible
	public static final Boolean HAS_NETWORK_CONTEXT {
		get {
			if(HAS_NETWORK_CONTEXT == null) {
				HAS_NETWORK_CONTEXT = CURRENT_COMMUNITY_ID != null;
			}
			return HAS_NETWORK_CONTEXT;
		}
		private set;
	}

	/**
	 * @description Grabs the community id of the current logged in user
	 * This is necessary to use a property to wrap getNetworkId since getNetworkId returns null in a testing context
	 */
	@TestVisible
	private static final Id CURRENT_COMMUNITY_ID {
		get {
			if(CURRENT_COMMUNITY_ID == null) {
				CURRENT_COMMUNITY_ID = Network.getNetworkId();
			}
			return CURRENT_COMMUNITY_ID;
		}
		private set;
	}

}