/**
  * @author	   : nandan.narasappa@auspost.com.au
  * @date		 : 01/09/2015
  * @description  : UTIL Class for saving constant values used across classes for SSSW.
  * @changelog
  * 01.08.2016  DYU	 Updated - Add Constants for MyPost Business AccountSource
  * 06.09.2016  Eric Shen  Add constact for processSnapitMissingItem
  * 24.03.2019  Ramtej.Juloori@auspost.com.au   Added method name insertCaseTeamMembersForChildCase
  * 02.04.2019  Rajesh Punjabi Added new constants for Five (5) days SLA Callback Requests. 
  * 21.05.2019  Rajesh Punjabi for Smart Forms.
  * 01.05.2019  disha.kariya@auspost.com.au Added Constant for Network Triggers 
  * 18.11.2019  saiswetha.pingali@auspost.com.au MW0003819
  * 2020-04-22  - Nathan Franklin - Commenting out unused code
  * 22.03.2021  Suman Gunaganti Added new constants for eParcel damage instructions
  * 15.04.2021  Naveen Rajanna Added new constants for case locality and case originator
  * 15.06.2021  Hara Sahoo Added new constants for case reopen queue
  * 16.08.2021  alex.volkov@auspost.com.au Added a constant for Network Queue developer name
  * 10.09.2021  hara.sahoo@auspost.com.au Added constants for Compensation statuses
  * 16.05.2022   SaiSwetha Pingali  Removed snapIt logic as it is no longer required.
  * 20.03.2023	- Noel Lim - added constants SSSW_AGENT_PROFILE, SSSW_SOCIAL_INTEGRATION_PROFILE, SSSW_BSP_COMMUNITY_USER_PROFILE
  * 27.03.2023 StephenL added constant: RECTYPE_ARTICLE_CONSIGNMENT
  * 13.06.2024 Parveen Kaushik Added new constants for Enquiry Mapping object to identify model type.
  * 10.07.2024 Vasu Gorakati Added new constant SSSW_ENTITLEMENT
  * 19-07-2024 - Ranjeewa Silva - Added constants for new SSSWRouting record type (UnifiedRouting) and new customer service agent profile name.
  */  
public with sharing class SSSWConstants {

	// NOT USED
	//public static final String CASE_PROFILES_ALLOWED_TO_CLOSE = 'DDC Consumer Community User,BSP Community User';
	
	/*** SLA constants ***/
	public static final Double SLA_HOURS_TO_MS_UNIT = 0.000000277778333;
	
	/*** Callback Request (Callback_Request__c) Object ***/
	public static final String CALLBACK_REQUEST_STATUS_NEW = 'New';
	public static final String CALLBACK_REQUEST_STATUS_OPEN = 'Open';
	public static final String CALLBACK_REQUEST_STATUS_CLOSED = 'Closed';
	public static final String CALLBACK_REQUEST_STATUS_CASE_UNRESOLVED = 'Case Unresolved';
	public static final String CALLBACK_REQUEST_STATUS_VOICEMAIL = 'Voicemail';
	public static final String CALLBACK_REQUEST_STATUS_NO_VOICEMAIL = 'No Voicemail';
	public static final String CALLBACK_REQUEST_STATUS_ASSIGNED = 'Assigned';
	public static final Set<String> CALLBACK_REQUEST_STATUS_RE_EXECUTION = new Set<String> {CALLBACK_REQUEST_STATUS_CASE_UNRESOLVED,CALLBACK_REQUEST_STATUS_VOICEMAIL,CALLBACK_REQUEST_STATUS_NO_VOICEMAIL};
	public static final Set<String> CALLBACK_REQUEST_STATUS_ALL_CLOSED = new Set<String> {CALLBACK_REQUEST_STATUS_CLOSED};
	 

	/*** Case Object ***/
	public static final String CASE_SLA_STATUS = 'Awaiting Network Response';
	public static final String CASE_TYPE = 'General Enquiry';
	public static final String CASE_ORIGIN = 'Phone';
	public static final String CASE_PRIORITY = 'Low';
	public static final String CASE_PROD_CAT = 'Domestic Parcels';
	public static final String CASE_PROD_SUB_CAT = 'Cash on Delivery';
	public static final String CASE_STATUS_CLOSED = 'Closed';
	public static final String CASE_STATUS_INPROGRESS = 'In Progress';
	public static final String CASE_STATUS_NEW = 'New';
	public static final String CASE_TYPE_INVESTIGATION  = 'Investigation';
	public static final String CASE_ENQUIRY_SUBTYPE = 'Disputed delivery scan';
	public static final String CASE_LOCALITY_DOMESTIC = 'Domestic';
	public static final String CASE_ORIGINATOR_ADDRESSEE = 'Addressee';
	
	/*** @author: rajesh.punjabi@mav3rik.com MyNetworkSmartForm Contants (Case Object)*/
	public static final String CASE_PRIORITY_HIGH = 'High';
	public static final String CASE_ORIGIN_INTERNAL_FORM = 'Internal Form';
	public static final Boolean CASE_IS_NEW_FOR_ROUTING = true;
	public static final String COMPENSATION_RT = 'Retail_Compensation';
	public static final String CASE_RT_SSSW_DELIVERY = 'SSSWDelivery';
	public static final Double COMPENSTATION_VALUE = 150.0;
	public static final String CASE_RESOLUTION_CODE =  'MyNetwork Resolution';
	public static final String CASE_RESOLUTION_RESULT_DAMAGES_MISSING_CONTENTS = 'Damaged & Missing Contents';
	public static final String CASE_TYPE_OF_DAMAGE_WINE_DAMAGE = 'Wine Damage';
	
	//Queues List
	public static final String QUEUE_NAME_SSSWNETWORKQUEUE = 'SSSW Network Queue'; 
	public static final String QUEUE_NAME_CALLBACKREQUEST = 'Callback Request Queue';
	public static final String QUEUE_NAME_REOPEN_Q='SSSW_Awaiting_Reopen';
	public static final String QUEUE_DEV_NAME_SSSWNETWORKQUEUE='SSSWNetworkQueue';
	
	/*** Variables to hold Class constants ***/
	public static final String SSSW_APP = 'SSSW';
	
	/*** CaseTriggerHelper Constants  ***/
	public static final String CASE_TRIGGER = 'CaseTrigger'; 
	public static final String CASE_INVESTIGATION_TRIGGER = 'CaseInvestigationTrigger'; 
	public static final String QUEUE_CHILDCASE_DEV = 'SSSWChildCases'; 
	public static final String STAT_CHILD_CASE_UPDATE = 'Child Case Update'; 
	public static final String RECTYPE_ACON_ALLCASE = 'Authorised Contact - All Cases';
	public static final String RECTYPE_ACON_CASEONLY = 'Authorised Contacts - Case Only';
	
	public static final String METH_UPDATEHLC = 'updateHLC'; 
	public static final String METH_COMP_MILESTONE = 'completeMilestone'; 
	public static final String METH_UPDATE_PARENT_CASE = 'updateParentCase';
	
	/*** CaseSharingUtility Constants  ***/
	public static final String PON_ROLE = 'SSSW PON';
	public static final String CONT_TYPE_IMAGE = 'image/png';
	public static final String SIGNATURE = 'Signature';
	public static final String HYPHEN = '-';
	public static final String PNG_FORMAT = '.png';
	
	public static final String METH_HANDLE_MBRS = 'handleCaseTeamMembers'; 
	public static final String METH_CREATE_SIGNATURE = 'createSignatureAttachments';
	public static final String METH_HANDLE_MBRS_CHILD_CASE = 'insertCaseTeamMembersForChildCase';
	
	/*** CaseCommonUtility Constants  ***/
	public static final String STAT_CLOSED = 'Closed';
	public static final String STAT_ON_HOLD = 'On Hold';
	public static final String NPS_CUTOFF_CUST_SETTING = 'NPSCutOffDate';
	public static final Integer NPS_CUTOFF_DAYS = 7;
	public static final String STAT_CUSTOMER_RESPONDED = 'Customer Responded';
	
	public static final String METH_ASSIGN_CONTACT = 'assignContactIDToCase'; 
	public static final String METH_VALIDATE_CASE = 'validateCase'; 
	public static final String METH_DETECT_SPAM = 'detectPermanentSpam'; 
	public static final String METH_CLOSE_CHILD_CASE = 'closeChildCases'; 
	public static final String METH_XFER_CASE = 'setOwnerToCurrentUser'; 
	public static final String METH_LINK_ARTICLE = 'linkCaseToArticles'; 
	public static final String METH_AVOID_CUST_CLOSE = 'avoidCustomerClose'; 
	public static final String METH_SUBSCRIBE_ARTICLE = 'setArticlesSubscribed';
	public static final String METH_CHECK_NPS_SOCIAL = 'checkOriginChangeForNPS'; 
	public static final String METH_ROUTE_CASE = 'routeCase'; 
	public static final String METH_PARENT_ROUTING = 'updateParentForRouting';
	public static final String METH_UPDATE_MANAGER_HIERARCHY = 'updateHierarchyManager';
	
	/*** CaseMilestoneUtility Constants  ***/
	public static final Decimal DEF_MILESTONE_WARNING_PERCENT = 0.2;
	public static final String STAT_COMPLETED = 'Completed';
	public static final String STAT_AWAITING_CUST_RESPONSE = 'Awaiting Customer Response';
	public static final String STAT_AWAITING_NTWRK_RESPONSE = 'Awaiting Network Response';
	public static final String CHARTER_MILESTONE = 'Charter';
	public static final String FCR_MILESTONE = 'First Customer Response';
	public static final String CUSTOMER_TIER = 'Customer Tier';
	public static final String NETWORK_TIER = 'Network Tier';
	public static final String CUSTOMER_MILESTONE_LIKE = 'Customer Tier%';
	public static final String NETWORK_MILESTONE_LIKE = 'Network Tier%';
	public static final String SUBJ_EMAIL = 'Email: ';
	public static final String SUBJ_NETWORK = ': Network Milestone ';
	public static final String SUBJ_INTERNAL = ': Internal Milestone ';
	public static final String SUBJ_CUSTOMER = ': Customer Milestone ';
	public static final String SUBJ_NOTIFICATION = ' email notification has been sent';
	public static final String FIRST_CUSTOMER_RESPONSE = 'First Customer Response';
	
	public static final String STATIC_BLOCK = 'staticBlock'; 
	public static final String METH_INSERT_MILESTONES = 'insertMilestones';
	public static final String METH_UPDATESLA = 'updateSLA';	
	public static final String METH_SETSLA = 'setSLA';	
	public static final String METH_SETESCALATION = 'setEscalationMail';
	public static final String METH_UPDATE_MILESTONES = 'updateMilestones';
	public static final String METH_FUTURE_UPDATE = 'futureUpdate';
	
	public static final String NTWRK_SOQL = 'SELECT Email_1__c,Email_2__c,Email_3__c,Email_4__c,Email_5__c' + 
												' FROM Network__c WHERE Id IN: usrOrNtwrkIds LIMIT : rowLimit';
	public static final String USR_SOQL = 'SELECT Email,Manager.Email,Manager.Manager.Email ' +
												' FROM User WHERE Id IN: usrOrNtwrkIds LIMIT : rowLimit';
	
	/*** Utility Constants  ***/
	public static final String METH_GETGROUPID = 'getGroupId';
	public static final String METH_GETGROUPS = 'getGroups';
	public static final String METH_GETGROUP_DETAILS = 'getGroupDetails';
	public static final String METH_GETUSERS = 'getUsers';	
	public static final String METH_GET_STD_ENTITLEMENT = 'getStandardEntitlement';	
	public static final String PERCENT = '%';
	public static final String ENTITLEMENT_ACC = 'SSSW Entitlements';	

	/*** SSSW Routing ***/
	public static final String RECTYPEROUTING = 'SSSWRouting';
	public static final String RECTYPENPS = 'SSSWNPS';
	public static final String RECTYPEESCALATION = 'SSSWEscalation';
	public static final String RECTYPEDESCRIPTION = 'SSSWDescription';
	public static final String SSSWROUTING_RECTYPE_UNIFIEDROUTING = 'UnifiedRouting';
	
	/*** CaseTrackingHelper Constants  ***/
	public static final String WHITE_SPACE = ' ';
	public static final String EMPTY_SPACE = '';
	public static final String SEMI_COLON = ';';
	public static final String OWNER = 'Owner';
	public static final String STATUS = 'Status';
	public static final String FLD_NETWORK = 'Network__c';
	public static final String FLD_Owner = 'OwnerId';
	public static final String QUEUE = 'QUEUE';
	public static final String FLD_NAME = 'Name';
	public static final String FLD_TZKEY = 'TimeZoneSidKey';
	public static final String DEF_TZKEY = 'Australia/Sydney';
	public static final String RECTYPE_ST_GENERAL = 'SSSW General';
	public static final String RECTYPE_CASE_FAX = 'SSSW Fax';	
	public static final String STAT_TRACK_FORMAT = 'dd-MM-yyyy hh:mm:ss a';
	public static final String STAT_NETWORK_RESPONDED = 'Network Responded';
	
	public static final String METH_INSERT_TRACKING = 'insertCaseStatusTracking';
	public static final String METH_UPDATE_TRACKING = 'updateCaseStatusTracking';
	public static final String METH_SET_TRACKING = 'setStatusTracking';
	public static final String METH_DEL_CASEFAX = 'deleteCaseForFax';
	
	
	/*** CaseOpportunityUtility Constants  ***/
	public static final String RECTYPE_CASE_SALES_MANAGER = 'Sales Manager Review Exception';
	
	public static final String METH_UPDATE_OPC = 'updateOPCUnderReviewBySalesManagerFlag';
	public static final String METH_UPDATE_OPPDriver = 'updateOpportunityDriver';
	
	/*** Contacts Constants  ***/
	public static final String SBS_ONLINE = 'SBsub_online'; 
	public static final String SBS_RETAIL = 'SBSub_Retail'; 
	public static final String OBJECT_NAME = 'Contact';
	
	/*** Networks Constants  ***/
	public static final String NETWORK_MANAGER_UPDATE = 'updateNetworkManagerOnLicence';
	
	/*** FacilitySearch Constants  ***/
	public static final String NETWORK_EMAIL = 'customerenquiry@auspost.com.au';
	public static final String MSG_CONTACT_NETWORK_PREFIX = 'Error: ';
	
	public static final String METH_CONTACT_EMAIL = 'contactViaEmail';
	public static final String METH_GENERATE_EMAILCONTENT = 'generateEmailContent';
	
	/*** ShareInformationController Constants  ***/
	public static final String METH_CREATE_SHAREINFO = 'createShareInfoActivity';
	
	/*** CaseCommentTriggerHelper Constants  ***/
	public static final String CASECOMMENT_TRIGGER = 'CaseCommentTrigger';
	public static final String METH_CHECK_NPS = 'checkNPS';
	public static final String METH_COMPLETE_FCR = 'completeFirstCustomerResponse'; 
	
	/*** PM26Form Constants ***/
	public static final String SEC_CON_FIRSTNAME = 'Secondary Contact First Name'; 
	public static final String FIRSTNAME = 'First Name'; 
	public static final String SEC_CON_LASTNAME = 'Secondary Contact Last Name'; 
	public static final String LASTNAME = 'Last Name'; 
	public static final String ADDRE_ADD1 = 'Sender Address 1'; 
	public static final String ADD1 = 'Address Line 1'; 
	public static final String ADDRE_ADD2 = 'Addressee Address 2'; 
	public static final String ADD2 = 'Address Line 2'; 
	public static final String ADDRE_SUB = 'Addressee Address Suburb'; 
	public static final String SUBURB = 'Suburb'; 
	public static final String ADDRE_STATE = 'Addressee Address State'; 
	public static final String STATE = 'State'; 
	public static final String ADDRE_COUNTRY = 'Addressee Address Country';											  
	public static final String COUNTRY = 'Country';
	public static final String ADDRE_POSTCODE = 'Addressee Address Postcode';
	public static final String POSTCODE = 'Post Code';				  
	public static final String ADDRE_EMAIL = 'Addressee Email';
	public static final String EMAIL = 'Email';
	public static final String PHONE = 'Phone';   
	public static final String DAMAGE_TYPE = 'Type of Damage'  ;
	public static final String DEF_PRD_TYPE = 'Investigation|Domestic Parcels';
	public static final String DEF_COUNTRY = 'Australia';
	public static final String SEL_PRD_CAT_FRST = 'Select Product Category First';
	public static final String SEL_PRD_CAT = 'Select Product Category';
	public static final String NONE = '--None--';
	public static final String INVEST_PRD_TYPE = 'Investigation';
	public static final String INTERNATIONAL_TYPE = 'International';
	public static final String NEW_LINE = '\n';
	public static final String SEL_PRD_SUB_CAT = 'Select Product Sub Category';
	public static final String DMG_TYPE1 = 'Packaging only'; 
	public static final String DMG_TYPE2 = 'Contents – repairable';
	public static final String DMG_TYPE3 = 'Contents – not repairable';
	public static final String DMG_TYPE4 = 'Contents missing – evidence of tampering';
	public static final String DMG_TYPE5 = 'Contents missing – no evidence of tampering';
	public static final String DMG_TYPE6 = 'Damaged after delivery';
	public static final String PM26_ENQ_SUB_TYPE = 'Damaged/Missing contents';
	public static final String PM26_ORIGIN = 'Internal form';
	public static final String COMMA_SEP = ',';
	public static final String HYPHEN_SPACED = ' - ';
	public static final String EXCEPTION_MSG = 'Please check the data entered or contact your system administrator.';
	public static final String CLASSNAME = 'PM26_CustomerComplaintFormContrExt';
	public static final String REQD_FIELD_MSS = 'Please fill in all required values';   
	
	/*** START MyPostBusinessLeadConvert Constants 27/07/2016  ***/
	public static final String METH_CONVERT_LEAD = 'convertLead';
	public static final String METH_CONVERT_LEAD_PC = 'convertLeadPersonAccount';
	public static final String CONTACT_TRIGGER = 'ContactTrigger'; 
	public static final String ACCOUNT_TRIGGER = 'AccountTrigger'; 
	public static final String NETWORK_TRIGGER = 'NetworkTrigger';
	/*** END MyPostBusinessLeadConvert Constants 27/07/2016  ***/
	
	/*** START OF UPDATE DYU MPB 01-AUG-2016 - MyPost Business AccountSource ***/
	public static final String MPB_ACCOUNT_SOURCE = 'MyPost Business';
	/*** END OF UPDATE DYU MPB 01-AUG-2016 ***/
	
	/*** START OF Account Trigger Optimization Constants -- eugene ***/
	public static final String OPP_LINE_ITEM = 'OpportunityLineItem';
	public static final String OPP_ID = 'OpportunityId';
	public static final String ACC_OBJ_TYPE = 'Account';
	public static final String LEGACY_ID = 'Legacy_Id__c';
	public static final String OPP_OBJ_TYPE = 'Opportunity';
	public static final String OPP_NUMBER = 'Opportunity_Number__c';
	public static final String OPP_ITEM_NUMBER = 'Opportunity_Item_Number__c';
	public static final String LEAD_NUMBER = 'Lead_Number__c';
	/*** END OF Account Trigger Optimization Constants ***/
	
	/*** START OF SSSW Send Bulk EMail Constants -- kalpita ***/
	public static final String CASE_OBJ = 'Case';
	public static final String CASE_RECTYPE_LIKE = 'SSSW%';
	public static final String CASE_STATUS = 'New';
	public static final String ORGWIDEEMAIL = 'customerservice@auspost.com.au';
	public static final String TASK_SUB = 'Email: Australia Post – Case';
	public static final String TASK_INT_TYPE = 'SSSW Bulk Emails';
	public static final String GENERAL_ENQUIRY = 'General Enquiry';
	public static final String Investigation = 'Investigation';
	public static final String Feedback = 'Feedback';
	public static final String CLOSE = 'Close';
	public static final String EMAIL_SUBJECT = 'Australia Post-No Reply';
	public static final String DEFAULT_TASKS  =  'Default_Taks' ;
	/*** END OF SSSW Send Bulk EMail Constants -- kalpita ***/
	
	/*** Default Email Template Class ***/
	public static final String SSSW_Default = 'SSSW_Default';
	
	/*** SSSW PON Update Class ***/
	public static final String SSSW_Generic = 'Generic';
	public static final String CLOSE_CONTAINSCHECK = 'Closed';
	public static final String NETWORK_RESP_OBJ = 'Network_Response__c';
	public static final String NETWORK_RESP_STATUSSET = 'Network Responded';
	public static final String DISPUTED_DELIVERY = 'Disputed Delivery Scan';
	public static final String OWADDR_CUST_SERVICE = 'customerservice@auspost.com.au';
	//public static final String OWADDR_CUST_SERVICE = 'customerservice@s-2ik1tldbiz5koa6ciw7acag7yd3neqfh7wqk98f15ee3mc6fr1.5d-18wbuaa.cs72.case.sandbox.salesforce.com';
	/**SSSW Compensation Constants **/
	public static final String STATUS_APPROVED_AWAITING_CUSTOMER = 'Approved Awaiting Customer';
	public static final String STATUS_APPROVED = 'Approved';

	/*** User Profiles ***/
	public static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
	public static final String SSSW_SOCIAL_INTEGRATION_PROFILE = 'SSSW Social Integration';
	public static final String SSSW_BSP_COMMUNITY_USER_PROFILE = 'BSP Community User';
	public static final String UNIFIED_AGENT_PROFILE = 'CustomerService';

	/*** Omnichannel Constants ***/
	public static final String OMNI_AGENTWORK_STATUS_OPENED = 'Opened';
	public static final String OMNI_AGENTWORK_STATUS_DECLINED = 'Declined';
	public static final String OMNI_AGENTWORK_STATUS_DECLINED_ONPUSHTIMEOUT = 'DeclinedOnPushTimeout';
	public static final String OMNI_AGENTWORK_STATUS_UNAVAILABLE = 'Unavailable';

	/* ExceptionCheckerService Constants*/
	public static final String RECTYPE_ARTICLE_CONSIGNMENT = 'Consignment';

	/*** Enquiry Mapping Constants ***/
	public static final String ENQUIRYMAPPING_UNIFIED_MODEL = 'Unified';
	public static final String ENQUIRYMAPPING_CLASSIC_MODEL = 'Classic';

	public static final String SSSW_ENTITLEMENT = 'Standard Entitlement';
}