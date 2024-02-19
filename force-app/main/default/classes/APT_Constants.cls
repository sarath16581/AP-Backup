/**
Description: store string constants

Created By: Mausam Padhiyar
Created Date: 13th Aug, 2015

Last Modified By: Mausam Padhiyar
Last Modified Date: 20th Sept, 2016 | 1165 : Contract Pricing

Last Modified By: Mausam Padhiyar
Last Modified Date: 25th Oct, 2016 | 1655 : copy and version SAP Contracts

Last Modified By: Mausam Padhiyar
Last Modified Date: 14th Dec, 2016 | 1550 | Partnership Entity Types

Last Modified By: Mausam Padhiyar
Last Modified Date: 10th Jan, 2017 | 1746 | Credit Assessment Status - Approve | Reject

Last Modified By: Mausam Padhiyar
Last Modified Date: 15th Feb, 2017 | 1550 | Credit Assessment Status - Completed or Cancelled

@ModifiedBy: Meet Desai
@ModifiedOn: 12 Mar, 2020
@Description: Updated Apttus Merge Service variable name from "services_Soap_u_29_0" to "services_Soap_u_38_0"

@ModifiedBy: Mahesh Patel
@ModifiedOn: 1 Oct, 2020
@Description: Added constants for startrack pricing

@ModifiedBy: Seth Heang
@ModifiedOn: 30 Nov, 2020
@Description: Added constants for updated credit assessment mismatched warning message from Equifax

@ModifiedBy: Sriharsha
@ModifiedOn: 22 Apr, 2022
@Description: Added constants for Contract validation.

@changelog:
2022-05-26 - Pradeep Jaiswal - CI-379 Added constant for International Return product
2022-08-04 - Seth Heang - Added Constants for Rating Plan Integration Changes
2023-02-26 - Nasir Jawed - Added Constants for Close Lost Opportunity,DOCUSIGN_OBJECT_API,OTHER_ROLE_BUFFER_DAYS ,END_DATE_BUFFER_DAYS
2023-03-07 - Nasir Jawed - Added Constants OTHER_ROLE_BUFFER_DAYS ,END_DATE_BUFFER_DAYS,APT_CARBON_COPY,APT_Contact_RECORDTYPE,APT_DOCUSIGN_RECIPIENTS_TYPE_SALES_USER,APT_DOCUSIGN_RECIPIENTS_TYPE_CUSTOMER
2023-03-23 - Yatika bansal - Added Constants for credit assessment status response used in custom checkout action
2023-04-08 - Yatika bansal - Added Constants for error message ,email and Contract status
2023-04-27 - Yatika bansal - Added Constant for Proposal Stage
2023-05-29 - Yatika bansal - Added Constant for credit assessment auto-approval status
2023-07-27 - Nasir JAwed - Added Constant BG BASE and Enterprize Onboarding
2024-02-19 - Mahesh Parvathaneni - Added constant CLOSE_DATE_DEFAULT_DAYS
**/
public with sharing class APT_Constants {
	//label
	public static final String SUCCESS_LABEL = 'SUCCESS';
	public static final String SUCCESS_LABEL_SMALL = 'success';

	public static final String PROPOSAL_APPROVAL_STATUS_PENDING_APPROVAL = 'Pending Approval';
	public static final String AGREEMENT_AMEND_RENEW_CATEGORY_ZONE_CHANGE ='Add/Change Lodgement Point (With Lodgement Zone Change)';

	//Opportunity nextStep and stages
	public static final String OPPORTUNITY_NEXTSTEP_UPDATE_OPPORTUNITY_DETAILS = 'Update opportunity details';
	public static final String OPPORTUNITY_NEXTSTEP_CONFIRM_ISSUES_NEEDS_AND_DESIRED_OUTCOMES = 'Confirm issues, needs and desired outcomes';
	public static final String OPPORTUNITY_NEXTSTEP_PRESENT_PROPOSAL_TO_CUSTOMER = 'Present the proposal to the customer';
	public static final String OPPORTUNITY_NEXTSTEP_OBTAIN_VERBAL_AGREEMENT = 'Obtain verbal agreement';
	public static final String OPPORTUNITY_NEXTSTEP_PREPARE_CONTRACT = 'Prepare Contract';
	public static final String OPPORTUNITY_STAGE_IDENTIFY = 'Identify';
	public static final String OPPORTUNITY_STAGE_NEGOTIATE = 'Negotiate';
	public static final String OPPORTUNITY_STAGE_QUALIFY = 'Qualify';
	public static final String OPPORTUNITY_STAGE_PROPOSE = 'Propose';
	public static final String OPPORTUNITY_NEXTSTEP_NEGOTIATE_TO_ACHIEVE_ALIGNMENT = 'Negotiate to achieve alignment';
	public static final String OPPORTUNITY_NEXTSTEP_PRESENT_FINAL_CONTRACT_TO_CUSTOMER = 'Present final contract to customer';

	// SEPERATORS
	public static final String SEPERATOR_BACKWARD_SLASH = '/';
	public static final String SEPERATOR_SIMILARITY = '~';
	public static final String SEPERATOR_COMMA_SPACE = ', ';
	public static final String SEPERATOR_EQUAL = '=';
	public static final String SEPERATOR_SPACE = ' ';
	public static final String SEPERATOR_NEW_LINE = '\n';
	public static final String SEPERATOR_COMMA = ',';
	public static final String SEPERATOR_DOT = '.';
	public static final String SEPERATOR_UNDER_SCROLL = '_';
	public static final String EMPTY_STRING = '';
	public static final String SEPERATOR_COLON = ':';
	public static final String SEPERATOR_SEMI_COLON = ';';
	public static final String SEPARATOR_RIGHT_ARROW = '->';
	public static final String SEPARATOR_GREATER_THAN_CHANGE = '">';

	//Logical Operator
	public static final String OPERATOR_AND = 'AND';
	public static final String OPERATOR_OR = 'OR';
	public static final String OPERATOR_EQUAL_TO = 'equal to';
	public static final String OPERATOR_LESS_THAN = 'less than';

	//Yes / No option
	public static final String OPTION_YES = 'Yes';
	public static final String OPTION_NO = 'No';

	//condition number
	public static final String ONE = '1';
	public static final String TWO = '2';
	public static final String THREE = '3';
	public static final String STRING_60992317 = '60992317';
	public static final String STRING_eParcelExpress = 'eParcelExpress_eParcelStandard';
	public static final String STRING_N1 = 'N1';
	public static final String STRING_AIRPCL = 'AIRPCL_AIRPTI';

	public static final Integer INTEGER_ZERO = 0;
	public static final Integer INTEGER_ONE = 1;
	public static final Integer INTEGER_TWO = 2;
	public static final Integer INTEGER_THREE = 3;

	public static final Boolean BOOL_TRUE = true;
	public static final Boolean BOOL_FALSE = false;

	//paranthesis
	public static final String ROUND_PARANTHESIS_START = '(';
	public static final String ROUND_PARANTHESIS_END = ')';

	//field types
	public static final String FIELD_TYPE_PICKLIST = 'PICKLIST';
	public static final String FIELD_TYPE_STRING = 'STRING';
	public static final String FIELD_TYPE_BOOLEAN = 'BOOLEAN';

	//json string
	public static final String EXPR_STR = 'exprStr';
	public static final String COND_EXPR_STR = 'condExpr';
	public static final String BOOL_OPER = 'BoolOper';
	public static final String COMP_OPER = 'CompOper';
	public static final String PREDICATES = 'predicates';
	public static final String RELATION_FIELD_NAME = 'relationFieldName';
	public static final String LINE_ITEM_ID_API_NAME = 'Apttus_Config2__LineItemId__c';
	public static final String CHILD_FILTER = 'childFilter';
	public static final String FILTER = 'filter';
	public static final String SEARCH_TEXT = 'searchText';
	public static final String SOBJECT_LABEL = 'sObjectLabel';
	public static final String SOBJECT_NAME = 'sObjectName';
	public static final String LINE_ITEM = 'Line Item';
	public static final String LINE_ITEM_SOBJECT_API_NAME = 'Apttus_Config2__LineItem__c';

	public static final String LHS_CHILD_FILTER_NAME = 'LHSChildFilterName';
	public static final String LHS_SOBJECT_NAME = 'LHSSObjectName';
	public static final String OFF_SET_VALUE = 'OffsetValue';
	public static final String REF_FIELD_NAME = 'RefFieldName';
	public static final String RHS_CHILD_FILTER_NAME = 'RHSChildFilterName';
	public static final String RHS_FIELD_LABEL = 'RHSFieldLabel';
	public static final String RHS_FIELD_NAME = 'RHSFieldName';
	public static final String RHS_FIELD_TYPE = 'RHSFieldType';
	public static final String RHS_SOBJECT_NAME = 'RHSSObjectName';
	public static final String ROW_NUM = 'RowNum';


	public static final String FIELDS = 'fields';
	public static final String FIELD_LABEL = 'FieldLabel';
	public static final String FIELD_NAME = 'FieldName';
	public static final String FIELD_TYPE = 'FieldType';
	public static final String FIELD_VALUE = 'FieldValue';

	public static final String CHILD_SOBJECT_LABEL = 'childSObjectLabel';
	public static final String CHILD_SOBJECT_NAME = 'childSObjectName';
	public static final String OBJECT_LABEL_PRODUCT_ATTRIBUTE_VALUE = 'Product Attribute Value';
	public static final String OBJECT_API_NAME_PRODUCT_ATTRIBUTE_VALUE = 'Apttus_Config2__ProductAttributeValue__c';
	public static final String LODGEMENT_ZONE_CODE = 'Lodgement Zone Code';
	public static final String LODGEMENT_ZONE_CODE_API_NAME = 'APT_Lodgement_Zone_Code__c';
	public static final String PRICE_STRUCTURE = 'Price Structure';
	public static final String PRICE_STRUCTURE_API_NAME = 'APTS_Price_Structure__c';
	public static final String ATTRIBUTE_PRICE_STRUCTURE_API_NAME = 'Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c';
	public static final String ATTRIBUTE_LODGEMENT_ZONE_CODE_API_NAME = 'Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c';
	public static final String BAND = 'Band';
	public static final String BAND_API_NAME = 'APT_Band__c';
	public static final String EPARCEL_LODGEMENT = 'eParcel Lodgment';
	public static final String EPARCEL_LODGEMENT_API_NAME = 'APT_eParcel_Lodgment__c';
	public static final String ATTRIBUTE_EPARCEL_LODGEMENT_API_NAME = 'Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c';
	public static final String ATTRIBUTE_BAND_API_NAME = 'Apttus_Config2__AttributeValueId__r.APT_Band__c';
	public static final String INDUSTRY = 'Industry';
	public static final String INDUSTRY_API_NAME = 'APT_Industry__c';
	public static final String ATTRIBUTE_INDUSTRY_API_NAME = 'Apttus_Config2__AttributeValueId__r.APT_Industry__c';
	public static final String DOMESTIC_PRICE_DATA_OBJECT_API_NAME = 'APT_Domestic_Price_Data__c';
	public static final String INTERNATIONAL_PRICE_DATA_OBJECT_API_NAME = 'APT_International_Price_Data__c';
	public static final String STRING_ID_A1POM = 'A1pOMJJ0QXea';
	public static final String STRING_VAN_ONLY = 'VAN Only';
	public static final String STRING_CATEGORY = 'Category';
	public static final String STRING_NO_COMMENTS = 'No Comments';
	public static final String STRING_60000000 = '60000000';

	//URL parameters
	public static final String URL_NEXTSTEP = 'nextStep';
	public static final String URL_RETURL = 'retURL';
	public static final String URL_PRESENT_PROPOSAL = 'Apttus_Proposal__ProposalPresent';
	public static final String URL_ACCEPT_PROPOSAL = 'Apttus_QPConfig__ProposalAccept';

	//line type
	public static final String LINE_TYPE_PRODUCT_SERVICE = 'Product/Service';

	//bundle name
	public static final String BUNDLE_NAME_INTERNATIONAL = 'International Bundle';
	public static final String BUNDLE_NAME_INTERNATIONAL2 = 'International Bundle2';

	//international products
	public static final String AIRLET_INTERNATIONAL_PRODUCT = 'AIRLET';
	public static final String AIRPCL_INTERNATIONAL_PRODUCT = 'AIRMAIL_LETTERS';
	//Added by spingali for INC1758955 - Airmail letters checkbox issue.
	//public static final String AIRMAIL_INTERNATIONAL_PRODUCT = 'AIRMAIL_LETTERS';
	public static final String AIRPTI_INTERNATIONAL_PRODUCT = 'AIRPTI';
	public static final String AIRRPI_INTERNATIONAL_PRODUCT = 'AIRRPI';
	public static final String AIRSMPCL_INTERNATIONAL_PRODUCT = 'AIRSMPCL';
	public static final String ECIPCL_INTERNATIONAL_PRODUCT = 'ECIPCL';
	public static final String EMSDOCT_INTERNATIONAL_PRODUCT = 'EMSDOCT';
	public static final String EMSMERCH_INTERNATIONAL_PRODUCT = 'EMSMERCH';
	public static final String EMSMER20_INTERNATIONAL_PRODUCT = 'EMSMER20';

	//New International Products and there optional Products
	public static final String EXPRESS_DOCT_INTERNATIONAL_PRODUCT = 'EXPRESS_DOCT';
	public static final String EXPRESS_MERCH_INTERNATIONAL_PRODUCT = 'EXPRESS_MERCH';
	public static final String STANDARD_INTERNATIONAL_PRODUCT = 'STANDARD';
	public static final String STANDARD_SIGN_INTERNATIONAL_PRODUCT = 'STANDARD_SIG';
	public static final String ECONOMY_INTERNATIONAL_PRODUCT = 'ECONOMY';
	public static final String ECONOMY_SIGN_INTERNATIONAL_PRODUCT = 'ECONOMY_SIG';
	public static final String InternationalAirmailLetters_INTERNATIONAL_PRODUCT = 'InternationalAirmailLetters';
	public static final String RETURNS_EXPRESS_INTERNATIONAL_PRODUCT = 'RETURNS_EXPRESS';
	public static final String RETURNS_STANDARD_INTERNATIONAL_PRODUCT = 'RETURNS_STANDARD';

	//zone
	public static final String ZONE1 = 'Zone1';
	public static final String ZONE2 = 'Zone2';
	public static final String ZONE3 = 'Zone3';
	public static final String ZONE4 = 'Zone4';
	public static final String ZONE5 = 'Zone5';
	public static final String ZONE6 = 'Zone6';
	public static final String ZONE7 = 'Zone7';
	public static final String ZONE8 = 'Zone8';
	public static final String ZONE9 = 'Zone9';


	//international letters
	public static final String CSP_PRICE_POINT = 'CSP';
	public static final String ePARCEL_PRICE_POINT = 'eParcel';

	//band
	public static final String BAND_1 = 'BAND 1';
	public static final String BAND_2 = 'BAND 2';
	public static final String BAND_3 = 'BAND 3';
	public static final String BAND_4 = 'BAND 4';
	public static final String BAND_5 = 'BAND 5';

	//charge type
	public static final String CHARGE_TYPE_STANDARD_PRICE = 'Standard Price';
	public static final String CHARGE_TYPE_AIRPCL = 'AIRPCL';
	public static final String CHARGE_TYPE_AIRSMPCL = 'AIRSMPCL';
	public static final String CHARGE_TYPE_EMSDOCT = 'EMSDOCT';
	public static final String CHARGE_TYPE_EMSMERCH = 'EMSMERCH';
	public static final String CHARGE_TYPE_EMSMER20 = 'EMSMER20';
	public static final String CHARGE_TYPE_ePARCEL_RETURNs_DELIVERY_FEE = 'eParcel Returns - Delivery Fee (per article)';

	//price type
	public static final String PRICE_TYPE_ONE_TIME = 'One Time';
	public static final String PRICE_TYPE_USAGE = 'Usage';

	//price method
	public static final String PRICE_METHOD_PER_UNIT = 'Per Unit';

	//price UOM
	public static final String PRICE_UOM_EACH = 'Each';
	public static final String SRRING_AAT = 'AAT';
	public static final String STRING_BANDED = 'BANDED {Z30}';
	public static final String STRING_BANDED_Z6 = 'BANDED {Z6}';
	public static final String STRING_BANDEDWINE = 'BANDED WINE {Z40}';

	//Dimension Value Type
	public static final String DIMENSION_VALUE_TYPE_DISCRETE = 'Discrete';
	public static final String DIMENSION_VALUE_TYPE_RANGE = 'Range';
	public static final String STRING_TEST_PRODUCT_ATTRIBUTE_GROUP = 'Test Product Attribute Group';

	//International Price Type
	public static final String INTERNATIONAL_PRICE_TYPE = 'International Price Type';
	public static final String INTERNATIONAL_PRICE_TYPE_PER_KG = 'Per Kg';
	public static final String INTERNATIONAL_PRICE_TYPE_PER_Item = 'Per Item';

	//adjustment type
	public static final String ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE = 'List Price Override';
	public static final String ADJUSTMENT_TYPE_PRICE_OVERRIDE = 'Price Override';

	//Domestic Price Type
	public static final String DOMESTIC_PRICE_TYPE = 'Domestic Price Type';
	public static final String DOMESTIC_PRICE_TYPE_BASE = 'Base';
	public static final String DOMESTIC_PRICE_TYPE_SUBSEQUENT = 'Subsequent';
	public static final String DOMESTIC_PRICE_TYPE_PER_KG = 'Per Kg';

	//product code
	public static final String PRODUCT_CODE_INTERNATIONAL_BUNDLE = 'InternationalBundle';
	public static final String PRODUCT_CODE_INTERNATIONAL_PCMS = 'InternationalDigitalPCMSBundle';
	public static final String PRODUCT_CODE_INTERNATIONAL_PCMS_airmail = 'InternationalDigitalPCMSBundlewithAirmail';
	public static final String PRODUCT_CODE_INTERNATIONAL_PCMSNew = 'International Digital PCMS Bundle';
	public static final String PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new = 'International Digital PCMS Bundle incl Airmail Letters';
	public static final String PRODUCT_CODE_INTERNATIONAL_BUNDLE_new = 'International Bundle';
	public static final String PRODUCT_CODE_PriorityProd_RegularSpeedService='RSS9999';
	public static final String PRODUCT_CODE_PriorityProd_PremExpSpeedService='PESS12345';
	public static final String PRODUCT_CODE_INTERNATIONAL_RETURNS='RAX400000';


	public static final String PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE = 'InternationalDigitalPCMSBundle';
	public static final String PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL = 'InternationalDigitalPCMSBundlewithAirmail';
	public static final String PRODUCT_CODE_INTERNATIONAL_AIRMAIL_LETTERS = 'InternationalAirmailLetters';
	public static final String PRODUCT_CODE_INTERNATIONAL_BUNDLE2 = 'InternationalBundle2';
	public static final String PRODUCT_CODE_EPARCEL_CALL_FOR_RETURN = 'eParcel Call for Return';
	public static final String PRODUCT_CODE_REGISTERED_POST_INTERNATIONAL_PARCELS = 'Registered Post International Parcels';
	public static final String PRODUCT_CODE_EXPRESS_COURIER_INTERNATIONAL = 'Express Courier International';
	public static final String PRODUCT_CODE_AIRMAIL_PARCELS = 'Air Mail Parcels';
	public static final String PRODUCT_CODE_INTERNATIONAL_PACK_N_TRACK = 'International Pack and Track';
	public static final String PRODUCT_CODE_IDENTITY_ON_DELIVERY_SERVICE = 'Identity on Delivery Service';
	public static final String PRODUCT_CODE_MIN_COLLECTION_VALUE = 'Minimum Collection Value';
	public static final String PRODUCT_CODE_EPARCEL_POST_RETURN = 'eParcel Post Return';
	public static final String PRODUCT_CODE_POST_BILLPAY = 'Post Billpay';
    public static final String PRODUCT_CODE_METRO = 'Metro';
	public static final String PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES = 'Unaddressed Mail Services';

	//New Optional Products for new bundles
	public static final String PRODUCT_CODE_NEW_EXPRESS_DOCT = 'EXPRESS_DOCT';
	public static final String PRODUCT_CODE_NEW_EXPRESS_MERCH = 'EXPRESS_MERCH';
	public static final String PRODUCT_CODE_NEW_STANDARD = 'STANDARD';
	public static final String PRODUCT_CODE_NEW_ECONOMY = 'ECONOMY';
	public static final String PRODUCT_CODE_NEW_RETURNS_EXPRESS = 'RETURNS_EXPRESS';
	public static final String PRODUCT_CODE_NEW_RETURNS_STANDARD = 'RETURNS_STANDARD';
	public static final String PRODUCT_CODE_NEW_STANDARD_SIGN = 'STANDARD_SIG';
	public static final String PRODUCT_CODE_NEW_ECONOMY_SIGN = 'ECONOMY_SIG';
	public static final String PRODUCT_CODE_NEW_AIRMAIL_LETTERS = 'AIRMAIL_LETTERS';


	public static final String PRODUCT_CODE_ePARCEL_STANDARD = 'eParcelStandard';
	public static final String PRODUCT_CODE_ePARCEL_EXPRESS = 'eParcelExpress';
	public static final String PRODUCT_CODE_MISSING_MANIFEST_FEE = 'MissingManifestFee';
	public static final String PRODUCT_CODE_ADMINISTRATIVE_FEE = 'AdministrativeFee';
	public static final String PRODUCT_CODE_MINIMUM_COLLECTION_VALUE = 'MinimumCollectionValue';
	public static final String PRODUCT_CODE_RETURN_TO_SENDER = 'ReturntoSender';
	public static final String PRODUCT_CODE_UMS = 'UMS';
	public static final String PRODUCT_CODE_PRINT_POST = 'Print Post';
	public static final String PRODUCT_CODE_COURIER = 'Courier';
	public static final String PRODUCT_CODE_LOCAL_PICKUP_DELIVERY = 'LPDC';
	public static final String STRING_POSTAL_SERVICES = 'Postal Services';

	public static final String PRODUCT_CODE_APPC ='APPC';
	public static final String PRODUCT_TYPE_PARCEL_CONTRACT = 'Parcel Contract';
	public static final String PRODUCT_CLASSIFICATION_APPC_STANDARD = 'APPC-Standard';
	public static final String PRODUCT_CLASSIFICATION_APPC_PREMIUM = 'APPC-Premium';
	public static final String R2T_APPC_CONTRACT = 'R2T APPC Contract';

	//network type
	public static final String NETWORK_TYPE_STANDARD = 'Standard';
	public static final String NETWORK_TYPE_EXPRESS = 'Express';
	public static final String STRING_LETTERS = 'Letters';
	public static final String STRING_BI1234 = 'BI1234';
	public static final String STRING_MEDIUM = 'Medium';
	public static final String STRING_PRODUCTS = 'Products';
	public static final String STRING_THIS_IS_A_CASE = 'This is a case';
	public static final String STRING_DESCRIBE = 'Describe';
	public static final String STRING_LODGEMENT_POINT = 'Lodgement Point';
	public static final String STRING_RANDOM_STRING = 'dagydddheu';

	//document types
	public static final String DOCUMENT_TYPE_DOC = 'DOC';
	public static final String DOCUMENT_TYPE_DOCX = 'DOCX';
	public static final String DOCUMENT_TYPE_PDF = 'PDF';
	public static final String DOCUMENT_TYPE_RTF = 'RTF';
	public static final String DOCUMENT_TYPE_DOCX_LOWER = 'docx';
	public static final String DOCUMENT_TYPE_PDF_LOWER = 'pdf';
	public static final String DOCUMENT_TYPE_RTF_LOWER = 'rtf';

	//Access levels
	public static final String ACCESS_LEVEL_EDIT = 'Full Access';
	public static final String ACCESS_FULL = 'Full';

	//approval stage
	public static final String APPROVAL_STAGE_DRAFT = 'Draft';
	public static final String APPROVAL_STAGE_APPROVED = 'Approved';
	public static final String APPROVAL_STAGE_DENIED = 'Denied';
	public static final String APPROVAL_STAGE_GENERATED = 'Generated';
	public static final String APPROVAL_STAGE_PRESENTED = 'Presented';
	public static final String APPROVAL_STAGE_ACCEPTED = 'Accepted';
	public static final String APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC = 'Accepted without proposal document';

	//action label
	public static final String ACTION_LABEL_CALCULATE_ESTIMATED_REVENUE = 'APT_CalculateEstimatedRevenue';
	public static final String ACTION_LABEL_SEARCH_LODGEMENT_ZONE = 'APT_SearchLodgementZone';

	//weight measure
	public static final String WEIGHT_MEASURE_DEADWEIGHT = 'DEADWEIGHT';
	public static final String WEIGHT_MEASURE_CUBIC = 'CUBIC';
	public static final String STRING_SAMPLE_ATTACHMENT = 'Sample Attachment';

	//action name
	public static final String ACTION_NAME_RENEW = 'Renew';
	public static final String ACTION_NAME_AMEND = 'Amend';
	public static final String ACTION_NAME_DoV = 'DoV';
	public static final String ACTION_NAME_DoV_Increase = 'DoV Increase';
	public static final String ACTION_NAME_DoV_Decrease = 'DoV Decrease';
	public static final String OPPORTUNITY_SUBTYPE_DoV_Increase = 'DoV Increase';
	public static final String OPPORTUNITY_SUBTYPE_RENEWAL = 'Re-Contract';

	//action type
	public static final String ACTION_TYPE_RENEWAL = 'Renewal';

	//Stage Name
	public static final String STAGE_NAME_IDENTIFY = 'Identify';

	//opportunity type
	//public static final String OPPORTUNITY_TYPE_EXISTING_CUSTOMER = 'Existing Customer';

	//lead source
	public static final String LEAD_SOURCE_CONTRACT_RENEWAL = 'Contract Renewal';

	//classification
	public static final String CLASSIFICATION_RENEWAL = 'Renewal';
	public static final String CLASSIFICATION_GROWTH = 'Growth';
	public static final String STRING_UP_SELL = 'Up Sell';
	public static final String STRING_TEST1 = 'Test';
	public static final String STRING_SAMPLE = 'Sample';
	public static final String SAMPLE_EMAIL = 'xyz@abc.com';
	public static final String STRING_AGREEMENT = 'Agreement';

	//record type
	public static final String RECORD_TYPE_PROPOSAL = 'Proposal';
	public static final String RECORD_TYPE_RENEWAL_QUOTE = 'Renewal Quote';
	public static final String RECORD_TYPE_AMENDMENT_QUOTE = 'Amendment Quote';
	public static final String RECORD_TYPE_RENEWAL_CONTRACT = 'Renewal Contract';
	public static final String RECORD_TYPE_DOV_CONTRACT = 'DoV Contract';
	public static final String RECORD_TYPE_CONTRACT_MANAGEMENT_ENQUIRY = 'Contract Management Enquiry';

	//Configuration status
	public static final String CONFIGURATION_STATUS_FINALIZED = 'Finalized';

	//case
	public static final String CASE_STATUS_NEW = 'New';
	public static final String CASE_ORIGIN_SALESFORCE = 'Salesforce';
	public static final String CASE_INITIATING_AREA_SALESFORCE = 'Salesforce';
	public static final String CASE_TYPE_SALES_CONTRACT_CONSULTING = 'Sales Contract Consulting';
	public static final String CASE_WORK_TYPE_ADDENDUM_DOV = 'Addendum/DOV';
	public static final String CASE_SUPPORT_WORK_TYPE_DEAL_ENABLEMENT = 'Deal Enablement Support';

	//Namespace
	public static final String NAMESPACE_APTTUS_CMCONFIG = 'Apttus_CMConfig__';
	public static final String NAMESPACE_APTTUS = 'Apttus__';

	//pricing system properties
	public static final String R2T_INTERNATIONAL_PRICING_PROPERTIES = 'R2T International Pricing Properties';
	public static final String R2T_DOMESTIC_PRICING_PROPERTIES = 'R2T Domestic Pricing Properties';

	//account Type
	public static final String ACCOUNT_TYPE_CHARGE_ACCOUNT_PLUS_SUB_ACCOUNT = 'Charge Account + Sub Account';

	//Error Messsage
	public static final String ERROR_MESSAGE_CONSTRAINT_RULES = System.Label.APT_Constraint_Rule_Error_Message;
	public static final String ERROR_MESSAGE_INVALID_PROPOSAL = 'Missing Quote/Proposal. Can not update Quote/Porposal.';
	public static final String ERROR_MESSAGE_MALFORMED_URL = 'Malformed URL Parameters';
	public static final String ERROR_MESSAGE_CANNOT_ACCEPT_PROPOSAL = 'Cannot accept the expired proposal. To accept this proposal please update the proposal expiration date.';
	public static final String ERROR_MESSAGE_CANNOT_PRESENT_PROPOSAL = 'Cannot present the expired proposal. To present this proposal please update the proposal expiration date.';
	public static final string ERROR_MESSAGE_CANNOT_CREATE_CONTRACT ='Cannot Create a Contract document for an expired Contract.Please Create a new contract to continue.';
	public static final string ERROR_MESSAGE_CANNOT_SEND_CONTRACT='Cannot send a contract out for signature for an expired Contract. Please Create a new contract to continue.';
	//Approval Rejection comments mandotory
	public static final String APPROVAL_REJECTION_COMMENTS_MANDOTORY = 'Please provide Rejection commnets';
	public static final String APPROVAL_STATUS_REJECTED = 'Rejected';
	public static final String APPROVAL_STATUS_CANCELLED = 'Cancelled';
	public static final String APPROVAL_STATUS_PROCESSING_APPROVAL = 'Processing Approval';


	//Agreement
	public static final String AGREEMENT_STATUS_FULLY_SIGNED = 'Fully Signed';
	public static final String AGREEMENT_STATUS_SFDC_CASE_CREATED = 'SFDC Case Created';
	public static final String AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES = 'In Signatures';
	public static final String AGREEMENT_STATUS_CATEGORY_REQUEST = 'Request';
	public static final String AGREEMENT_STATUS_CATEGORY_IN_AUTHORING = 'In Authoring';
	public static final String AGREEMENT_STATUS_OTHER_PARTY_SIGNATURE = 'Other Party Signatures';
	public static final String AGREEMENT_STATUS_SIGNED_BY_CUSTOMER_ONLY = 'Signed by Customer Only';
	public static final String AGREEMENT_STATUS_AUTHOR_CONTRACT = 'Author Contract';
	public static final String AGREEMENT_SOURCE_OTHER_PARTY_PAPER = 'Other Party Paper';
	public static final String AGREEMENT_CATEGORY_CUSTOMISED = 'Customised';
	public static final String TERM_FIXED_TERM = 'Fixed Term';
	public static final String AGREEMENT_STATUS_REQUEST = 'Request';

	public static final String AGREEMENT_ATTACHMENT_ERROR_MESSAGE='Please attach the documents in Notes and Attachments';
	public static final String AGREEMENT_DATE_ERROR_MESSAGE='Agreement commencement date cannot be after offer expiration date';

	//AttachFile Controller
	public static final String IMAGESONLY= 'Please upload images only of type JPEG or PNG';
	public static final String Qoute = '\'';
	public static final String FOLDERNAME = 'images';
	public static final String SUCCESS_UPLOAD_MESSAGE = 'uploaded successfully';
	public static final String RESTRICTION_FILE_UPLOAD_MESSAGE = 'Exception';
	public static final String FOLDER_DOES_EXIST_MESSAGE = 'Folder does not exist';
	public static final String FILE_SIZE_RESTRICTION='File Size is more than 1MB';
	public static final String IMAGE_TAG = '<img src=https://';
	public static final String SERVLET_TAG = '/servlet/servlet.FileDownload?file=';
	public static final String SERVLET = 'servlet';
	public static final String IMAGE_SERVER = 'ImageServer';
	public static final String CLOSE_TAG = ' class="richText" > ';

	//Manage Contarct LodgementPoint
	public static final String PRODUCT_PROMO_POST = 'Promo Post';
	public static final String PRODUCT_PROMO_POST2 = 'Promo Post2';
	public static final String MSG_NO_LINE_ITEMS = 'There are no Agreement Line Items found';
	public static final String MSG_NO_LODGEMENT_POINT_ZONE = 'There are no Lodgement Points found for this Lodgement Zone';
	public static final String MSG_FILL_FILTER = 'Please enter a filter parameter';
	public static final String MSG_POSTCODE_OUTSIDE_ZONE = 'Entered Post Code is outside Lodgement Zone';
	public static final String MSG_PLEASE_SELECT_LODGEMENT_POINT = 'Please select Lodgement Point first';
	public static final String MSG_LODGEMENT_POINTS_OUTSIDE_PROMOPOST= 'Selected Lodgement Point outside the post code of Promo Post Product';
	public static final String MSG_LODGEMENT_POINTS_ALREADY_ADDED = 'Lodgement Point already added';
	public static final String MSG_NO_LODGEMENT_POINT_FOUND = 'No Lodgement Points found';
	public static final String MSG_ONLY_ONE_LP_ALLOWED = 'Only One Lodgement Point allowed for eParcel and eParcel Express products';

	//validation call back
	public static final String MSG_ONLY_ONE_LP_ALLOWED_CART = 'We cannot have more than one Lodgement points added for eParcel and eParcel Express products,Please review to finalize';


	//contract type
	public static final String CONTRACT_TYPE_NEW_CONTRACT = 'New Contract';
	public static final String CONTRACT_TYPE_RENEWAL_CONTRACT = 'Renewal Contract';

	//Product Group
	public static final String PRODUCT_GROUP_PARCEL = 'PARCEL';
	public static final String PRODUCT_GROUP_INTERNATIONAL_POSTAL = 'INTERNATIONAL POSTAL';

	//contract detail type
	public static final String CONTRACT_DETAIL_NEW_CUSTOMER = 'NEW_CUSTOMER';
	public static final String CONTRACT_DETAIL_INTERNATIONAL_NEW_EPARCEL = 'INTERNATIONAL_NEW_EPARCEL';
	public static final String CONTRACT_DETAIL_INTERNATIONAL_RENEWAL_EPARCEL = 'INTERNATIONAL_RENEWAL_EPARCEL';

	//opportunity type
	public static final String OPPORTUNITY_TYPE_NEW_CUSTOMER = 'New Customer';
	public static final String OPPORTUNITY_TYPE_EXISTING_CUSTOMER = 'Existing Customer';
	public static final String OPPORTUNITY_OFFERING_TYPE_PRODUCT = 'Product';

	//sales activity
	public static final String SALES_ACTIVITY_NEW = 'NEW';
	public static final String SALES_ACTIVITY_RENEWAL = 'RENEWAL';

	//quote type
	public static final String QUOTE_TYPE_DRAFT = 'DRAFT';
	public static final String QUOTE_TYPE_FINAL = 'FINAL';
	public static final String STATUS_DETAILS_TYPE_FINAL = 'FINAL';

	//Source System
	public static final String SOURCE_SYSTEM_APTTUS = 'APTTUS';

	//payment Method
	public static final String PAYMENT_METHOD_CASH_ACCOUNT = 'Cash Account';

	//account type
	public static final String ACCOUNT_TYPE_CASH = 'CASH';
	public static final String ACCOUNT_TYPE_CASH_LOWER = 'cash';
	public static final String ACCOUNT_TYPE_CUST = 'CUST';

	//subaccount type
	public static final String SUB_ACCOUNT_TYPE_CUST = 'CUST';

	//sales rep type
	public static final String SALES_REP_TYPE_SELLER = 'SELLER';

	//rate card type
	public static final String RATE_CARD_TYPE_DOMESTIC = 'DOMESTIC';
	public static final String RATE_CARD_TYPE_INTERNATIONAL = 'INTERNATIONAL';

	//product details
	public static final String PRODUCT_DETAILS_PCMS = 'PCMS';
	public static final String PRODUCT_DETAILS_INTERNATIONAL_PARCEL = 'INTERNATIONAL PARCEL';
	public static final String PRODUCT_DETAILS_INTERNATIONAL_POSTAL = 'INTERNATIONAL POSTAL';
	public static final String PRODUCT_DETAILS_UNADDRESSED_MAIL = 'Unaddressed Mail';
	public static final String PRODUCT_DETAILS_PRINT_POST = 'Print Post';

	//service type
	public static final String SERVICE_TYPE_PARCEL_POST = 'PARCEL POST';
	public static final String SERVICE_TYPE_EXPRESS_POST = 'EXPRESS POST';
	public static final String SERVICE_TYPE_EPARCEL_STANDARD = 'STANDARD';
	public static final String SERVICE_TYPE_EPARCEL_EXPRESS = 'EXPRESS';
	public static final String SCENARIO_TYPE_CSP_RENEWAL = 'INTERNATIONAL_RENEWAL_BPA';
	public static final String SCENARIO_TYPE_PCMS_RENEWAL = 'INTERNATIONAL_RENEWAL_EPARCEL';

	//provisioning method
	public static final String PROVISIONING_METHOD_CSP = 'CSP';
	public static final String PROVISIONING_METHOD_PCMS = 'PCMS';

	public static final String UPLOAD_TYPE_USER = 'USER';
	public static final String UPLOAD_TYPE_TOOL_NAME = 'APTTUS';
	public static final String FLAG = 'APP_ROBOT';

	//dispersion type
	public static final String DISPERSION_TYPE_MANUAL = 'MANUAL';
	public static final String DISPERSION_TYPE_DEFAULT = 'DEFAULT';

	//sub-product
	public static final String SUB_PRODUCT_PARCEL_SERVICES_EPARCEL = 'Parcel Services eParcel';
	public static final String SUB_PRODUCT_PARCEL_SERVICES_EXPRESS_EPARCEL = 'Parcel Services Express eParcel';

	//Category
	public static final String CATEGORY_CAT1 = 'CAT1';
	public static final String CATEGORY_CAT2 = 'CAT2';
	public static final String CATEGORY_CAT3 = 'CAT3';
	public static final String CATEGORY_CAT4 = 'CAT4';
	public static final String CATEGORY_CAT5 = 'CAT5';
	public static final String CATEGORY_CAT6 = 'CAT6';

	public static final String VEDA_SERVER_ISSUE = 'Downstream system responded with faultcode contact system admin for more details. Try again in a few minutes.';

	//Scenario Type
	public static final String SCENARIO_TYPE_CSP = 'INTERNATIONAL_NEW_BPA';
	public static final String SCENARIO_TYPE_PCMS = 'INTERNATIONAL_NEW_EPARCEL';
	public static final String SCENARIO_TYPE_NEW_DIGITAL = 'INTERNATIONAL_NEW_DIGITAL';

	//OPC RecordType
	public static final String OPC_Existing_RecordType = 'Existing Opportunity Type';

	//Credit Assessment Status.
	public static final String CREDIT_ASSESSMENT_STATUS_APPROVED = 'Approved';
	public static final String CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED = 'Auto-Approved';
	public static final String CREDIT_ASSESSMENT_STATUS_REFER = 'refer';
	public static final String CREDIT_ASSESSMENT_STATUS_REFER_ALL_CAPITAL = 'REFER';
	public static final String CREDIT_ASSESSMENT_STATUS_REFER_CAPITAL = 'Refer';
	public static final String CREDIT_ASSESSMENT_STATUS_REFERRED = 'Referred';
	public static final String CREDIT_ASSESSMENT_STATUS_DECLINE = 'DECLINE'; //Added By apttus Support
	public static final String STRING_RESPONSE_MOCK = 'response_x';
	public static final String STRING_RESPONSE_COMPLETE = 'Complete';
	public static final String STRING_RESPONSE_INCOMPLETE = 'Incomplete';

	//Network- Transport Capabilities picklist Values
	public static final String TRANSPORT_CAPABILITY_EITHER_VAN_OR_TRUCK = 'Either VAN or Truck';

	//product names
	public static final String PRODUCT_NAME_UMS = 'Unaddressed Mail Services';
	public static final String PRODUCT_NAME_NonContractedUMS = 'UMS Non Contracted';
	public static final String PRODUCT_NAME_NonContractedPrintPost = 'PrintPost Non Contracted';
	public static final String PRODUCT_NAME_PRINT_POST = 'Print Post';
	public static final String PRODUCT_NAME_CLEAN_MAIL = 'Clean Mail';
	public static final String PRODUCT_NAME_SAMPLE_POST = 'Sample Post';
	public static final String PRODUCT_NAME_PRESORT_LETTERS = 'PreSort Letters';
	public static final String PRODUCT_NAME_IMPACT_MAIL = 'Impact Mail';
	public static final String PRODUCT_NAME_ACQUISITION_MAIL = 'Acquisition Mail';
	public static final String PRODUCT_NAME_CHARITY_MAIL = 'Charity Mail';
	public static final String PRODUCT_NAME_REGISTERED_POST = 'Registered Post';
	public static final String PRODUCT_NAME_PO_BOXES = 'PO Boxes';
	public static final String PRODUCT_NAME_COUNCILLOR_MAIL = 'Councillor Mail';
	public static final String PRODUCT_NAME_PROMO_POST = 'Promo Post';
	public static final String PRODUCT_NAME_IMPRINT_METERED_POST = 'Imprint/Metered Mail';
	public static final String PRODUCT_NAME_REPLY_PAID = 'Reply Paid';
	public static final String PRODUCT_NAME_LOCAL_COUNTRY_LETTER = 'Local Country Letter';
	public static final String PRODUCT_NAME_COMPETITION_MAIL = 'Competition Mail';
	public static final String PRODUCT_NAME_LOCAL_PICKUP_DELIVERY = 'Local Pickup and Delivery Services';


	public static final String INTERNATIONAL_PRICING_BATCH_STATUS = '*** International Pricing Batch Status ***';
	public static final String JOB_COMPLETED_SUCCESSFULLY = 'The job completed sucessfully.';
	public static final String JOB_PROCESSED_WITH = 'The job processed with ';
	public static final String FAILURES_ERRORS = ' failures. \n\n Error(s) : \n ';
	public static final String SAP_CONTRACT_JOB_COMPLETED = ' Apttus SAP Contract Job completed with';

	//error messages
	public static final String ERROR_MISSING_R2T_WEIGHT_FIELD_MAPPING = 'Missing R2T Weight Field Mapping.';
	public static final String ERROR_INVALID_R2T_WEIGHT_FIELD_MAPPING = 'Invalid R2T Weight Field Mapping.';
	public static final String ERROR_MISSING_DIMENSION_TYPE_FOR = 'Missing Dimension Type for ';
	public static final String ERROR_MISSING_DIMENSION_VALUE_FOR = 'Missing Dimension Value for ';
	public static final String ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT = 'No Charge Types found for product ';
	public static final String ERROR_NO_CUSTOM_SETTINGS_WITH_NAME = 'No custom settings with name ';
	public static final String FOUND = 'found';
	public static final String PRICE_DIMENSIONS_ARE_NOT_CONFIGURED = 'Price Dimensions are not configured.';
	public static final String ERROR_VALUE_ALREADY_EXIST = 'Value already exist in system at line: ';
	public static final String ERROR_DUPLICATE_VALUE_AT_LINE = 'Duplicate value at line: ';
	public static final String ERROR_NUMBER_OF_CHAR_RESTRICTION = 'Number of characters must be 7 at line: ';
	public static final String ERROR_EMPTY_VALUE_AT_LINE = 'Empty value at line: ';


	public static final String ERROR_MISSING_DEFAULT_PRICE_LIST_ID = 'Missing Default Price List ID in R2T System Properties.';


	public static final string PROPOSAL_OVERWEIGHT_ITEM = 'Overweight Items';
	public static final string PROPOSAL_DGT = 'Dangerous Goods';
	public static final string PROPOSAL_DOMESTIC_OVERWEIGHT_ITEM = 'Domestic Overweight Items';
	public static final string PROPOSAL_INTERNATIONAL_OVERWEIGHT_ITEM = 'International Overweight Items';
	public static final string PROPOSAL_INTERNATIONAL_ITEM = 'International Items';
	public static final string PROPOSAL_UMS_OVERWEIGHT_ITEM = 'UMS Overweight';


	public static final string PARAM_ID = 'id';
	public static final string PARAM_COUNT = 'count';
	public static final string PARAM_NAME='name';
	public static final string PARAM_TEXT='text';
	Public static final Integer PARAM_CONTRACT_EXP_DAYS=59;
	Public static final string PARAM_APPC_PRODUCT='Australia Post Parcel Contract';
	public static final string PARAM_PRODUCT_Type='Product/Service';
	public static final string PARAM_PRODUCT_Type_Misc='Misc';
	public static final string APT_VfcontractPage='APT_CreateContractValidation';
	public static final string APT_VfcontractesignaturePage='APT_HelptotheSeller';
	public static final string PARAM_ACCOUNT_TYPE = 'accountType';
	public static final string PARAM_RECORDTYPE = 'recordType';
	public static final string PARAM_RETURN_URL = 'retURL';
	public static final string PARAM_AGREEMENT_ID = 'agreementId';
	public static final string PARAM_ACTION_NAME = 'actionName';
	public static final string PARAM_IS_ASSET_DISABLED = 'isAssetDisabled';
	public static final string PARAM_USE_ADVANCED_APPROVAL = 'useAdvancedApproval';
	public static final string PARAM_FLOW = 'flow';
	public static final string PARAM_SELECTED_CATEGORY = 'selectedCategory';
	public static final string PARAM_PROPOSAL_ID = 'proposalID';
	public static final string PARAM_ACCOUNT_ID = 'accountId';
	public static final string PARAM_RECORD_NO = 'recordNo';
	public static final string PARAM_CHARGE_ACCOUNT_ID = 'chargeAccountId';

	public static final string WEBSERVICE_INVALID_ABN = 'Invalid ABN. ABN must be of 11 characters';
	public static final string WEBSERVICE_INVALID_ACN = 'Invalid ACN. ACN must be of 9 characters';
	public static final string WEBSERVICE_INVALID_INPUT = 'Invalid input. Please enter atleast 1 characters';

	public static final string ERROR_SOAP_FAULT = 'faultcode=server';
	public static final string ERROR_VEDA_ERROR = 'Veda Exception';
	public static final string ERROR_SOAP_ENDPOINT_EXCEPTION = 'Missing End Point URL.';
	public static final string WARNING_ENTITY_TYPE_TRUST = 'Entity Type is Trust.';
	public static final string WARNING_INVALID_ASIC_TYPE = 'Invalid ASIC Type.';

	public static final string STRING_FORMAT_DESCRIPTION = ' : Description : ';
	public static final string STRING_FORMAT_CODE = 'Code : ';
	public static final string CONSTANT_VEDA_TERM_DAYS = '30';
	public static final string CONSTANT_VEDA_ACCOUNT_TYPE = 'D30';
	public static final string CONSTANT_PDEV = 'pdev';
	public static final string CONSTANT_DEV_COMP_AP_ID = '1009564100';
	public static final string CONSTANT_DEV_INDV_AP_ID = '2009564200';

	public static final string WARNING_MULTIPLE_RECORDS = 'Multiple records found. Select one record by clicking on View and then Select or click on refer to select multiple credit assessment records.';

	public static final string CONSTANT_VEDA_REGD = 'REGD';
	public static final string CONSTANT_VEDA_TRUST = 'TRUST';
	public static final string ADMIN_ENTRY_PRIVACY_STATEMENT = 'APT_PrivacyStatement';

	public static final string PRINT_POST_RATES_NON_CONTRACTED = '0 - 99K'; // Updated by Adrian Recio, Changed from 0 - 250K to 0 - 99K

	public static final string MAIL_DEAR_ALL = '<p>Dear All,</p><p></p>';
	public static final String MAIL_CHARGE_ACCOUNT = '<p>Charge account - ';
	public static final String MAIL_HAS_BEEN_REFERRED = ' has been Referred</p>';
	public static final String MAIL_CREDIT_ASSESSMENT_UNDER_FOLLOWING = '<p>Find credit assessments under following Account <a href="';
	public static final String MAIL_TAGS_AP = '</a> </p>';
	public static final String MAIL_SUBJECT_CHARGE_ACCOUNT = 'Charge account - ';
	public static final String MAIL_SUBJECT_HAS_BEEN_REFERRED = ' has been Referred';

	public static final String NAMESPACE_APTTUS_ONLY = 'Apttus';

	public static final string FLOW_RENEW_FLOW = 'RenewalQuote';

	public static final string BOOLEAN_TRUE = 'true';

	public static final string ERROR_MISSING_CONFIGURATION = 'Missing configuration.';
	public static final string ERROR_MISSING_PROPOSAL = 'Missing Proposal.';
	public static final string ERROR_MISSING_CREDIT_ASSESSMENT = 'Missing Credit Assessment.';

	public static final String APPROVAL_STAGE_APPROVE = 'Approve';
	public static final String APPROVAL_STAGE_APPROVE2 = 'APPROVE';
	public static final String APPROVAL_STAGE_REJECT = 'Reject';
	public static final String APPROVAL_STAGE_REJECT2 = 'REJECT';

	public static final string SEPARATOR_COLON = ': ';
	public static final string SEPARATOR_DOUBLEUNDERSCORE = '__';
	public static final string SEPARATOR_NEXT_LINE = '\n';
	public static final string SEPARATOR_PERCENT = '%';


	public static final string END_CHARACTER_C = 'c';
	public static final string END_CHARACTER_D = 'D';

	public static final string CREDIT_ASSESSMENT_REFFERED = 'Referred';
	public static final string CREDIT_ASSESSMENT_DECLINE = 'Decline';
	public static final string VEDA_NO_RESPONSE_FOUND = 'No Response Found.';
	public static final string PROPOSAL_IS_MISSING = 'Quote/Proposal is missing.';
	public static final string RENEWAL_AGREEMENT_FAILED = 'After Renew Agreement failed.';
	public static final string AMEND_AGREEMENT_FAILED = 'After Amend Agreement failed.';
	public static final string MISSING_CONTRACT_NUMBER = 'Missing Contract Number on Quote/Proposal.';
	public static final string NO_ENTITY_LEGAL_NAME_MATCHED = 'Organisations Legal Entity Name\'s Results does not Match with any queryABN Search. ';
	public static final string ORG_UPDATED_SUCCESSFUL = 'Data updated successfully in Organisation';
	public static final string DETAILS_MISMATCHED_UPDATE_MSG = 'Click \"Update\" button below to update the correct values in Organisation record. If you are unsure, click \"Cancel\" to review/amend the data in Organisation record and then re-perform credit assessment.';
	public static final string DETAILS_MISMATCHED_REFER_MSG = 'Clicking \"Credit Assessment\" will refer the credit application to Credit Management Team for manual credit assessment. Alternatively, resolve the data mismatch issue with Data Quality Team and re-perform credit assessment';
	public static final string DETAILS_MISMATCHED_BLANK = '\"BLANK"';


	//public static final string EMPTY_STRING = '';
	public static final string STRING_SPACE_DOUBLE_QUOTES = ' "';
	public static final string STRING_DOUBLE_QUOTES = '"';
	public static final string STRING_HTML_BR = '<br/>';
	public static final string AMENDED_CONTRACT_TYPE = 'Amend Contract';
	public static final string RENEW_CONTRACT_TYPE = 'Renew Contract';
	public static final string NEW_CONTRACT_TYPE = 'New Contract';

	public static final string SELECT_OPTION_NONE = 'None';

	public static final string ERROR_SELECT_CATEGORY = 'Please select category.';
	public static final string ERROR_SETTING_NOT_CONFIGURED = 'Settings for this Category are not configured properly, please contact Administrator.';
	public static final string ERROR_MISSING_DEFAULT_PRICE = 'Missing default price list in R2T System Properties.';

	public static final string ERROR_COPY_CONFIG_FIELDS = 'Copy Configuration failed.';
	public static final string ERROR_COPY_PROPOSAL_CHILD_FAILED = 'Copy Proposal Child records failed.';

	public static final string JOB_EXECUTION_SUCCESSFUL = 'Job has been scheduled for execution successfully.';
	public static final string ADD_COLON = ':';
	public static final string ADD_WHITESPACE = ' ';
	public static final string ADD_HYPHEN = '-';
	public static final string ADD_ZERO = '0';
	public static final string ADD_DOUBLEZERO = '00';
	public static final string ADD_TEN = '10';
	public static final string ADD_QUESTIONMARK = '?';
	public static final string ADD_ASTERISK = '*';
	public static final string DOMESTIC_PRICING_JOB = 'Calculate Domestic Pricing Job';
	public static final string INTERNATIONAL_PRICING_JOB = 'Calculate International Pricing Job';
	public static final string DEFINE_STRING = '';
	public static final string MONTH_JAN = 'Jan';
	public static final string MONTH_Feb = 'Feb';
	public static final string MONTH_Mar = 'Mar';
	public static final string MONTH_Apr = 'Apr';
	public static final string MONTH_May = 'May';
	public static final string MONTH_Jun = 'Jun';
	public static final string MONTH_Jul = 'Jul';
	public static final string MONTH_Aug = 'Aug';
	public static final string MONTH_Sep = 'Sep';
	public static final string MONTH_Oct = 'Oct';
	public static final string MONTH_Nov = 'Nov';
	public static final string MONTH_Dec = 'Dec';

	public static final string ADD_COMMA = ',';
	public static final string ADD_TILDE = '~';
	public static final string JOB_PROCESSED = 'The job processed with ';
	//public static final string FAILURES_ERRORS = ' failures. \n\n Error(s) : \n ';
	public static final string INTERNATIONAL_PRICING_STATUS = '*** International Pricing Batch Status ***';
	public static final string PRICING_JOB_STATUS = '*** Pricing Batch Job Status ***';

	public static final string DOMESTIC_PRICING_PROCESSED = 'The Domestic Pricing Batch job has processed ';
	public static final string BATCHES_WITH = ' batches with ';
	public static final string DOMESTIC_PRICING_STATUS = '*** Domestic Pricing Batch Status ***';
	public static final string NO_PRODUCT_DOMESTIC_PRICING = 'No product found for domestic pricing.';
	//public static final string FOUND = ' found.';
	public static final string NO_PRICE_DIMENSION_WITH_NAME = 'No Price Dimension with Name ';
	public static final string NO_CUSTOM_SETTINGS_WITH_NAME = 'No Custom Settings with name ';
	public static final string MISSING_DIMENSION_VALUE_FOR = 'Missing Dimension Value for ';
	public static final string A_PERIOD = '.';
	public static final string MISSING_DIMENSION_TYPE_FOR = 'Missing Dimension Type for ';
	public static final string MISSING_DEFAULT_PRICELIST_ID = 'Missing Default Price List ID in R2T System Properties.';

	//CUSTOM SETTING NAME

	public static final String CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES = 'System Properties';
	//label
	//public static final String SUCCESS_LABEL = 'SUCCESS';
	public static final String LABEL_APPROVAL_STEP_DANGEROUS_GOODS = 'Dangerous Goods';
	public static final String LABEL_APPROVAL_STEP_OVER_WEIGHT = 'Overweight items';
	public static final String LABEL_APPROVAL_STEP_DOMESTIC_OVERWEIGHT_ITEMS = 'Domestic Overweight Items';
	public static final String LABEL_APPROVAL_STEP_INTERNATIONAL_OVERWEIGHT_ITEMS = 'International Overweight Items';
	public static final String LABEL_APPROVAL_STEP_INTERNATIONAL_ITEMS = 'International Items';
	public static final String LABEL_APPROVAL_STEP_UMS_OVERWEIGHT = 'UMS Overweight';
	public static final String LABEL_BACK_TO_QUOTE = 'Back to Quote';
	public static final String LABEL_BACK_TO_SHOPPING_CART = 'Back to Shopping Cart';
	public static final String LABEL_SUPERSEDED = 'Superseded';
	public static final String LABEL_LINE_TYPE_OPTION = 'Option';
	public static final String LABEL_LINE_TYPE_OPT = 'opt';
	public static final String LABEL_LINE_TYPE_BUNDLE = 'bundle';
	public static final String LABEL_CONTRACTED_PRICE_INCREASES = 'Contracted Price Increases';
	public static final String LABEL_FLOW = 'flow';
	public static final String LABEL_ACTIVATED = 'Activated';
	public static final String LABEL_USER_ID_PREFIX = '005';
	public static final String LABEL_APPROVAL_REQUIRED = 'Approval Required';
	public static final String LABEL_VISIBILITY_VISIBLE = 'visibility:visible;';
	public static final String LABEL_VISIBILITY_HIDDEN = 'visibility:hidden;';
	public static final String LABEL_NAMESPACE_CONFIG2 = 'Apttus_Config2__pricing';
	public static final String LABEL_LINE_STATUS = 'Pending';
	public static final String LABEL_LINE_STATUS_DEF_PENDING = 'Default Pending';
	public static final String STRING_PRICING_MANAGEMENT = 'Pricing Management';
	public static final String STRING_URL_PROPOSAL_CONFIGURATION = '/apex/Apttus_QPConfig__ProposalConfiguration?Id=';
	public static final String STRING_FLOW_NEW_QUOTE_ADVANCED = '&flow=NewQuote&useAdvancedApproval=true&useDealOptimizer=true';
	public static final String STRING_URL_FLOW_APPROVAL = '&flow=Approval flow&useAdvancedApproval=true&useDealOptimizer=true';
	public static final String STRING_URL_RENEWAL_QUOTE = '&flow=RenewalQuote&useAdvancedApproval=true&useDealOptimizer=true';
	public static final String STRING_URL_AMEND_QUOTE_CART = '&flow=RenewalQuote&productOrderByClause=APT_Most_Popular__c NULLS LAST&useAdvancedApproval=true&launchState=catalog#!/search/';
	public static final String STRING_URL_PROPOSAL_CART = '/apex/Apttus_Config2__Cart?businessObjectId=';

	// Custom metadata types
	public static final String DESTINATION_ZONE_LIST_ORDER_MAPPING = 'DestinationZoneListOrderMapping';

	//FILE TYPE
	public static final String FILE_TYPE_JPEG = 'jpeg';
	public static final String FILE_TYPE_PNG = 'png';
	public static final String FILE_TYPE_GIF = 'gif';

	//DATA TYPE
	public static final String DATA_TYPE_NUMBER = 'Number';
	public static final String DATA_TYPE_TEXT = 'Text';

	// SOQL QUERY
	public static final String SOQL_SELECT = 'Select ';
	public static final String SOQL_SELECT_ID = 'Select ID,';
	public static final String SOQL_FROM = ' from ';
	public static final String SOQL_WHERE_ID = ' where id= ';
	public static final string SOQL_AGREEMENT_OBJECT = 'Apttus__APTS_Agreement__c';
	public static final string SOQL_QUOTE_LODGEMENT_POINT_OBJECT = 'APT_Quote_Lodgement_Point__c';
	public static final string SQOL_OPERATIONAL_SCHEDULE_OBJECT = 'APT_Operational_Schedule__c';
	public static final String SOQL_AGREEMENT_QUERY = ' FROM Apttus__APTS_Agreement__c WHERE Id in :setChildAgreementId';
	public static final String SOQL_OPERATIONAL_SCHEDULE_QUERY = ' FROM APT_Operational_Schedule__c WHERE APT_Contract__c in :setParentAgreementId';
	public static final String SOQL_PRODUCT_ATTRIBUTE_VALUE = 'select Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c,Apttus_Config2__LineItemId__r.Apttus_Config2__OptionId__r.Name,Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.Name,Apttus_Config2__LineItemId__r.APT_Product_Name__c,APT_Volume_Data__c,Apttus_Config2__LineItemId__r.Apttus_Config2__OptionId__c';
	public static final String SOQL_PRODUCT_ATTRIBUTE_VALUE_FROM = ' from Apttus_Config2__ProductAttributeValue__c where Apttus_Config2__LineItemId__c IN:ltsLineItems';
	public static final string SOQL_QUOTE_LODGEMENT_POINT_FROM = ' from APT_Quote_Lodgement_Point__c where APT_Quote_Proposal__c in :setQuoteId';
	public static final string SOQL_LINE_ITEM_RATE_CARD_OBJECT = 'APT_Line_Item_Rate_Card__c';
	public static final string SOQL_LINE_ITEM_RATE_CARD_FROM = ' FROM APT_Line_Item_Rate_Card__c WHERE APT_Proposal_Line_Item__c IN :setPropLineItemId ORDER BY Name ASC';
	public static final string SOQL_QUOTE_RATE_CARD_OBJECT = 'APT_Quote_Rate_Card__c';
	public static final string SOQL_QUOTE_RATE_CARD_QUERY = ', APT_Line_Item__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c FROM APT_Quote_Rate_Card__c WHERE APT_Line_Item__c IN : setLineItemId ORDER BY Name ASC';
	public static final string SOQL_LINE_ITEM_OBJECT = 'APT_Line_Item__c';
	public static final string SOQL_POSTBILLPAT_CONTRACT = 'APT_Postbillpay_Contract';
	public static final string SOQL_AGREEMENT_LINE_ITEM_OBJECT = 'Apttus__AgreementLineItem__c';
	public static final string SOQL_AGREEMENT_OBJECT_SELECT = 'SELECT Apttus__AgreementId__c, ';
	public static final string SOQL_AGREEMENT_RATE_CARD_OBJECT = 'APT_Agreement_Rate_Card__c';
	public static final string SOQL_AGREEMENT_LINE_ITEM_SELECT_INNER = ', (select APT_Agreement_Line_Item__c, ';
	public static final string SOQL_AGREEMENT_RATE_CARD_OBJECT_INNER_REF = ' from Agreement_Rate_Card__r) ';
	public static final string SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT = 'APT_Agreement_Lodgement_Point__c';
	public static final string SOQL_AGREEMENT_LODGEMENT_POINT_FIELDS = ', (select APT_Agreement__c, APT_Organisation__c, ';
	public static final string SOQL_AGREEMENT_LODGEMENT_POINT_FROM = ' from Agreement_Lodgement_Point__r) ';
	public static final string SOQL_AGREEMENT_USAGE_PRICE_TIER_OBJECT = 'Apttus_CMConfig__AgreementUsagePriceTier__c';
	public static final string SOQL_AGREEMENT_USAGE_PRICE_TIER_SELECT_INNER = ', (select Apttus_CMConfig__LineItemId__c, ';
	public static final string SOQL_AGREEMENT_USAGE_PRICE_TIER_FROM = ' from Apttus_CMConfig__UsagePriceTiers__r) ';
	public static final string SOQL_AGREEMENT_USAGE_PRICE_TIER_WHERE = ' Where Apttus__AgreementId__c in : agreementIds';
	public static final string SOQL_INTERNATIONAL_PRICE_DATA_ORDER_BY = ' FROM APT_International_Price_Data__c Order By APT_Zone__c limit 10000';
	public static final string SOQL_INTERNATIONAL_PRICE_DATA_OBJECT = 'APT_International_Price_Data__c';

	public static final String SEPERATOR_NO_SPACE = '';
	public static final String SEPERATOR_HYPHEN = ' -';
	public static final String SEPERATOR_PERCENT = '%';
	public static final String SEPERATOR_NO_SPACE_HYPHEN = '-';
	public static final String SEPERATOR_AND = '&';
	public static final String SEPERATOR_UNDER_SCORE = '_';
	public static final String SEPERATOR_AND_AMP = '&amp;';

	public static final String STRING_ERROR_MESSAGE_MISSING_ACCOUNT_TYPES = 'Missing Account Types in custom settings R2T System Properties';
	public static final String ERROR_MESSAGE_MISSING_CUSTOM_SETTINGS = 'Missing custom settings R2T System Properties';

	//URL parameters
	public static final String URL_ID = 'id';
	public static final String URL_NAME = 'name';
	public static final String URL_HOST = 'Host';
	public static final String URL_SELECTED_VALUE = 'selectedValue';
	public static final String URL_OBJ = 'obj';
	public static final String URL_COMBO_LABEL = 'comboLabel';
	public static final String URL_TEMPLATEID = 'templateID';
	public static final String URL_TEMPLATENAME = 'templateName';
	public static final String URL_DOC_FORMAT = 'docFormat';
	public static final String URL_PARENTID = 'parentId';
	public static final String URL_AGREEMENTID = 'agreementId';
	public static final String URL_SELECTED_CATEGORY = 'selectedCategory';
	public static final String URL_SERVICES_SOAP = '/services/Soap/u/28.0/';
	public static final String URL_SERVICES_SOAP_V43 = '/services/Soap/u/43.0/';
	public static final String URL_SERVICES_SOAP_DOWNLOAD_DOCUMENT = '/sfc/servlet.shepherd/document/download/';
	public static final String URL_SERVICES_OPERATION_CONTEXT_S1 = 'operationContext=S1';
	public static final String URL_AMEND_RENEW_PAGE = '/apex/APT_AmendRenew?agreementId=';
	public static final String URL_AMEND_RENEW_PAGE_ACTION_NAME = '&actionName=DoV';
	public static final String URL_SEND_MAIL_PAGE = '/apex/Apttus__SendEmail?id=';
	public static final String URL_SEND_MAIL_PAGE_PARAMETERS = '&action=Send_To_Other_Party_For_Signatures';
	public static final String URL_DOCUSIGN_CREATE_ENVELOPE = '/apex/Apttus_CMDSign__CMDocuSignCreateEnvelope?id=';
	public static final String URL_REFERER = 'Referer';
	public static final String URL_SOURCE = 'source';
	public static final String URL_QUOTE = 'Quote';
	public static final String URL_CART = 'Cart';
	public static final String URL_BUSINESS_OBJECT_ID = 'businessObjectId';
	public static final String URL_LAUNCH_STATE = 'launchState';
	public static final String URL_CONFIG_REQUEST_ID = 'configRequestId';
	public static final String URL_ROWID_TO_DELETE = 'rowidTodelete';
	public static final String URL_ENTRY_TO_CLONE = 'entryToClone';
	public static final String URL_QUANTITY_VALUE = 'quantityVal';
	public static final String URL_UNTI_SALES_PRICE_VALUE = 'unitsalespriceVal';
	public static final String URL_ROW_NUM = 'rowNum';
	public static final String URL_OPPORTUNITY_ID = 'opportunityId';
	public static final String URL_ACCOUNT_ID = 'accountId';
	public static final String URL_GUIDED_SELLING_FLOW_PAGE = '/apex/APT_GuidedSellingFlow?opportunityId=';
	public static final String URL_ID_EQUALS = '&Id=';
	public static final String URL_RET_ID = '&retId=';
	public static final String URL_BUSINESS_OBJECT_ID_EQUALS = '&businessObjectId=';
	public static final String URL_CONFIG_REQUEST_ID_EQUALS = '&configRequestId=';
	public static final String URL_INTERVIEW_NAME = '&interviewName=';
	public static final String URL_CLASSIFICATIONNAME_ID = '&classificationNameId=';
	public static final String URL_PROPOSAL = 'Proposal';
	public static final String URL_SAVED = 'Saved';
	public static final String URL_CALLER_PAGE = 'callerPage';
	public static final String URL_PRM = '/prm/';
	public static final String URL_GUIDED_SELLING_FLOW = 'APT_GuidedSellingFlow';
	public static final String URL_DEFAULT = 'default';
	public static final String URL_NEW_QUOTE = 'NewQuote';
	public static final String URL_WARNING = 'WARNING';
	public static final String URL_SELECTRECORDID = 'selectedRecordID';
	public static final String APT_RENEWAL_QUOTE = 'APT_Renewal_Quote';
	public static final String APT_AMENDMENT_QUOTE = 'APT_Amendment_Quote';

	public static final String MSA = 'MSA';
	public static final String RECORD_TYPE_MSA_SERVICE_SCHEDULE = 'MSA & Service Schedule';
	public static final String RECORD_TYPE_SECURE_PAY_ONLINE_PAYMENTS = 'SecurePay Online Payments';

	//Error Messsage
	//public static final String ERROR_MESSAGE_INVALID_PROPOSAL = 'Missing Quote/Proposal. Can not update Quote/Porposal.';
	public static final String ERROR_MESSAGE_NO_PRODUCTS_THAT_CAN_BE_CLASSIFIED = 'There are no Products that can be classified';
	public static final String ERROR_MESSAGE_CLASSIFICATION_IS_MANDATORY = 'Clasification is mandatory';
	public static final String ERROR_MESSAGE_QUANTITY_IS_MANDATORY = 'Quantity is mandatory';
	public static final String ERROR_MESSAGE_UNIT_SALES_PRICE_MANDATORY = 'Unit Sales Price is mandatory';
	public static final String ERROR_MESSAGE_REVENUE_START_DATE_MANDATORY = 'Revenue Start Date is mandatory';
	public static final String ERROR_MESSAGE_REVENUE_END_DATE_MANDATORY = 'Revenue End Date is mandatory';
	public static final String ERROR_MESSAGE_MULTIPLE_ENTRIES_SAME_CLASSIFICATION = 'We can\'t have multiple entries with same clasification for a Product';
	public static final String ERROR_MESSAGE_GROWTH_LINE_MANDATORY = 'For every renewal line there has to be a growth line';
	public static final String ERROR_MESSAGE_MISSING_DEFAULT_PRICELIST_ID = 'Missing Default Price List Id in R2T System Properties.';
	public static final String ERROR_MESSAGE_MISSING_CLASSIFICATION_ID = 'Missing Classification Id in R2T System Properties.';
	public static final String ERROR_MESSAGE_MISSING_INTERVIEW_NAME = 'Missing Interview Name in R2T System Properties.';

	public static final String OPPORTUNITY_TYPE_NEW_OPPORTUNITY_TYPE = 'New Opportunity Type';
	public static final String OPPORTUNITY_TYPE_NEW_BUSINESS = 'New Business';
	public static final String OPPORTUNITY_TYPE_CROSS_SELL = 'Cross Sell';
	public static final String RECONTRACTING = 'Recontracting';
	public static final String OPPORTUNITY_TYPE_EXISTING_OPPORTUNITY_TYPE = 'Existing Opportunity Type';

	public static final String PRODUCT_NAME_EPARCEL = 'eParcel';
	public static final String PRODUCT_NAME_EPARCEL_EXPRESS = 'eParcel Express';


	//error messages
	public static final String ERROR_PREFIX = 'Error:';
	public static final String ERROR_CANNOT_ADD_MORE_THAN = 'You cannot add more than ';
	public static final String ERROR_PRODUCT_SAME_TIME = ' products at the same time.';
	public static final String ERROR_MISSING_LINE_ITEM = 'Missing Line Item.';
	public static final String ERROR_INVALID_RATE_CARD_KEY = 'Invalid Rate Card Key.';
	public static final String ERROR_MISSING_END_POINT_URL = 'Missing End Point URL';
	public static final String ERROR_CUSTOMER_ID_RECEIVED = 'Customer Id received - ';
	public static final String ERROR_CUSTOMER_ID_MISMATCH = ' does not match with customer Id on Quote - ';
	public static final String ERROR_FAULT_CODE = 'faultcode=server';
	public static final String ERROR_DOWNSTREAM_ERROR = 'Downstream system is not responding. Try again in a few minutes.';
	public static final String ERROR_DIMENSIONS_NOT_IN_CUSTOM_SETTINGS = 'Dimensions are not configured in custom settings with name ';
	public static final String ERROR_NO_CSTM_SETTINGS = 'No Custom Settings with name ' ;
	public static final String ERROR_MISSING_DIM_TYPE = 'Missing Dimension Type for ';
	public static final String ERROR_MISSING_DIM_VALUE = 'Missing Dimension Value for ';

	public static final String EMAIL_SUB_DOMESTIC_PRICING_BATCH_STATUS = '*** Domestic Pricing Batch Status ***';
	public static final String STR_FOUND = 'found';
	public static final String STR_TRUE = 'True';
	public static final String STR_FALSE = 'False';
	public static final String EMAIL_PLAIN_TEXT_PART_1 = 'The Domestic Pricing Batch job has processed ';
	public static final String EMAIL_PLAIN_TEXT_PART_2 = ' batches with ';
	public static final String EMAIL_PLAIN_TEXT_PART_3 = ' failures. \n\n Error(s) : \n ';
	public static final String EMAIL_PLAIN_SUCCESS_PART_1 = 'The Domestic Pricing Batch job completed successfully with ';
	public static final String EMAIL_PLAIN_SUCCESS_PART_2 = ' failures.';

	public static final String EMAIL_SUB_INTERNATIONAL_PRICING_BATCH_STATUS = '*** International Pricing Batch Status ***';
	public static final String APEX_JOB_PROCESSED = 'The batch Apex job processed ';

	public static final String NO_INTERNATION_PRODUCT_FOUND = 'No international product found to calculate pricing.';
	public static final String NO_INTERNATIONAL_PRICE_FOUND = 'No International Price Data found.';

	public static final String CONTRACT_NUMBER = 'Contract Number';
	public static final String SAPERP_CONTRACT_NUMBER = 'SAPERP Contract Number';
	public static final String BUSINESS_REFERENCE_ID = 'Business Reference Id';
	public static final String RESPONSE = 'Response';
	public static final String SYNC_CONTRACT_RATES_ERROR = '*** Sync Contract Rates Error ***';
	public static final String SYNC_CONTRACT_RATES_RESPONSE = '*** Sync Contract Rates Response ***';
	public static final String SYNC_CONTRACT_RATES_RESPONSE_MSG = 'The Sync Contract Rates Batch job completed successfully with 0 failures. \n\n Response(s): \n ';
	public static final String SYNC_CONTRACT_RATES_BATCH_JOB_COMPLETED_WITH = 'The Sync Contract Rates Batch job completed with ';
	public static final String FAILURES_AND_RESPONSES = ' failures. \n\n Response(s) : \n ';
	public static final String ERRORS_AND_NEW_LINE = '\n\n Error(s) : \n ';
	public static final String SPECIAL_CHAR_PATTERN = '[^\\w]';
	public static final String UPLOAD_NEW_CONTRACT_INFO = 'UPLOAD_NEW_ContractInfo';
	public static final String UPLOAD_NEW_CONTRACT_RATE_CARD = 'UPLOAD_NEW_ContractRateCard';
	public static final String UPLOAD_NEW_CONTRACT_RATES = 'UPLOAD_NEW_ContractRates';
	public static final String UPLOAD_RENEWAL_CONTRACT_INFO = 'UPLOAD_RENEWAL_ContractInfo';
	public static final String UPLOAD_RENEWAL_CONTRACT_RATE_CARD = 'UPLOAD_RENEWAL_ContractRateCard';
	public static final String UPLOAD_RENEWAL_CONTRACT_RATES = 'UPLOAD_RENEWAL_ContractRates';

	public static final String FILE_EXT_CSV = '.csv';

	public static final String SERVICE_TYPE_S = 'S';
	public static final String SERVICE_TYPE_X = 'X';

	public static final String SIGNATURE_Y = 'Y';
	public static final String SIGNATURE_N = 'N';

	public static final String LODGEMENT_ZONE_CODE_AU = 'AU';

	public static final String COUNTRY_CODE_UK = 'UK';
	public static final String COUNTRY_CODE_NZ = 'NZ';

	public static final String ePARCEL_POST_RETURN = 'eParcelPostReturn';
	public static final String PARCEL_POST_CALL_RETURN_DELIVERY_FEE = 'Parcel Post Call for Returns - Delivery Fee (per article)';
	public static final String PARCEL_POST_CALL_RETURN_PICK_UP_FEE = 'Parcel Post Call for Returns - Pick-up Fee (per request)';
	public static final String ePARCEL_IDENTITY_DELIVERY_SERVICE = 'eParcelIdentityonDeliveryService';
	public static final String SYNC_CONTRACT_RATES = 'syncContractRates';
	public static final String STRING_AUSTRALIA = 'australia';
	public static final String STIRNG_ORG123 = 'ORG123';
	public static final String STRING_DWS12 = 'DwS12';
	public static final String STRING_PCODE = 'Pcode';
	public static final String STRING_LZOONE = 'LZoone';
	public static final String STRING_OTYPE = 'OType';
	public static final String STRING_5000 = '5000';

	public static final String AGREEMENT_ID = 'agId';
	public static final String SELECTALIID= 'selectedALIId';
	public static final String PRODSPECIFIC= 'ProdSpecific';
	public static final String ACTIVE = 'Active';
	public static final String CLOSED = 'Closed';
	public static final String DELIVERY1 = 'Delivery_1';
	public static final String RETAIL2 = 'Retail_2';
	public static final String BUSINESS_HUB3 = 'Business_Hub_3';
	public static final String NETWORK_C1= 'Network__c';
	public static final String MORE_THAN_2000_LP= 'More than 2000 Lodgement Points found,Please use filter to Narrow down the results';

	// Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
	public static final String QUERY_STR1= 'Select id,Name,Post_Code__c,State__c,APT_Business_Unit__c,APT_eParcel_Enabled__c,Org_ID__c,APT_DWS_ID__c,' +
											'Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c where ' +
											'Status__c != \'Closed\' AND APT_Business_Unit__c!=null AND recordtypeID in (Select id from RecordType where DeveloperName in (\'Delivery_1\',\'Retail_2\',\'Business_Hub_3\') and SobjectType = \'Network__c\')';

	// Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
	public static final String COUNTQRYSTR1 = 'select count() from Network__c where Status__c != \'Closed\' AND APT_Business_Unit__c!=null AND recordtypeID in (Select id from RecordType where DeveloperName in (\'Delivery_1\',\'Retail_2\',\'Business_Hub_3\') and SobjectType = \'Network__c\')';
	public static final String AND_POST_CODE_STRING = ' AND Post_Code__c >=:postCodeStart AND Post_Code__c <=:postCodeEnd';
	public static final String AND_PC_STRING = ' AND Post_Code__c >=:startPC AND Post_Code__c <=:endPC';
	public static final String POST_CODE_STRING2= ' AND ( id in:networkHubIds OR Post_Code__c =: selectedPostCode) ';
	public static final String AND_STATE_STRING1= ' AND State__c =: selectedState';
	public static final String GENERIC = 'generic';
	public static final String AND_POST_CODE_STRING3 = ' AND Post_Code__c >=:postCodeStartLZ AND Post_Code__c <=:postCodeEndLZ';

	// Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
	public static final String AND_BUSINESS_UNIT_1 = ' AND APT_Business_Unit__c LIKE: bussinessUnit';
	public static final String AND_TRANSPORT_CAPABILITY1 = ' AND APT_Transport_Capability__c != null';
	public static final String AND_TRANSPORT_CAPABILITY2 = ' AND APT_Transport_Capability__c like: tempInput';
	public static final String AND_EPARCEL_ENABLED1 = ' AND APT_eParcel_Enabled__c =: eParcelEnabled';
	public static final String ORDER_BY_POST_CODE1 = ' ORDER BY Post_Code__c Limit: recordsperpage OFFSET: offSetVal';
	public static final String PLEASE_SELECT_CASH_1 = 'Please select Cash Account';
	public static final String PLEASE_SELECT_SUB_1 = 'Please select sub Account';
	public static final String PLEASE_SELECT_CHARGE_1 = 'Please select Charge Account';
	public static final String QRYSTRG1 = 'select id,APT_Lodgement_Point_Name__c,APT_Agreement_Line_Item__c,APT_Product__c from APT_Agreement_Lodgement_Point__c where APT_Agreement__c =:agreementId AND APT_Lodgement_Point_Lookup__c=:lstLodgementPointselected AND APT_Status__c =\'Active\'';
	public static final String DEACTIVATEALIID = 'deactivateALIId';
	public static final String INACTIVE = 'Inactive';
	public static final String NONE_2 = '---None---';
	public static final String HUB = 'Hub';
	public static final String RETAIL_LPO = 'Retail - LPO';
	public static final String RETAIL_CORP = 'Retail - Corp';
	public static final String PARCEL_SERVICES = 'Parcel Services';
	public static final String POSTAL_DELIVERY = 'Postal Delivery';
	public static final String NAME2 = 'Name';
	public static final String REDIRECTALIID = 'redirectALIId';
	public static final String LKID = '_lkid';
	public static final String FORWARD_E = '/e';
	public static final String APT_ORGANISATION_C_OBJECT = 'APT_Organisation__c';
	public static final String APT_CONTRACT_C_OBJECT = 'APT_Contract__c';
	public static final String APT_LODGEMENT_POINT_C_OBJECT = 'APT_Lodgement_Point__c';
	public static final String APT_CUSTOMER_CONTACT_NAME_OBJECT = 'APT_Customer_Contact_Name__c';
	public static final String APT_COLLECTION_STREET_ADDRESS_C_OBJECT = 'APT_Collection_Street_Address__c';
	public static final String APT_SUBURB_C_OBJECT = 'APT_Suburb__c';
	public static final String APT_POSTAL_CODE_C_OBJECT = 'APT_Postal_Code__c';
	public static final String APT_STATE_C_OBJECT = 'APT_State__c';

	public static final String ENTEREDACCVAL= 'enteredAccVal';
	public static final String PRODCONID= 'prodConId';
	public static final String QUOTEID= 'quoteId';
	public static final String BILLINGACCCPQ= 'billingAccCPQ';
	public static final String PLEASE_ENTER_BILLING_ACCOUNT= 'Please search Billing Account related to the Organisation';
	public static final String THERE_ARE_NO_BILLING_ACCOUNTS1= 'There are no Billing Accounts found for the Organisation';
	public static final String PLEASE_ENTER_SOME_TEXT1= 'Please enter some text in Name field';
	public static final String CASHACCOUNTCLM= 'cashAccountCLM';
	public static final String CHARGEACCOUNTCLM= 'chargeAccountCLM';
	public static final String SUBACCOUNTCLM= 'subAccountCLM';

	public static final String APEX_SCHEMA_URL1 = 'http://www.auspost.com.au/Schema/Party/Customer/queryABN:v1';
	public static final String FALSE_2 = 'false';

	public static final String RESOURCE_URL1 = '/resource/APT_Pricing_Approval_Help';
	public static final String FIRST_PAGE_CART ='/apex/Cart?configRequestId={!Apttus_Config2__TempObject__r.id}&cartStatus=New&id={!Apttus_Config2__ProductConfiguration__r.id}&flow=NewQuote#/catalog';

	public static final String LABEL_FOR = 'For ';
	public static final String PRODUCT_BILLING_ACCOUNT1 = ' Product Billing Account Type cannot be Cash Account';
	public static final String LABEL_LINEITEM = 'LineItem';
	public static final String SEPARATOR_COMMA_SPACE = ', ';

	public static final String PARAM_OBJECTTYPE = 'objType';
	public static final String PARAM_PROPOSAL_ID2 = 'proposalId';
	public static final String PARAM_IS_EXISTING_CUSTOMER = 'isExistingCustomer';
	public static final String MISSING_CHARGE_ACCOUNT = 'Please Select Parent Account.';
	public static final String MISSING_PROPOSAL = 'Missing Proposal';
	public static final String PLEASE_PROVIDE_SUB_ACCOUNT_DETAILS = 'Please provide Sub-Account Details as you have selected Charge Account + Sub Account as Account Type for Quote/Proposal.';

	public static final String ERRORMESSAGE_1 = 'An unexpected error occured, please contact your Administrator';
	public static final String SYSTEMDMLEXCEPTION = 'System.DmlException';
	public static final String SYSTEMLISTEXCEPTION = 'System.ListException';
	public static final String SYSTEMMATHEXCEPTION = 'System.MathException';
	public static final String SYSTEMNOACCESSEXCEPTION = 'System.NoAccessException';
	public static final String SYSTEMNULLPOINTEREXCEPTION = 'System.NullPointerException';
	public static final String SYSTEMQUERYEXCEPTION = 'System.QueryException';
	public static final String SYSTEMSTRINGEXCEPTION = 'System.StringException';
	public static final String SYSTEMVISUALFORCEEXCEPTION = 'System.VisualforceException';
	public static final String SYSTEMTYPEEXCEPTION = 'System.TypeException';
	public static final String STRING_PARTNER = 'Partner';
	public static final String STRING_POWER_PARTNER = 'PowerPartner';
	public static final String STRING_PRM = '/prm';
	public static final String STRING_APEX = '/apex';
	public static final String PRODUCT_CONFIGURATION_OBJECT = 'Apttus_Config2__ProductConfiguration__c';
	public static final String APPROVAL_STATUS_NOT_SUBMITTED = 'Not Submitted';
	public static final String STRING_USER1 = 'User';
	public static final String STRING_RELATED_USER = 'Related User';
	public static final String STRING_CUSTOM_USER = 'Custom User';
	public static final String ERROR_MESSAGE_2 = 'ERROR: ';
	public static final String ERROR_MESSAGE_3 = 'Error occured while accessing approvers list, please contact your System Administrator.';

	public static final String STRING_PDF = 'pdf';
	public static final String STRING_PARENTRECORDID = 'parentRecordID';
	public static final String STRING_ISPRESTOMODE = 'isPrestoMode';
	public static final String STIRNG_ID_CAPITAL = 'ID';
	public static final String STIRNG_ID_FIRST_CAPITAL = 'Id';
	public static final String SOQL_QUERY_FROM_OBJECT_LINEITEM = ' from Apttus_Config2__LineItem__c';
	public static final String SOQL_WHERE_ID_LINEITEM = ' where id =: lineItemID';
	public static final String ERROR_MULTIPLE_APPS_FOUND = ' Multiple Apps found. ';
	public static final String ERROR_NO_APPS_FOUND = ' No Apps found.';
	public static final String STRING_EPARCEL_2 = 'Eparcel';
	public static final String STRING_PRICING_PRODUCTS = 'Pricing Products';
	public static final String ERROR_MESSAGE_4 = 'Invalid pricing product selected for given ';
	public static final String ERROR_MESSAGE_5 = ' Invalid Line Item ID.';
	public static final String STRING_DOCUMENT_PROCESSING = ' Document processing failed Please try again.';
	public static final String PDF_ATTACHED_TO_LINEITEM = 'PDF attached to line item.';
	public static final String APPNAME1 = 'appName';

	public static final String REVENUE_COMMITTMENT_LESS_THAN_3000 = 'Less than 3,000';
	public static final String REVENUE_COMMITTMENT_3000_4999 = '3,000 - 4,999';
	public static final String REVENUE_COMMITTMENT_5000_19999 = '5,000 - 19,999';
	public static final String REVENUE_COMMITTMENT_20000_34999 = '20,000 - 34,999';
	public static final String REVENUE_COMMITTMENT_35000_50000 = '35,000 - 50,000';
	public static final String REVENUE_COMMITTMENT_ABOVE_50000 = 'Above 50,000';



	public static final String STRING_AUSTRALIA_POST_PRICE_LIST = 'Australia Post Price List';

	public static final String STRING_OPPORTUNITY = 'Opportunity';
	public static final String STRING_FROM_OPPORTUNITY_WHERE = ' FROM Opportunity WHERE Id = :originalOpportunityId';
	public static final String PROPOSAL_LINEITEM_OBJECT = 'Apttus_Proposal__Proposal_Line_Item__c';
	public static final String STRING_FROM_PLI = ' FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_QPConfig__ConfigurationId__c = :configurationId';
	public static final String SUMMARY_GROUP_ID_OBJECT = 'Apttus_CMConfig__SummaryGroupId__c';
	public static final String ATTRIBUTE_VALUE_ID_OBJECT = 'Apttus_CMConfig__AttributeValueId__c';
	public static final String USAGE_PRICETEIR_OBJECT = 'Apttus_Config2__UsagePriceTier__c';
	public static final String STRING_USAGEPRICE_TEIR = ' FROM Apttus_Config2__UsagePriceTier__c WHERE Apttus_Config2__LineItemId__c IN :setLineItemId';

	public static final String STRING_SELECT_ID_FROM_ACCOUNT = 'select id from account where ';
	public static final String STRING_SELECT_ID_FROM_CREDIT_ASSESSMENT = 'select id from APT_Credit_Assessment__c where ';
	public static final String STRING_APT_ABN_C = ' APT_ABN__C =: ABN';
	public static final String STRING_ABN_C = ' ABN__c =: ABN';
	public static final String STRING_APT_ACN_C = ' APT_ACN__C =: ACN';
	public static final String STRING_ACN_C = ' ACN__c =: ACN';
	public static final String STRING_FORWARD_CART = '#/cart';

	public static final String RANDOM_STRING = 'asdas';
	public static final String TEMP_STRING = 'temp';
	public static final String STRING_PRV = 'PRV';
	public static final String STRING_009610342 = '009610342';
	public static final String STRING_100 = '100';
	public static final String STRING_12345678911 = '12345678911';
	public static final String STRING_213456 = '213456';
	public static final String STRING_PTR = 'PTR';
	public static final String STRING_ACT = 'ACT';
	public static final String STRING_NT = 'NT';
	public static final String STRING_undetermined = 'undetermined';
	public static final String STRING_0820 = '0820';
	public static final String STRING_87009610342 = '87009610342';
	public static final String STRING_INDV = 'INDV';
	public static final String STRING_AUSTRALIAN_PRIVATE_COMPANY = 'Australian Private Company';
	public static final String STRING_AUSTRALIAN_Postal_Corporation = 'Australian Postal Corporation';
	public static final String STRING_COMPUTER_COMPANY = 'THE COMPUTER COMPANY PTY. LTD.';
	public static final String STRING_COMPUTER_PVT_LTD = 'THE COMPUTER COMPANY PTY LTD TRADING AS SOUND SPECTRUM';
	public static final String STRING_ACN = 'ACN';
	public static final String STRING_ALASKA = 'Alaska';
	public static final String STRING_APTY = 'APTY';
	public static final String STRING_BUSINESS = 'Bussiness';

	public static final String POSTAL_SERVICES = 'PostalServices';


	public static final String STRING_CHARGE = 'charge';
	public static final String TEST_EMAIL = 'test@example.com';
	public static final String STRING_AUSTRALIAPOST = 'australiapost';
	public static final String STRING_TEST_ORGANIZATION = 'test organisation';
	public static final String STRING_ENTERPRISE = 'Enterprise';
	public static final String STRING_TEST_OPPORTUNITY = 'test opportunity';
	public static final String STRING_LINE_ITEM = 'Line Item : ';
	public static final String STRING_VIEW_RATE_CARD_FAILED = ' View rate card Failed';
	public static final String STRING_R2T_PROPOSAL_TEMPLATE = 'R2T Proposal Template';
	public static final string TEMPLATE_APPC_PROPOSAL = 'APPC_Proposal';
	public static final string METADATTYPERECORD_TEMPLATE_APPC_RATE_CARD = 'APPC_RateCard';
	public static final String STRING_VIEW_RATE_CARD_ON_LINEITEMS = '*** View rate cards on Line Items ***';
	public static final String STRING_PROPOSALDOC_EMAIlSUBJECT = '*** Notification for Proposal Document - ';
	public static final String STRING_STAR=' ***';
	public static final String STRING_PDEAR = '<p>Dear ';
	public static final String STRING_TAG_P = ',</p><p>';
	public static final String STRING_VIEW_RATE_CARDS_BATCH_JOB = 'View rate cards Batch job has processed ';
	public static final String STRING_YOUR_PROPOSAL_HAS_BEEN_GENERATED = '</p><p> Your Proposal has been generated. Click this <a href="';
	public static final String STRING_LINKA = 'link</a> ';
	public static final String STRING_AND_GO_TO_NOTES_AND_ATTACHMENTS = 'and go to Notes and Attachments Section to view the proposal.</p>';

	public static final String STRING_APT_CSS_JS = 'APT_CSS_JS';
	public static final String STRING_VIEW_RATE_TEST_QUERY = 'View_Rate_Card__c,Test_View_Rate_Card__c,APT_Charge_Code_Formula__c,APT_Get_Renewal_Rates__c,APT_Classification__c,Apttus_Config2__AttributeValueId__r.Category__c,Apttus_Config2__ProductId__r.ProductCode';
	public static final String STRING_APTTUS_CQAPPROV_QUERY = 'Apttus_CQApprov__Approval_Status__c,Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c,APT_Customised_Pricing__c,Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c,APT_Pricing_Reason__c';
	public static final String STRING_C_MANUFACTURING = 'C Manufacturing';
	public static final String STRING_SELECT_ID_NAME = 'SELECT Id, Name,';
	public static final String STRING_FROM_APTUS_CONFIG = ' FROM Apttus_Config2__LineItem__c WHERE Id != null';

	public static final String STRING_SYSTEM_ADMINISTRATOR = 'System Administrator';
	public static final String STRING_BG_BASE = 'BG Base';
	public static final String STRING_ONBOARDING = 'Enterprise Onboarding';
	public static final String STRING_TEST_ATTACHMENT_FOR_PARENT = 'Test Attachment for Parent';
	public static final String STRING_TEST_DATA = 'Test Data';
	public static final String STRING_TEMPLATE = 'Template';

	public static final String XML_STRING1 = '<?xml version="1.0" encoding="UTF-8"?><ConfigRequest><BusinessObjectId>';
	public static final String XML_STRING2 = '</BusinessObjectId><BusinessObjectType>Proposal</BusinessObjectType><BusinessObjectTitle>';
	public static final String XML_STRING3 = '</BusinessObjectTitle><PriceListId>';
	public static final String XML_STRING4 = '</PriceListId><AccountId>';
	public static final String XML_STRING5 = '</AccountId><FinalizePage>Apttus_QPConfig__ProposalFinalize</FinalizePage><CallerPackageNS>Apttus_QPConfig</CallerPackageNS><Fields><Field><Name>Name</Name><Value>';
	public static final String XML_STRING6 = '</Value></Field><Field><Name>Apttus_Config2__EffectiveDate__c</Name><Value>';
	public static final String XML_STRING7 = '</Value></Field><Field><Name>Apttus_QPConfig__Proposald__c</Name><Value>';
	public static final String XML_STRING8 = '</Value></Field><Field><Name>Apttus_Config2__ExpectedStartDate__c</Name><Value>';
	public static final String XML_STRING9 = '</Value></Field><Field><Name>Apttus_Config2__ExpectedEndDate__c</Name><Value>';
	public static final String XML_STRING10 = '</Value></Field></Fields></ConfigRequest>';

	//public static String MERGE_SERVER_SETTINGS = '/' + 'services' + '/' + 'Soap' + '/' + 'u' + '/' + '29.0' + '/';
	public static final String CONTRACT_LINK_ACCESS = 'Please click on the below link to access contract: ';
	public static final String CREATE_CONTRACT_JOB_ERROR = '*** Create Contract Job Error ***';
	public static final String CREATED_CONTRACT_JOB_COMPLETED_WITH = 'Create Contract Job Completed with ';
	public static final String CREATE_CONTRACT_JOB_STATUS = '*** Create Contract Job Status ***';
	public static final String CREATE_CONTRACT_JOB_COMPLETED_SUCCESSFULLY = 'The Create Contract Job Completed Successfully.';

	public static final String FILE_NAME_MERGE = 'Merge';

	public static final String UNEXPECTED_END_OF_FILE_FROM_SERVER = 'Unexpected end of file from server';

	public static final String CATEGORY_DEFAULT = 'Default';
	public static final String CATEGORY_SUBMIT = 'Submit';

	public static final String STATUS_CATEGORY = 'Completed';
	public static final String STATUS_FAILED = 'Failed';
	public static final String DOC_FORMAT_PDF = '.pdf';

	public static final String EMAIL_TEST_USER = 'testuser@apttusdemo.com';
	public static final String ALIAS_TEST_USER = 'testuser';
	public static final String EMAILENCODINGKEY_TEST_USER ='ISO-8859-1';
	public static final String LASTNAME_TEST_USER = 'Smith';
	public static final String LANGUAGELOCALEKEY_TEST_USER = 'en_US';
	public static final String LOCALESIDKEY_TEST_USER = 'en_AU';
	public static final String TIMEZONESIDKEY_TEST_USER = 'Australia/Sydney';

	//Async Merge Constants
	public static final String ASYNC_ACTION_GENERATE = 'Generate';
	public static final String ASYNC_ACTION_REGENERATE = 'Regenerate';
	public static final String ASYNC_CALL_TYPE = 'Merge Document';
	public static final String ASYNC_DOC_TYPE_PDF = 'PDF';
	public static final String ASYNC_PROTE_LEVEL_COMMENT_AND_TRACK_CHANGE = 'Insert comments and tracked changes only';

	//Template constants
	public static final String TYPE_AGR = 'Agreement';
	public static final String AGR_TYPE_MSA_SERVICE = 'MSA & Service Schedule';
	public static final String CATG_SUBMIT = 'Submit';
	public static final String SUBCATG_DEFAULT = 'Default';
	public static final String LANG_ENG = 'English';
	public static final String LOCALE_ENG = 'English (United Kingdom)';

	public static final String SOAP_FAULT = 'SOAP Fault:';
	public static final String FAULT_CODE = 'faultcode=';

	public static final String SETTLEMENT_PROFILE_3 = '003 - 3 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_5 = '005 - 5 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_7 = '007 - 7 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_14 = '014 - 14 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_15 = '015 - 15 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_28 = '028 - 28 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_30 = '030 - 30 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_45 = '045 - 45 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_60 = '060 - 60 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_90 = '090 - 90 Days from Invoice';
	public static final String SETTLEMENT_PROFILE_120 = '120 - 120 Days from Invoice';
	public static final String PRICING_PLAN_1_2 = '1.2';
	public static final String PRICING_PLAN_1_3 = '1.3';
	public static final String PRICING_PLAN_1_4 = '1.4';
	public static final String PRICING_PLAN_1_5 = '1.5';
	public static final String PRICING_PLAN_1_6 = '1.6';
	public static final String PRICING_PLAN_1_7 = '1.7';
	public static final String PRICING_PLAN_1_8 = '1.8';
	public static final String PRICING_PLAN_1_9 = '1.9';
	public static final String PRICING_PLAN_2_0 = '2.0';
	public static final String PRICING_PLAN_2_1 = '2.1';
	public static final String PRICING_PLAN_2_2 = '2.2';
	public static final String PRICING_PLAN_2_3 = '2.3';
	public static final String PRICING_PLAN_2_4 = '2.4';
	public static final String PRICING_PLAN_3_5 = '3.5';

	public static final String Other_Product = 'OtherProduct';
	public static final String eParcel_Product = 'eParcelProduct';

	public static final String Signer = 'Signer';
	public static final String In_Person_Signer = 'In Person Signer';
	public static final String HelpText = 'HelpText';
	public static final String MinSigners = 'MinSigners';
	public static final String MIN_RECIPIENT_ERROR = ' Minimum Number of Signers for this Contract Type is: ';

	public static final String URL_ADD_SIGNER = '/apex/Apttus_DocuApi__DefaultRecipient?id=';

	public static final string strCustomerName = 'Customer Name';

	public static final String CASE_DETAILS = 'Case Details';
	public static final String PROCESSING_IMAGE = 'Processing.. Please wait..';
	public static final String SAVE_BUTTON = 'Save';
	public static final String CANCEL_BUTTON = 'Cancel';

	public static final String RECORD_TYPE_NAME_MSA = 'MSA';
	public static final String SUBTYPE_LONG_FORM = 'Long Form';
	public static final String TERM_OPEN_ENDED = 'Open Ended';

	public static final String STATUS_CATEGORY_IN_EFFECT = 'In Effect';
	public static final String APT_Unique_fields = 'APT_Minimum_Quantity__c,Category__c';
	public static final String APT_Cash_Account = 'Cash Account';
	public static final String Legacy_Id = '60000000';
	public static final String Prospect = 'Prospect';
	public static final String Known = 'Known';
	public static final String Error = 'ERROR';

	public static final String Organisation_ABN_ACN_Duplicate = 'There is an existing Organisation with this identical ABN or ACN';
	public static final String Organisation_ACN_Invalid = 'Organisation ACN does not Match with Veda ACN : ';
	public static final String Organisation_ABN_Invalid ='Organisation ABN does not Match with Veda ABN : ';
	public static final String Organisation_Name_Invalid = 'Organisation Name does not Match with Veda organisation Name: ';
	public static final String Check_details_and_try_again = ' Check details and try again';
	public static final String Individual_Credit_Assessment_Results = 'Individual Credit Assessment Results';
	public static final String Credit_Assessment_Outcome = 'Credit Assessment Outcome';
	public static final String Account_Role_must_be_Prospect = 'Account Role must be Prospect.';
	public static final String Credit_Assessment_Less_then_5k_are_Automatically_approved = 'Credit Assessment Less then 5k are Automatically approved';
	public static final String Organisation_Name_ABN_ACN_Match_with_Older_Customer_Organisation = 'Organisation Name/ABN/ACN Match with Older Customer Organisation';
	public static final String Estimated_Credit_Limit_is_greated_then_25000 = 'Estimated Credit Limit is greated then 25000';
	public static final String Organisation_Name_does_not_Match_with_Veda_organisation_Name = 'Organisation Name does not Match with Veda organisation Name';
	public static final String Veda_Entity_type_is_Trust = 'Veda Entity type is Trust';
	public static final String PageType = 'PageType';
	public static final String No_Credit_Assessments_Found = 'No Credit Assessments Found.';
	public static final String Multiple_Credit_Assessments_Referred_to_Credit_Team = 'Multiple Credit Assessments Referred to Credit Team';
	public static final String Credit_Assessment_Referred_to_Credit_Team = 'Credit Assessment Referred to Credit Team';
	public static final String B_Mining = 'B Mining';
	public static final String Standard_Price = 'Standard Price';
	public static final String Aust_Antarctic_Territory = 'Aust Antarctic Territory';
	public static final String TestaPTTUS = 'TestaPTTUS';
	public static final String Product_Configuration = 'Product Configuration';
	public static final String Ad_Hoc = 'Ad Hoc';
	public static final String Ready_For_Finalization = 'Ready For Finalization';
	public static final String eParcelExpress = 'eParcelExpress';
	public static final String account_query = 'select id from account where Role_Type_Roll_Up__c=: cust AND (';
	// public static final String account_query = 'select id from account where (';
	public static final String Customer = 'Customer';
	/* Start: Meet Desai: Updated Apttus Merge Service's API Version from 29 to 38 */
	public static final String services_Soap_u_38_0 = '/services/Soap/u/38.0/';
	public static final String services_Soap_u_52_0 = '/services/Soap/u/52.0/';
	/* End: Meet Desai: Updated Apttus Merge Service's API Version from 29 to 38 */
	public static final String Left_curly_bracket = '{';
	public static final String product_non_contracted = ', Apttus_Proposal__Product__r.Non_contracted__c,';
	public static final String product_product_type = ' Apttus_Proposal__Product__r.APT_Product_type__c ';
	public static final String Record_Update_Successfull = 'Record Updated Successfully';

	public static final String Australia_Post_All_Categories = 'Australia Post - All Categories';
	public static final String CAT_OFFERING = 'Offering';
	public static final String SOQL_PROPOSAL_OBJECT = 'Apttus_Proposal__Proposal__c';
	public static final String PROPOSAL_NAME = 'Test Proposal';
	public static final String SOQL_CASHACCOUNT_OBJECT = 'APT_Cash_Account__c';
	public static final String SOQL_SUBACCOUNT_OBJECT = 'APT_Sub_Account__c';
	public static final String SOQL_CHARGEACCOUNT_OBJECT = 'APT_Charge_Account__c';
	public static final String FIELDSETNAME = 'Dimension';
	public static final String FIELDSETNAME_EXPORT = 'Dimension_For_Export';
	public static final String QUERYSTRING_ACCOUNT = 'APT_Selected__c FROM ';
	public static final String WHERECLAUSE_ACCOUNT = ' Where APT_Organisation__c =:accId';
	public static final String EXPORTACCOUNT_URL = '/apex/APT_exportAccountDetail?id=';
	public static final String GettAccoundDetail_URL = '/apex/APT_GetAccountDetails?id=';
	public static final String QUERYSTRING_SELECTEDACCOUNTS = ' Where APT_Organisation__c =:accId AND APT_Selected__c=true';

	public static final String strHeader = '<?xml version="1.0"?> <?mso-application progid="Excel.Sheet"?>';

	public static final String EPARCELS_DOMESTIC = 'eParcels Domestic';
	public static final String INTERNATIONAL = 'International';
	public static final string multiple_values = 'Multiple Values';

	public static final string CONFIG_TYPE_STAND_ALONE = 'Standalone';

	public static final string FIELDSETNAME_CASHACCOUNT_LP = 'APT_Dimension_for_Cash_Account';
	public static final string FIELDSETNAME_SUBACCOUNT_LP = 'APT_Dimension_for_Sub_Account';
	public static final string FIELDSETNAME_CHARGEACCOUNT_LP = 'APT_Dimension_for_Charge_Account';
	public static final string WHERECLAUSE_AGMTLP = ' where APT_Charge_Account__c IN:allIdSet OR APT_Cash_Account__c IN:allIdSet OR APT_Sub_Account__c IN:allIdSet';

//***Test Class Constant Created By Jetha ***********//
	public static final String TEST_ACCOUNT_TYPE = 'Charge Account + Sub Account';
	public static final String TEST_ACCOUNT_ACN = '123456789';
	public static final String TEST_ACCOUNT_ABN = '12345678910';
	public static final String TEST_ACCOUNT_LEGACY_ID = '60000000';
	public static final String TEST_Cust_NAME = 'Test Customer';
	public static final String TEST_Cust_STATE = 'ACT';
	public static final String TEST_BUSINESS_NAME = 'Test Business Name';
	public static final String TEST_BRANCH = 'State Branch';
	public static final String TEST_COUNTRY_CODE = 'AU';
	public static final String TEST_STATUS_OPEN = 'Open';
	public static final Integer NUMBER_1 = 1;
	public static final Integer NUMBER_10 = 10;
	public static final String APPROVAL_STATUS_SUBMITTED = 'Submitted';
	public static final Integer NUMBER_9999 = 9999;
	public static final String DEVELOPER_NAME_DELIVERY_1 = 'Delivery_1';
	public static final String NETWORK_SOBJECT_TYPE = 'Network__c';
	public static final String STRING_LOGGEMENT = 'Lodgement';

	// Constants added for international CO
	public static final String STRING_XLS ='xls';
	public static final String IS_CALL_FROM_RC = 'isCallFromRC';
	public static final String MAIL_SUBJECT_RC = '*** View Rate Calculators***';
	public static final String STRING_RATE_CALC_BATCH_JOB = 'Rate Calculator Batch job has processed ';
	public static final String STRING_YOUR_RATE_CARD_HAS_BEEN_GENERATED = '</p><p> Your Rate Calculators have been generated. Click this <a href="';
	public static final String FILE_DIGITALCODE = 'Digital';
	public static final String FILE_NDIGITALCODE = 'Non_Digital';
	public static final String FILENAME_CODE_INT = '_International_';
	public static final String FILENAME_CODE_RATE ='_Rate_Calculator.xlsx';
	public static final String STRING_AND_GO_TO_NOTES_AND_ATTACHMENTS_RC = 'and go to Notes and Attachments Section to view the Rate Calculator.</p>';
	public static final String PRODUCT_NAME_INTERNATIONAL_BUNDLE = 'International Bundle';
	public static final String OFFER_HIGHER_BAND = 'Offer Higher Band';

	public static final String PRICING_SCHEDULE = 'Pricing Schedule';

	public static final String CREATE_AMENDMENT_CONTRACT = 'Create Contract Amendment';

	public static final String RATE = 'Rate';
	public static final String DETAILED_RATE = 'Detailed Rate';

	public static final String CONTRACT_NUMBER_PARM = 'cntrNbr_1';

	public static final String R2T_CONTRACT_LETTER_HEAD = 'R2T Contract Letterhead';
	public static final String R2T_QUOTE_LETTER_HEAD_FOOTER = 'R2T_Quote_LetterHead_Footer';
	public static final String PARMA_ID = '?id=';
	public static final String PARMA_O_ID = '&oid=';

	public static final String RECORD_TYPE_POST_BILLPAY_CONTRACT = 'Post Billpay Contract';
    public static final String RECORD_TYPE_POST_BILLPAY_OS = 'Post_BillPay';
    public static final String PRODUCT_CODE_POSTBILLPAY ='PBP';

	public static final String SAP_CONTRACT_OBJECT = 'APT_SAP_Contracts__c';
	public static final String FROM_SAP_CONTRACT_OBJECT = ' FROM APT_SAP_Contracts__c WHERE APT_Apttus_Contract__c = :originalAgreementId';
	public static final String FROM_WHERE_SAP_CONTRACT_STATUS = ' FROM APT_SAP_Contracts__c WHERE APT_Apttus_Contract__c = :originalAgreementId and SAP_Contract_Status__c != \'Inactive\' ';


	public static final String ADMIN_LARGE_CART_THRESHOLD = 'APTS_LargeCartThreshold';
	public static final String PRICE_STRUCTURE_WINE_Z30 = 'WINE {Z30}';

	public static final String CREDIT_ASSESSMENT_ALREADY_APPROVED_OR_REFERRED = 'Credit Assessment has been already approved or rejected.';
	//public static final String CREDIT_ASSESSMENT_ALREADY_REFERRED = 'The Credit Assessment has been already referred.';
	public static final String CREDIT_ASSESSMENT_ALREADY_REFERRED = 'The Credit Assessment is pending.';
	public static final String CREDIT_ASSESSMENT_ALREADY_APPROVED = 'Approved Credit Assessment exists and the request will be referred to Credit Management.';
	public static final String CREDIT_ASSESSMENT_ALREADY_DECLINE = 'Declined Credit Assessment exists against the Customer and the request will be Referred to Credit Management.';
	public static final String CREDIT_ASSESSMENT_ALREADY_REJECTED = 'Rejected Credit Assessment exists against the Customer and the request will be Referred to Credit Management.';

	public static final String ENTITY_TYPE_FPT = 'FPT';
	public static final String ENTITY_TYPE_PTR = 'PTR';
	public static final String ENTITY_TYPE_LTP = 'LTP';
	public static final String ENTITY_TYPE_LTDP = 'LTDP';
	public static final String ENTITY_TYPE_PARTNERSHIP = 'Partnership';

	public static final String OBJECT_CONTRACT = 'APT_Apttus_Contract__c';
	public static final String MIN_DATE = 'minDate';
	public static final String OFFLINE_RATES = 'Offline Rates';
	public static final String OFFLINE = 'Offline';

	public static final String CREDIT_ASSESSMENT_STATUS_CANCELLED = 'Cancelled';
	public static final String CREDIT_ASSESSMENT_STATUS_COMPLETED = 'Completed';

	public static final String SOBJECT_OPPORTUNITY_PRODUCT_LINE_ITEM = 'APT_Opportunity_Product_Line_Item__c';
	public static final String OPPORTUNITY_RECORD_TYPE_NEW_OPPORTUNITY_TYPE = 'APT_New_Opportunity_Type';
	public static final String OPPORTUNITY_RECORD_TYPE_EXISTING_OPPORTUNITY_TYPE = 'APT_Existing_Opportunity_Type';

	//Added By HA
	public static final string PRODUCT_AIRMAILLETTER='AIRMAIL_LETTERS';
	public static final string PRODUCT_EXTRACOVER='ExtraCover';
	public static final string PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE='ECONOMY_SIG';
	public static final string PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE='STANDARD_SIG';
	public static final string PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE='InternationalDigitalPCMSBundle';
	public static final string PRODUCT_InternationalExpressDocuments='EXPRESS_DOCT';
	public static final string PRODUCT_InternationalExpressMerchandise='EXPRESS_MERCH';
	public static final string PRODUCT_InternationalStandard='STANDARD';
	public static final string PRODUCT_InternationalEconomy='ECONOMY';
	public static final string PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS='RETURNS_EXPRESS';
	public static final string PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD='RETURNS_STANDARD';
	public static final string PRODUCT_MinimumCollectionValue='COLLECTION_FEE';
	public static final string PRODUCT_MissingManifestFee='MISSING_MANIFEST_FEE';
	public static final string PRODUCT_AdministrativeFee='ADMINISTRATIVE_FEE';
	public static final string PRODUCT_InternationalExtraCover='InternationalExtraCover';

	//Added for weight Range and Weight Codes
	public static final string Weight_0_5='0.5';
	public static final string Weight_1='1.0';
	public static final string Weight_2='2.0';
	public static final string Weight_20='20.0';


	public static final string Weight_Upto500g='up to 500g';
	public static final string Weight_Over500gupto1kg='over 500g up to 1kg';
	public static final string Weight_Over1kgupto2kg='over 1kg up to 2kg';
	public static final string Weight_Upto2kg='up to 2kg';
	public static final string Weight_Over2kgupto20kg='over 2kg up to 20kg';


	public static final string NEW_INT_BUNDLE='INTERNATIONAL_NEW_DIGITAL';
	public static final string NEW_INT_BUNDLE_RENEW='INTERNATIONAL_RENEWAL_DIGITAL';
	public static final string INT_YES='YES';
	public static final string INT_NO='NO';
	public static final string INT_Y='Y';
	public static final string INT_N='N';

	public static final string INTERNATIONAL_AIRMAIL_LETTERS='International Airmail Letters';
	public static final string CONFIGID ='ConfigId';
	public static final string BUNDLELINENO ='BundleLineNo';
	public static final string PROPOSALID ='ProposalId';

	public static final string OPERATIONAL_SCHEDULE_STARTTRACK_RECORDTYPE = 'Startrack';
	public static final string OPERATIONAL_SCHEDULE_WORKFORCE_VERIFICATION_RECORDTYPE = 'Workforce Verification';
	public static final string OPERATIONAL_SCHEDULE_STARTRACK_PRODUCT_TYPE = 'StarTrack';
	public static final string OPERATIONAL_SCHEDULE_EXPRESS_ROAD_PRODUCT= 'Road Express - STE';
	public static final string OPERATIONAL_SCHEDULE_SPECIAL_SERVICES_PRODUCT = 'Special Services - STE';
	public static final string OPERATIONAL_SCHEDULE_PRIORITY_AIR_SERVICES_PRODUCT = 'Premium - STE';
	public static final string OPERATIONAL_SCHEDULE_SECURITY_SERVICES_PRODUCT = 'Security Express - STE';
	public static final string OPERATIONAL_SCHEDULE_NEXT_FLIGHT_PRODUCT = 'Next Flight - STE';

	//ST Pricing
	public static final String ST_PRICING_PROPERTIES = 'ST Pricing Properties';
	public static final String ST_SINGLE_PRICING_PROPERTIES = 'ST Single Pricing Properties';
	public static final string PRODUCTTYPE_STARTRACK = 'StarTrack';
	public static final string NO_PRODUCT_ST_PRICING = 'No product found for startrack pricing.';
	public static final string RECORDTYPE_STARTRACK = 'Star Track';
	public static final String FIELD_EXPR = 'FieldExpr';
	public static final String ZONE_TYPE = 'Zone Type';
	public static final String PRICE_TYPE = 'Price Type';
	public static final String INBOUND = 'Inbound';
	public static final String OUTBOUND = 'Outbound';
	public static final String ZONE_TYPE_DIRECT = 'Direct';
	public static final String ZONE_TYPE_ONFORWARDING = 'Onforwarding';
	public static final String ZONE_TYPE_ONFORWARDING_ALTERNATE = 'Onforwarding Alternate';
	public static final String ZONE_TYPE_ALTERNATE = 'Alternate';
	public static final String ST_PRICE_TYPE_BASE = 'Base';
	public static final String ST_PRICE_TYPE_MINIMUM = 'Minimum';
	public static final String ST_PRICE_TYPE_PER_KG = 'Per Kg';
	public static final String ST_LODGEMENT_ZONE_API = 'APT_Lodgement_Zone_Code__c';
	public static final String ST_DIRECT_ZONE_API = 'APT_Direct_Zone__c';
	public static final String ST_ONFORWARDING_ZONE_API = 'APT_Onforwarding_Zone__c';
	public static final String ST_ONFORWARDING_ALTERNATE_ZONE_API = 'APT_Onforwarding_Alternate_Zone__c';
	public static final String ST_SINGLE_VALUES_TO_EXCLUDE = 'Outbound - Inbound,Lodgement Zone,Destination Zone,Rate Card Version,Rate Card Updated On,Rate Card Updated On,Zone Type';
	public static final String OG_SE_PRICING_PRODUCTS = 'Security Express Pricing Products';
	public static final String OG_EXP_PRICING_PRODUCTS = 'EXP Pricing Products';
	public static final String OG_PREMIUM_PRICING_PRODUCTS = 'Priority Air Service Pricing Products';
	public static final String OG_SPECIAL_PRICING_PRODUCTS = 'Special Services Pricing Products';
	public static final String OG_NEF_PRICING_PRODUCTS = 'NXF Pricing Products';

	public static final string POSTCODEANDSUBURB_ATTRIBUTE_ERROR = 'Please select Postcode-Suburb Attribute for: ';
	public static final string RECORDTYPE_AUSPOST = 'AusPost';

	public static final string DETERMINE_ST_ZONE_TYPES_PROCESSED = 'The Determine ST ZoneTypes Batch job has processed ';

	public static final string RATE_TYPE_OFFLINE = 'Offline';
	public static final string RATE_TYPE_STANDARD = 'Standard';

	//Docusign Recipients
	public static final string DOCUSIGN_RECIPIENT_RECORDTYPE_CONTACT = 'Contact';
	public static final string DOCUSIGN_RECIPIENT_RECORDTYPE_USER = 'User';
	public static final string DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL = 'Email';
	public static final string AUSPOST_EMAIL = 'auspost.com';

	//Operational Schedule Track Mail
	public static final string OPERATIONAL_SCHEDULE_TRACKMAIL_PRODUCT_TYPE = 'Track Mail';
	public static final String AND_INCLUDE_LP_FILTER = ' AND Org_ID__c IN: incExcLPs';
	public static final String AND_EXCLUDE_LP_FILTER = ' AND Org_ID__c NOT IN: incExcLPs';
	public static final String INCLUDE = 'Include';
	public static final String EXCLUDE = 'Exclude';

	//APPC PSR Details
	public static final String RECORD_TYPE_NAME_APPC = 'Australia_Post_Parcel_Contract'; //UserStory:CI-126
	public static final String PSR_APPC_RECORD_TYPE_APINAME = 'Pricing_Support_Request_Australia_Post_Parcel_Contract';
	public static final String PSR_APPC_PRODUCT_NAME = 'Australia Post Parcel Contract';
	public static final String PSR_STATUS_COMPLETE = 'Completed';
	public static final String PSR_STAGE_COMPLETE = 'Completed';
	public static final String PSR_APPC_STANDARD_DELEGATED_PRICING = 'Delegated Pricing';
	public static final String PSR_APPC_CUSTOM_PRICING = 'Customised Pricing';

	public static final string PRICING_CATEGORY_STANDARD = 'Standard';
	public static final String RATING_PLAN_ACTIVATION_LABEL = 'RatingPlanActivation';
	public static final String RATING_CARD_ACTIVATION_LABEL = 'RateCardActivation';

	public static final String APPC_CUSTOMER_TIER_DEFAULT = 'CUST_TIER_DEFAULT';
	public static final String ANYWHERE_PRICE_STRUCTURE = 'Z001';

	public static final String APT_KG_Rate = '_KR';
	public static final String APT_Basic_Rate = '_BR';
	public static final String RATING_MODEL_PD = 'PD';
	public static final String TC_PRICEPOINT_ALWAYS_ON='TCOVER-NR';
	public static final String TC_IDENTIFIER_ALWAYS_ON='TCOVER-NR'+'_'+'FE002';
	public static final String TC_PRICEPOINT_ADHOC='TCOVER-1';
	public static final String TC_IDENTIFIER_ADHOC='TCOVER-1'+'_'+'FE002';
	public static final String TC_COVER_TYPE_ALWAYS_ON='Always On';
	public static final String TC_COVER_TYPE_ADHOC='Adhoc';
	public static final set<string> TRANSIT_COVER_PRODUCTS=new set<string>{'Standard Parcel Transit Cover','Premium Express Parcel Transit Cover'};
	public static final map<string,string> TC_PP_TYPE_MAP = new map<string,string>{'TCOVER-1_FE002'=>'Adhoc','TCOVER-NR_FE002'=>'Always On'};

	public static final String OPPORTUNITY_STAGENAME_CLOSED_LOST = 'Closed Lost';
	public static final Integer OTHER_ROLE_BUFFER_DAYS = 10;
	public static final Integer START_DATE_BUFFER_DAYS = 15;
	public static final Integer END_DATE_BUFFER_DAYS = 365;
	public static final String APT_CARBON_COPY = 'Carbon Copy';
	public static final String APT_Contact_RECORDTYPE = 'Customer';
	public static final String APT_DOCUSIGN_RECIPIENTS_TYPE_SALES_USER = 'Sales user';
	public static final String APT_DOCUSIGN_RECIPIENTS_TYPE_CUSTOMER = 'Customer';

	//Email
	public static final String EMAIL_TEMP_AGREEMENT_SIGNED_AFTER_EXPIRY = 'APT_AgreementSignedAfterOfferExpiry';
	public static final String ORG_WIDE_EMAIL_NO_REPLY = 'noreply@auspost.com.au';

	public static final Integer CLOSE_DATE_DEFAULT_DAYS = 30;
}