/**************************************************
Description:    Utility class to capture global values
History:
--------------------------------------------------
SEPT.21.2015 Fahad Akhtar - Modified
October 5, 2015 - Patrick James Franco - Removed unused Completed task status
August 22, 2016 - David Catindoy - Added new constant variables.
April 06, 2017 - Andrew Judd - Add new constant for Contact Type = Sender
October 02, 2017 - Angelo Rivera - Added for Minor Work MWT0004521
2018-05-27  nathan.franklin@auspost.com.au Add Delivery Enquiry Developer Name constant
2018-06-21  nathan.franklin@auspost.com.au Adding values for non transactional IVR exclusions (CCTR/CTI Project)
2020-04-22 - Nathan Franklin - Removing unused code
2021-09-09 - Steve Judd - Added values for MW0004540
2022-02-22  naveen.rajanna@auspost.com.au - Added constants for REQ2723199
2022-11-23 - Mahesh Parvathaneni - Addded constants for StarTrack Agent and Care agent
2023-02-15 - naveen.rajanna@auspost.com.au - REQ3072620 Added constants for Web Bookings Queue, ETA Queue and renamed labels
2023-07-18 - mel.patil2@auspost.com.au - REQ3247592 renamed label for StarTrack Recycle Bin to CRM Recycle Bin
**************************************************/
public class StarTrack_Constants {

    // NOT USED
    //public static final String BSP_PROFILENAME = 'BSP Community User';

    public static final String ID_PREFIX_CASE = '500';
    public static final Boolean hideSSCR5 = StarTrack_Settings__c.getOrgDefaults().Hide_SSCR5_Changes_for_AP_User__c;
    public static final String ST_CASE_AUTOCLOSE_CUST_PERM = 'StarTrack_Autoclose_Case_from_Task';

    public static final Set<String> CONSIGN_SUMSTATUS = new Set<String>{'Notified', 'Picked Up', 'In Transit', 'Delivered', 'Partially Picked Up', 'Partially Delivered', 'Partially On Forwarded', 'On Forwarded'};
    public static final Set<String> ARTICLE_ADDRESS_FIELDS = new Set<String>{'SenderCompany__c', 'SenderName__c', 'SenderAddress__c', 'Sender_Suburb__c', 'SenderState__c', 'SenderPostcode__c', 'ReceiverCompany__c', 'ReceiverName__c', 'ReceiverAddress__c', 'Receiver_Suburb__c', 'ReceiverState__c', 'ReceiverPostcode__c'};
    public static final String TASK_TYPE_OPERATION = 'Operations Task';
    public static final Boolean ST_TRUE = true;
    public static final Boolean ST_FALSE = false;
    public static final String TASK_TYPE_REMINDER = 'Reminder';
    public static final String TASK_STATUS_NOTSTARTED = 'Not Started';
    public static final String TASK_STATUS_WAITING = 'Waiting for Operations';
    public static final String TASK_STATUS_ACKNOWLEDGED = 'Acknowledged';
    public static final String TASK_STATUS_FINISHED = 'Finished';
    public static final String TASK_STATUS_FINISHED_RESOLVED = 'Finished - Case Resolved'; //27-08-2021 SJudd - Added for Minor Work MW0004540
    public static final String TASK_STATUS_COMPLETED = 'Completed';
    public static final String TASK_STATUS_REJECTED = 'Rejected';
    public static final String TASK_INTERACTION = 'Phone';
    public static final String TASK_TYPE_PHONE = 'Phone Call';
    public static final String TASK_NA = 'None Identified';
    public static final String TASK_RECTYPE_ACTIVITY = 'StarTrack Activity';
    public static final String TASK_RECTYPE_OPERATION = 'StarTrack Task';
    public static final String Global_NA = 'N/A';
    public static final String GLOBAL_NONE = '--None--';
    public static final String GLOBAL_NO = 'No';
    public static final String TASK_RESOLUTION_CODE = StarTrack_Settings__c.getOrgDefaults().StarTrack_Default_Task_Resolution_Code__c;
    public static final String TASK_PRIORITY_NORMAL = 'Normal';
    public static final Integer LIMITBY = 10;
    public static final String NETWORK_PREFMETHOFTASKING_PARENT = 'Parent Depot';
    public static final String NETWORK_PREFMETHOFTASKING_SYSTEM = 'System';
    public static final String NETWORK_PREFMETHOFTASKING_EMAIL = 'Email';
    public static final String NETWORK_PREFMETHOFTASKING_PHONE = 'Phone';
    public static final String NETWORK_PREFMETHOFTASKING_FAX = 'Fax';
    public static final String CASE_RESOLUTION_DUPLICATE = 'Closed - Duplicate';
    public static final String CASE_RES_DEF = 'System Closed';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_STATUS_INVESTIGATION = 'Awaiting Investigation';
    public static final String CASE_STATUS_WAITINGOPERATIONS = 'Waiting on operations';
    public static final String CASE_STATUS_WAITINGONCUSTOMER = 'Waiting on customer';
    public static final String CASE_UPDATE_CUSTOMERRESP = 'Customer Responded';
    public static final String CASE_UPDATE_OPERATIONSRESP = 'Operations Responded'; //10-02-2017 APRivera - Added for Minor Work MWT0004521
    public static final String TASK_SUBTYPE_MASSTASKING = 'Operations - Mass Tasking';
    public static final String TASK_SUBTYPE_SINGLETASKING = 'Operations - Single Tasking';
    public static final String WFE_STATUS_OPEN = 'Open';
    public static final String WFE_STATUS_CLOSE = 'Closed';
    public static final String TASK_UPDATE_REASSIGN = 'Reassign';
    public static final String DEPOTAREA_AREA_BRANCHMANAGEMENT = 'Management';
    public static final String RECORDTYPE_DEPOT_METRO = 'StarTrack_Metro_9';
    public static final String RECORDTYPE_DEPOT_REGIONAL = 'StarTrack_Regional_10';
    public static final String RECORDTYPE_DEPOT_AGENT = 'StarTrack_Agent_11';
    public static final String RECORDTYPE_DEPOT_CARE_AGENT = 'StarTrack_Care_Agent_12';
    public static final String TASK_DEPOT_FILTER_ALL_STATE = 'All by State';
    public static final String VALIDATION_REQUIRE_FIELD_VALUE = 'Please provide a value.';
    public static final String TASK_VALIDATION_RESOLUTION_CODE = 'Resolution Code is required when status is set to \'Finished\'.';
    public static final String CASE_PURPOSE_PICKUPETA = 'Pickup ETA';
    public static final String CASE_PURPOSE_MISSEDPICKUP = 'Missed Pickup';
    public static final String CASE_PURPOSE_CONTROLLEDRETURN = 'Controlled Returns';
    public static final String CASE_PURPOSE_DEF = 'Other';
    public static final String CASE_PURPOSE_LATEDELIVERY = 'Late Delivery';
    public static final String CASE_ENQUIRY_REDELIVERY = 'Redelivery';
    public static final String CASE_ENQUIRY_REDIRECTION = 'Redirection';
    public static final String CASE_ENQUIRY_DEPOTCOLLECTION = 'Depot Collection';
    public static final String CASE_PURPOSE_DEPOTCREATED = 'Depot Created'; //10-02-2017 APRivera - Added for Minor Work MWT0004521
    public static final String CASE_RESOLUTIONCODE_INVCOMPLETED = 'Resolved - Investigation Completed'; //10-02-2017 APRivera - Added for Minor Work MWT0004521
    public static final String CASE_RESOLUTIONCODE_REDIRECTED = 'Resolved - Redirected'; //27-08-2021 SJudd - Added for Minor Work MW0004540
    public static final String CASE_RESOLUTIONCODE_DEPOTCOLLECTION = 'Resolved - Depot Collection'; //27-08-2021 SJudd - Added for Minor Work MW0004540
    public static final String CASE_TYPE_DAMAGED = 'Damaged'; //10-02-2017 APRivera - Added for Minor Work MWT0004521
    public static final String CASE_ENQUIRY_LDC = 'LDC';
    public static final String CASE_ENQUIRY_DEF = 'Other';
    public static final String CASE_DELIVERY_RT = 'Delivery Enquiry';
    public static final String CASE_DELIVERY_DEVNAME_RT = 'StarTrack_PUD_Enquiry';
    public static final String CASE_PBE_RT = 'Pickup Booking Enquiry';
    public static final String CASE_CREDIT_RT = 'Credit Dispute Claim';
    public static final String CASE_VOCINC_RT = 'Voice of Customer Incident';
    public static final String CASE_VOC_RT = 'Voice of Customer Enquiry';
    public static final String CASE_TWC_RT = 'Transit Warranty Claim';
    public static final String CASE_VOCINC_RT_DEV = 'StarTrack_Voice_of_Customer_Incident';
    public static final String CASE_VOC_RT_DEV = 'StarTrack_Voice_of_Customer';
    public static final String CASE_DELIVERY_RT_DEV = 'StarTrack_PUD_Enquiry';
    public static final String CASE_TWC_RT_DEV = 'StarTrack_Transit_Warranty_Claim';
    public static final String CASE_CREDIT_RT_DEV = 'StarTrack_Credit_Dispute_Claim';
    public static final String CASE_PBE_RT_DEV = 'StarTrack_Pickup_Booking_Enquiry';

    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CASE_ORIGIN_EMAIL = 'Email';
    public static final String CASE_ORIGIN_PHONE = 'Phone';
    public static final String CASE_ORIGIN_BSC = 'Email - BSC';
    public static final String MOBILE_PREFCONTACT_METHOD = 'Mobile';
    public static final String CASE_STAT_CLOSED = 'Closed';
    public static final String CASE_STAT_REOPENED = 'Reopened';
    public static final String CASE_STAT_AWAITINGREVIEW = 'Awaiting Review';
    public static final String CASE_STAT_AWAITINGAPPROVAL = 'Awaiting Approval';
    public static final String CASE_STAT_INTEGRATION = 'Waiting on Integration';
    public static final String CASE_STAT_CLOSEDEXP = 'Closed - Expired';
    public static final String CASE_STAT_CLOSEDCV = 'Closed - Customer Viewed';
    public static final String CASE_STAT_CLOSED_PEN = 'Closed - Pending';
    public static final String CASE_STAT_PENCUSNOTIF = 'Pending Customer Notification';
    public static final String CASE_APPROVALSTAT_PENDING = 'Pending';
    public static final String CASE_DIRECTION_IN = 'Inbound';
    public static final String CASE_CONTYPE_RECEIVER = 'Receiver';
    public static final String CASE_CONTYPE_INITIAL = 'Initial';
    public static final String CASE_CONTYPE_SENDER = 'Sender';
    public static final String DEPOTAREA_AREA_DRIVERCONTACT = 'Driver Contact';
    public static final String DEPOTAREA_AREA_OPERATIONS = 'Operations';
    public static final String OPS_NEWTASK_VIA_EMAIL = 'StarTrack_Send_task_email_alert_from_workflow_email_alert_object';
    public static final String OPS_CLOSETASK_VIA_EMAIL = 'StarTrack_Send_task_completed_email_alert';
    public static final String STCUSTOMERSTREAM_RUBY = 'Ruby';
    public static final String TRANSFER_QUEUE = 'Transfer Queue';
    public static final String DEPOT_OWNER_QUEUE = 'Depot Owner Queue';
    public static final String RECYCLE_BIN_QUEUE = 'CRM Recycle Bin';
    public static final String WEB_BOOKINGS_QUEUE = 'StarTrack Pickup Enquiry Queue';
    public static final String ETA_QUEUE = 'StarTrack ETA Request Queue';
    public static final String ST_NETWORK_CUST_NOTIF = 'StarTrack Network Customer Notification';
    public static final String ST_EVENT_TYPE = 'DELIVERED'; 
    public static final String ST_SCAN_TYPE = 'Label'; 
    public static final String CON_LASTUP_TYPE = 'FULL';
    public static final String CON_REC_TYPE = 'Consignment';
    public static final String CASE_ACTCLOSED = 'Close Case';
    public static final String CASE_ACTSENDEMAIL = 'Send Email';
    public static final String CASE_ACTCOMMENT = 'Create Case Comment';
    public static final String CASE_ACTSENDNOTIF = 'Send Notification';
    public static final String CASE_ACT_REJECTAPPROVAL = 'Reject Approval';
    public static final String CASE_ACT_UPDATESTAT = 'Update Status';
    public static final String TASK_ACTFINISHED = 'Close Task';
    public static final String WF_ACTCLOSED = 'Close WF Email';
    public static final String CASE_STARTRACK_RECTYPE = 'StarTrack';
    public static final String CALLLOG_PREFIX = ' Call: ';
    public static final String INBOUND_CALLLOG_PREFIX = 'Inbound Call:';
    public static final String OUTBOUND_CALLLOG_PREFIX = 'Outbound Call:';
    public static final String OUTBOUND_CALLLOG = 'Outbound';
    public static final String FAILED_TASK = 'Encountered an error while updating this record in bulk.';
    public static final String WAITING_ON_INVESTIGATOR = 'Waiting on Investigator';
    public static final String INVESTIGATOR_RESPONDED = 'Investigator Responded';
    public static final String PROFILE_ST_SUPPORT = 'StarTrack Support';
    public static final String ID_PREFIX_TASK = '00T';
    public static final String FEED_ITEM_TYP_TEXTPOST = 'TextPost';
    public static final String FEED_COMM_TYP_TXTCOMM = 'TextComment';
    public static final String CON_STAT_ACTIVE = 'Active';
    public static final String CONTACT_TYPE = 'StarTrack Service';
    public static final String SUB_REJECTAPPROVAL_COMMENT = 'Rejected automatically via subscription model.';
    public static final String REJECT_APPROVAL = 'Reject';
    public static final String SUCCESS_COMMENT = 'Subscription Automation success for Case Action ';
    public static final String CASECLOSE_SUCCESS_COMMENT = 'Subscription Automation success for Case Action Close Case. \n\n Consignment Summary Status - <ConsignSumStat> \n Number of PODs - <NumofPODs> \n Number of Delivery Events - <NumofEvents> \n' +
                                                            'Case Record Type - <CaseRecType> \n Case Type - <CaseType> \n Case Purpose - <CasePurpose> \n Case Status - <CaseStat> \n Is POD Required to Close Case for the Billing Account? - <IsPODReq>';
    public static final String FAILURE_COMMENT = 'Subscription Automation not processed for Case Action ';
    public static final String ID_FIELD = 'Id';
    public static final String PRIORITY_NORMAL = 'Normal';
    public static final String PRIORITY_HIGH = 'High';
    public static final String PRIORITY_URGENT = 'Urgent';
    public static final String PRIORITY_CRITICAL = 'Critical';
    public static final String DUPLICATE_CASE = 'DUPLICATE CASE-';
    public static final String DUPLICATE_EMAIL = StarTrack_Settings__c.getOrgDefaults().ST_Duplicate_Inbound_Email_Prefix__c;
    public static final String PREMIUM = 'Premium';
    public static final String EXPRESS = 'Express';
    public static final String CREDITCLAIM_INVSUBJECT = '001-00';
    public static final String SYSTEM_SUPPORT_USER = 'System Support';
    public static final String DEPOTAREA_REQUIRED = 'Depot Area: Value is required.';
    public static final String ADD_CONTACT = 'Add Contact';
    public static final String ADD_NEW_CONTACT = '+Add New Contact';
    public static final String STRELCONT_RT = 'StarTrack Related Contact';
    public static final String SUBAUTO_RULEFUNC = 'StarTrack Subscription Automation';
    public static final String NOTIFAUTO_RULEFUNC = 'StarTrack Notification Automation';
    public static final String SMSTEMP_CASENUMBER = '<Case Number>';
    public static final String SMSTEMP_CONSIGNNUMBER = '<Consign Number>';
    public static final String rePrefix = 'Re: ';
    public static final String rePrefix2 = 'RE: ';
    public static final String forwardPrefix1 = 'Fw: ';
    public static final String forwardPrefix3 = 'FW: ';
    public static final String forwardPrefix2 = 'Fwd: ';
    public static final String forwardPrefix4 = 'FWD: ';
    public static final String KEYWRD_SUBJECT_PREFIX_REF = 'ref:_';
    public static final String KEYWRD_SUBJECT_SUFFIX_REF = ':ref';
    
    //StarTrack_Case_ConsignSearch_Controllerx.cls constants
    public static final String STARTRACK = 'StarTrack';
    public static final String CUSTOM = 'Custom';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String BASIC = 'Basic ';

    public static final String DATEFORMAT = 'yyyyMMdd';
    public static final String DATETIMEFORMAT = 'YYYYMMddHHmmss';
    public static final String DATETIMEFORMATTZ = 'yyyy-MM-dd\'T\'HH:mm:ss.SSSZ';

    public static final String SOURCEID_SALESFORCE = 'Salesforce';
    public static final String ACTION_SEARCH = 'Search';

    public static final String REQUEST_ACTION_FULL = 'FULL';
    public static final String REQUEST_ACTION_SUMMARY = 'SUMMARY';

    public static final String TYPE_UNIQUEEXTERNALID = 'UNIQUEEXTERNALID';
    public static final String TYPE_CONSIGNMENT = 'CONSIGNMENT';

    public static final String METHOD_PROCESSSEARCHCONSIGNMENT = 'processSearchConsignment';
    public static final String METHOD_SEARCHCONSIGNMENT = 'searchConsignment';
    public static final String METHOD_PROCESSCREATECASE = 'processCreateCase';
    public static final String METHOD_CREATECASE = 'createCase';
    public static final String METHOD_PROCESSASSIGNTOCASE = 'processAssignToCase';
    public static final String METHOD_ASSIGNTOCASE = 'assignToCase';

    public static final String CLASS_CONSIGNSEARCH = 'StarTrack_Case_ConsignSearch_ControllerX';

    public static final String ERROR = 'ERROR';
    public static final String CALLOUTEXCEPTION = 'CalloutException';
    public static final String DMLEXCEPTION = 'DmlException';
    public static final String EXCEPTION_KYWRD = 'Exception';

    public static final String ERR_KEYWRD_COULDNOTFINDCLIENTCERT = 'Could not find client cert with dev name';
    public static final String ERR_KEYWRD_TIMEOUT = 'Time out';
    public static final String ERR_KEYWRD_FAILEDTOGETELEM = 'Failed to get next element';
    public static final String ERR_KEYWRD_POLICYFALSIFIED = 'Policy Falsified';
    
    public static final String ERR_CODE_0 = '0';
    public static final String ERR_CODE_ART_NOT_FOUND = 'Article Not Found';

    public static final String KEYWRD_SEARCHCONSIGNTIMEOUT = 'Search Consignment Timeout';
    public static final String KEYWRD_ERRCONSIGNSEARCH = 'Error on Consignment search';
    public static final String KEYWRD_ERRCREATECASE = 'Error on Case create';
    public static final String KEYWRD_ERRUPDATECASE = 'Error on Case update';
    public static final String KEYWRD_ENTERDATES = 'Enter dates';
    public static final String KEYWRD_DATEVALIDATION = 'date validation';
    public static final String KEYWRD_DATEDIFFERENCE = 'date diffrence';
    public static final String KEYWRD_DATEDURERROR = 'date duration error';
    public static final String KEYWRD_NOOFSEARCHCHAR = 'Number of search characters';
    public static final String KEYWRD_NOOFCHARERR = 'Number of character error';
    public static final String KEYWRD_SUBURBERR = 'Suburb error';
    public static final String KEYWRD_SPECIALCHARS = 'Special Characters';
    public static final String SPECIALCHARS = '(?!^)';
    public static final String KEYWRD_INVALIDCHARERR = 'Invalid character error';
    public static final String KEYWRD_NOSELECTEDCONSIGN = 'No selected Consignment';
    public static final String KEYWRD_CASECREATETIMEOUT = 'Case Create Timeout';
    public static final String KEYWRD_SIGXSTRING = 'Signature XString: data value too large';
    public static final String KEYWRD_ASSIGNCONTIMEOUT = 'Assign Consignment Timeout';
    public static final String KEYWRD_NEWEMAILRECVD = 'New Email Received';

    //David Catindoy - Sept. 10, 2016 - Added constants for StarTrack Card Left controller.
    public static final String CASEPURPOSE_CARDLEFT = 'Card Left';
    public static final String CASEENTYPE_CHECKADDRESS = 'Check Address';
    public static final String AUTHREQUIRED = 'Sender authorisation required';
    public static final String ENQ_NO = 'enquiry No';
    public static final String ENQ_YES = 'enquiry Yes';
    public static final String ATL_NO = 'ATL No';
    public static final String ATL_YES = 'ATL Yes';
    public static final String ATL_SERVICE = 'ATL service';
    public static final String DELIVERY = 'delivery';
    public static final String CARDLEFT_SERVICE = 'service';
    public static final String SERVICETYPE_AIRLOCK = 'Airlock';
    public static final String ERROR_NULLCONSIGNORDEPOT = 'Network/Consignment is NULL';
    public static final String ERRORDEFMSG_NULLCONSIGNORDEPOT = 'This action cannot be performed until a consignment and receiving depot is associated to the case.';
    public static final String ERROR_MANDATORY1 = 'Mandatory Fields 1';
    public static final String ERRORMSG_MANDATORY1 = 'Business Name, Phone, Delivery/Collection Date fields should be mandatory.';
    public static final String ERROR_ADDRESSMISSING = 'Delivery Address Missing';
    public static final String ERRORMSG_ADDRESSMISSING = 'Please fill out the Delivery Address fields.';
    public static final String ERROR_MANDATORY2 = 'Mandatory Fields 2';
    public static final String ERRORMSG_MANDATORY2 = 'Phone and Delivery/Collection Date fields should be mandatory.';
    public static final String ERROR_DATENOTALLOWED = 'Past Date Not Allowed';
    public static final String ERRORMSG_DATENOTALLOWED = 'You cannot choose today\'s date or date that has passed already.';
    public static final String ERROR_DATENOTVALID = 'Delivery Date Not Valid';
    public static final String ERRORMSG_DATENOTVALID = 'The selected delivery date is either not within business hours or is a public holiday for the associated receiving depot';
    public static final String ERROR_OVERRIDEREASON = 'Blank Override Reason';
    public static final String ERRORMSG_OVERRIDEREASON = 'The override restriction reason must be filled out when selecting override.';
    public static final String ERROR_ENQUIRYTYPENOTALLOWED = 'Enquiry Type Not Allowed';
    public static final String ERRORMSG_ENQUIRYTYPENOTALLOWED = 'This customer account does not allow ';
    public static final String ERROR_ENQUIRYTYPEAUTH = 'Enquiry Type Authorization Required';
    public static final String ERROR_SERVICETYPENOTALLOWED = 'Service Type Not Allowed';
    public static final String ERRORMSG_ERVICETYPENOTALLOWED = 'This freight service type does not allow for a ';
    public static final String ERROR_ATLSERVICENOTALLOWED = 'Service Type Not Allowed ATL';
    public static final String ERRORMSG_ATLSERVICENOTALLOWED = 'This freight service type does not allow authority to leave requests.';
    public static final String ERROR_ATLAUTH = 'ATL Sender Authorization Required';
    public static final String ERROR_ATLNOTALLOWED = 'ATL Not Allowed';
    public static final String ERRORMSG_ATLNOTALLOWED = 'This customer account does not allow Authority to leave.';
    public static final String ERROR_DELIVERYDATE1 = 'Delivery Date Warning 1';
    public static final String ERROR_DELIVERYDATE2 = 'Delivery Date Warning 2';
    public static final String ERRORMSG_BILLINGACCOUNTNULL = 'This action cannot be performed until a billing account is associated to the case.';
    public static final String NORECORD_FOUND = 'No record found.';
    public static final String ERROR_EMAILISBLANK = 'Validate Caller Email';
    public static final String ERRORMSG_EMAILISBLANK = 'Email address is required if preferred method of contact is \'Email\'.';
    public static final String ERROR_PHONEISBLANK = 'Validate Caller Phone Number';
    public static final String ERRORMSG_PHONEISBLANK = 'Phone number is required if preferred method of contact is \'Phone\'.';
    public static final String ERROR_MOBILEISBLANK = 'Validate Caller Mobile Number';
    public static final String ERRORMSG_MOBILEISBLANK = 'Mobile number is required if preferred method of contact is \'Mobile\'.';
    public static final String ERROR_PREFMETHODISBLANK = 'Validate Pref Method of Contact';
    public static final String ERRORMSG_PREFMETHODISBLANK = 'Preferred Method of Contact cannot be blank if \'Notification Required\' is selected.';
    public static final String ERROR_PREFMETHODISREQUIRED = 'Pref Method of Contact Required';
    public static final String ERRORMSG_PREFMETHODISREQUIRED = 'Preferred Method of Contact is required.';
    public static final String ERRORMSG_CASECLOSED = 'Add Contact action cannot be performed when case is closed.';
    public static final String ERRORMSG_MOBILEINVALID = 'Invalid Mobile Number. Please enter 10 digits.';
    public static final String ERRORMSG_PHONEINVALID = 'Invalid Phone Number. Please enter 6 or 10 digits.';
    public static final String ERRORMSG_PHONEINVALID13 = 'Invalid Phone Number. The 6-digit phone number should start with 13.';
    public static final String ERRORMSG_CONTACTTYPE = 'Contact Type is required.';
    
    //David Catindoy - Sept. 12, 2016 - Added constants for StarTrackNoConsignmentDataPAController.
     public static final String DELIVERY_TYPE = 'Delivery Type';
     public static final String QUEUE_PREFIX = '00G';
     public static final String ERRORMSG_DELIVERYTYPE = 'Delivery Type: Value is required.';
     public static final String ERRORMSG_OWNERISQUEUE = 'Please take ownership of the case and try again.';
     public static final String ERRORMSG_LDCCASE = 'LDC case depot can no longer be changed after it entered the LDC process.';
     public static final String ERRORMSG_CONSIGNNODATA = 'You cannot edit \'No Data\' Sender and Receiver details if the associated Consignment is not a \'No Data\' Consignment.';
     
     public static final String CASEMILESTONE_CUST_FIRST_RESP ='StarTrack - Customer 1st Response';
     //Andrew Judd - 06-04-2017 - B1647 - Added constant for bspEnquiry
     public static final String CASE_CONTACT_TYPE_SENDER = 'Sender';
       
     // Madhusudhan | PBRP 2021 *** CaseTriggerHelper Constants  ***/
     public static final String CASE_TRIGGER = 'CaseTrigger';
    public static final String ASYNC_QUEUEABLE = 'Queueable';
     // a list of fields which define an IVR case as non 'transactional'
     // this is applicable to any cases with Origin of 'IVR'
     public static final Map<String, Set<String>> NON_TRANSACTIONAL_IVR_EXCLUSIONS = new Map<String, Set<String>>{
        'Call_Purpose__c' => new Set<String>{'Card Left'}
    };

    /**
     * @description A special custom permission that is set on users with with the permission set 'StarTrack_Autoclose_Case_from_Task' to determine whether a user can autoclose cases
     * Using a custom setting allows global activation.
     */
    @TestVisible
    public static final Boolean CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK {
        get {
            if (CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK == null) {
                StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
                if (stSettings.StarTrack_AutoClose_Case_from_Task__c) {
                    CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK = true;
                } else if (FeatureManagement.checkPermission('StarTrack_Autoclose_Case_from_Task')) {
                    CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK = true;
                } else {
                    CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK = false;
                }
            }
            return CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK;
        }
        private set;
    }
}