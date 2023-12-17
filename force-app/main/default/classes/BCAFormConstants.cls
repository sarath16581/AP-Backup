/**
* @description	   : BCAFormController helper class
* @author			: avula.jansirani@auspost.com.au
* @group			 : 
* @last modified on  : 06-09-2021
* @last modified by  : ankur.gandhi@auspost.com.au
* Modifications Log 
* Ver   Date		 Author							   Modification
* -------------------------------------------------------------------------
* 1.0   29-03-2021  avula.jansirani@auspost.com.au   Initial Version
* 2023-05-05	Naveen Rajanna	REQ3184691	changed api version and added new constant for custom settings DIGITAL_ID_IS_PRODUCTION
**/
public with sharing class BCAFormConstants {

	public static final String UNDER_MAINTENANCE = 'Under Maintenance';
	public static final String NETWORK_FILTER = 'Network_Filter';
	public static final String DIGITAL_ID_CLIENT_ID = 'Digital Id Client Id';
	public static final String DIGITAL_ID_CLIENT_SECRET = 'Digital Id Client Secret';
	public static final String DIGITAL_ID_URL = 'Digital Id URL';
	public static final String DIGITAL_ID_IS_PRODUCTION = 'Digital Id Is Production';

	public static final String BCA_SKIP_VALIDATION = 'BCA Skip Validation';
	public static final String BCA_ABN_DETAILS_KEY = 'BCA_ABN_DETAILS';
	public static final String ASIC_REPORT = 'asicReport';
	public static final String ABR_REPORT = 'abrReport';


	public static final String CREDIT_LIMIT_TIMES = 'Credit_Limit_Times';
	public static final String MINIMUM_CREDIT_AMOUNT = 'Minimum_Credit_Amount';
	public static final String SUMMARY_TC_DOWNLOAD_URL = 'Summary_TC_Download_URL';
	public static final String SUMMARY_PRIVACY_NOTICE_URL = 'Summary_Privacy_Notice_URL';
	public static final String DIRECT_DEBIT_TC_DOWNLOAD_URL = 'DirectDebit_TC_Download_URL';
	public static final String CREDIT_AMOUNT_ROUND_NEAREST = 'Credit_Limit_Round_Nearest';

	public static final String ENTITY_TYPE_TRUST = 'TRUST';
	public static final String ENTITY_TYPE_GOVERNMENT = 'GOVT';
	public static final String ENTITY_TYPE_PARTNERSHIP = 'PARTNERSHIP';
	public static final String ENTITY_TYPE_BUSINESS = 'BUSINESS';
	public static final String ENTITY_TYPE_OTHER_INCORPORATED = 'OTHER_INCORPORATED';
	public static final String ENTITY_TYPE_INDV = 'INDV';
	
	public static final String CREDIT_ASSESSMENT_STATUS_REFERRED = 'Referred';
	public static final String CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED = 'Auto-Approved';
	public static final String CREDIT_ASSESSMENT_STATUS_REJECTED = 'Rejected';
	public static final String CREDIT_ASSESSMENT_STATUS_WORK_IN_PROGRESS = 'Work-In-Progress';
	public static final String CREDIT_ASSESSMENT_STATUS_APPROVED = 'Approved';
	
   // public static final String CREDIT_ASSESSMENT_REFERRED_MSG_TO_APPLICANT = 'The application is in review/in progress';
	//public static final String CREDIT_ASSESSMENT_AUTO_APPROVED_MSG_TO_APPLICANT = 'The application is created and auto approved successfully';
	
	public static final String CREDIT_ASSESSMENT_RECEIVED_STATUS_TO_APPLICANT = '<h1 class=\'slds-text-align_center\'>Application received</h1>';
	public static final String CREDIT_ASSESSMENT_SUCCESSFUL_STATUS_TO_APPLICANT = '<h1 class=\'slds-text-align_center\'>Application successful</h1>';
	public static final String CREDIT_ASSESSMENT_ERROR_STATUS_TO_APPLICANT = '<h1 class=\'slds-text-align_center\'>Something went wrong.</h1>';
	
	public static final String CREDIT_ASSESSMENT_INSERTION_SUCCESS = 'success';
	public static final String CREDIT_ASSESSMENT_INSERTION_FAILURE = 'error';
	
	public static final String DUPLICATE_ORG_REASON = 'Organisation Name/ABN/ACN Match with Older Customer Organisation';
	public static final String TRUST_REFERRAL_REASON = 'Veda Entity type is Trust';
	public static final String PARTNERSHIP_REFERRAL_REASON = 'Veda Entity type is Partnership';
	public static final String HOTLISTED_CUSTOMER_REFERRAL_REASON = 'Hotlisted Customer';
	public static final String PREVIOUS_C_A_REJECTED_REFERRAL_REASON = 'Credit Assessment has been previously rejected.';
	public static final String CREDIT_SUSPECT_REFERRAL_REASON = 'Credit Suspect Match';

	public static final String ASSESSMENT_INITIATION_TYPE_ONLINE = 'Online';
	
	public static final String MESSAGE_HEADER_TO_USER_HAVING_EXISTING_BILLING_ACCOUNT = 'You\'ve already got an account';
	public static final String MESSAGE_BODY_TO_USER_HAVING_EXISTING_BILLING_ACCOUNT = '<p>It looks like you\'ve already got a Business Credit Account with Australia Post. Please contact your account manager for more information, or refer to your invoice for your credit officer\'s details.</p><br/> <p> Otherwise, email us at <b>newcreditaccount@auspost.com.au</b> for further assistance.</p>';
	
	public static final String MESSAGE_HEADER_TO_USER_HAVING_EXISTING_CREDIT_ASSESMENT = 'You\'ve already applied';
	public static final String MESSAGE_BODY_TO_USER_HAVING_EXISTING_CREDIT_ASSESMENT = '<p>It looks like you\'ve already submitted an application for a Business Credit Account. Check your email inbox (including your junk folder) for application updates.</p><br/> <p> If you don\'t hear from us in 5 business days, contact <b>newcreditaccount@auspost.com.au</b> for further assistance.</p>';

	public static final String CREDIT_ASSESSMENT_AUTO_APPROVED_MSG_TO_APPLICANT = '<p class=\'slds-text-align_center\'>Customer reference number: <xxxxxx> </p> <br/> <p class=\'slds-text-align_center\'>Congratulations you\'ve successfully created an Australia Post Business Credit Account.</p> <br/> <p class=\'slds-text-align_center\'> We\'ve sent a confirmation email to <b><CONTACT_EMAIL> </b> with all the important things, including *****.</p>';
	public static final String CREDIT_ASSESSMENT_REFERRED_MSG_TO_APPLICANT = '<p class=\'slds-text-align_center\'>Customer reference number: <xxxxxx> </p> <br/> <p class=\'slds-text-align_center\'> Thanks for submitting your details.</p> <br/> <p class=\'slds-text-align_center\'> Our team is reviewing your application and will email <b><CONTACT_EMAIL> </b> with an update soon. Check your inbox (including your junk folder) for updates.</p>';  
	//public static final String MESSAGE_BODY_TO_USER_FOR_ERROR_IN_CREDIT_ASSESMENT_CREATION = '<p class=\'slds-text-align_center\'>You\'ve come across a temporary technical issue.<br/>Try again later or contact the <a href=\'https://auspost.com.au/help-and-support\'><u><b>help and support</b></u></a> if you continue to experience issues</p>';
	public static final String MESSAGE_BODY_TO_USER_FOR_ERROR_IN_CREDIT_ASSESMENT_CREATION = '<p class=\'slds-text-align_center\'>It looks like we weren\'t able to complete your Business Credit Application form. Please try again later, or visit <a href=\'https://auspost.com.au/help-and-support\'><u><b>help and support</b></u></a> for assistance</p>';
   
	public static final String ERROR = 'error';
	public static final String OK = 'ok';
	public static final String NO_RESULTS = 'no results';
	
	public static final String CREDIT_LIMIT_GREATER_THAN_FIFTY_K_REASON = 'Proposed credit limits greater than $50k are referred to credit team for assessment';
	
	public static final Integer EQUIFAX_TIME_OUT_IN_SECONDS = 120;
	public static final INTEGER EQUIFAX_MAX_APPROVED_CREDIT_LIMIT =50000;
	
	public static final String SUMMARY_PDF_FILE_NAME ='bcaAppSummary';
	public static final String INTEGRATION_STATUS_REQUESTED = 'Requested';

	public static final String CREDIT_SUSPECT_MATCH_THRESHOLD = 'Credit Suspect Match Threshold';
	public static final String FAIL_REASON_CREDIT_SUSPECT = 'Credit suspect identified in the application';

	public static final String BCASETTING_AUTO_APPROVAL_MAX_CREDIT_LIMIT = 'Auto_Approval_Max_Credit_Limit';
	public static final String BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD = 'Credit Suspect Match Threshold';
}