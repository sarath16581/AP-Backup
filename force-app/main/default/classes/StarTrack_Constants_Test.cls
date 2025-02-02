/**
 * @description       : Test class for StarTrack_Constants
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 **/
@IsTest
private class StarTrack_Constants_Test {

    @IsTest
    static void constantValues() {
        System.assertEquals(StarTrack_Constants.ID_PREFIX_CASE, '500');
        System.assertEquals(StarTrack_Constants.hideSSCR5, StarTrack_Settings__c.getOrgDefaults().Hide_SSCR5_Changes_for_AP_User__c);
        System.assertEquals(StarTrack_Constants.ST_CASE_AUTOCLOSE_CUST_PERM, 'StarTrack_Autoclose_Case_from_Task');
        System.assertEquals(StarTrack_Constants.TASK_TYPE_OPERATION, 'Operations Task');
        System.assertEquals(StarTrack_Constants.ST_TRUE, true);
        System.assertEquals(StarTrack_Constants.ST_FALSE, false);
        System.assertEquals(StarTrack_Constants.TASK_TYPE_REMINDER, 'Reminder');
        System.assertEquals(StarTrack_Constants.TASK_STATUS_NOTSTARTED, 'Not Started');
        System.assertEquals(StarTrack_Constants.TASK_STATUS_WAITING, 'Waiting for Operations');
        System.assertEquals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, 'Acknowledged');
        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, 'Finished');
        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED, 'Finished - Case Resolved'); //27-08-2021 SJudd - Added for Minor Work MW0004540
        System.assertEquals(StarTrack_Constants.TASK_STATUS_COMPLETED, 'Completed');
        System.assertEquals(StarTrack_Constants.TASK_STATUS_REJECTED, 'Rejected');
        System.assertEquals(StarTrack_Constants.TASK_INTERACTION, 'Phone');
        System.assertEquals(StarTrack_Constants.TASK_TYPE_PHONE, 'Phone Call');
        System.assertEquals(StarTrack_Constants.TASK_NA, 'None Identified');
        System.assertEquals(StarTrack_Constants.TASK_RECTYPE_ACTIVITY, 'StarTrack Activity');
        System.assertEquals(StarTrack_Constants.TASK_RECTYPE_OPERATION, 'StarTrack Task');
        System.assertEquals(StarTrack_Constants.Global_NA, 'N/A');
        System.assertEquals(StarTrack_Constants.GLOBAL_NONE, '--None--');
        System.assertEquals(StarTrack_Constants.GLOBAL_NO, 'No');
        System.assertEquals(StarTrack_Constants.TASK_RESOLUTION_CODE, StarTrack_Settings__c.getOrgDefaults().StarTrack_Default_Task_Resolution_Code__c);
        System.assertEquals(StarTrack_Constants.TASK_PRIORITY_NORMAL, 'Normal');
        System.assertEquals(StarTrack_Constants.LIMITBY, 10);
        System.assertEquals(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT, 'Parent Depot');
        System.assertEquals(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM, 'System');
        System.assertEquals(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL, 'Email');
        System.assertEquals(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PHONE, 'Phone');
        System.assertEquals(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_FAX, 'Fax');
        System.assertEquals(StarTrack_Constants.CASE_RESOLUTION_DUPLICATE, 'Closed - Duplicate');
        System.assertEquals(StarTrack_Constants.CASE_RES_DEF, 'System Closed');
        System.assertEquals(StarTrack_Constants.CASE_STATUS_NEW, 'New');
        System.assertEquals(StarTrack_Constants.CASE_STATUS_INVESTIGATION, 'Awaiting Investigation');
        System.assertEquals(StarTrack_Constants.CASE_STATUS_WAITINGOPERATIONS, 'Waiting on operations');
        System.assertEquals(StarTrack_Constants.CASE_STATUS_WAITINGONCUSTOMER, 'Waiting on customer');
        System.assertEquals(StarTrack_Constants.CASE_UPDATE_CUSTOMERRESP, 'Customer Responded');
        System.assertEquals(StarTrack_Constants.CASE_UPDATE_OPERATIONSRESP, 'Operations Responded'); //10-02-2017 APRivera - Added for Minor Work MWT0004521
        System.assertEquals(StarTrack_Constants.TASK_SUBTYPE_MASSTASKING, 'Operations - Mass Tasking');
        System.assertEquals(StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING, 'Operations - Single Tasking');
        System.assertEquals(StarTrack_Constants.WFE_STATUS_OPEN, 'Open');
        System.assertEquals(StarTrack_Constants.WFE_STATUS_CLOSE, 'Closed');
        System.assertEquals(StarTrack_Constants.TASK_UPDATE_REASSIGN, 'Reassign');
        System.assertEquals(StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT, 'Management');
        System.assertEquals(StarTrack_Constants.RECORDTYPE_DEPOT_METRO, 'StarTrack_Metro_9');
        System.assertEquals(StarTrack_Constants.RECORDTYPE_DEPOT_REGIONAL, 'StarTrack_Regional_10');
        System.assertEquals(StarTrack_Constants.RECORDTYPE_DEPOT_AGENT, 'StarTrack_Agent_11');
        System.assertEquals(StarTrack_Constants.RECORDTYPE_DEPOT_CARE_AGENT, 'StarTrack_Care_Agent_12');
        System.assertEquals(StarTrack_Constants.TASK_DEPOT_FILTER_ALL_STATE, 'All by State');
        System.assertEquals(StarTrack_Constants.VALIDATION_REQUIRE_FIELD_VALUE, 'Please provide a value.');
        System.assertEquals(StarTrack_Constants.TASK_VALIDATION_RESOLUTION_CODE, 'Resolution Code is required when status is set to \'Finished\'.');
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_PICKUPETA, 'Pickup ETA');
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_MISSEDPICKUP, 'Missed Pickup');
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_CONTROLLEDRETURN, 'Controlled Returns');
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_DEF, 'Other');
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_LATEDELIVERY, 'Late Delivery');
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_REDELIVERY, 'Redelivery');
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_REDIRECTION, 'Redirection');
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION, 'Depot Collection');
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_DEPOTCREATED, 'Depot Created'); //10-02-2017 APRivera - Added for Minor Work MWT0004521
        System.assertEquals(StarTrack_Constants.CASE_RESOLUTIONCODE_INVCOMPLETED, 'Resolved - Investigation Completed'); //10-02-2017 APRivera - Added for Minor Work MWT0004521
        System.assertEquals(StarTrack_Constants.CASE_RESOLUTIONCODE_REDIRECTED, 'Resolved - Redirected'); //27-08-2021 SJudd - Added for Minor Work MW0004540
        System.assertEquals(StarTrack_Constants.CASE_RESOLUTIONCODE_DEPOTCOLLECTION, 'Resolved - Depot Collection'); //27-08-2021 SJudd - Added for Minor Work MW0004540
        System.assertEquals(StarTrack_Constants.CASE_TYPE_DAMAGED, 'Damaged'); //10-02-2017 APRivera - Added for Minor Work MWT0004521
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_LDC, 'LDC');
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEF, 'Other');
        System.assertEquals(StarTrack_Constants.CASE_DELIVERY_RT, 'Delivery Enquiry');
        System.assertEquals(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT, 'StarTrack_PUD_Enquiry');
        System.assertEquals(StarTrack_Constants.CASE_PBE_RT, 'Pickup Booking Enquiry');
        System.assertEquals(StarTrack_Constants.CASE_CREDIT_RT, 'Credit Dispute Claim');
        System.assertEquals(StarTrack_Constants.CASE_VOCINC_RT, 'Voice of Customer Incident');
        System.assertEquals(StarTrack_Constants.CASE_VOC_RT, 'Voice of Customer Enquiry');
        System.assertEquals(StarTrack_Constants.CASE_TWC_RT, 'Transit Warranty Claim');
        System.assertEquals(StarTrack_Constants.CASE_VOCINC_RT_DEV, 'StarTrack_Voice_of_Customer_Incident');
        System.assertEquals(StarTrack_Constants.CASE_VOC_RT_DEV, 'StarTrack_Voice_of_Customer');
        System.assertEquals(StarTrack_Constants.CASE_DELIVERY_RT_DEV, 'StarTrack_PUD_Enquiry');
        System.assertEquals(StarTrack_Constants.CASE_TWC_RT_DEV, 'StarTrack_Transit_Warranty_Claim');
        System.assertEquals(StarTrack_Constants.CASE_CREDIT_RT_DEV, 'StarTrack_Credit_Dispute_Claim');
        System.assertEquals(StarTrack_Constants.CASE_PBE_RT_DEV, 'StarTrack_Pickup_Booking_Enquiry');
        System.assertEquals(StarTrack_Constants.CASE_ORIGIN_WEB, 'Web');
        System.assertEquals(StarTrack_Constants.CASE_ORIGIN_EMAIL, 'Email');
        System.assertEquals(StarTrack_Constants.CASE_ORIGIN_PHONE, 'Phone');
        System.assertEquals(StarTrack_Constants.CASE_ORIGIN_BSC, 'Email - BSC');
        System.assertEquals(StarTrack_Constants.MOBILE_PREFCONTACT_METHOD, 'Mobile');
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, 'Closed');
        System.assertEquals(StarTrack_Constants.CASE_STAT_REOPENED, 'Reopened');
        System.assertEquals(StarTrack_Constants.CASE_STAT_AWAITINGREVIEW, 'Awaiting Review');
        System.assertEquals(StarTrack_Constants.CASE_STAT_AWAITINGAPPROVAL, 'Awaiting Approval');
        System.assertEquals(StarTrack_Constants.CASE_STAT_INTEGRATION, 'Waiting on Integration');
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSEDEXP, 'Closed - Expired');
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSEDCV, 'Closed - Customer Viewed');
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED_PEN, 'Closed - Pending');
        System.assertEquals(StarTrack_Constants.CASE_STAT_PENCUSNOTIF, 'Pending Customer Notification');
        System.assertEquals(StarTrack_Constants.CASE_APPROVALSTAT_PENDING, 'Pending');
        System.assertEquals(StarTrack_Constants.CASE_DIRECTION_IN, 'Inbound');
        System.assertEquals(StarTrack_Constants.CASE_CONTYPE_RECEIVER, 'Receiver');
        System.assertEquals(StarTrack_Constants.CASE_CONTYPE_INITIAL, 'Initial');
        System.assertEquals(StarTrack_Constants.CASE_CONTYPE_SENDER, 'Sender');
        System.assertEquals(StarTrack_Constants.DEPOTAREA_AREA_DRIVERCONTACT, 'Driver Contact');
        System.assertEquals(StarTrack_Constants.DEPOTAREA_AREA_OPERATIONS, 'Operations');
        System.assertEquals(StarTrack_Constants.OPS_NEWTASK_VIA_EMAIL, 'StarTrack_Send_task_email_alert_from_workflow_email_alert_object');
        System.assertEquals(StarTrack_Constants.OPS_CLOSETASK_VIA_EMAIL, 'StarTrack_Send_task_completed_email_alert');
        System.assertEquals(StarTrack_Constants.STCUSTOMERSTREAM_RUBY, 'Ruby');
        System.assertEquals(StarTrack_Constants.TRANSFER_QUEUE, 'Transfer Queue');
        System.assertEquals(StarTrack_Constants.DEPOT_OWNER_QUEUE, 'Depot Owner Queue');
        System.assertEquals(StarTrack_Constants.RECYCLE_BIN_QUEUE, 'CRM Recycle Bin');
        System.assertEquals(StarTrack_Constants.ST_NETWORK_CUST_NOTIF, 'StarTrack Network Customer Notification');
        System.assertEquals(StarTrack_Constants.ST_EVENT_TYPE, 'DELIVERED'); 
        System.assertEquals(StarTrack_Constants.ST_SCAN_TYPE, 'Label'); 
        System.assertEquals(StarTrack_Constants.CON_LASTUP_TYPE, 'FULL');
        System.assertEquals(StarTrack_Constants.CON_REC_TYPE, 'Consignment');
        System.assertEquals(StarTrack_Constants.CASE_ACTCLOSED, 'Close Case');
        System.assertEquals(StarTrack_Constants.CASE_ACTSENDEMAIL, 'Send Email');
        System.assertEquals(StarTrack_Constants.CASE_ACTCOMMENT, 'Create Case Comment');
        System.assertEquals(StarTrack_Constants.CASE_ACTSENDNOTIF, 'Send Notification');
        System.assertEquals(StarTrack_Constants.CASE_ACT_REJECTAPPROVAL, 'Reject Approval');
        System.assertEquals(StarTrack_Constants.CASE_ACT_UPDATESTAT, 'Update Status');
        System.assertEquals(StarTrack_Constants.TASK_ACTFINISHED, 'Close Task');
        System.assertEquals(StarTrack_Constants.WF_ACTCLOSED, 'Close WF Email');
        System.assertEquals(StarTrack_Constants.CASE_STARTRACK_RECTYPE, 'StarTrack');
        System.assertEquals(StarTrack_Constants.CALLLOG_PREFIX, ' Call: ');
        System.assertEquals(StarTrack_Constants.INBOUND_CALLLOG_PREFIX, 'Inbound Call:');
        System.assertEquals(StarTrack_Constants.OUTBOUND_CALLLOG_PREFIX, 'Outbound Call:');
        System.assertEquals(StarTrack_Constants.OUTBOUND_CALLLOG, 'Outbound');
        System.assertEquals(StarTrack_Constants.FAILED_TASK, 'Encountered an error while updating this record in bulk.');
        System.assertEquals(StarTrack_Constants.WAITING_ON_INVESTIGATOR, 'Waiting on Investigator');
        System.assertEquals(StarTrack_Constants.INVESTIGATOR_RESPONDED, 'Investigator Responded');
        System.assertEquals(StarTrack_Constants.PROFILE_ST_SUPPORT, 'StarTrack Support');
        System.assertEquals(StarTrack_Constants.ID_PREFIX_TASK, '00T');
        System.assertEquals(StarTrack_Constants.FEED_ITEM_TYP_TEXTPOST, 'TextPost');
        System.assertEquals(StarTrack_Constants.FEED_COMM_TYP_TXTCOMM, 'TextComment');
        System.assertEquals(StarTrack_Constants.CON_STAT_ACTIVE, 'Active');
        System.assertEquals(StarTrack_Constants.CONTACT_TYPE, 'StarTrack Service');
        System.assertEquals(StarTrack_Constants.SUB_REJECTAPPROVAL_COMMENT, 'Rejected automatically via subscription model.');
        System.assertEquals(StarTrack_Constants.REJECT_APPROVAL, 'Reject');
        System.assertEquals(StarTrack_Constants.SUCCESS_COMMENT, 'Subscription Automation success for Case Action ');
        System.assertEquals(StarTrack_Constants.CASECLOSE_SUCCESS_COMMENT, 'Subscription Automation success for Case Action Close Case. \n\n Consignment Summary Status - <ConsignSumStat> \n Number of PODs - <NumofPODs> \n Number of Delivery Events - <NumofEvents> \n' + 'Case Record Type - <CaseRecType> \n Case Type - <CaseType> \n Case Purpose - <CasePurpose> \n Case Status - <CaseStat> \n Is POD Required to Close Case for the Billing Account? - <IsPODReq>');
        System.assertEquals(StarTrack_Constants.FAILURE_COMMENT, 'Subscription Automation not processed for Case Action ');
        System.assertEquals(StarTrack_Constants.ID_FIELD, 'Id');
        System.assertEquals(StarTrack_Constants.PRIORITY_NORMAL, 'Normal');
        System.assertEquals(StarTrack_Constants.PRIORITY_HIGH, 'High');
        System.assertEquals(StarTrack_Constants.PRIORITY_URGENT, 'Urgent');
        System.assertEquals(StarTrack_Constants.PRIORITY_CRITICAL, 'Critical');
        System.assertEquals(StarTrack_Constants.DUPLICATE_CASE, 'DUPLICATE CASE-');
        System.assertEquals(StarTrack_Constants.DUPLICATE_EMAIL, StarTrack_Settings__c.getOrgDefaults().ST_Duplicate_Inbound_Email_Prefix__c);
        System.assertEquals(StarTrack_Constants.PREMIUM, 'Premium');
        System.assertEquals(StarTrack_Constants.EXPRESS, 'Express');
        System.assertEquals(StarTrack_Constants.CREDITCLAIM_INVSUBJECT, '001-00');
        System.assertEquals(StarTrack_Constants.SYSTEM_SUPPORT_USER, 'System Support');
        System.assertEquals(StarTrack_Constants.DEPOTAREA_REQUIRED, 'Depot Area: Value is required.');
        System.assertEquals(StarTrack_Constants.ADD_CONTACT, 'Add Contact');
        System.assertEquals(StarTrack_Constants.ADD_NEW_CONTACT, '+Add New Contact');
        System.assertEquals(StarTrack_Constants.STRELCONT_RT, 'StarTrack Related Contact');
        System.assertEquals(StarTrack_Constants.SUBAUTO_RULEFUNC, 'StarTrack Subscription Automation');
        System.assertEquals(StarTrack_Constants.NOTIFAUTO_RULEFUNC, 'StarTrack Notification Automation');
        System.assertEquals(StarTrack_Constants.SMSTEMP_CASENUMBER, '<Case Number>');
        System.assertEquals(StarTrack_Constants.SMSTEMP_CONSIGNNUMBER, '<Consign Number>');
        System.assertEquals(StarTrack_Constants.rePrefix, 'Re: ');
        System.assertEquals(StarTrack_Constants.rePrefix2, 'RE: ');
        System.assertEquals(StarTrack_Constants.forwardPrefix1, 'Fw: ');
        System.assertEquals(StarTrack_Constants.forwardPrefix3, 'FW: ');
        System.assertEquals(StarTrack_Constants.forwardPrefix2, 'Fwd: ');
        System.assertEquals(StarTrack_Constants.forwardPrefix4, 'FWD: ');
        System.assertEquals(StarTrack_Constants.KEYWRD_SUBJECT_PREFIX_REF, 'ref:_');
        System.assertEquals(StarTrack_Constants.KEYWRD_SUBJECT_SUFFIX_REF, ':ref');
        System.assertEquals(StarTrack_Constants.STARTRACK, 'StarTrack');
        System.assertEquals(StarTrack_Constants.CUSTOM, 'Custom');
        System.assertEquals(StarTrack_Constants.AUTHORIZATION, 'Authorization');
        System.assertEquals(StarTrack_Constants.BASIC, 'Basic ');
        System.assertEquals(StarTrack_Constants.DATEFORMAT, 'yyyyMMdd');
        System.assertEquals(StarTrack_Constants.DATETIMEFORMAT, 'YYYYMMddHHmmss');
        System.assertEquals(StarTrack_Constants.DATETIMEFORMATTZ, 'yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        System.assertEquals(StarTrack_Constants.SOURCEID_SALESFORCE, 'Salesforce');
        System.assertEquals(StarTrack_Constants.ACTION_SEARCH, 'Search');
        System.assertEquals(StarTrack_Constants.REQUEST_ACTION_FULL, 'FULL');
        System.assertEquals(StarTrack_Constants.REQUEST_ACTION_SUMMARY, 'SUMMARY');
        System.assertEquals(StarTrack_Constants.TYPE_UNIQUEEXTERNALID, 'UNIQUEEXTERNALID');
        System.assertEquals(StarTrack_Constants.TYPE_CONSIGNMENT, 'CONSIGNMENT');
        System.assertEquals(StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, 'processSearchConsignment');
        System.assertEquals(StarTrack_Constants.METHOD_SEARCHCONSIGNMENT, 'searchConsignment');
        System.assertEquals(StarTrack_Constants.METHOD_PROCESSCREATECASE, 'processCreateCase');
        System.assertEquals(StarTrack_Constants.METHOD_CREATECASE, 'createCase');
        System.assertEquals(StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, 'processAssignToCase');
        System.assertEquals(StarTrack_Constants.METHOD_ASSIGNTOCASE, 'assignToCase');
        System.assertEquals(StarTrack_Constants.CLASS_CONSIGNSEARCH, 'StarTrack_Case_ConsignSearch_ControllerX');
        System.assertEquals(StarTrack_Constants.ERROR, 'ERROR');
        System.assertEquals(StarTrack_Constants.CALLOUTEXCEPTION, 'CalloutException');
        System.assertEquals(StarTrack_Constants.DMLEXCEPTION, 'DmlException');
        System.assertEquals(StarTrack_Constants.EXCEPTION_KYWRD, 'Exception');
        System.assertEquals(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT, 'Could not find client cert with dev name');
        System.assertEquals(StarTrack_Constants.ERR_KEYWRD_TIMEOUT, 'Time out');
        System.assertEquals(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM, 'Failed to get next element');
        System.assertEquals(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED, 'Policy Falsified');
        System.assertEquals(StarTrack_Constants.ERR_CODE_0, '0');
        System.assertEquals(StarTrack_Constants.ERR_CODE_ART_NOT_FOUND, 'Article Not Found');
        System.assertEquals(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT, 'Search Consignment Timeout');
        System.assertEquals(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH, 'Error on Consignment search');
        System.assertEquals(StarTrack_Constants.KEYWRD_ERRCREATECASE, 'Error on Case create');
        System.assertEquals(StarTrack_Constants.KEYWRD_ERRUPDATECASE, 'Error on Case update');
        System.assertEquals(StarTrack_Constants.KEYWRD_ENTERDATES, 'Enter dates');
        System.assertEquals(StarTrack_Constants.KEYWRD_DATEVALIDATION, 'date validation');
        System.assertEquals(StarTrack_Constants.KEYWRD_DATEDIFFERENCE, 'date diffrence');
        System.assertEquals(StarTrack_Constants.KEYWRD_DATEDURERROR, 'date duration error');
        System.assertEquals(StarTrack_Constants.KEYWRD_NOOFSEARCHCHAR, 'Number of search characters');
        System.assertEquals(StarTrack_Constants.KEYWRD_NOOFCHARERR, 'Number of character error');
        System.assertEquals(StarTrack_Constants.KEYWRD_SUBURBERR, 'Suburb error');
        System.assertEquals(StarTrack_Constants.KEYWRD_SPECIALCHARS, 'Special Characters');
        System.assertEquals(StarTrack_Constants.SPECIALCHARS, '(?!^)');
        System.assertEquals(StarTrack_Constants.KEYWRD_INVALIDCHARERR, 'Invalid character error');
        System.assertEquals(StarTrack_Constants.KEYWRD_NOSELECTEDCONSIGN, 'No selected Consignment');
        System.assertEquals(StarTrack_Constants.KEYWRD_CASECREATETIMEOUT, 'Case Create Timeout');
        System.assertEquals(StarTrack_Constants.KEYWRD_SIGXSTRING, 'Signature XString: data value too large');
        System.assertEquals(StarTrack_Constants.KEYWRD_ASSIGNCONTIMEOUT, 'Assign Consignment Timeout');
        System.assertEquals(StarTrack_Constants.KEYWRD_NEWEMAILRECVD, 'New Email Received');
        System.assertEquals(StarTrack_Constants.CASEPURPOSE_CARDLEFT, 'Card Left');
        System.assertEquals(StarTrack_Constants.CASEENTYPE_CHECKADDRESS, 'Check Address');
        System.assertEquals(StarTrack_Constants.AUTHREQUIRED, 'Sender authorisation required');
        System.assertEquals(StarTrack_Constants.ENQ_NO, 'enquiry No');
        System.assertEquals(StarTrack_Constants.ENQ_YES, 'enquiry Yes');
        System.assertEquals(StarTrack_Constants.ATL_NO, 'ATL No');
        System.assertEquals(StarTrack_Constants.ATL_YES, 'ATL Yes');
        System.assertEquals(StarTrack_Constants.ATL_SERVICE, 'ATL service');
        System.assertEquals(StarTrack_Constants.DELIVERY, 'delivery');
        System.assertEquals(StarTrack_Constants.CARDLEFT_SERVICE, 'service');
        System.assertEquals(StarTrack_Constants.SERVICETYPE_AIRLOCK, 'Airlock');
        System.assertEquals(StarTrack_Constants.ERROR_NULLCONSIGNORDEPOT, 'Network/Consignment is NULL');
        System.assertEquals(StarTrack_Constants.ERRORDEFMSG_NULLCONSIGNORDEPOT, 'This action cannot be performed until a consignment and receiving depot is associated to the case.');
        System.assertEquals(StarTrack_Constants.ERROR_MANDATORY1, 'Mandatory Fields 1');
        System.assertEquals(StarTrack_Constants.ERRORMSG_MANDATORY1, 'Business Name, Phone, Delivery/Collection Date fields should be mandatory.');
        System.assertEquals(StarTrack_Constants.ERROR_ADDRESSMISSING, 'Delivery Address Missing');
        System.assertEquals(StarTrack_Constants.ERRORMSG_ADDRESSMISSING, 'Please fill out the Delivery Address fields.');
        System.assertEquals(StarTrack_Constants.ERROR_MANDATORY2, 'Mandatory Fields 2');
        System.assertEquals(StarTrack_Constants.ERRORMSG_MANDATORY2, 'Phone and Delivery/Collection Date fields should be mandatory.');
        System.assertEquals(StarTrack_Constants.ERROR_DATENOTALLOWED, 'Past Date Not Allowed');
        System.assertEquals(StarTrack_Constants.ERRORMSG_DATENOTALLOWED, 'You cannot choose today\'s date or date that has passed already.');
        System.assertEquals(StarTrack_Constants.ERROR_DATENOTVALID, 'Delivery Date Not Valid');
        System.assertEquals(StarTrack_Constants.ERRORMSG_DATENOTVALID, 'The selected delivery date is either not within business hours or is a public holiday for the associated receiving depot');
        System.assertEquals(StarTrack_Constants.ERROR_OVERRIDEREASON, 'Blank Override Reason');
        System.assertEquals(StarTrack_Constants.ERRORMSG_OVERRIDEREASON, 'The override restriction reason must be filled out when selecting override.');
        System.assertEquals(StarTrack_Constants.ERROR_ENQUIRYTYPENOTALLOWED, 'Enquiry Type Not Allowed');
        System.assertEquals(StarTrack_Constants.ERRORMSG_ENQUIRYTYPENOTALLOWED, 'This customer account does not allow ');
        System.assertEquals(StarTrack_Constants.ERROR_ENQUIRYTYPEAUTH, 'Enquiry Type Authorization Required');
        System.assertEquals(StarTrack_Constants.ERROR_SERVICETYPENOTALLOWED, 'Service Type Not Allowed');
        System.assertEquals(StarTrack_Constants.ERRORMSG_ERVICETYPENOTALLOWED, 'This freight service type does not allow for a ');
        System.assertEquals(StarTrack_Constants.ERROR_ATLSERVICENOTALLOWED, 'Service Type Not Allowed ATL');
        System.assertEquals(StarTrack_Constants.ERRORMSG_ATLSERVICENOTALLOWED, 'This freight service type does not allow authority to leave requests.');
        System.assertEquals(StarTrack_Constants.ERROR_ATLAUTH, 'ATL Sender Authorization Required');
        System.assertEquals(StarTrack_Constants.ERROR_ATLNOTALLOWED, 'ATL Not Allowed');
        System.assertEquals(StarTrack_Constants.ERRORMSG_ATLNOTALLOWED, 'This customer account does not allow Authority to leave.');
        System.assertEquals(StarTrack_Constants.ERROR_DELIVERYDATE1, 'Delivery Date Warning 1');
        System.assertEquals(StarTrack_Constants.ERROR_DELIVERYDATE2, 'Delivery Date Warning 2');
        System.assertEquals(StarTrack_Constants.ERRORMSG_BILLINGACCOUNTNULL, 'This action cannot be performed until a billing account is associated to the case.');
        System.assertEquals(StarTrack_Constants.NORECORD_FOUND, 'No record found.');
        System.assertEquals(StarTrack_Constants.ERROR_EMAILISBLANK, 'Validate Caller Email');
        System.assertEquals(StarTrack_Constants.ERRORMSG_EMAILISBLANK, 'Email address is required if preferred method of contact is \'Email\'.');
        System.assertEquals(StarTrack_Constants.ERROR_PHONEISBLANK, 'Validate Caller Phone Number');
        System.assertEquals(StarTrack_Constants.ERRORMSG_PHONEISBLANK, 'Phone number is required if preferred method of contact is \'Phone\'.');
        System.assertEquals(StarTrack_Constants.ERROR_MOBILEISBLANK, 'Validate Caller Mobile Number');
        System.assertEquals(StarTrack_Constants.ERRORMSG_MOBILEISBLANK, 'Mobile number is required if preferred method of contact is \'Mobile\'.');
        System.assertEquals(StarTrack_Constants.ERROR_PREFMETHODISBLANK, 'Validate Pref Method of Contact');
        System.assertEquals(StarTrack_Constants.ERRORMSG_PREFMETHODISBLANK, 'Preferred Method of Contact cannot be blank if \'Notification Required\' is selected.');
        System.assertEquals(StarTrack_Constants.ERROR_PREFMETHODISREQUIRED, 'Pref Method of Contact Required');
        System.assertEquals(StarTrack_Constants.ERRORMSG_PREFMETHODISREQUIRED, 'Preferred Method of Contact is required.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_CASECLOSED, 'Add Contact action cannot be performed when case is closed.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_MOBILEINVALID, 'Invalid Mobile Number. Please enter 10 digits.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_PHONEINVALID, 'Invalid Phone Number. Please enter 6 or 10 digits.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_PHONEINVALID13, 'Invalid Phone Number. The 6-digit phone number should start with 13.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_CONTACTTYPE, 'Contact Type is required.');
        System.assertEquals(StarTrack_Constants.DELIVERY_TYPE, 'Delivery Type');
        System.assertEquals(StarTrack_Constants.QUEUE_PREFIX, '00G');
        System.assertEquals(StarTrack_Constants.ERRORMSG_DELIVERYTYPE, 'Delivery Type: Value is required.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_OWNERISQUEUE, 'Please take ownership of the case and try again.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_LDCCASE, 'LDC case depot can no longer be changed after it entered the LDC process.');
        System.assertEquals(StarTrack_Constants.ERRORMSG_CONSIGNNODATA, 'You cannot edit \'No Data\' Sender and Receiver details if the associated Consignment is not a \'No Data\' Consignment.');
        System.assertEquals(StarTrack_Constants.CASEMILESTONE_CUST_FIRST_RESP,'StarTrack - Customer 1st Response');
        System.assertEquals(StarTrack_Constants.CASE_CONTACT_TYPE_SENDER, 'Sender');
        System.assertEquals(StarTrack_Constants.CASE_TRIGGER, 'CaseTrigger');
        System.assertEquals(StarTrack_Constants.ASYNC_QUEUEABLE, 'Queueable');

        System.assert(StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.containsKey('Call_Purpose__c'));
        System.assert(StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get('Call_Purpose__c') != null);
        System.assert(StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get('Call_Purpose__c').contains('Card Left'));

        Set<String> expectedCONSIGN_SUMSTATUS = new Set<String>{'Notified', 'Picked Up', 'In Transit', 'Delivered', 'Partially Picked Up', 'Partially Delivered', 'Partially On Forwarded', 'On Forwarded'};
        for(String str: expectedCONSIGN_SUMSTATUS) {
            System.assert(StarTrack_Constants.CONSIGN_SUMSTATUS.contains(str), 'List should contain ' + str);
        }

        Set<String> expectedARTICLE_ADDRESS_FIELDS = new Set<String>{'SenderCompany__c', 'SenderName__c', 'SenderAddress__c', 'Sender_Suburb__c', 'SenderState__c', 'SenderPostcode__c', 'ReceiverCompany__c', 'ReceiverName__c', 'ReceiverAddress__c', 'Receiver_Suburb__c', 'ReceiverState__c', 'ReceiverPostcode__c'};
        for(String str: expectedARTICLE_ADDRESS_FIELDS) {
            System.assert(StarTrack_Constants.ARTICLE_ADDRESS_FIELDS.contains(str), 'List should contain ' + str);
        }

        StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
        stSettings.StarTrack_AutoClose_Case_from_Task__c = true;
        upsert stSettings;
        System.assertEquals(true, StarTrack_Constants.CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK);

    }
}