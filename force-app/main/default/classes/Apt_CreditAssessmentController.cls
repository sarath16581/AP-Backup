/**
* @author Himanshu jain
* @date 2015-10-01
* @group Controller
* @tag Controller
* @tag CSP
* @domain CreditAssessment
* @description Integrate with TIBCO for credit assessment flow
* @changelog
* 2015-10-01 - Himanshu jain - Created
* 2016-09-07 - Mausam Padhiyar - Negative Credit Limit
* 2016-09-15 - Mausam Padhiyar - Credit Assessment referred manually?
* 2016-11-15 - Mausam Padhiyar - Credit Assessment referred manually?
* 2016-11-25 - Mausam Padhiyar - 1552
* 2016-12-14 - Mausam Padhiyar - 1550
* 2016-12-19 - Mausam Padhiyar - 1549
* 2017-01-20 - Mausam Padhiyar - 1746
* 2017-04-27 - Sheryl Crisostomo - 1855 - Added new custom label to update State error message
* 2020-09-16 - Lija Jawahar - Update proposal with credit assessment details
* 2020-11-20 - Seth Heang - STP 3414 - Modify Account 'Update' functionalty, Hide 'Next' and 'Update' button based on Organisation Roles of Known, Prospect or Customer
* 2020-12-11 - Shashwat Nath - STP 2832 - Populate Values for "Aus Post Proposed for New Account" and "StarTrack Proposed for New Account" field on Credit Assessment.
* 2021-05-05 - Madhuri Awasthi - REQ2472870 - Credit Limit Field Calculation EnhancementRequest
* 2021-05-06 - Dheeraj Mandavilli - STP 4285 - Added a new VF page to Navigate to SubAccountRequest Form LWC component from Credit Asessment process initiated from Propsoal Record.
* 2021-05-21 - Dheeraj Mandavilli - STP 5839 - Added logic to switch between LWC component and VF page based upon Teams vs SAP from Credit Asessment process initiated from Propsoal Record.
* 2021-06-08 - Seth Heang - STP 5389 - Pre-populate Trustee Name and Trustee ACN from Opportunity
* 2023-03-02 - Harry Wang - STP-7602 - adding new parameter: contextId allowing redirect based on contextId
* 2023-04-19 - Ken McGuire - Proposal field migration to opportunity
* 2023-11-26 - Harry Wang - Adding navigation to Create_Sub_Accounts lightning component tab
*/

public with sharing class Apt_CreditAssessmentController {

	public AddressExtension mailingAddress {get;set;}
	public AddressExtension physicaladdress {get;set;}
	public AddressExtension soleTraderAddrress{get;set;}
	public AddressExtension residentialAddress{get;set;}

	private static final Integer NEAREST_ROUND_OFF = 100;

	//Adding new variables for RoundUp thousands

	private static final Integer NEAREST_ROUND_OFF_2 = 1000;
	private static final Integer NEAREST_ROUND_OFF_3 = 999;
	public Integer creditRoundUp = null;
	public Integer creditRoundUpResult=null;

	public boolean showMultipleRefer{get;set;}

	public boolean isAccountFlow { get; set;}
	public boolean isAnonymousFlow { get; set;}
	//private variables
	private String creditAssesmentId;
	private String proposalId;
	private String contextId;
	public decimal sum {get;set;}
	public string entityTypeForAssessment;
	public boolean isGovernmentEntity;


	Public String PageType {get;set;}

	public static final string PAGE_TYPE_CHARGE_ACCOUNT = 'ChargeAccount';
	public static final string PAGE_TYPE_SEARCH_ABN = 'searchABN';
	public static final string PAGE_TYPE_ABN_RESULTS = 'ABNResults';
	public static final string PAGE_TYPE_SHOW_DETAILS = 'showDetails';
	public static final string PAGE_TYPE_COMPANY_BUSINESS = 'company';
	public static final string PAGE_TYPE_SOLE_TRADER = 'individual';
	public static final string PAGE_TYPE_RESULTS = 'result';
	public static final string PRE_DECLINE = 'PRE_DECLINE';
	public static final string PRE_REFER = 'PRE_REFER';
	public static final string APPLICATION_DECISION = 'applicationDecision';
	public static final string DESCRIPTION = 'description';
	public static final string RESPONSE_EXCEPTION = 'Exception';
	public static final string EXCEPTION_DESCRIPTION = 'ExceptionDescription';
	public static final string COMPANY_BUSINESS_DECISION = 'companyBusinessDecision';
	public static final string COMPANY_BUSINESS_ASSESSMENT_OUTCOME = 'Company Business Credit Assessment Outcome';
	public static final string AUTO_APPROVED = 'Auto-Approved';
	public static final string ORGANIZATION_TYPE_GOVERNMENT = 'GOVT';
	public static final string OTHER_TYPE = 'Other';
	public static final string ENTITY_TYPE_OIE = 'OIE';
	public static final string OTHER_INCORPORATED = 'OTHER_INCORPORATED';
	public static final string OTHER= 'OTHER';
	public static final string MANUAL_ENTRY_SCREEN= 'Manual Entry Screen';
	public static final string WORK_IN_PROGRESS = 'Work-In-Progress';


	//public variables
	public List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgIdResultList {get;set;}


	public APT_Credit_Assessment__c creditAssesment {get;set;}

	public APT_ASIC_Report__c selectedASICReport {get;set;}
	public APT_ABRreport__c selectedABRReport {get;set;}

	public Integer selectedOrgIdUniqueNumber {get;set;}

	public String ServiceType{get;set;}
	private String accountID;
	public Account account {get;set;}
	public String userinput{get;set;}
	public String assesmentType{get;set;}

	public String OrgIdAssessmentStatusLT5K{get;set;}
	public Boolean OrgIdNameMatchLT5K{get;set;}

	public Boolean isEverythingOk {get;set;}

	public boolean showChargeAccount {get{
		return PAGE_TYPE_CHARGE_ACCOUNT.equalsIgnoreCase(PageType);
	} set;}
	public Boolean showSearchCreditAssessment {get{
		return (PAGE_TYPE_SEARCH_ABN.equalsIgnoreCase(PageType) || PAGE_TYPE_ABN_RESULTS.equalsIgnoreCase(PageType));
	} set;}
	public Boolean showCompanyBusiness {get{
		return PAGE_TYPE_COMPANY_BUSINESS.equalsIgnoreCase(PageType);
	} set;}
	public Boolean showSoleTrader  {get{
		return PAGE_TYPE_SOLE_TRADER.equalsIgnoreCase(PageType);
	} set;}

	public Boolean showSearchResults {get{
		return PAGE_TYPE_ABN_RESULTS.equalsIgnoreCase(PageType);
	} set;}


	public Boolean showCreditAssesssmentResults {get{
		return PAGE_TYPE_RESULTS.equalsIgnoreCase(PageType);
	} set;}


	public static final string strTitle = 'Credit Assessment';
	public static string strGetValTitle {get{return strTitle;} set;}

	public static final string strTitleBusiness = 'Business Details';
	public static string strGetValTitleBusiness {get{return strTitleBusiness;} set;}

	public static final string strTitleMktOptOut = 'Marketing information Opt-out';
	public static string strGetValTitleMktOptOut {get{return strTitleMktOptOut;} set;}

	public static final string strTitlePrivacy = 'Privacy Statement';
	public static string strGetValTitlePrivacy {get{return strTitlePrivacy;} set;}

	public static final string strProcessing = 'Processing.. Please wait..';
	public static string strGetValProcessing {get{return strProcessing;} set;}

	public static final string strContinue = 'Continue';
	public static string strGetValContinue {get{return strContinue;} set;}

	public static final string strWait = 'Please wait..';
	public static string strGetValWait {get{return strWait;} set;}

	public static final string strBack = 'Back';
	public static string strGetValBack {get{return strBack;} set;}

	public static final string strTitleSearchOrg = 'Search Organisation (For best match result, please enter ACN where available)';
	public static string strGetValTitleSearchOrg {get{return strTitleSearchOrg;} set;}

	public static final string strSearchResults = 'Search Results';
	public static string strGetValSearchResults {get{return strSearchResults;} set;}

	// Hotlist variables
	public static final string strHotlistWarning = 'Hotlisted Customer Warning';
	public static string strGetValHotlistWarning {get{return strHotlistWarning;} set;}
	public Boolean proceedHotlistCreditAssessment {get; set;}
	public Boolean displayHotlistPopup {get; set;}

	Apttus_Proposal__Proposal__c proposal;
	Account accnt;

	//result Page Variables
	public String ResultPageTitle {get;set;}
	public String CreditAssessmentFinalOutcome {get;set;}


	@TestVisible
	String creditAssessmentId;
	String creditCheckExceptionMsg;

	public APT_CompanyCreditAssessmentWrapper.CompanyBusinessResponse_element responseWrapper {get; set;}
	public APT_IndividualCreditAssessmentWrapper.individualCommercialResponse_element individualResponseWrapper {get; set;}

	public boolean showCompanyBusinessResponse {get; set;}
	public boolean showSoleTraderResponse {get; set;}
	public Boolean showApprovedPage {get;set;}


	String opportunityId;
	public APT_Charge_Account__c chargeAccount {get; set;}
	public boolean displayPopUp {get; set;}
	public Apttus__APTS_Admin__c admin {get; set;}
	public boolean isReferred {get; set;}
	boolean isReportSelected = false;
	String accountType;
	public boolean isApprove {get; set;}
	public boolean accountIsUpdated {get; set;}
	public boolean disableCreditAssessmentBtn {get; set;}
	public boolean hideUpdateBtn {get; set;}
	public String totalProposedLimit {get;set;}

	//public String entityType;
	public boolean isEntityTypePartnership {get; set;}  //1550
	public Integer creditAssessmentRecordCount {get; set;}  //1550
	public APT_Credit_Assessment__c creditAssess;
	public boolean referToCredit;

	/* New Variables added for MW0003829 to store the original Organisation Name , ABN , ACN */
	public string originalOrganisationName;
	public string originalOrganisationABN;
	public string originalOrganisationACN;


	/**
	 This constructor method identifies that whether
	  we are getting from  account or proposal
	 and passing account info to credit assessment object
	**/
	public Apt_CreditAssessmentController (ApexPages.StandardController controller){
		try {
			if(String.isNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.PageType))){
				PageType = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get(APT_Constants.PageType));
			} else {
				PageType = PAGE_TYPE_CHARGE_ACCOUNT;
			}

			proceedHotlistCreditAssessment = false;
			isEntityTypePartnership = false;    //1550
			creditAssessmentRecordCount = 0;    //1550
			isEverythingOk = true;
			isGovernmentEntity = false;
			originalOrganisationName = '';
			originalOrganisationABN = '';
			originalOrganisationACN = '';
			hideUpdateBtn = false;
			accountIsUpdated = false;
			disableCreditAssessmentBtn = false;
			chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Entity_Type__c = COMPANY;
			admin =  new Apttus__APTS_Admin__c();
			proposal = new Apttus_Proposal__Proposal__c();
			responseWrapper = new APT_CompanyCreditAssessmentWrapper.CompanyBusinessResponse_element();
			individualResponseWrapper = new APT_IndividualCreditAssessmentWrapper.individualCommercialResponse_element();
			if(String.isNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_ID))){
				accountID = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_ID));
				accountType = Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_ACCOUNT_TYPE);
				isAccountFlow = true;

			} else if(String.isNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_PROPOSAL_ID))) {
				isAnonymousFlow = false;
				isAccountFlow = false;
				proposalID = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_PROPOSAL_ID));
				contextId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('contextId'));
				proposal = [SELECT id, Apttus_Proposal__Account__c, Apttus_Proposal__Account__r.Role_Type_Roll_Up__c,
						Apttus_Proposal__Account__r.Name, Apttus_Proposal__Opportunity__r.IsStartrackProposal__c,
						APT_Credit_Assessment_Status__c, Apttus_Proposal__Opportunity__c,Apttus_Proposal__Opportunity__r.amount,
						APT_Method_of_Payment__c, APT_Credit_Referred_Manually__c
				FROM Apttus_Proposal__Proposal__c
				WHERE Id =: proposalID];
				if(proposal != null ) {
					if(String.isNotBlank(proposal.Apttus_Proposal__Account__c)){
						accountID = proposal.Apttus_Proposal__Account__c;
					} else {
						isEverythingOk = false;
					}

					opportunityId = proposal.Apttus_Proposal__Opportunity__c;
					accountType = proposal.APT_Method_of_Payment__c;


				} else {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MISSING_PROPOSAL));
				}
			} else{
				isAccountFlow = false;
				isEverythingOk = false;
				isAnonymousFlow = true;
				mailingAddress = new AddressExtension(APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING);
				physicaladdress = new AddressExtension(APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING, APT_Constants.EMPTY_STRING);
			}
		} catch (exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
	}
	/**
		Init method
	**/
	public void init(){

		showSearchResults = false;
		PageType = PAGE_TYPE_CHARGE_ACCOUNT;
		creditAssesment = new APT_Credit_Assessment__c();
		assesmentType = APT_WebServiceUtility.ACN;
		referToCredit = false;
		try{
			if(String.isNotBlank(accountID)){
				account = [select ABN__c, Legal_Name__c, ACN__c, Name, Organisation_Trading_Name__c,Role_Type_Roll_Up__c,L2C_Star_Track_Approved_Credit_Limit__c,
						BillingPostalCode, BillingState, BillingStreet, BillingCity, BillingCountry,L2C_Approved_AP_Credit_Limit__c,
						ShippingState, ShippingPostalCode, ShippingStreet, ShippingCity, ShippingCountry,isPersonAccount, L2C_Hotlist__c
				from Account
				where id =: accountID];

				mailingAddress = new AddressExtension(account.billingStreet, APT_Constants.EMPTY_STRING, account.BillingCity, account.BillingState, account.BillingPostalCode, account.ABN__c, account.BillingCountry);
				physicaladdress = new AddressExtension(account.ShippingStreet, APT_Constants.EMPTY_STRING, account.ShippingCity, account.ShippingState, account.ShippingPostalCode, account.ABN__c, account.ShippingCountry);

				// Storing the Account Name , Account ABN and Account ACN into the Respective Variables created as per MW0003829 on 1/11/2019
				originalOrganisationName = account.name;
				originalOrganisationABN = account.ABN__c;
				originalOrganisationACN = account.ACN__c;

				if(String.isNotBlank(account.ACN__c)){
					userinput = account.ACN__c;
				} else if(String.isNotBlank(account.ABN__c)){
					userinput = account.ABN__c;
					assesmentType = APT_WebServiceUtility.ABN;
				}

				/**
				 * Check if the Orgnisation role is 'Customer', then flag 'hideUpdateBtn' to true
				 * the flag is used to hide the 'Update' button on VF page
				 *  */
				if(APT_Constants.Customer.equalsIgnoreCase(account.Role_Type_Roll_Up__c)){
					hideUpdateBtn = true;
				}

				chargeAccount.APT_Organisation__c = accountID;

				chargeAccount.APT_ABN__c = account.ABN__c;
				chargeAccount.APT_ACN__c = account.ACN__c;
				chargeAccount.APT_Company_Name__c = account.Name;

				/* Shashwat.Nath@Aupost.com added the below if else Condition as part of the user strory STP-2832 to auto calculate .
					1. If proposal is not startrack then AP proposed credit limit would be calculated based on Opportunity Amount multiplied by .25(which is configurable)
					   and is added to the already Aprroved AP credit limit at the Organisation Level.
					2. If proposal is startrack then ST proposed credit limit would be calculated based on Opportunity Amount multiplied by .25(which is configurable)
					   and is added to the already Aprroved ST credit limit at the Organisation Level.
				*/
				if('No'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
					chargeAccount.AP_Proposed_Credit_Limit__c = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c + (account.L2C_Approved_AP_Credit_Limit__c !=null ? account.L2C_Approved_AP_Credit_Limit__c : 0 )).intValue();
					chargeAccount.Star_Track_Proposed_Credit_Limit__c = (account.L2C_Star_Track_Approved_Credit_Limit__c !=null ? account.L2C_Star_Track_Approved_Credit_Limit__c : 0 ).intValue();
				}
				else If('Yes'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
					chargeAccount.Star_Track_Proposed_Credit_Limit__c = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c  + (account.L2C_Star_Track_Approved_Credit_Limit__c !=null ? account.L2C_Star_Track_Approved_Credit_Limit__c : 0 )).intValue();
					chargeAccount.AP_Proposed_Credit_Limit__c = (account.L2C_Approved_AP_Credit_Limit__c !=null ? account.L2C_Approved_AP_Credit_Limit__c : 0).intValue();
				}

				totalProposedLimit = '$'+ String.ValueOf((chargeAccount.AP_Proposed_Credit_Limit__c + chargeAccount.Star_Track_Proposed_Credit_Limit__c).intValue())+'.00';

				/* Shashwat.Nath@Auspost.com.code ends */

				//billing address
				chargeAccount.APT_Billing_Addres_State__c = mailingAddress.state;
				chargeAccount.APT_Billing_Address_Street_Postcode__c = mailingAddress.PostCode;
				chargeAccount.APT_Billing_Address_Suburb__c = mailingAddress.city;
				chargeAccount.APT_Billing_Address_Street_Name__c = String.isNotBlank(mailingAddress.Line1) ? (mailingAddress.Line1).left(25) : APT_Constants.EMPTY_STRING;
				chargeAccount.APT_Billing_Address_country_code__c = mailingAddress.country;
				chargeAccount.APT_Billing_Address_Street_Type__c = mailingAddress.Line2;
				chargeAccount.APT_Street_Address_Street_Type__c = physicaladdress.Line2;
				chargeAccount.APT_Billing_Address_Country_Code__c = String.isNotBlank(account.BillingCountry) ? account.BillingCountry.subString(0, 2):APT_Constants.EMPTY_STRING;

				//street address
				chargeAccount.APT_Street_Address_State__c = account.ShippingState;
				chargeAccount.APT_Street_Address_Street_Postcode__c = account.ShippingPostalCode;
				chargeAccount.APT_Street_Address_Suburb__c = account.ShippingCity;

				chargeAccount.APT_Street_Address_Street_Name__c = account.ShippingStreet;
				chargeAccount.APT_Street_Address_Country_Code__c = String.isNotBlank(account.ShippingCountry) ? account.ShippingCountry.subString(0, 2):APT_Constants.EMPTY_STRING;
			}

			if(String.isNotBlank(opportunityId)) {
				Opportunity oppty = [SELECT Id, Amount, ExpectedRevenue, Trustee_name__c, Trustee_ACN__c, KeyContact__r.Name,
						KeyContact__r.Phone, KeyContact__r.FirstName, KeyContact__r.LastName
				FROM Opportunity
				WHERE Id = :opportunityId];

				if(oppty != null) {
					if(oppty.Amount != null) {
						decimal creditLimitRequired = (oppty.Amount / 12) * 2;
						decimal roundedCreditLimitRequired = Math.ceil(creditLimitRequired/NEAREST_ROUND_OFF) * NEAREST_ROUND_OFF;
						chargeAccount.APT_Credit_Limit_Required__c = roundedCreditLimitRequired.setScale(2);
					}
					chargeAccount.APT_Name_of_Contact_Person__c = oppty.KeyContact__r.Name;
					chargeAccount.APT_First_Name__c = oppty.KeyContact__r.FirstName;
					chargeAccount.APT_Last_Name__c = oppty.KeyContact__r.LastName;
					chargeAccount.APT_Phone_Number__c = oppty.KeyContact__r.Phone;
					// STP-5389 pre-populate Trustee Name and Trustee ACN from Opportunity
					chargeAccount.APT_Trustee_Name__c = oppty.Trustee_name__c;
					chargeAccount.APT_Trustee_ACN__c = oppty.Trustee_ACN__c;
				}
			}
			if(string.isNotBlank(proposalID)){
				chargeAccount.APT_Quote_Proposal__c = proposalID;
			}

		} catch (exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
		orgIdResultList = null;
		showSearchResults = false;
	}


	/**
		Next for Charge Account
	 **/
	public PageReference doNextForChargeAccount() {
		try {
			if(chargeAccount.AP_Proposed_Credit_Limit__c ==null){
				chargeAccount.AP_Proposed_Credit_Limit__c = 0 ;
			}

			if(chargeAccount.Star_Track_Proposed_Credit_Limit__c==null){
				chargeAccount.Star_Track_Proposed_Credit_Limit__c= 0 ;
			}
			if((chargeAccount.AP_Proposed_Credit_Limit__c + chargeAccount.Star_Track_Proposed_Credit_Limit__c) < 1) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.L2C_Credit_Limit_Not_Populated));
				return null;
			}
			else{
				Sum = (chargeAccount.AP_Proposed_Credit_Limit__c + chargeAccount.Star_Track_Proposed_Credit_Limit__c).intValue() ;
				chargeAccount.L2C_Total_Proposed_Credit__c = String.ValueOf(Sum );

			}
			//1339
			decimal roundedCreditLimitRequired = 0;
			if(chargeAccount.APT_Credit_Limit_Required__c != null ){
				roundedCreditLimitRequired = Math.ceil(chargeAccount.APT_Credit_Limit_Required__c/NEAREST_ROUND_OFF) * NEAREST_ROUND_OFF;
			}
			chargeAccount.APT_Credit_Limit_Required__c = roundedCreditLimitRequired.setScale(2);

			if(!isAnonymousFlow){
				chargeAccount.APT_Billing_Addres_State__c = mailingAddress.state;
				chargeAccount.APT_Billing_Address_Street_Postcode__c = mailingAddress.PostCode;
				chargeAccount.APT_Billing_Address_Suburb__c = mailingAddress.city;
				chargeAccount.APT_Billing_Address_country_code__c = mailingAddress.country;
				chargeAccount.APT_Billing_Address_Street_Name__c = String.isNotBlank(mailingAddress.Line1) ? mailingAddress.Line1.left(25) : APT_Constants.EMPTY_STRING;
				chargeAccount.APT_Street_Address_State__c = physicalAddress.State;
				chargeAccount.APT_Street_Address_Street_Postcode__c = physicalAddress.PostCode;
				chargeAccount.APT_Street_Address_Suburb__c = physicalAddress.City;
				chargeAccount.APT_Street_Address_Country_Code__c = physicalAddress.Country;
				chargeAccount.APT_Street_Address_Street_Name__c = String.isNotBlank(physicalAddress.Line1) ? physicalAddress.Line1.left(25) : APT_Constants.EMPTY_STRING;
				chargeAccount.APT_Billing_Address_Street_Type__c = mailingAddress.Line2;
				chargeAccount.APT_Street_Address_Street_Type__c = physicaladdress.Line2;
			}
			chargeAccount.APT_CustomerAgreementToPrivacyStatement__c = true;
			displayPopUp = true;
			admin = [SELECT Id, Apttus__Code__c, Apttus__Value__c FROM Apttus__APTS_Admin__c
			WHERE Name =: APT_Constants.ADMIN_ENTRY_PRIVACY_STATEMENT limit 1];
		} catch(Exception ex){
			displayPopUp = false;
			PageType = PAGE_TYPE_CHARGE_ACCOUNT;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
		return null;
	}


	/**
		This method will return Company Business Types
	 **/
	public List<SelectOption> getCompanyBusinessType() {
		try {
			List<SelectOption> options = new List<SelectOption>();
			options.add(new SelectOption(APT_WebServiceUtility.ACN,APT_WebServiceUtility.ACN));
			options.add(new SelectOption(APT_WebServiceUtility.ABN,APT_WebServiceUtility.ABN));
			options.add(new SelectOption(APT_WebServiceUtility.ORGANIZATION_NAME, APT_WebServiceUtility.ORGANIZATION_NAME));
			return options;
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	/**
		This method is org Id Webservice
		Queries for ASIC report based on provided ABN or ACN using Credit assessment query service
	**/
	public void requestOrgIDDetails(){

		String OrganisationNumber = null;
		String AustralianBusinessNumber= null;
		String OrgName= null;
		Boolean searchByBusinessName = false;


		if(assesmentType == APT_WebServiceUtility.ABN){
			AustralianBusinessNumber = userinput; //'87009610342';
			chargeAccount.APT_ABN__c = userinput;
			if(userinput.length() != 11) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.WEBSERVICE_INVALID_ABN));
				return;
			}
		} else if(assesmentType == APT_WebServiceUtility.ACN){
			OrganisationNumber = userinput;
			chargeAccount.APT_ACN__c = userinput;
			if(userinput.length() != 9) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.WEBSERVICE_INVALID_ACN));
				return;
			}
		} else {
			searchByBusinessName = true;
			OrgName = userinput;
			if(userinput.length() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.WEBSERVICE_INVALID_INPUT));
				return;
			}
		}

		//1550
		if(isEntityTypePartnership) {
			//hargeAccount.APT_ABN__c = AustralianBusinessNumber;
			//chargeAccount.APT_ACN__c = OrganisationNumber;
			//chargeAccount.APT_Company_Name__c = account.Name;

			chargeAccount.APT_Name_of_Contact_Person__c = null;
			ChargeAccount.APT_Phone_Number__c = null;
			chargeAccount.APT_First_Name__c = null;
			chargeAccount.APT_Last_Name__c = null;
			ChargeAccount.APT_Applicant1_Date_of_Birth__c = null;
		}
		//1550

		try{

			// Setup the user input ABN/ACN data for the duplicate check validation
			List<Account> accDupCheck = new List<Account>();
			Account accTestDupCheck = new Account();
			// Business Name is not in scope for duplicate check
			if(!searchByBusinessName){
				accTestDupCheck.ABN__c = userinput;
				accTestDupCheck.ACN__c = userinput;
			}
			accTestDupCheck.recordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0].Id;
			accDupCheck.add(accTestDupCheck);

			// trigger existing duplicate rule and associated ABN/ACN matching rule to check on the user input ABN/ACN prior to Equifax Lookup
			if(!isAnonymousFlow && containDuplicate_ABN_ACN(accDupCheck, account.id) == true){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.Organisation_ABN_ACN_Duplicate));
				return;
			}
			if((proposal != null && String.isNotBlank(proposal.Apttus_Proposal__Account__c) && String.isNotBlank(proposal.Apttus_Proposal__Account__r.Role_Type_Roll_Up__c) && proposal.Apttus_Proposal__Account__r.Role_Type_Roll_Up__c.equalsIgnoreCase(APT_Constants.Prospect))
					|| (account != null && String.isNotBlank(account.Role_Type_Roll_Up__c) && account.Role_Type_Roll_Up__c.equalsIgnoreCase(APT_Constants.Prospect)) || isAnonymousFlow) {

				//approved or rejected
				//1746
				list<APT_Credit_Assessment__c> listCreditAssessment = [SELECT Id, Name, APT_ABN__c, APT_ACN__c,
						APT_Credit_Assessment_Status__c ,APT_Legal_Entity_Name__c,APT_Organisation_Name__c,APT_Organisation_Name__r.Role_Type_Roll_Up__c
				FROM APT_Credit_Assessment__c
				WHERE //APT_Organisation_Name__c = :accountID AND
						APT_Credit_Assessment_Complete__c = true
						AND ((APT_ABN__c != null AND APT_ABN__c = :AustralianBusinessNumber) OR (APT_ACN__c != null AND APT_ACN__c = :OrganisationNumber))
						AND (APT_Credit_Assessment_Status__c = :APT_Constants.APPROVAL_STAGE_APPROVED
						OR APT_Credit_Assessment_Status__c = :APT_Constants.APPROVAL_STATUS_REJECTED)];

				//1746

				if(listCreditAssessment != null && listCreditAssessment.size() > 0 && !isAnonymousFlow) {
					//create credit assessment
					creditAssesment.APT_Legal_Entity_Name__c = account.Name;
					creditAssesment.APT_Organisation_Name__c = accountID;
					creditAssesment.APT_Proposal__c = proposalId;
					creditAssesment.APT_ABN__c = AustralianBusinessNumber;
					creditAssesment.APT_ACN__c = OrganisationNumber;
					creditAssesment.APT_Credit_Assessment_Status__c = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
					//1550
					creditAssesment.APT_Credit_Amount_Required__c = ChargeAccount.APT_Credit_Limit_Required__c;
					creditAssesment.L2C_AP_Proposed_Credit_Limit__c = chargeAccount.AP_Proposed_Credit_Limit__c;

					/* Shashwat.Nath@Aupost.com added the below if else Condition as part of the user strory STP-2832 to populate
					1. If proposal is not startrack then AP proposed for New Account would be populated based on Opportunity Amount multiplied by .25(which is configurable).
					   This is the value which would be passed as credit amount to SAP for billing account creation.
					2. If proposal is startrack then ST proposed for new Account would be calculated based on Opportunity Amount multiplied by .25(which is configurable)
					*/
					//Applying the RoundUp to next thousands for both AP and ST
					if('No'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
						creditRoundUp = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c).intValue() ;
						creditRoundUpResult = ((creditRoundUp + NEAREST_ROUND_OFF_3)/NEAREST_ROUND_OFF_2)*NEAREST_ROUND_OFF_2;
						creditAssesment.Aus_Post_Proposed_for_New_Account__c = creditRoundUpResult;
					}
					else if('Yes'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
						creditRoundUp = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c).intValue();
						creditRoundUpResult = ((creditRoundUp + NEAREST_ROUND_OFF_3)/NEAREST_ROUND_OFF_2)*NEAREST_ROUND_OFF_2;
						creditAssesment.StarTrack_Proposed_for_New_Account__c = creditRoundUpResult;
					}

					/*Shashwat.Nath@auspost.com code ends */

					creditAssesment.L2C_Star_Track_Proposed_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
					creditAssesment.L2C_Referral_Rejection_Reason__c = APT_Constants.CREDIT_ASSESSMENT_ALREADY_APPROVED_OR_REFERRED;
					if(isEntityTypePartnership){
						creditAssesment.APT_Assessment_Type__c = 'Partnership';
						creditAssesment.APT_Business_Type__c = 'Partnership';
					}
					//1550
					insert creditAssesment;

					ResultPageTitle = APT_Constants.Credit_Assessment_Outcome;
					CreditAssessmentFinalOutcome = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
					AssessmentOutComeReason = APT_Constants.CREDIT_ASSESSMENT_ALREADY_APPROVED_OR_REFERRED;
					PageType = PAGE_TYPE_RESULTS;

					return;
				}

				// Checking if there is already a credit assessment record in Approved or Rejected status When doing Assessment from Manual Entry Screen
				else if(listCreditAssessment != null && listCreditAssessment.size() > 0 && isAnonymousFlow && APT_Constants.Prospect.equalsIgnoreCase(listCreditAssessment[0].APT_Organisation_Name__r.Role_Type_Roll_Up__c)) {
					// Setting up the Field values for the Credit Assessment record
					creditAssesment.APT_Legal_Entity_Name__c = listCreditAssessment[0].APT_Legal_Entity_Name__c;
					creditAssesment.APT_Organisation_Name__c = listCreditAssessment[0].APT_Organisation_Name__c;
					creditAssesment.APT_ABN__c = AustralianBusinessNumber;
					creditAssesment.APT_ACN__c = OrganisationNumber;
					// Setting the status as Referred
					creditAssesment.APT_Credit_Assessment_Status__c = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
					//1550
					creditAssesment.APT_Credit_Amount_Required__c = ChargeAccount.APT_Credit_Limit_Required__c;
					creditAssesment.L2C_AP_Proposed_Credit_Limit__c = chargeAccount.AP_Proposed_Credit_Limit__c;
					creditAssesment.L2C_Star_Track_Proposed_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
					creditAssesment.L2C_Referral_Rejection_Reason__c = APT_Constants.CREDIT_ASSESSMENT_ALREADY_APPROVED_OR_REFERRED;
					if(isEntityTypePartnership){
						creditAssesment.APT_Assessment_Type__c = 'Partnership';
						creditAssesment.APT_Business_Type__c = 'Partnership';
					}
					//inserting the credit assessment record
					database.insert(creditAssesment);
					// Setting the Outcome page
					ResultPageTitle = APT_Constants.Credit_Assessment_Outcome;
					CreditAssessmentFinalOutcome = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
					AssessmentOutComeReason = APT_Constants.CREDIT_ASSESSMENT_ALREADY_APPROVED_OR_REFERRED;
					creditAssesment.L2C_Star_Track_Proposed_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
					PageType = PAGE_TYPE_RESULTS;

					return;
				}
			}

			//referred //Case# 00209306// Defect# 1746
			list<APT_Credit_Assessment__c> listReferredCreditAssessment = [SELECT Id, Name, APT_ABN__c, APT_ACN__c,
					APT_Credit_Assessment_Status__c
			FROM APT_Credit_Assessment__c
			WHERE //APT_Organisation_Name__c = :accountID AND
					APT_Credit_Assessment_Complete__c = true
					AND ((APT_ABN__c != null AND APT_ABN__c = :AustralianBusinessNumber) OR (APT_ACN__c != null AND APT_ACN__c = :OrganisationNumber))
					//AND (APT_ABN__c = :AustralianBusinessNumber OR APT_ACN__c = :OrganisationNumber)
					AND APT_Credit_Assessment_Status__c = :APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED];


			if(listReferredCreditAssessment != null && listReferredCreditAssessment.size() > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.CREDIT_ASSESSMENT_ALREADY_REFERRED));
				return;
			}
			APT_ServicePartyCustomerService service = new APT_ServicePartyCustomerService();
			APT_ServicePartyCustomerService.ABNServices_v1HTTPEndpoint1 endPoint = new APT_ServicePartyCustomerService.ABNServices_v1HTTPEndpoint1();


			endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
			endPoint.Header = APT_WebServiceUtility.getOrgIDInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYABN);
			endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;

			APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
			if(r2tSystemProperty != null && r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c != null) {
				endPoint.endpoint_x = r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c;
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SOAP_ENDPOINT_EXCEPTION));
			}
			APT_SchemaPartyCustomerService.queryABNResponseType responseService;

			APT_SchemaPartyCustomerService.BusinessRegistrationNumber_element BusinessRegistrationNumber= null;
			String BureauReference= null;

			showSearchResults = true;


			responseService = endPoint.queryABN_v1(OrganisationNumber,AustralianBusinessNumber, OrgName,BusinessRegistrationNumber,BureauReference);
			APT_OrgIDWebServiceWrapper.queryABNResponseType orgIdResponse = APT_CompanyBusinessContHelper.parseOrgIDResponseToWrapper(responseService, chargeAccount.APT_Credit_Limit_Required__c,chargeAccount.APT_Company_Name__c);
			orgIdResultList = orgIdResponse.OrgIdResult;
			PageType = PAGE_TYPE_ABN_RESULTS;

			if(orgIdResultList.size() > 1){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, APT_Constants.WARNING_MULTIPLE_RECORDS));
			}

			if(orgIdResponse.Error != null && (String.isNotBlank(orgIdResponse.Error.ErrorTypeCode)
					|| String.isNotBlank(orgIdResponse.Error.InputContainer)
					|| String.isNotBlank(orgIdResponse.Error.ErrorDescriptionTypeCode))){

				String errormessage = APT_Constants.ERROR_VEDA_ERROR + APT_Constants.SEPARATOR_COLON
						+ orgIdResponse.Error.ErrorDescriptiontype + APT_Constants.Check_details_and_try_again ;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errormessage));
			}

			// Checking if assessment is being carried out from Manual Entry Screen
			if(isAnonymousFlow){
				List<Account> accList = new List<Account>();
				// Finding out if the user is using ABN for searching the Organisation
				if(APT_WebServiceUtility.ABN.equalsIgnoreCase(assesmentType)){
					// fetching account details to check if the account exist in salesforce and if it is hotlisted one.
					accList = [Select id, L2C_Hotlist__c , billingStreet , BillingCity , BillingState , BillingPostalCode ,
							ABN__c , BillingCountry , ShippingStreet , ShippingCity , ShippingState , ShippingPostalCode ,
							ShippingCountry from Account WHERE ABN__c =:userinput LIMIT 1];

				}
				// Finding out if the user is using ACN for searching the Organisation
				else if(APT_WebServiceUtility.ACN.equalsIgnoreCase(assesmentType)){
					// fetching account details to check if the account exist in salesforce and if it is hotlisted one.
					accList = [Select id, L2C_Hotlist__c , billingStreet , BillingCity , BillingState , BillingPostalCode ,
							ABN__c , BillingCountry , ShippingStreet , ShippingCity , ShippingState , ShippingPostalCode ,
							ShippingCountry from Account WHERE ACN__c =:userinput LIMIT 1];
				}
				If(!accList.isEmpty() && accList[0].L2C_Hotlist__c){
					// Setting the hotlist override option to true
					proceedHotlistCreditAssessment = true;
					// Setting the boolean for Hotlist Warning/Overriding popup to true
					displayHotlistPopup = true;
					// Pre populating the address information for the Company Detail/Individual Detail page with the information existing in the Hotlisted Account Record.
					mailingAddress = new AddressExtension(accList[0].billingStreet, APT_Constants.EMPTY_STRING, accList[0].BillingCity, accList[0].BillingState, accList[0].BillingPostalCode, accList[0].ABN__c, accList[0].BillingCountry);
					physicaladdress = new AddressExtension(accList[0].ShippingStreet, APT_Constants.EMPTY_STRING, accList[0].ShippingCity, accList[0].ShippingState, accList[0].ShippingPostalCode, accList[0].ABN__c, accList[0].ShippingCountry);

				}
			}

		} Catch(Exception ex){
			String errorMessage = ex.getMessage().toLowerCase();
			if(errorMessage.contains(APT_Constants.ERROR_SOAP_FAULT)){
				errorMessage = APT_Constants.VEDA_SERVER_ISSUE + APT_Constants.SEPERATOR_COLON  + ex.getMessage();
			} else{
				errorMessage = ex.getMessage();
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage));
		}
	}



	/**
		This method will select ASIC/ABR Report based on OrgID service response. This gets invoked when user
		clicks on the Select Button on the Org ID search Page when doing the Credit Assessment.The Method redirects the
		User to either Company Credit Assessmet Page or to the Individual Assessment Page.
	 **/
	public void selectReport(){
		try{
			//selectedOrgIdReport
			APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrap = APT_CompanyBusinessContHelper.getSelectedOrgIDWrapper(orgIdResultList, selectedOrgIdUniqueNumber);

			//1550
			String entityType;
			if(orgIDWrap.AustralianBusinessRegisterReport != null && orgIDWrap.AustralianBusinessRegisterReport.EntityTypeInd != null) {
				entityType = orgIDWrap.AustralianBusinessRegisterReport.EntityTypeInd;
				if(String.isNotBlank(entityType) && (entityType.equalsIgnoreCase(APT_Constants.ENTITY_TYPE_FPT)
						|| entityType.equalsIgnoreCase(APT_Constants.ENTITY_TYPE_PTR)
						|| entityType.equalsIgnoreCase(APT_Constants.ENTITY_TYPE_LTP)
						|| entityType.equalsIgnoreCase(APT_Constants.ENTITY_TYPE_LTDP)) ) {

					isEntityTypePartnership = true;
				}
			}
			//1550

			isTrustFlag = false;
			selectedASICReport = APT_CompanyBusinessContHelper.getSelectedASICReport(orgIdWrap.ASICReport);
			selectedABRReport = APT_CompanyBusinessContHelper.getSelectedABRReport(orgIdWrap.AustralianBusinessRegisterReport);
			//1550
			if(selectedABRReport != null && String.isNotBlank(selectedABRReport.APT_Entity_Type_Text__c) && selectedABRReport.APT_Entity_Type_Text__c.contains(APT_Constants.ENTITY_TYPE_PARTNERSHIP)) {
				creditAssesment.APT_Assessment_Type__c = selectedABRReport.APT_Entity_Type_Text__c;
				creditAssesment.APT_Business_Type__c = selectedABRReport.APT_Entity_Type_Text__c;
			}
			//1550
			Boolean hasPartnershipError = false;
			if(APT_WebServiceUtility.ENTITY_TYPE_COMPANY.equalsIgnoreCase(orgIdWrap.EntityTypeCustom) || ORGANIZATION_TYPE_GOVERNMENT.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)
					|| OTHER_INCORPORATED.equalsIgnoreCase(orgIdWrap.EntityTypeCustom) || OTHER.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)){
				//1550
				if(ORGANIZATION_TYPE_GOVERNMENT.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)){
					isGovernmentEntity = true;
				}

				if(OTHER_INCORPORATED.equalsIgnoreCase(orgIdWrap.EntityTypeCustom) || OTHER.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)){
					entityTypeForAssessment = OTHER_TYPE ;
				}
				else{
					entityTypeForAssessment = APT_WebServiceUtility.ORGANIZATION_TYPE_COMPANY ;
				}
				if(isEntityTypePartnership) {
					isEntityTypePartnership = false;
					hasPartnershipError = true;
					updateCreditAssessmentRefered(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED);
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Partnership entity type Credit Assessment has been referred as Business entity type has been selected.'));
				} else {
					PageType = PAGE_TYPE_COMPANY_BUSINESS;
					creditAssesment = APT_CompanyBusinessContHelper.showCompanyBusinessPage(creditAssesment, orgIdWrap);

					chargeAccount = APT_CompanyBusinessContHelper.chargeAccountForCompanyBusiness(orgIdWrap, chargeAccount);
				}
				//1550
			} else if(APT_WebServiceUtility.ENTITY_TYPE_TRUST.equalsIgnoreCase(orgIdWrap.EntityTypeCustom) ||
					APT_WebServiceUtility.ENTITY_TYPE_INDIVIDUAL.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)) {

				//1550
				if(isEntityTypePartnership && APT_WebServiceUtility.ENTITY_TYPE_TRUST.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)) {
					isEntityTypePartnership = false;
					hasPartnershipError = true;
					updateCreditAssessmentRefered(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED);
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Partnership entity type Credit Assessment has been referred as Trust entity type has been selected.'));
				} else {
					PageType = PAGE_TYPE_SOLE_TRADER;
					creditAssesment = APT_CompanyBusinessContHelper.showSoletraderPage(creditAssesment, orgIdWrap);
					chargeAccount = APT_CompanyBusinessContHelper.chargeAccountForSoleTrader(orgIdWrap, chargeAccount);
					soleTraderAddrress = new AddressExtension(chargeAccount.APT_Applicant1_BA_Street_Name__c, APT_Constants.EMPTY_STRING, chargeAccount.APT_Applicant1_BA_Suburb__c, chargeAccount.APT_Applicant1_BA_State__c, chargeAccount.APT_Applicant1_BA_Street_Postcode__c, APT_Constants.EMPTY_STRING, chargeAccount.APT_Applicant1_BA_Country_Code__c);
					residentialAddress = new AddressExtension(chargeAccount.APT_Applicant1_SA_Street_Name__c, APT_Constants.EMPTY_STRING, chargeAccount.APT_Applicant1_SA_Suburb__c, chargeAccount.APT_Applicant1_SA_State__c, chargeAccount.APT_Applicant1_SA_Street_Postcode__c, APT_Constants.EMPTY_STRING, chargeAccount.APT_Applicant1_SA_Country_Code__c);

					if(APT_WebServiceUtility.ENTITY_TYPE_TRUST.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO ,APT_Constants.WARNING_ENTITY_TYPE_TRUST));
						isTrustFlag = true;
					}
				}

			}

			else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,APT_Constants.WARNING_INVALID_ASIC_TYPE));
			}

			//1550
			if(!hasPartnershipError && !isAnonymousFlow) {
				verifyAccountDetails();
			}
			//1550
		} catch (Exception ex) {
			String errorMessage = ex.getMessage().toLowerCase();
			if(errorMessage.contains(APT_Constants.ERROR_SOAP_FAULT)){
				errorMessage = APT_Constants.VEDA_SERVER_ISSUE;
			} else{
				errorMessage = ex.getMessage();
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage));
		}
	}


	/**
	This method is invoked when User clicks on the Update Button on the Company/Individual Credit Assessment Page .
	This updates the Account Instance with the Name, ABN , ACN returned by the Equifax but does not update the Account Yet.
 **/
	public void updateAccount(){
		try{
			Boolean equifaxBlankValues = false;
			Boolean isSoleTrader = false;

			// Check if the Entity type is Sole Trader
			if(PAGE_TYPE_SOLE_TRADER.equalsIgnoreCase(PageType)){
				isSoleTrader = true;
			}

			account.Name = chargeAccount.APT_Company_Name__c;
			if(String.isNotBlank(chargeAccount.APT_ACN__c)){
				account.ACN__c = chargeAccount.APT_ACN__c;
			}else if(String.IsBlank(chargeAccount.APT_ACN__c) && String.isNotBlank(account.ACN__c)){
				equifaxBlankValues = true;
				// Overwrite 'Blank' ACN value returned from Equifax to Salesforce's ACN
				if(isSoleTrader){
					account.ACN__c = chargeAccount.APT_ACN__c;
				}
			}
			if(String.isNotBlank(chargeAccount.APT_ABN__c)){
				account.ABN__c = chargeAccount.APT_ABN__c;
			}else if(String.IsBlank(chargeAccount.APT_ABN__c) && String.isNotBlank(account.ABN__c)){
				equifaxBlankValues = true;
			}
			Boolean isAccountChanged;
			if(!isAnonymousFlow){
				isAccountChanged = !isAccountNotChanged(account);
				if(APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c)){
					// Update the "Organisation_Trading_Name__c" on Legal Entity Name if the field is initially blank, for 'Known' Organisation role
					if(String.isBlank(account.Organisation_Trading_Name__c)){
						account.Organisation_Trading_Name__c = account.Name;
					}
				}
				// Update the Account details if Organisation role is 'Known' or 'Prospect', and Equifax does not return blank values while Salesforce has values
				if((APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) ||
						APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c)) && isAccountChanged && (!equifaxBlankValues || (equifaxBlankValues && isSoleTrader))){

					List<Account> accList = new List<Account>();
					accList.add(account);
					Database.SaveResult[] srList = Database.update(accList, false);
					Boolean updateSuccessful = true;
					// Iterate through each returned result
					for (Database.SaveResult sr : srList) {
						if (!sr.isSuccess()) {
							updateSuccessful = false;
							// Operation failed, so display errors on VF pages
							for(Database.Error err : sr.getErrors()) {
								ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getStatusCode() + ': ' + err.getMessage()));
							}
						}
					}

					// flag 'accountIsUpdated' to true, is used to rerender the VF page
					accountIsUpdated = updateSuccessful;
				}
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
		}
		verifyAccountDetails();
	}


	/**
		This method used for redirect to next page to Proposal/Account/Subaccount
	**/
	public PageReference redirectToNextPage(){
		//update chargeAccount;
		try {

			//1550
			list<APT_Credit_Assessment__c> listCreditAssessment = new list<APT_Credit_Assessment__c>();
			for(APT_Credit_Assessment__c ca : [SELECT Id, APT_Status__c
			FROM APT_Credit_Assessment__c
			WHERE APT_Proposal__c = :proposalId
			AND APT_Status__c = null]) {

				ca.APT_Status__c = APT_Constants.CREDIT_ASSESSMENT_STATUS_COMPLETED;
				listCreditAssessment.add(ca);
			}

			if(listCreditAssessment.size() > 0) {
				update listCreditAssessment;
			}
			//1550

			PageReference redirectPage = null;
			if(creditAssesment != null && String.isNotBlank(creditAssesment.ID)){
				redirectPage = updateProposalAndRedirectToSubAccount(creditAssesment.ID,creditAssesment.APT_Credit_Assessment_Status__c);
			} else {
				redirectPage = updateProposalAndRedirectToSubAccount(null,null);
			}
			return redirectPage;
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}






	/**
		This method will select ASIC/ABR Report based on OrgID service response.
		Method to close the Popup
	**/
	public void goBack() {
		try {
			displayHotlistPopup = false;
			displayPopUp= false;
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}
	}



	/**
	 This method will refer credit assessment.
	**/
	public void doRefer() {
		try{
			PageType = PAGE_TYPE_RESULTS;

			if(orgIdResultList.size() >= 1){
				APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdWrap = orgIdResultList[0];
				if(APT_WebServiceUtility.ENTITY_TYPE_TRUST.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)) {
					chargeAccount.APT_Entity_Type__c = TRUST;
				} else if(APT_WebServiceUtility.ENTITY_TYPE_INDIVIDUAL.equalsIgnoreCase(orgIdWrap.EntityTypeCustom)) {
					chargeAccount.APT_Entity_Type__c = SOLETRADER;
				} else {
					chargeAccount.APT_Entity_Type__c = COMPANY;
				}
			}

			upsert chargeAccount;
			if(orgIdResultList.size() == 1){
				insertMultipleCreditAssessments(orgIdResultList, APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED);
				ResultPageTitle = APT_Constants.Credit_Assessment_Referred_to_Credit_Team;
			} else if(orgIdResultList.size() > 1){
				insertMultipleCreditAssessments(orgIdResultList , APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED);
				ResultPageTitle = APT_Constants.Multiple_Credit_Assessments_Referred_to_Credit_Team;
			} else {
				ResultPageTitle = APT_Constants.No_Credit_Assessments_Found;
			}

			//1222
			if(!isAnonymousFlow){
				proposal.APT_Credit_Referred_Manually__c = true;
				update proposal;
			}
			//1222

			CreditAssessmentFinalOutcome = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
		} catch(system.exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
	}
	/**
	   This method will select ASIC/ABR Report based on OrgID service response.
	**/
	private void insertMultipleCreditAssessments(List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgIdResultWrapList,
			String creditAssessmentStatus){

		if(orgIdResultWrapList != null && orgIdResultWrapList.size() > 0){

			referToCredit = true;
			Map<String, APT_ASIC_Report__c> asicReportsMap = new Map<String, APT_ASIC_Report__c>();
			Map<String, APT_ABRreport__c> abrReportsMap = new Map<String, APT_ABRreport__c>();
			Map<String, APT_Credit_Assessment__c> creditAssessments = new Map<String, APT_Credit_Assessment__c>();
			Integer counter = 0;
			APT_ASIC_Report__c asicReport = new APT_ASIC_Report__c ();
			APT_ABRreport__c abrReport = new APT_ABRreport__c ();
			//APT_Credit_Assessment__c creditAssess;
			for(APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdResultWrapper :  orgIdResultWrapList) {
				counter++;
				asicReport = APT_CompanyBusinessContHelper.getSelectedASICReport(orgIdResultWrapper.ASICReport);
				abrReport = APT_CompanyBusinessContHelper.getSelectedABRReport(orgIdResultWrapper.AustralianBusinessRegisterReport);

				if(asicReport != null) {
					asicReportsMap.put(APT_Constants.PARAM_RECORD_NO + counter, asicReport);
				}

				if(abrReport != null) {
					abrReportsMap.put( APT_Constants.PARAM_RECORD_NO + counter, abrReport);
				}

				creditAssess = new APT_Credit_Assessment__c();

				creditAssess = APT_CompanyBusinessContHelper.showSoletraderPage(creditAssess, orgIdResultWrapper);
				creditAssess = APT_CompanyBusinessContHelper.showCompanyBusinessPage(creditAssess, orgIdResultWrapper);
				if(!isAnonymousFlow){
					creditAssess.L2C_Assessment_Type__c = 'Proposal';
				}
				else if(isAnonymousFlow){
					creditAssess.L2C_Assessment_Type__c = MANUAL_ENTRY_SCREEN;
				}
				creditAssessments.put(APT_Constants.PARAM_RECORD_NO + counter, creditAssess);
			}

			insert abrReportsMap.values();
			insert asicReportsMap.values();
			for(String key : creditAssessments.KeySet()){
				creditAssess = new APT_Credit_Assessment__c();
				creditAssess  = creditAssessments.get(key);
				asicReport = asicReportsMap.get(key);
				abrReport = abrReportsMap.get(key);

				creditAssess = getCreditAssessmentFromChargeAccount(chargeAccount, creditAssess, creditAssessmentStatus);
				creditAssess.APT_ASIC_Report__c = asicReport != null ? asicReport.id : null;
				creditAssess.APT_ABR_Report__c = abrReport != null ? abrReport.id : null;

				//Case# 00209306// Defect# 1746 // Added By Apttus TS
				if(assesmentType == APT_WebServiceUtility.ABN){
					creditAssess.APT_ABN__c = userinput;
				}else if(assesmentType == APT_WebServiceUtility.ACN){
					creditAssess.APT_ACN__c = userinput;
				}
			}

			insert creditAssessments.values();
		}
	}

	/**
		This method will Query Credit assessment from charge account.
	**/
	public APT_Credit_Assessment__c getCreditAssessmentFromChargeAccount(APT_Charge_Account__c chargeAccount,APT_Credit_Assessment__c creditAssesment, String creditAssessmentStatus){
		try {
			creditAssesment.APT_Credit_Assessment_Status__c = creditAssessmentStatus;
			//remove driver's license number
			creditAssesment.APT_Applicant_1_Drivers_Licence_Number__c = null;
			creditAssesment.APT_Applicant_2_Drivers_Licence_Number__c = null;

			creditAssesment.APT_Proposal__c = proposalID;
			creditAssesment.APT_Organisation_Name__c = accountId;
			if(chargeAccount.APT_Industry_Type__c != null) {
				creditAssesment.APT_Industry_Type__c = chargeAccount.APT_Industry_Type__c.subString(0, 1);
			}

			if(String.IsBlank(creditAssesment.APT_Legal_Entity_Name__c)){
				creditAssesment.APT_Legal_Entity_Name__c = chargeAccount.APT_Company_Name__c;
			}
			creditAssesment.APT_Term_Days__c = APT_Constants.END_CHARACTER_D + chargeAccount.APT_Term_Days__c;
			creditAssesment.APT_Account_Type__c = APT_Constants.END_CHARACTER_D + chargeAccount.APT_Term_Days__c;
			creditAssesment.APT_Credit_Amount_Required__c = chargeAccount.APT_Credit_Limit_Required__c;
			creditAssesment.L2C_AP_Proposed_Credit_Limit__c = chargeAccount.AP_Proposed_Credit_Limit__c;
			creditAssesment.L2C_Star_Track_Proposed_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
			/* Shashwat.Nath@Aupost.com added the below if else Condition as part of the user strory STP-2832 to populate
					1. If proposal is not startrack then AP proposed for New Account would be populated based on Opportunity Amount multiplied by .25(which is configurable).
					   This is the value which would be passed as credit amount to SAP for billing account creation.
					2. If proposal is startrack then ST proposed for new Account would be calculated based on Opportunity Amount multiplied by .25(which is configurable)
			*/
			//Applying the RoundUp to next thousands for both AP and ST
			if('No'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
				creditRoundUp = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c).intValue() ;
				creditRoundUpResult = ((creditRoundUp + NEAREST_ROUND_OFF_3)/NEAREST_ROUND_OFF_2)*NEAREST_ROUND_OFF_2;
				creditAssesment.Aus_Post_Proposed_for_New_Account__c = creditRoundUpResult;
			}
			else if('Yes'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
				creditRoundUp = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c).intValue();
				creditRoundUpResult = ((creditRoundUp + NEAREST_ROUND_OFF_3)/NEAREST_ROUND_OFF_2)*NEAREST_ROUND_OFF_2;
				creditAssesment.StarTrack_Proposed_for_New_Account__c = creditRoundUpResult;
			}

			/* Shashwat.Nath@Auspost.com code ends */

			creditAssesment.APT_Applicant_1_First_Name__c = chargeAccount.APT_First_Name__c;
			creditAssesment.APT_Applicant_1_Last_Name__c = chargeAccount.APT_Last_Name__c;
			creditAssesment.APT_Applicant_1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;
			creditAssesment.APT_Charge_Account__c = chargeAccount.Id;
			return creditAssesment;
		}   catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	/**
	 This method will update quote/proposal with credit assessment status.
	**/
	private PageReference updateProposalAndRedirectToSubAccount(String creditAssessmentID, String creditAssessmentStatus){
		PageReference redirectPage = null;

		if(proposal != null && !isAccountFlow) {

			if(String.isNotBlank(creditAssessmentID)){
				proposal.APT_Credit_Assessment__c = creditAssessmentID;
			}
			if(String.isNotBlank(creditAssessmentStatus)){
				if((APT_Constants.CREDIT_ASSESSMENT_DECLINE).equalsIgnoreCase(creditAssessmentStatus)) {
					creditAssessmentStatus = APT_Constants.APPROVAL_STATUS_REJECTED;
				} else if(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFER .equalsIgnoreCase(creditAssessmentStatus)
						|| APT_Constants.ERROR.equalsIgnoreCase(creditAssessmentStatus)) {
					creditAssessmentStatus = APT_Constants.CREDIT_ASSESSMENT_REFFERED ;
				} else if (APT_Constants.APPROVAL_STAGE_APPROVE.equalsIgnoreCase(creditAssessmentStatus)){
					creditAssessmentStatus = APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED;
				}
			} else{
				creditAssessmentStatus = APT_Constants.CREDIT_ASSESSMENT_REFFERED ;
			}

			//1550
			/*
			if(isEntityTypePartnership) {
				if(String.isNotBlank(creditAssessmentStatus) && !creditAssessmentStatus.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED)) {
					proposal.APT_Credit_Assessment_Status__c = creditAssessmentStatus;
				}
			} else {
			*/
			proposal.APT_Credit_Assessment_Status__c = creditAssessmentStatus;
			//}


			list<APT_Credit_Assessment__c> listCA = new list<APT_Credit_Assessment__c>();
			for(APT_Credit_Assessment__c ca : [SELECT Id, APT_Credit_Assessment_Complete__c
			FROM APT_Credit_Assessment__c
			WHERE APT_Proposal__c = :proposal.Id]) {

				ca.APT_Credit_Assessment_Complete__c = true;
				listCA.add(ca);
			}

			if(listCA.size() > 0) {
				update listCA;
			}

			/*
			if(String.isNotBlank(creditAssessmentStatus) && creditAssessmentStatus.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED )) {
				proposal.APT_Credit_Rejected_By_Veda__c = true;
			}
			*/

			//1550

			proposal.APT_Estimated_Credit_Amount__c = Decimal.valueOf(chargeAccount.L2C_Total_Proposed_Credit__c);
			proposal.APT_Credit_Assessment_Status_Details__c = AssessmentOutComeReason;

			/**
			//Defect 1222 START
			if(creditAssessmentStatus == APT_Constants.CREDIT_ASSESSMENT_REFFERED) {
				proposal.APT_Credit_Referred_Manually__c = false;
			}
			//Defect 1222 END
			**/
			update proposal;

			if(accountType != null && accountType.equalsIgnoreCase(APT_Constants.ACCOUNT_TYPE_CHARGE_ACCOUNT_PLUS_SUB_ACCOUNT) == true) {
				if(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c == 'No'){
					redirectPage = Page.SubAcctReqFormCmpfromCreditAssesment;
				}else{
					redirectPage = new PageReference('/lightning/n/Create_Sub_Accounts');
					redirectPage.getParameters().put('c__isTEAMRequest', String.valueOf(true));
					redirectPage.getParameters().put('c__recordId', chargeAccount.Id);
					redirectPage.getParameters().put('c__isBillingAccount', String.valueOf(false));
				}
				redirectPage.getParameters().put(APT_Constants.PARAM_PROPOSAL_ID, proposal.Id);
				redirectPage.getParameters().put('contextId', contextId);
				redirectPage.getParameters().put(APT_Constants.PARAM_CHARGE_ACCOUNT_ID, chargeAccount.Id);
			} else {
				if (String.isNotBlank(contextId)) {
					redirectPage = new PageReference('/' + contextId);
				} else {
					redirectPage = new ApexPages.StandardController(proposal).View();
				}
			}
		} else if(isAccountFlow) {

			if((APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED).equalsIgnoreCase(creditAssessmentStatus)){
				sendEmailAccountFlow();
			}

			if(accountType != null && accountType.equalsIgnoreCase(APT_Constants.ACCOUNT_TYPE_CHARGE_ACCOUNT_PLUS_SUB_ACCOUNT) == true) {
				redirectPage =  Page.APT_SubAccountAssessment;
				redirectPage.getParameters().put(APT_Constants.PARAM_ACCOUNT_ID, accountId);
				redirectPage.getParameters().put(APT_Constants.PARAM_CHARGE_ACCOUNT_ID, chargeAccount.Id);
			} else {
				redirectPage = backToAccount();
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MESSAGE_INVALID_PROPOSAL));
		}

		if(redirectPage != null){
			redirectPage.setRedirect(true);
		}
		return redirectPage;
	}
	/**
	 This method will send email.
	**/
	public void sendEmailAccountFlow(){
		try {
			// URL.getSalesforceBaseUrl() is no longer be usable post 59.0, should be removed in future work
			String body  = APT_Constants.MAIL_DEAR_ALL
					+ APT_Constants.MAIL_CHARGE_ACCOUNT + account.Name + APT_Constants.MAIL_HAS_BEEN_REFERRED
					+ APT_Constants.MAIL_CREDIT_ASSESSMENT_UNDER_FOLLOWING+ URL.getSalesforceBaseUrl().toExternalForm() + APT_Constants.SEPERATOR_BACKWARD_SLASH + accountId + APT_Constants.SEPARATOR_GREATER_THAN_CHANGE + account.Name+APT_Constants.MAIL_TAGS_AP;

			String subject = APT_Constants.MAIL_SUBJECT_CHARGE_ACCOUNT + account.Name + APT_Constants.MAIL_SUBJECT_HAS_BEEN_REFERRED;

			String toEmailId = Userinfo.getUserEmail();


			APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
			//get email addresses
			String emailAddresses;
			if(r2tSystemProperties != null) {
				emailAddresses = r2tSystemProperties.APT_Credit_Management_Team_Email__c;
			}

			list<String> toAddresses = new list<String>();
			if(String.isNotBlank(emailAddresses)) {
				toAddresses = emailAddresses.split(APT_Constants.ADD_COMMA);
			}
			toAddresses.add(toEmailId);

			// Define the email
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setReplyTo(Userinfo.getUserEmail());
			mail.setSenderDisplayName(Userinfo.getName());
			mail.setToAddresses(toAddresses);
			mail.setSubject(subject);
			mail.setHtmlBody(body);

			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}
	}

	/**
	 This method will return to search screen
	 **/
	public void backToSearch(){
		try {
			PageType = PAGE_TYPE_ABN_RESULTS;
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}
	}


	/**
	 This method will redirect user to quote/proposal detail page
	 **/
	public pageReference backToProposal(){
		try {
			Apttus_Proposal__Proposal__c prop = new Apttus_Proposal__Proposal__c();
			prop.id = proposalId;
			return new ApexPages.StandardController(prop).View();
		} catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	/**
	   This method will redirect user to Account detail page
	 **/
	public pageReference backToAccount(){
		try {
			Account acc = new Account();
			acc.id = AccountID;
			return new ApexPages.StandardController(acc).View();
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	/**
	   This method will redirect user to the record detail page of given context
	 **/
	public pageReference backToContext(Id contextId){
		try {
			return new PageReference('/' + contextId);
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	/**
	  Cancel button action
	 **/
	public PageReference back(){
		try {

			//1550
			list<APT_Credit_Assessment__c> listCreditAssessment = new list<APT_Credit_Assessment__c>();
			for(APT_Credit_Assessment__c ca : [SELECT Id, APT_Status__c
			FROM APT_Credit_Assessment__c
			WHERE APT_Proposal__c = :proposalId
			AND APT_Status__c = null]) {

				ca.APT_Status__c = APT_Constants.CREDIT_ASSESSMENT_STATUS_CANCELLED;
				listCreditAssessment.add(ca);
			}

			if(listCreditAssessment.size() > 0) {
				update listCreditAssessment;
			}
			//1550

			PageReference redirectPage = null;
			if(String.isNotBlank(proposalId) && String.isBlank(contextId)){
				//back to proposal
				redirectPage  = backToProposal();
			} else if(String.isNotBlank(proposalId) && String.isNotBlank(contextId)) {
				// back to object of context
				redirectPage = backToContext(contextId);
			} else if(String.isNotBlank(AccountID)){
				//back to account
				redirectPage  = backToAccount();
			}
			return redirectPage;
		} catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	/**
	  Continue button action
	 **/
	public PageReference doContinue() {

		PageReference redirectPage = null;
		try {
			//update charge account details for Privacy and
			//upsert chargeAccount;

			if(chargeAccount.APT_CustomerAgreementToPrivacyStatement__c) {
				displayPopUp = false;
				PageType = PAGE_TYPE_SEARCH_ABN;
			}
			else if(!chargeAccount.APT_CustomerAgreementToPrivacyStatement__c) {
				redirectPage  = back();
			} else {
				displayHotlistPopup = false;
				redirectPage = null;
			}
		} catch(Exception ex){
			displayPopUp = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
		return redirectPage;
	}

	/**
		This method will select ASIC/ABR Report based on OrgID service response.
	 **/
	public boolean isTrustFlag {get;set;}
	/**
		This method is called from the Update Account Method . It checks whether the Account Instance Name , ABN , ACN
		matches with the Name, ABN, ACN  returned by the Equifax . If these attribute Match the warnings from the page are removed ,
		otherwise warnings on the mismatch of attributes is displayed to User.
	 **/
	public void  verifyAccountDetails(){
		try {
			Boolean orgDetailsMisMatched = false;
			if(!(account.Name).equalsIgnoreCase(chargeAccount.APT_Company_Name__c)){
				String equifaxAccountName = String.isNotBlank(chargeAccount.APT_Company_Name__c) ? chargeAccount.APT_Company_Name__c : APT_Constants.DETAILS_MISMATCHED_BLANK;
				String sfAccountName = String.isNotBlank(account.Name) ? account.Name : APT_Constants.DETAILS_MISMATCHED_BLANK;
				orgDetailsMisMatched = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Legal Entity Name from Equifax ' + equifaxAccountName + ' and Legal Entity Name in Salesforce organisation record ' + sfAccountName +' don\'t match.'));
			}
			if((String.isNotBlank(account.ABN__c) && String.isNotBlank(chargeAccount.APT_ABN__c) && !(account.ABN__c).equalsIgnoreCase(chargeAccount.APT_ABN__c))
					|| (String.isNotBlank(account.ABN__c) && String.isBlank(chargeAccount.APT_ABN__c))
					|| (String.isBlank(account.ABN__c) && String.isNotBlank(chargeAccount.APT_ABN__c))){
				String equifaxABN = String.isNotBlank(chargeAccount.APT_ABN__c) ? chargeAccount.APT_ABN__c : APT_Constants.DETAILS_MISMATCHED_BLANK;
				String sfABN = String.isNotBlank(account.ABN__c) ? account.ABN__c : APT_Constants.DETAILS_MISMATCHED_BLANK;
				orgDetailsMisMatched = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'ABN number from Equifax ' + equifaxABN + ' and ABN in Salesforce organisation record ' + sfABN +' don\'t match.'));
			}
			if((String.isNotBlank(account.ACN__c) && String.isNotBlank(chargeAccount.APT_ACN__c) && !(account.ACN__c).equalsIgnoreCase(chargeAccount.APT_ACN__c))
					|| (String.isNotBlank(account.ACN__c) && String.isBlank(chargeAccount.APT_ACN__c))
					|| (String.isBlank(account.ACN__c) && String.isNotBlank(chargeAccount.APT_ACN__c))){
				String equifaxACN = String.isNotBlank(chargeAccount.APT_ACN__c) ? chargeAccount.APT_ACN__c : APT_Constants.DETAILS_MISMATCHED_BLANK;
				String sfACN = String.isNotBlank(account.ACN__c) ? account.ACN__c : APT_Constants.DETAILS_MISMATCHED_BLANK;
				orgDetailsMisMatched = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'ACN number from Equifax ' + equifaxACN + ' and ACN in Salesforce organisation record ' + sfACN +' don\'t match.'));
			}

			// For 'Customer' role and mismatch is founded, display warning message
			// 'Display' button is hidden by default if the role is 'Customer'
			if(orgDetailsMisMatched == true && APT_Constants.Customer.equalsIgnoreCase(account.Role_Type_Roll_Up__c)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, APT_Constants.DETAILS_MISMATCHED_REFER_MSG));
			}
			// For Role type is 'Prospect' or 'Known' and mismatch is found, disable the 'Credit Assessment' button and display 'Update' button
			else if(orgDetailsMisMatched == true && (APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) || APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c))){
				disableCreditAssessmentBtn = true;
				hideUpdateBtn = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, APT_Constants.DETAILS_MISMATCHED_UPDATE_MSG));
			}
			// For Role type is 'Prospect' or 'Known' and account has been updated, enable the Credit Assessment Button
			else if(orgDetailsMisMatched == false && accountIsUpdated == true && (APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) || APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c))){
				disableCreditAssessmentBtn = false;
				hideUpdateBtn = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, APT_Constants.ORG_UPDATED_SUCCESSFUL));
			}// No mismatch is found and account is not updated, hide the 'Update' button
			else if(orgDetailsMisMatched == false && accountIsUpdated == false){
				hideUpdateBtn = true;
			}
		} catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}
	}


	public string creditAssessmentErrorMessage {get;set;}
	/**
	  This method is invoked when User Clicks on the Next button on the Company/Individual Credit Assessment Screen.
	  Method contains the rules which either refers/ Approves or Send the Request to Equifax for Getting the Credit Assessment
	  Details.
   **/
	public void doCreditCheck() {
		String initialPageType = PageType;
		try{

			//940
			APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
			if(r2tSystemProperty != null && String.isNotBlank(r2tSystemProperty.APT_Credit_Assessment_Valid_States__c)) {
				list<String> listValidStates = r2tSystemProperty.APT_Credit_Assessment_Valid_States__c.split(APT_Constants.SEPERATOR_COMMA);
				if(listValidStates != null) {
					set<String> setValidStates = new set<String>();
					for(String vs : listValidStates) {
						setValidStates.add(vs);
					}
					Boolean bIsValidState = true;
					//27042017 SC: 1855 Added new custom label to show State Error Message
					if(mailingAddress != null && String.isNotBlank(mailingAddress.state) && !setValidStates.contains(mailingAddress.state)) {
						bIsValidState = false;
						//creditAssessmentErrorMessage = 'Invalid State.';
						creditAssessmentErrorMessage = Label.APT_State_Name_in_Uppercase;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
					}
					//27042017 SC: 1855 Added new custom label to show State Error Message
					if(physicaladdress != null && String.isNotBlank(physicaladdress.state) && !setValidStates.contains(physicaladdress.state)) {
						bIsValidState = false;
						//creditAssessmentErrorMessage = 'Invalid State.';
						creditAssessmentErrorMessage = Label.APT_State_Name_in_Uppercase;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
					}
					//27042017 SC: 1855 Added new custom label to show State Error Message
					if(soleTraderAddrress != null && String.isNotBlank(soleTraderAddrress.state) && !setValidStates.contains(soleTraderAddrress.state)) {
						bIsValidState = false;
						//creditAssessmentErrorMessage = 'Invalid State.';
						creditAssessmentErrorMessage = Label.APT_State_Name_in_Uppercase;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
					}
					//27042017 SC: 1855 Added new custom label to show State Error Message
					if(residentialAddress != null && String.isNotBlank(residentialAddress.state) && !setValidStates.contains(residentialAddress.state)) {
						bIsValidState = false;
						//creditAssessmentErrorMessage = 'Invalid State.';
						creditAssessmentErrorMessage = Label.APT_State_Name_in_Uppercase;
					}

					if(bIsValidState) {
						creditAssessmentErrorMessage = '';
					}
				}
			}
			//940
			if(String.isBlank(creditAssessmentErrorMessage)) {  //940

				/**
				 * Below Code has been moved to updateAccount() method, as the DML Update is now executed on the click of "Update" button prior to performing credit assessment
				 * Previously, the DML Update is executed on the click of "Next" button while performing credit assessment
				 *
				Boolean isAccountChanged;
				if(!isAnonymousFlow){
					isAccountChanged = !isAccountNotChanged(account);
					if(APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) && isAccountChanged){
						update account;
					}
				}
				*/
				//charge account
				populateChargeAccountAddress();
				if(isTrustFlag){
					chargeAccount.APT_Entity_Type__c = TRUST;
				}
				//1550
				if(isEntityTypePartnership && !isAnonymousFlow) {   //partnership

					creditAssesment.APT_Partner_Name__c = chargeAccount.APT_First_Name__c + APT_Constants.SEPERATOR_SPACE + chargeAccount.APT_Last_Name__c;

					chargeAccount.APT_Entity_Type__c = APT_Constants.ENTITY_TYPE_PARTNERSHIP;   //1549
					list<APT_Credit_Assessment__c> listCreditAssessment = new list<APT_Credit_Assessment__c>();
					listCreditAssessment = [SELECT Id, APT_Charge_Account__c,
							APT_Charge_Account__r.APT_Credit_Limit_Required__c,
							APT_Charge_Account__r.APT_Partner2_Credit_Limit_Required__c,
							APT_Charge_Account__r.APT_Partner3_Credit_Limit_Required__c,
							APT_Charge_Account__r.APT_Partner4_Credit_Limit_Required__c
					FROM APT_Credit_Assessment__c
					WHERE APT_Proposal__c = :proposalID
					AND APT_Status__c != :APT_Constants.CREDIT_ASSESSMENT_STATUS_CANCELLED];

					if(listCreditAssessment != null && listCreditAssessment.size() > 0) {
						if(listCreditAssessment[0].APT_Charge_Account__c != null) {
							Set<String> chargeAccountFieldNameSet = APT_AmendRenewUtility.getAllFieldsAPIName(APT_Constants.SOQL_CHARGEACCOUNT_OBJECT);
							//String chargeAccountId = listCreditAssessment[0].APT_Charge_Account__c;

							String chargeAccountId;

							for(APT_Credit_Assessment__c ca : listCreditAssessment) {
								if(creditAssessmentRecordCount == 0 && ca.APT_Charge_Account__r.APT_Credit_Limit_Required__c == null) {
									chargeAccountId = ca.APT_Charge_Account__c;
								} else if(creditAssessmentRecordCount == 1 && ca.APT_Charge_Account__r.APT_Partner2_Credit_Limit_Required__c == null) {
									chargeAccountId = ca.APT_Charge_Account__c;
								} else if(creditAssessmentRecordCount == 2 && ca.APT_Charge_Account__r.APT_Partner3_Credit_Limit_Required__c == null) {
									chargeAccountId = ca.APT_Charge_Account__c;
								} else if(creditAssessmentRecordCount == 3 && ca.APT_Charge_Account__r.APT_Partner4_Credit_Limit_Required__c == null) {
									chargeAccountId = ca.APT_Charge_Account__c;
								}
							}

							APT_Charge_Account__c ca = new APT_Charge_Account__c();
							if(String.isNotBlank(chargeAccountId)){
								String chargeAccountQuery = APT_Constants.SOQL_SELECT
										+ APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SOQL_CHARGEACCOUNT_OBJECT)
										+ ' FROM ' + APT_Constants.SOQL_CHARGEACCOUNT_OBJECT
										+ ' WHERE Id = :chargeAccountId';
								list<APT_Charge_Account__c> listChargeAccount = database.query(String.escapeSingleQuotes(chargeAccountQuery));

								if(listChargeAccount != null && listChargeAccount.size() > 0) {
									ca = listChargeAccount[0];
								}
							}

							populateChargeAccountForPartnership(ca, creditAssessmentRecordCount);

							upsert ca;

							creditAssesment.APT_Charge_Account__c = ca.Id;
						}
					} else {
						upsert chargeAccount;
					}
				} else {
					if(isAnonymousFlow){
						list<APT_Credit_Assessment__c> listInProgressCreditAssessment = [SELECT Id, Name, APT_ABN__c, APT_ACN__c,
								APT_Credit_Assessment_Status__c,APT_Charge_Account__c
						FROM APT_Credit_Assessment__c
						WHERE //APT_Organisation_Name__c = :accountID AND
								APT_Credit_Assessment_Complete__c = true
								AND ((APT_ABN__c != null AND APT_ABN__c = :chargeAccount.APT_ABN__c) OR (APT_ACN__c != null AND APT_ACN__c = :chargeAccount.APT_ACN__c))
								//AND (APT_ABN__c = :AustralianBusinessNumber OR APT_ACN__c = :OrganisationNumber)
								AND APT_Credit_Assessment_Status__c =:WORK_IN_PROGRESS];

						if(!listInProgressCreditAssessment.isEmpty() && listInProgressCreditAssessment[0].APT_Charge_Account__c!=null){
							chargeAccount.id = listInProgressCreditAssessment[0].APT_Charge_Account__c ;
						}
					}
					upsert chargeAccount;
				}

				//1550
				String creditAssessmentStat = null;
				if(!isAnonymousFlow){
					if(account.L2C_HotList__c == true && proceedHotlistCreditAssessment == false){
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						AssessmentOutComeReason = APT_Constants.Credit_Assessment_Referred_to_Credit_Team;
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = Label.L2C_Hotlist_Customer;
					}
					// This piece of code is commented on 01/11/2019 to implement changes in regards to MW0003829

					/* else if(!APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) && isAccountChanged){
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						AssessmentOutComeReason = APT_Constants.Account_Role_must_be_Prospect;
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = APT_Constants.Account_Role_must_be_Prospect;
					}*/

					/* -This piece of else if block is implemented on 01/11/2019 for the MWMW0003829
						The logic checks if for a prospect/customer the Account Name in SF does not match with the Equifax Account Name
						then the Credit Assessment would be Referred .

					   -'account.name' would match the Equifax Account Name if user clicks on the UPDATE button on the Assessment Screen even for Customers
						 and therefore an additional check 'originalOrganisationName' is added to make sure the Credit Assesement for Customers are
						 still referred even if User Clicks on UPDATE button as we are not suppose to update the Customers Account Data in salesforce for
						 Mismatch of name , ABN , ACN

						 STP-3414 - Include 'Known' Organisation Role into the logic
					*/

					else if(!(account.Name).equalsIgnoreCase(chargeAccount.APT_Company_Name__c)||
							(!APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) && !APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c) &&
									!originalOrganisationName.equalsIgnoreCase(chargeAccount.APT_Company_Name__c))){

						/*As the Organisation name does not match with the Equifax Returned Organisation Name
						  the Credit Assessment Would be Referred */

						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;

						//This is an additional Check to confirm if ABN is not blank for an account at SF level & if it does not match with the ABN returned by Equifax

						if(String.isNotBlank(originalOrganisationABN) &&
								!originalOrganisationABN.equalsIgnoreCase(chargeAccount.APT_ABN__c)){
							// Populating the Outcome Reason to be displayed on the Outcome Screen
							AssessmentOutComeReason = 'Organisation name and ABN does not match';
							// Setting the Referral Rejection Reason
							creditAssesment.L2C_Referral_Rejection_Reason__c = 'Organisation name and ABN does not match';
						}

						//This is an additional Check to confirm if ACN is not blank for an account at SF level & if it does not match with the ABN returned by Equifax
						else if(String.isNotBlank(originalOrganisationACN) &&
								!originalOrganisationACN.equalsIgnoreCase(chargeAccount.APT_ACN__c)){

							// Populating the Outcome Reason to be displayed on the Outcome Screen
							AssessmentOutComeReason = 'Organisation name and ACN does not match';
							// Updating the Referral/Rejection reason on the Credit Assessment Record
							creditAssesment.L2C_Referral_Rejection_Reason__c = 'Organisation name and ACN does not match';
						}
						// If there was only a Mismatch of Account name between the Salesforce and Equifax
						else{

							// Populating the Outcome Reason to be displayed on the Outcome Screen
							AssessmentOutComeReason = 'Organisation name does not match';
							// Updating the Referral/Rejection reason on the Credit Assessment Record
							creditAssesment.L2C_Referral_Rejection_Reason__c = 'Organisation name does not match';
						}
					}

					/* -This piece of else if block is implemented on 01/11/2019 for the MW0003829
						The logic checks if for a prospect/customer ABN at SF side does not match with that from Equifax
					   - account.ABN__C' would match the Equifax Account ABN if user clicks on the UPDATE button on the Assessment Screen even for Customers
						 and therefore an additional check 'originalOrganisationABN' is added to make sure the Credit Assesement for Customers are
						 still referred even if User Clicks on UPDATE button as we are not suppose to update the Customers Account Data in salesforce for
						 Mismatch of name , ABN , ACN

						 STP-3414 - Include 'Known' Organisation Role into the logic
				   */

					else if((String.isNotBlank(account.ABN__C) && !(account.ABN__C).equalsIgnoreCase(chargeAccount.APT_ABN__c)) || (!APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) &&
							!APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c) && String.isNotBlank(originalOrganisationABN) &&
							!originalOrganisationABN.equalsIgnoreCase(chargeAccount.APT_ABN__c))){
						// Setting the Status to Referred
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						// Populating the Outcome Reason to be displayed on the Outcome Screen
						AssessmentOutComeReason = 'ABN does not match';
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = 'ABN does not match';
					}

					/* - This piece of else if block is implemented on 01/11/2019 for the MW0003829
						 The logic checks if for a prospect/customer ACN at SF side does not match with that from Equifax
					   - account.ACN__C' would match the Equifax Account ACN if user clicks on the UPDATE button on the Assessment Screen even for Customers
						 and therefore an additional check 'originalOrganisationACN' is added to make sure the Credit Assesement for Customers are
						 still referred even if User Clicks on UPDATE button as we are not suppose to update the Customers Account Data in salesforce for
						 Mismatch of name , ABN , ACN

						 STP-3414 - Include 'Known' Organisation Role into the logic
					*/

					else if((String.isNotBlank(account.ACN__C) && !(account.ACN__C).equalsIgnoreCase(chargeAccount.APT_ACN__c)) || (!APT_Constants.Prospect.equalsIgnoreCase(account.Role_Type_Roll_Up__c) &&
							!APT_Constants.Known.equalsIgnoreCase(account.Role_Type_Roll_Up__c) && String.isNotBlank(originalOrganisationACN) &&
							!originalOrganisationACN.equalsIgnoreCase(chargeAccount.APT_ACN__c))){
						// Setting the Status to Referred
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						// Populating the Outcome Reason to be displayed on the Outcome Screen
						AssessmentOutComeReason = 'ACN does not match';
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = 'ACN does not match';
					}

					else if(isTrustFlag){
						chargeAccount.APT_Entity_Type__c = TRUST;
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						AssessmentOutComeReason = APT_Constants.Veda_Entity_type_is_Trust;
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = APT_Constants.Veda_Entity_type_is_Trust;
					}
					else if(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c) > Decimal.ValueOf(Label.L2C_Upper_Threshold_Limit_For_Credit_Assessment)){
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = Label.L2C_Above_Threshold_Value_Message;
					} else if(APT_CompanyBusinessContHelper.ValidateIsExistingABNACN(chargeAccount, account.Id)){
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						AssessmentOutComeReason = APT_Constants.Organisation_Name_ABN_ACN_Match_with_Older_Customer_Organisation;
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = APT_Constants.Organisation_Name_ABN_ACN_Match_with_Older_Customer_Organisation;
					}
					else if(isGovernmentEntity){
						creditAssessmentStat  = AUTO_APPROVED ;
						if(account !=null){
							/* The below piece of code is commented just to make sure the Customer Account is not Updated with changes
							   on Name , ABN and ACN as per MW0003829 on 1/11/2019. There is no chnage in the functionality */

							/*account.L2C_Approved_AP_Credit_Limit__c  = chargeAccount.AP_Proposed_Credit_Limit__c ;
							account.L2C_Star_Track_Approved_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
							Database.update(account);*/

							/*
								The below piece of code is implemented just to make sure the Customer Account is not Updated with changes
								on Name , ABN and ACN  and only the L2C_Approved_AP_Credit_Limit__c  ,  L2C_Star_Track_Approved_Credit_Limit__c
								field values are updated as per MW0003829 on 1/11/2019. There is no chnage in the functionality
							*/

							List<Account> accTobeUpdatedList = new List<Account>();
							accTobeUpdatedList = [select id from account where ID =:account.id LIMIT 1];
							accTobeUpdatedList[0].L2C_Approved_AP_Credit_Limit__c  = chargeAccount.AP_Proposed_Credit_Limit__c ;
							accTobeUpdatedList[0].L2C_Star_Track_Approved_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
							Database.update(accTobeUpdatedList);



						}
						//AssessmentOutComeReason = Label.L2C_Govt_Auto_Approval;
					}
					else if(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c) < Decimal.ValueOf(Label.L2C_Lower_Threshold_Limit_For_Credit_Assessment)){
						creditAssessmentStat  = AUTO_APPROVED ;
						if(account !=null){

							/* The below piece of code is commented just to make sure the Customer Account is not Updated with changes
								  on Name , ABN and ACN as per MW0003829 on 1/11/2019. There is no chnage in the functionality */

							/* account.L2C_Approved_AP_Credit_Limit__c  = chargeAccount.AP_Proposed_Credit_Limit__c ;
							   account.L2C_Star_Track_Approved_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
							   Database.update(account);
							*/

							/*
								The below piece of code is implemented just to make sure the Customer Account is not Updated with changes
								on Name , ABN and ACN  and only the L2C_Approved_AP_Credit_Limit__c  ,  L2C_Star_Track_Approved_Credit_Limit__c
								field values are updated as per MW0003829 on 1/11/2019. There is no chnage in the functionality
							*/

							List<Account> accTobeUpdatedList = new List<Account>();
							accTobeUpdatedList = [select id from account where ID =:account.id LIMIT 1];
							accTobeUpdatedList[0].L2C_Approved_AP_Credit_Limit__c  = chargeAccount.AP_Proposed_Credit_Limit__c ;
							accTobeUpdatedList[0].L2C_Star_Track_Approved_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
							Database.update(accTobeUpdatedList);

						}

					} else if(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c ) >= Decimal.ValueOf(Label.L2C_Lower_Threshold_Limit_For_Credit_Assessment) && Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c ) <= Decimal.ValueOf(Label.L2C_Upper_Threshold_Limit_For_Credit_Assessment)){
						doCreditCheckFlag = true;
						insertCreditRecord();
					} else {
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
					}
				}
				else{
					//Checking if the Organisation for which assessment is being done is a Trust and setting the status as referred.
					if(isTrustFlag){
						chargeAccount.APT_Entity_Type__c = TRUST;
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
						AssessmentOutComeReason = APT_Constants.Veda_Entity_type_is_Trust;
						// Updating the Referral/Rejection reason on the Credit Assessment Record
						creditAssesment.L2C_Referral_Rejection_Reason__c = APT_Constants.Veda_Entity_type_is_Trust;
					}
					//Checking if the Organisation for which assessment is being done is of Govt. Type and setting the status as Auto-Approved.
					else if(isGovernmentEntity){
						creditAssessmentStat  = AUTO_APPROVED ;
						//AssessmentOutComeReason = Label.L2C_Govt_Auto_Approval;
					}
					//Checking if the total credit amount is less the threshold value which is currently set at 10k and setting the status as Auto-Approved
					else if(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c) < Decimal.ValueOf(Label.L2C_Lower_Threshold_Limit_For_Credit_Assessment)){
						creditAssessmentStat  = AUTO_APPROVED ;
					}
					//Checking if the total credit amount is greater than the threshold value which is currently 10k and sending the amount to equifax for assessment.
					else if(Decimal.ValueOf(chargeAccount.L2C_Total_Proposed_Credit__c ) >= Decimal.ValueOf(Label.L2C_Lower_Threshold_Limit_For_Credit_Assessment)){
						doCreditCheckFlag = true;
						insertCreditRecord();
					}
					// setting the status to referred for any other results
					else {
						creditAssessmentStat = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
					}
				}
				//1222
				if(!isAnonymousFlow && String.isNotBlank(creditAssessmentStat) && creditAssessmentStat.equalsIgnoreCase(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED)) {
					proposal.APT_Credit_Referred_Manually__c = false;
					update proposal;
				}
				//1222

				if(!doCreditCheckFlag){
					updateCreditAssessmentRefered(creditAssessmentStat);
				}
			}
		} catch(Exception ex){
			creditAssessmentErrorMessage = ex.getMessage();//APT_Constants.Account_Role_must_be_Prospect;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			PageType = initialPageType;
		}
	}
	Public final static String COMPANY = 'Company';
	Public final static String SOLETRADER = 'Individual';
	Public final static String TRUST = 'Trust';


	private void populateChargeAccountAddress(){
		if(PAGE_TYPE_SOLE_TRADER.equalsIgnoreCase(PageType)){
			chargeAccount.APT_Applicant1_BA_State__c=soleTraderAddrress.state  ;
			chargeAccount.APT_Applicant1_BA_Street_Postcode__c= soleTraderAddrress.PostCode ;
			chargeAccount.APT_Applicant1_BA_Suburb__c =soleTraderAddrress.city ;
			chargeAccount.APT_Applicant1_BA_Street_Type__c =soleTraderAddrress.Line2 ;
			chargeAccount.APT_Applicant1_BA_Country_code__c =soleTraderAddrress.country ;
			chargeAccount.APT_Applicant1_BA_Street_Name__c = String.isNotBlank(soleTraderAddrress.Line1) ? soleTraderAddrress.Line1.left(25) : APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Applicant1_SA_State__c=residentialAddress.state  ;
			chargeAccount.APT_Applicant1_SA_Street_Postcode__c= residentialAddress.PostCode ;
			chargeAccount.APT_Applicant1_SA_Suburb__c =residentialAddress.city ;
			chargeAccount.APT_Applicant1_SA_Street_Type__c =residentialAddress.Line2 ;
			chargeAccount.APT_Applicant1_SA_Country_Code__c =residentialAddress.country ;
			chargeAccount.APT_Applicant1_SA_Street_Name__c = String.isNotBlank(residentialAddress.Line1) ? residentialAddress.Line1.left(25) : APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Entity_Type__c = SOLETRADER;

			//1550
			/**
			//Emptying Company Business address Fields
			chargeAccount.APT_Billing_Addres_State__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Billing_Address_Street_Postcode__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Billing_Address_Suburb__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Billing_Address_Street_Name__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Billing_Address_country_code__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Billing_Address_Street_Type__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Street_Address_Street_Type__c = APT_Constants.EMPTY_STRING;


			chargeAccount.APT_Street_Address_State__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Street_Address_Street_Postcode__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Street_Address_Suburb__c = APT_Constants.EMPTY_STRING;

			chargeAccount.APT_Street_Address_Street_Name__c = APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Street_Address_Country_Code__c = APT_Constants.EMPTY_STRING;
			**/
			//1550


		} else {
			chargeAccount.APT_Billing_Addres_State__c = mailingAddress.state;
			chargeAccount.APT_Billing_Address_Street_Postcode__c = mailingAddress.PostCode;
			chargeAccount.APT_Billing_Address_Suburb__c = mailingAddress.city;
			chargeAccount.APT_Billing_Address_Street_Name__c = String.isNotBlank(mailingAddress.Line1) ? (mailingAddress.Line1).left(25) : APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Billing_Address_country_code__c = mailingAddress.country;
			chargeAccount.APT_Billing_Address_Street_Type__c = mailingAddress.Line2;
			chargeAccount.APT_Street_Address_Street_Type__c = physicaladdress.Line2;


			chargeAccount.APT_Street_Address_State__c = physicaladdress.state;
			chargeAccount.APT_Street_Address_Street_Postcode__c = physicaladdress.PostCode;
			chargeAccount.APT_Street_Address_Suburb__c = physicaladdress.city;

			chargeAccount.APT_Street_Address_Street_Name__c = String.isNotBlank(physicaladdress.Line1) ? (physicaladdress.Line1).left(25) : APT_Constants.EMPTY_STRING;
			chargeAccount.APT_Entity_Type__c = COMPANY;
			chargeAccount.APT_Street_Address_Country_Code__c = physicaladdress.country;

		}

	}

	/**
		Populate charge account for partnership
	*/
	private void populateChargeAccountForPartnership(APT_Charge_Account__c ca, Integer existingCreditAssessmentSize) {
		if(existingCreditAssessmentSize == 0) {
			//partner 1
			ca.APT_ABN__c = chargeAccount.APT_ABN__c;
			ca.APT_ACN__c = chargeAccount.APT_ACN__c;
			ca.APT_Business_name__c = chargeAccount.APT_Business_name__c;
			ca.APT_Credit_Limit_Required__c = chargeAccount.APT_Credit_Limit_Required__c;

			ca.APT_First_Name__c = chargeAccount.APT_First_Name__c;
			ca.APT_Last_Name__c = chargeAccount.APT_Last_Name__c;
			ca.APT_Applicant1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;

			ca.APT_Applicant1_BA_Unit_Number__c = chargeAccount.APT_Applicant1_BA_Unit_Number__c;
			ca.APT_Applicant1_BA_Street_Number__c = chargeAccount.APT_Applicant1_BA_Street_Number__c;
			ca.APT_Applicant1_BA_Street_Name__c = chargeAccount.APT_Applicant1_BA_Street_Name__c;
			ca.APT_Applicant1_BA_Street_Type__c = chargeAccount.APT_Applicant1_BA_Street_Type__c;
			ca.APT_Applicant1_BA_Suburb__c = chargeAccount.APT_Applicant1_BA_Suburb__c;
			ca.APT_Applicant1_BA_State__c = chargeAccount.APT_Applicant1_BA_State__c;
			ca.APT_Applicant1_BA_Street_Postcode__c = chargeAccount.APT_Applicant1_BA_Street_Postcode__c;
			ca.APT_Applicant1_BA_Telephone__c = chargeAccount.APT_Applicant1_BA_Telephone__c;

			ca.APT_Applicant1_SA_Unit_Number__c = chargeAccount.APT_Applicant1_SA_Unit_Number__c;
			ca.APT_Applicant1_SA_Street_Number__c = chargeAccount.APT_Applicant1_SA_Street_Number__c;
			ca.APT_Applicant1_SA_Street_Name__c = chargeAccount.APT_Applicant1_SA_Street_Name__c;
			ca.APT_Applicant1_SA_Street_Type__c = chargeAccount.APT_Applicant1_SA_Street_Type__c;
			ca.APT_Applicant1_SA_Suburb__c = chargeAccount.APT_Applicant1_SA_Suburb__c;
			ca.APT_Applicant1_SA_State__c = chargeAccount.APT_Applicant1_SA_State__c;
			ca.APT_Applicant1_SA_Street_Postcode__c = chargeAccount.APT_Applicant1_SA_Street_Postcode__c;
		} else if(existingCreditAssessmentSize == 1) {
			//partner 2
			ca.APT_Partner2_ABN__c = chargeAccount.APT_ABN__c;
			ca.APT_Partner2_ACN__c = chargeAccount.APT_ACN__c;
			ca.APT_Partner2_Business_name__c = chargeAccount.APT_Business_name__c;
			ca.APT_Partner2_Credit_Limit_Required__c = chargeAccount.APT_Credit_Limit_Required__c;

			ca.APT_Partner2_First_Name__c = chargeAccount.APT_First_Name__c;
			ca.APT_Partner2_Last_Name__c = chargeAccount.APT_Last_Name__c;
			ca.APT_Partner2_Applicant1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;

			ca.APT_Partner2_Applicant1_BA_Unit_Number__c = chargeAccount.APT_Applicant1_BA_Unit_Number__c;
			ca.APT_Partner2_Applicant1_BA_Street_Number__c = chargeAccount.APT_Applicant1_BA_Street_Number__c;
			ca.APT_Partner2_Applicant1_BA_Street_Name__c = chargeAccount.APT_Applicant1_BA_Street_Name__c;
			ca.APT_Partner2_Applicant1_BA_Street_Type__c = chargeAccount.APT_Applicant1_BA_Street_Type__c;
			ca.APT_Partner2_Applicant1_BA_Suburb__c = chargeAccount.APT_Applicant1_BA_Suburb__c;
			ca.APT_Partner2_Applicant1_BA_State__c = chargeAccount.APT_Applicant1_BA_State__c;
			ca.APT_P2_Applicant1_BA_Street_Postcode__c = chargeAccount.APT_Applicant1_BA_Street_Postcode__c;
			ca.APT_Partner2_Applicant1_BA_Telephone__c = chargeAccount.APT_Applicant1_BA_Telephone__c;

			ca.APT_Partner2_Applicant1_SA_Unit_Number__c = chargeAccount.APT_Applicant1_SA_Unit_Number__c;
			ca.APT_Partner2_Applicant1_SA_Street_Number__c = chargeAccount.APT_Applicant1_SA_Street_Number__c;
			ca.APT_Partner2_Applicant1_SA_Street_Name__c = chargeAccount.APT_Applicant1_SA_Street_Name__c;
			ca.APT_Partner2_Applicant1_SA_Street_Type__c = chargeAccount.APT_Applicant1_SA_Street_Type__c;
			ca.APT_Partner2_Applicant1_SA_Suburb__c = chargeAccount.APT_Applicant1_SA_Suburb__c;
			ca.APT_Partner2_Applicant1_SA_State__c = chargeAccount.APT_Applicant1_SA_State__c;
			ca.APT_P2_Applicant1_SA_Street_Postcode__c = chargeAccount.APT_Applicant1_SA_Street_Postcode__c;

		} else if(existingCreditAssessmentSize == 2) {
			//partner 3
			ca.APT_Partner3_ABN__c = chargeAccount.APT_ABN__c;
			ca.APT_Partner3_ACN__c = chargeAccount.APT_ACN__c;
			ca.APT_Partner3_Business_name__c = chargeAccount.APT_Business_name__c;
			ca.APT_Partner3_Credit_Limit_Required__c = chargeAccount.APT_Credit_Limit_Required__c;

			ca.APT_Partner3_First_Name__c = chargeAccount.APT_First_Name__c;
			ca.APT_Partner3_Last_Name__c = chargeAccount.APT_Last_Name__c;
			ca.APT_Partner3_Applicant1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;

			ca.APT_Partner3_Applicant1_BA_Unit_Number__c = chargeAccount.APT_Applicant1_BA_Unit_Number__c;
			ca.APT_Partner3_Applicant1_BA_Street_Number__c = chargeAccount.APT_Applicant1_BA_Street_Number__c;
			ca.APT_Partner3_Applicant1_BA_Street_Name__c = chargeAccount.APT_Applicant1_BA_Street_Name__c;
			ca.APT_Partner3_Applicant1_BA_Street_Type__c = chargeAccount.APT_Applicant1_BA_Street_Type__c;
			ca.APT_Partner3_Applicant1_BA_Suburb__c = chargeAccount.APT_Applicant1_BA_Suburb__c;
			ca.APT_Partner3_Applicant1_BA_State__c = chargeAccount.APT_Applicant1_BA_State__c;
			ca.APT_P3_Applicant1_BA_Street_Postcode__c = chargeAccount.APT_Applicant1_BA_Street_Postcode__c;
			ca.APT_Partner3_Applicant1_BA_Telephone__c = chargeAccount.APT_Applicant1_BA_Telephone__c;

			ca.APT_Partner3_Applicant1_SA_Unit_Number__c = chargeAccount.APT_Applicant1_SA_Unit_Number__c;
			ca.APT_Partner3_Applicant1_SA_Street_Number__c = chargeAccount.APT_Applicant1_SA_Street_Number__c;
			ca.APT_Partner3_Applicant1_SA_Street_Name__c = chargeAccount.APT_Applicant1_SA_Street_Name__c;
			ca.APT_Partner3_Applicant1_SA_Street_Type__c = chargeAccount.APT_Applicant1_SA_Street_Type__c;
			ca.APT_Partner3_Applicant1_SA_Suburb__c = chargeAccount.APT_Applicant1_SA_Suburb__c;
			ca.APT_Partner3_Applicant1_SA_State__c = chargeAccount.APT_Applicant1_SA_State__c;
			ca.APT_P3_Applicant1_SA_Street_Postcode__c = chargeAccount.APT_Applicant1_SA_Street_Postcode__c;

		} else if(existingCreditAssessmentSize == 3) {
			//partner 4
			ca.APT_Partner4_ABN__c = chargeAccount.APT_ABN__c;
			ca.APT_Partner4_ACN__c = chargeAccount.APT_ACN__c;
			ca.APT_Partner4_Business_name__c = chargeAccount.APT_Business_name__c;
			ca.APT_Partner4_Credit_Limit_Required__c = chargeAccount.APT_Credit_Limit_Required__c;

			ca.APT_Partner4_First_Name__c = chargeAccount.APT_First_Name__c;
			ca.APT_Partner4_Last_Name__c = chargeAccount.APT_Last_Name__c;
			ca.APT_Partner4_Applicant1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;

			ca.APT_Partner4_Applicant1_BA_Unit_Number__c = chargeAccount.APT_Applicant1_BA_Unit_Number__c;
			ca.APT_Partner4_Applicant1_BA_Street_Number__c = chargeAccount.APT_Applicant1_BA_Street_Number__c;
			ca.APT_Partner4_Applicant1_BA_Street_Name__c = chargeAccount.APT_Applicant1_BA_Street_Name__c;
			ca.APT_Partner4_Applicant1_BA_Street_Type__c = chargeAccount.APT_Applicant1_BA_Street_Type__c;
			ca.APT_Partner4_Applicant1_BA_Suburb__c = chargeAccount.APT_Applicant1_BA_Suburb__c;
			ca.APT_Partner4_Applicant1_BA_State__c = chargeAccount.APT_Applicant1_BA_State__c;
			ca.APT_P4_Applicant1_BA_Street_Postcode__c = chargeAccount.APT_Applicant1_BA_Street_Postcode__c;
			ca.APT_Partner4_Applicant1_BA_Telephone__c = chargeAccount.APT_Applicant1_BA_Telephone__c;

			ca.APT_Partner4_Applicant1_SA_Unit_Number__c = chargeAccount.APT_Applicant1_SA_Unit_Number__c;
			ca.APT_Partner4_Applicant1_SA_Street_Number__c = chargeAccount.APT_Applicant1_SA_Street_Number__c;
			ca.APT_Partner4_Applicant1_SA_Street_Name__c = chargeAccount.APT_Applicant1_SA_Street_Name__c;
			ca.APT_Partner4_Applicant1_SA_Street_Type__c = chargeAccount.APT_Applicant1_SA_Street_Type__c;
			ca.APT_Partner4_Applicant1_SA_Suburb__c = chargeAccount.APT_Applicant1_SA_Suburb__c;
			ca.APT_Partner4_Applicant1_SA_State__c = chargeAccount.APT_Applicant1_SA_State__c;
			ca.APT_P4_Applicant1_SA_Street_Postcode__c = chargeAccount.APT_Applicant1_SA_Street_Postcode__c;

		}
	}

	/**
		This method will select ASIC/ABR Report based on OrgID service response.
   **/
	private boolean isAccountNotChanged(Account acc){
		try {
			Boolean Flag = true;
			if(acc != null){
				Account oldAccount = [select id, ABN__c, ACN__c, Name from Account where id =:acc.ID];
				if(String.isBlank(oldAccount.Name) || !(oldAccount.Name).equalsIgnoreCase(acc.Name)){
					Flag = false;
				}
				if(String.isBlank(oldAccount.ABN__c) || !(oldAccount.ABN__c).equalsIgnoreCase(acc.ABN__c)){
					Flag = false;
				}

				if(String.isBlank(oldAccount.ACN__c) || !(oldAccount.ACN__c).equalsIgnoreCase(acc.ACN__c)){
					Flag = false;
				}
			}
			return flag;
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}

	}



	public boolean doCreditCheckFlag = false;
	/**
	This method will select ASIC/ABR Report based on OrgID service response.
 **/
	private void updateCreditAssessmentRefered(String status){
		try {
			creditAssesment.APT_Credit_Assessment_Status__c = status;
			insertCreditRecord();
			//updateProposalAndRedirectToSubAccount(creditAssesment.Id,status);
			ResultPageTitle = APT_Constants.Credit_Assessment_Outcome;
			CreditAssessmentFinalOutcome = status;
			PageType = PAGE_TYPE_RESULTS;
		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}

	}
	/**
	This method will select ASIC/ABR Report based on OrgID service response.
 **/
	public void checkCreditAssessment() {
		String initialPageType = PageType;
		try{
			if(doCreditCheckFlag && PAGE_TYPE_SOLE_TRADER.equalsIgnoreCase(PageType)){
				doSoleTraderCreditAssessment();

			} else if(doCreditCheckFlag && PAGE_TYPE_COMPANY_BUSINESS.equalsIgnoreCase(PageType)){
				doCompanyBusinessCreditAssessment();
			} else if(String.isNotblank(creditAssessmentErrorMessage)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,creditAssessmentErrorMessage));
			}

			//1550
			if(String.isNotBlank(CreditAssessmentFinalOutcome) && CreditAssessmentFinalOutcome.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED)) {
				isEntityTypePartnership = false;
				//end partnership process
			}
			//1550

			//1760
			if(String.isNotBlank(CreditAssessmentFinalOutcome) && CreditAssessmentFinalOutcome.equalsIgnoreCase('REFER')) {
				CreditAssessmentFinalOutcome = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;

				proposal.APT_Credit_Referred_Manually__c = false;
				update proposal;
			}
			//1760

		} Catch (Exception ex){
			String errorMessage = ex.getMessage().toLowerCase();
			if(errorMessage.contains(APT_Constants.ERROR_SOAP_FAULT)){
				errorMessage = APT_Constants.VEDA_SERVER_ISSUE;
			} else{
				errorMessage = ex.getMessage();
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage));
			PageType = initialPageType;
		}
	}

	public String AssessmentOutComeReason {get;set;}

	/*------------------------------------------------------------
	Author:        Shashwat Nath
	Description:   Method to perform the Credit Assessment for Individual/Sole Trader and
				   store the results sent by the Equifax.
	Inputs:        N/A
	Returns:       void
	*/

	private void doSoleTraderCreditAssessment(){
		try {
			Map<String,String> IndividualBusinessDecisionMap = new Map<String,String>();
			//Calling the method for Individual Assessment and storing the Result in Individiual decision Map.
			IndividualBusinessDecisionMap = APT_CompanyBusinessContHelper.creditCheckForSoleTrader(creditAssesment.Id,chargeAccount);
			if(IndividualBusinessDecisionMap != null &&  IndividualBusinessDecisionMap.containsKey(APPLICATION_DECISION)){
				//Checking if the Decision returned by Equifax is either pre-decline or decline then setting outcome as rejected
				if(PRE_DECLINE.equalsIgnoreCase(IndividualBusinessDecisionMap.get(APPLICATION_DECISION)) ||
						APT_Constants.CREDIT_ASSESSMENT_STATUS_DECLINE.equalsIgnoreCase(IndividualBusinessDecisionMap.get(APPLICATION_DECISION))){
					CreditAssessmentFinalOutcome = APT_Constants.APPROVAL_STATUS_REJECTED;
				}
				//Checking if the Decision retirned by Equifax is either pre-refer or refer then setting outcome as referred
				else if(PRE_REFER.equalsIgnoreCase(IndividualBusinessDecisionMap.get(APPLICATION_DECISION)) ||
						APT_Constants.CREDIT_ASSESSMENT_STATUS_REFER_ALL_CAPITAL.equalsIgnoreCase(IndividualBusinessDecisionMap.get(APPLICATION_DECISION))){
					CreditAssessmentFinalOutcome = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
				}
				//Checking if the Decision returned by Equifax is Approve then setting outcome as Approved
				else if(APT_Constants.APPROVAL_STAGE_APPROVE2.equalsIgnoreCase(IndividualBusinessDecisionMap.get(APPLICATION_DECISION))){
					CreditAssessmentFinalOutcome = APT_Constants.APPROVAL_STAGE_APPROVED;
				}
				else{
					CreditAssessmentFinalOutcome = IndividualBusinessDecisionMap.get(APPLICATION_DECISION);
				}
				//Setting the page Result title which would be displayed on the outcome screen
				ResultPageTitle = APT_Constants.Individual_Credit_Assessment_Results;
				PageType = PAGE_TYPE_RESULTS;
				//Setting the Credit Assessment Status
				creditAssesment.APT_Credit_Assessment_Status__c = CreditAssessmentFinalOutcome;
				if(IndividualBusinessDecisionMap.ContainsKey(DESCRIPTION) &&
						!APT_Constants.APPROVAL_STAGE_APPROVE2.equalsIgnoreCase(IndividualBusinessDecisionMap.get(APPLICATION_DECISION))){
					creditAssesment.L2C_Referral_Rejection_Reason__c = IndividualBusinessDecisionMap.get(DESCRIPTION);
				}
				// Updating the Credit Assessment Record
				database.update(creditAssesment);

			} else {
				// If response from Equifax contains Exception then displaying the Error to the User as a page Message
				if(IndividualBusinessDecisionMap !=null && IndividualBusinessDecisionMap.containsKey(RESPONSE_EXCEPTION)){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, IndividualBusinessDecisionMap.get(EXCEPTION_DESCRIPTION)));
					PageType = PAGE_TYPE_SOLE_TRADER;
				}
			}
		}  catch(Exception ex){
			// Displaying error to the user for any generic Exception
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}

	}

	/*------------------------------------------------------------
	Author:        Shashwat Nath
	Description:   Method to perform the Credit Assessment for Company and
				   store the results sent by the Equifax.
	Inputs:        N/A
	Returns:       void
	*/
	private void doCompanyBusinessCreditAssessment(){

		Map<String,String> CompanyBusinessDecisionMap = new Map<String,String>();
		//Calling the method for Company Business Assessment and storing the Result in Company Business Map.
		CompanyBusinessDecisionMap = APT_CompanyBusinessContHelper.creditCheckForCompanyBusiness(creditAssesment.ID , entityTypeForAssessment, chargeAccount );
		try {
			if(CompanyBusinessDecisionMap != null && CompanyBusinessDecisionMap.containsKey(COMPANY_BUSINESS_DECISION)) {
				//Checking if the Decision retirned by Equifax is either pre-decline or decline then setting outcome as rejected
				if(PRE_DECLINE.equalsIgnoreCase(CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION)) ||
						APT_Constants.CREDIT_ASSESSMENT_STATUS_DECLINE.equalsIgnoreCase(CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION))){
					CreditAssessmentFinalOutcome = APT_Constants.APPROVAL_STATUS_REJECTED;
				}
				//Checking if the Decision returned by Equifax is either pre-refer or refer then setting outcome as referred
				else if(PRE_REFER.equalsIgnoreCase(CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION)) ||
						APT_Constants.CREDIT_ASSESSMENT_STATUS_REFER_ALL_CAPITAL.equalsIgnoreCase(CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION))){
					CreditAssessmentFinalOutcome = APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED;
				}
				//Checking if the Decision returned by Equifax is Approve then setting outcome as Approved
				else if(APT_Constants.APPROVAL_STAGE_APPROVE2.equalsIgnoreCase(CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION))){
					CreditAssessmentFinalOutcome = APT_Constants.APPROVAL_STAGE_APPROVED;
				}
				else{
					CreditAssessmentFinalOutcome = CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION);
				}
				//Setting the page Result title which would be displayed on the outcome screen
				ResultPageTitle = COMPANY_BUSINESS_ASSESSMENT_OUTCOME;
				PageType = PAGE_TYPE_RESULTS;
				//Setting the Credit Assessment Status
				creditAssesment.APT_Credit_Assessment_Status__c = CreditAssessmentFinalOutcome;
				if(CompanyBusinessDecisionMap.containsKey(DESCRIPTION) &&
						!APT_Constants.APPROVAL_STAGE_APPROVE2.equalsIgnoreCase(CompanyBusinessDecisionMap.get(COMPANY_BUSINESS_DECISION))){
					creditAssesment.L2C_Referral_Rejection_Reason__c = CompanyBusinessDecisionMap.get(DESCRIPTION);
				}
				// Updating the Credit Assessment Record
				database.update(creditAssesment);
			} else {
				// If response from Equifax contains Exception then displaying the Error to the User as a page Message
				if(!CompanyBusinessDecisionMap.keyset().isEmpty() && CompanyBusinessDecisionMap.containsKey(RESPONSE_EXCEPTION)){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CompanyBusinessDecisionMap.get(EXCEPTION_DESCRIPTION)));
					PageType = PAGE_TYPE_COMPANY_BUSINESS;
				}
			}
		}  catch(Exception ex){
			// Displaying error to the user for any generic Exception
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
	}
	/**
	This method will select ASIC/ABR Report based on OrgID service response.
 */
	private void insertCreditRecord(){
		try {
			//1550
			if(isEntityTypePartnership) {
				insert selectedABRReport;
				insert selectedASICReport;
			} else {
				upsert selectedABRReport;
				upsert selectedASICReport;
			}
			//1550
			if(isAnonymousFlow){
				creditAssesment.L2C_Assessment_Type__c = MANUAL_ENTRY_SCREEN;
				list<APT_Credit_Assessment__c> listInProgressCreditAssessment = [SELECT Id, Name, APT_ABN__c, APT_ACN__c,
						APT_Credit_Assessment_Status__c
				FROM APT_Credit_Assessment__c
				WHERE //APT_Organisation_Name__c = :accountID AND
						APT_Credit_Assessment_Complete__c = true
						AND ((APT_ABN__c != null AND APT_ABN__c = :chargeAccount.APT_ABN__c) OR (APT_ACN__c != null AND APT_ACN__c = :chargeAccount.APT_ACN__c))
						//AND (APT_ABN__c = :AustralianBusinessNumber OR APT_ACN__c = :OrganisationNumber)
						AND APT_Credit_Assessment_Status__c =:WORK_IN_PROGRESS];
				//setting up details from created credit assessment record.

				if(!listInProgressCreditAssessment.IsEmpty()){
					creditAssesment.id = listInProgressCreditAssessment[0].id;
					creditAssesment.L2C_Assessment_Type__c ='Proposal';
				}
			}
			//setting up details from created credit assessment record.
			creditAssesment.APT_Legal_Entity_Name__c = chargeAccount.APT_Company_Name__c;

			creditAssesment.APT_ABN__c = chargeAccount.APT_ABN__c;
			creditAssesment.APT_ACN__c = chargeAccount.APT_ACN__c;
			if(!isAnonymousFlow){
				creditAssesment.APT_Organisation_Name__c = account.id;
				creditAssesment.APT_Proposal__c = proposalId;
				creditAssesment.L2C_Assessment_Type__c ='Proposal';
				creditAssesment.L2C_Star_Track_Proposed_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;

				/* Shashwat.Nath@Aupost.com added the below if else Condition as part of the user strory STP-2832 to populate
						1. If proposal is not startrack then AP proposed for New Account would be populated based on Opportunity Amount multiplied by .25(which is configurable).
						   This is the value which would be passed as credit amount to SAP for billing account creation.
						2. If proposal is startrack then ST proposed for new Account would be calculated based on Opportunity Amount multiplied by .25(which is configurable)
				*/
				//Applying the RoundUp to next thousands for both AP and ST
				if('No'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
					creditRoundUp = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c).intValue() ;
					creditRoundUpResult = ((creditRoundUp + NEAREST_ROUND_OFF_3)/NEAREST_ROUND_OFF_2)*NEAREST_ROUND_OFF_2;
					creditAssesment.Aus_Post_Proposed_for_New_Account__c = creditRoundUpResult;
				}
				else if('Yes'.equalsIgnoreCase(proposal?.Apttus_Proposal__Opportunity__r?.IsStartrackProposal__c)){
					creditRoundUp = ((proposal?.Apttus_Proposal__Opportunity__r?.amount !=null ? proposal.Apttus_Proposal__Opportunity__r.amount:0)*APT_R2T_System_Properties__c.getOrgDefaults().Opportunity_Value_Multiplier__c).intValue();
					creditRoundUpResult = ((creditRoundUp + NEAREST_ROUND_OFF_3)/NEAREST_ROUND_OFF_2)*NEAREST_ROUND_OFF_2;
					creditAssesment.StarTrack_Proposed_for_New_Account__c = creditRoundUpResult;
				}

				/* Shashwat.Nath@Auspost.com code ends */
			}

			creditAssesment.APT_ABR_Report__c = selectedABRReport.id;
			creditAssesment.APT_ASIC_Report__c = selectedASICReport.id;

			//update credit assessment fields
			if(chargeAccount.APT_Industry_Type__c != null) {
				creditAssesment.APT_Industry_Type__c = chargeAccount.APT_Industry_Type__c.subString(0, 1);
			}
			if(String.isNotBlank(creditAssesment.APT_Legal_Entity_Name__c) && !isAnonymousFlow){
				creditAssesment.APT_Legal_Entity_Name__c = account.Name;
			}
			else if(isAnonymousFlow){
				creditAssesment.APT_Legal_Entity_Name__c = chargeAccount.APT_Company_Name__c;
			}
			//update credit assessment fields

			creditAssesment.APT_Term_Days__c = APT_Constants.END_CHARACTER_D + chargeAccount.APT_Term_Days__c;
			creditAssesment.APT_Account_Type__c = APT_Constants.END_CHARACTER_D + chargeAccount.APT_Term_Days__c;
			creditAssesment.APT_Credit_Amount_Required__c = chargeAccount.APT_Credit_Limit_Required__c;
			creditAssesment.L2C_AP_Proposed_Credit_Limit__c = chargeAccount.AP_Proposed_Credit_Limit__c;
			creditAssesment.L2C_Star_Track_Proposed_Credit_Limit__c = chargeAccount.Star_Track_Proposed_Credit_Limit__c;
			creditAssesment.APT_Applicant_1_First_Name__c = chargeAccount.APT_First_Name__c;
			creditAssesment.APT_Applicant_1_Last_Name__c = chargeAccount.APT_Last_Name__c;
			creditAssesment.APT_Applicant_1_Date_of_Birth__c = chargeAccount.APT_Applicant1_Date_of_Birth__c;


			//Setting up charge account adress info.
			creditAssesment.APT_Applicant_1_Unit_Number__c = chargeAccount.APT_Applicant1_BA_Unit_Number__c;
			creditAssesment.APT_Applicant_1_Street_Number__c = chargeAccount.APT_Applicant1_BA_Street_Number__c;
			creditAssesment.APT_Applicant_1_Street_Name__c = chargeAccount.APT_Applicant1_BA_Street_Name__c;
			creditAssesment.APT_Applicant_1_Street_Type__c = chargeAccount.APT_Applicant1_BA_Street_Type__c;
			creditAssesment.APT_Applicant_1_Suburb__c = chargeAccount.APT_Applicant1_BA_Suburb__c;
			creditAssesment.APT_Applicant_1_Postcode__c = chargeAccount.APT_Applicant1_BA_Street_Postcode__c;
			creditAssesment.APT_Applicant_1_State__c = chargeAccount.APT_Applicant1_BA_State__c;
			creditAssesment.APT_Applicant_1_Country__c = chargeAccount.APT_Applicant1_BA_Country_Code__c;

			creditAssesment.APT_Applicant_1_Credit_Check_Consent__c = chargeAccount.APT_A1_Consent_to_check_credit_history__c;

			//1550
			if(String.isBlank(creditAssesment.APT_Charge_Account__c)) {
				creditAssesment.APT_Charge_Account__c = chargeAccount.Id;
			}
			//1550

			upsert creditAssesment;

		}  catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

		}
	}

	//1550
	/**
		Add Partner
	*/
	public PageReference addPartner() {
		PageType = PAGE_TYPE_SEARCH_ABN;
		creditAssesment = new APT_Credit_Assessment__c();
		doCreditCheckFlag = false;
		creditAssessmentRecordCount++;
		//userinput= null;
		return null;
	}

	/*------------------------------------------------------------
	Author:        Shashwat Nath
	Description:   Method to Redirect the user to the Credit assessment record detail page
	Inputs:        N/A
	Returns:       PageReference
	*/
	public PageReference redirectToCreditAssessmentRecord() {
		PageReference redirectPage = null;
		//Setting the page redirection to the credit assessment record detail page
		if(referToCredit){
			redirectPage = new ApexPages.StandardController(creditAssess).View();
		}
		else{
			redirectPage = new ApexPages.StandardController(creditAssesment).View();
		}
		creditAssesment.APT_Credit_Assessment_Complete__c = true;
		if(!referToCredit){
			database.update(creditAssesment);
		}
		//return page reference
		return redirectPage;
	}

	/*------------------------------------------------------------
	Author:        Shashwat Nath
	Description:   Method to redirect user to the home page
	Inputs:        N/A
	Returns:       PageReference
	*/
	public PageReference redirectToHomePage() {
		//Set page reference to redirect user back to home page
		PageReference pageRef = new PageReference('/');
		pageRef.setRedirect(true);
		//return page reference
		return pageRef;
	}

	/**
	 * @author:         Seth Heang
	 * @description:    Method to perform duplicate check on matching ABN/ACN of existing Organisation records
						The duplicate check is called prior to executing the ABN/ACN lookup at Equifax
	 * @param:          List<Account>
	 * @return:         Boolean - true if duplicate is found, otherwise false
	 */
	public static Boolean containDuplicate_ABN_ACN(List<Account> accList, Id acctId) {
		Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(accList);
		Account newAcc = new Account();
		/**
		 * Sample code from Salesforce, to return the duplicate records found by the matching rule on Organisation ABN/ACN
		 * Link: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Datacloud_FindDuplicatesResult.htm#apex_class_Datacloud_FindDuplicatesResult
		 *  */
		for (Datacloud.FindDuplicatesResult findDupeResult : results) {
			for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
				for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
					for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
						// save the duplicate record found by the matching rule and cast to Account type
						newAcc = (Account) matchRecord.getRecord();
					}
				}
			}
		}
		/**
		 * Ensure that the returned duplicate record is not the associated organisation of the proposal
		 * It must be a distinct and existing organisation record, unrelated to the current proposal
		 *  */
		if(String.isNotBlank(newAcc.id) && (newAcc.id != acctId)){
			return true;
		}
		return false;
	}
}