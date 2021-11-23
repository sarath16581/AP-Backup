/**
Description: This apex class is extension class for APT_CashAccountAssessment page
Created By: Adil muzaffar
Created Date: 09th Dec, 2015

Last Modified By: Mausam Padhiyar
Last Modified Date: 6th Sept, 2016 | 940 - Validate State

Last Modified By: Mausam Padhiyar
Last Modified Date: 5th Dec, 2016 | 1773 | Cash Account
*/
public with sharing class APT_CashAccountAssessmentController {
    public APT_ABRreport__c selectedABRReport{get;set;}
    public APT_ASIC_Report__c selectedASICReport{get;set;}
    public List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>orgIdResultList{get;set;}
    public APT_Cash_Account__c cashAccount{get;set;}
    public Account account{get;set;}
    
    
    public AddressExtension mailingAddress {get;set;}
    public AddressExtension physicaladdress {get;set;}
    
    
    private String opptyID;
    Apttus_Proposal__Proposal__c proposal;
    private String proposalId;
    
    public Boolean showCashAssessment{get;set;}
    public String assesmentType{get;set;}
    public String userinput{get;set;}
    public Boolean showSearchResults{get;set;}
    public Integer selectedOrgIdUniqueNumber{get;set;}
    public Boolean showCompanyBusiness{get;set;}
    public Boolean showSoleTrader{get;set;}
    private String creditAssesmentId;
    public APT_Credit_Assessment__c creditAssesment{get;set;}
    public Boolean showcashAccount{get;set;}
    public boolean displayPopUp{get;set;}
    public boolean isAccountFlow {get;set;}
    public string accountID {get;set;}
    
    //public static final string strTitle = 'Cash Account Assessment';
    //public static string strGetValTitle {get{return strTitle;} set;}
    
    //public static final string strCustomerDetails = 'Customer Details';
    //public static string strGetValCustomerDetails {get{return strCustomerDetails;} set;}

    
    public static string strGetValCustomerName {get{return APT_Constants.strCustomerName;} set;}
    
    //public static final string strABN = 'ABN';
    //public static string strGetValABN {get{return strABN;} set;}
    
    //public static final string strACN = 'ACN';
    //public static string strGetValACN {get{return strACN;} set;}
    
    //public static final string strLocationAddr = 'Location Address';
    //public static string strGetValLocationAddr {get{return strLocationAddr;} set;}
    
    //public static final string strCustomerLVL = 'Customer Lvl/Suite/Bldg';
    //public static string strGetValCustomerLVL {get{return strCustomerLVL;} set;}
    
    //public static final string strCustomerTel = 'Customer Telephone';
   //public static string strGetValCustomerTel {get{return strCustomerTel;} set;}
    
    //public static final string strCustomerFax = 'Customer Fax';
    //public static string strGetValCustomerFax {get{return strCustomerFax;} set;}
    
    //public static final string strCustomerWebsite = 'Customer Website';
    //public static string strGetValCustomerWebsite {get{return strCustomerWebsite;} set;}
    
    //public static final string strCustomerEmail = 'Customer Email ';
    //public static string strGetValCustomerEmail {get{return strCustomerEmail;} set;}
    
    //public static final string strCustomerTitle = 'Mr/Mrs/Dr Etc ';
    //public static string strGetValCustomerTitle {get{return strCustomerTitle;} set;}
    
    // static final string strContractFName = 'Contact First Name';
    //public static string strGetValContractFName {get{return strContractFName;} set;}
    
    //public static final string strContractLName = 'Contact Last Name';
    //public static string strGetValContractLName {get{return strContractLName;} set;}
    
    //public static final string strContractTitle = 'Contact Job Title';
    //public static string strGetValContractTitle {get{return strContractTitle;} set;}
    
    //public static final string strContractTel = 'Contact Telephone';
    //public static string strGetValContractTel {get{return strContractTel;} set;}
    
    //public static final string strContractMobile = 'Contact Mobile';
    //public static string strGetValContractMobile {get{return strContractMobile;} set;}
    
    //public static final string strContractFax = 'Contact Fax';
    //public static string strGetValContractFax {get{return strContractFax;} set;}
    
    //public static final string strMarket = 'Can we market to them?';
    //public static string strGetValMarket {get{return strMarket;} set;}
    
    //public static final string strContactEmail = 'Contact Email';
    //public static string strGetValContactEmail {get{return strContactEmail;} set;}
    
    //public static final string strMailingDetails = 'Mailing Details';
    //public static string strGetValMailingDetails {get{return strMailingDetails;} set;}
    
   // public static final string strSearchSelectOrg = 'Search and Select Organisation';
    //public static string strGetValSearchSelectOrg {get{return strSearchSelectOrg;} set;}
    
    //public static final string strSearchResult = 'Search Results';
    //public static string strGetValSearchResult {get{return strSearchResult;} set;}
    /**
     Constructor    
    **/
    public APT_CashAccountAssessmentController(ApexPages.StandardController controller) {
        init();
    }
    /**
        Init Method
    **/
    public void init () {
         try {
             showcashAccount = true;
            showCashAssessment = false;
            showSearchResults = false;
            cashAccount = new APT_Cash_Account__c();
            proposalID = Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_PROPOSAL_ID);
            accountID = Apexpages.currentPage().getParameters().get(APT_Constants.PARAM_ACCOUNT_ID);
            
            
            isAccountFlow = false;
            
            if(String.isBlank(proposalID) && String.isNotBlank(accountID)) {
                isAccountFlow = true;
            } else {
                proposal = [SELECT id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c
                            FROM Apttus_Proposal__Proposal__c WHERE Id = : proposalID];
                if (proposal != null) {
                    accountID = proposal.Apttus_Proposal__Account__c;
                    opptyID = proposal.Apttus_Proposal__Opportunity__c;
                    
                }
            } 
         } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            
        }
    }
    /**
     Method for cash account detail
    **/
    public void accounDetails() {
        try {
            cashAccount.APT_Organisation__c = accountID;
            creditAssesment = new APT_Credit_Assessment__c();
            assesmentType = APT_WebServiceUtility.ACN;
            if (String.isNotBlank(accountID)) {
                account = [select ABN__c, Legal_Name__c, ACN__c, Name, Organisation_Trading_Name__c, fax,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Website, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                from Account where id = : accountID];
                
                
                
                mailingAddress = new AddressExtension(account.billingStreet, APT_Constants.EMPTY_STRING, account.BillingCity, account.BillingState, account.BillingPostalCode, account.ABN__c, account.BillingCountry);
                physicaladdress = new AddressExtension(account.ShippingStreet, APT_Constants.EMPTY_STRING, account.ShippingCity, account.ShippingState, account.ShippingPostalCode, account.ABN__c, account.ShippingCountry);       
                    
                if (String.isNotBlank(account.ACN__c)) {
                    userinput = account.ACN__c;
                    
                } else if (String.isNotBlank(account.ABN__c)){
                    userinput = account.ABN__c;
                    assesmentType = APT_WebServiceUtility.ABN;
                } else {
                    
                }
                cashAccount.APT_Cust_Name__c = account.name;
                cashAccount.APT_Cust_Website__c = account.Website;
                cashAccount.APT_Cont_Telephone__c = account.phone;
                /*
                cashAccount.APT_Cust_State__c = account.ShippingState;
                cashAccount.APT_Cust_Postcode__c = account.ShippingPostalCode;
                cashAccount.APT_Cust_Str_no_Name__c = account.ShippingStreet;
                cashAccount.APT_Cust_Str_no_Name_mailing__c = account.BillingStreet;
                cashAccount.APT_Cust_State_mailing__c = account.BillingState;
                cashAccount.APT_Cust_Postcode_mailing__c = account.BillingPostalCode;*/
                cashAccount.APT_ABN__c = account.ABN__c;
                cashAccount.APT_ACN__c = account.ACN__c;
                cashAccount.APT_Cust_Fax__c = account.fax;
            }
            if (String.isNotBlank(opptyID)) {
                opportunity oppty = [select name, KeyContact__c from opportunity where id = : opptyID];
                if (oppty != null && String.isNotBlank(oppty.KeyContact__c)) {
                    contact con = [select name, Email, Fax, Salutation, FirstName, LastName, Phone, MobilePhone, Title from contact where id = : oppty.KeyContact__c];
                    cashAccount.APT_Cont_First_Name__c = con.FirstName;
                    cashAccount.APT_Cont_Last_Name__c = con.LastName;
                    cashAccount.APT_Cont_Mobile__c = con.MobilePhone;
                    cashAccount.APT_Cont_Telephone__c = con.Phone;
                    cashAccount.APT_Cont_Email__c = con.Email;
                    cashAccount.APT_Cont_Fax__c = con.Fax;
                    cashAccount.APT_Mr_Mrs_Dr_Etc__c = con.Salutation;
                    cashAccount.APT_Cont_Job_Title__c = con.Title;
                }
            }
            
            if(proposal != null){
                cashAccount.APT_Proposal__c = proposal.id;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           
        }
    }
    /**
     Method to redirect to proposal page
    **/
    public pageReference backToProposal() {
        try {
            PageReference redirectPage = null;
            if(isAccountFlow){
                Account acc = new Account();
                acc.id = accountID;
                redirectPage =  new ApexPages.StandardController(acc).View();
            } else{
                Apttus_Proposal__Proposal__c prop = new Apttus_Proposal__Proposal__c();
                prop.id = proposalId;
                redirectPage =  new ApexPages.StandardController(prop).View();
            }
            return redirectPage;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    /**
        Method to set option for company business type field
    **/
    public List < SelectOption > getCompanyBusinessType() {
        try {
            List < SelectOption > options = new List < SelectOption > ();
            options.add(new SelectOption(APT_WebServiceUtility.ACN, APT_WebServiceUtility.ACN));
            options.add(new SelectOption(APT_WebServiceUtility.ABN, APT_WebServiceUtility.ABN));
            options.add(new SelectOption(APT_WebServiceUtility.ORGANIZATION_NAME, APT_WebServiceUtility.ORGANIZATION_NAME));
            return options;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
    /**
     * This method will insert cash account record
     */
    public PageReference createCashAccount() {
        //1773
        upsert cashAccount;
        //1773
        
        return null;
    }
    
    /** 
     Method to retrieve org details
    **/
    public void requestOrgIDDetails() {
        
        String OrganisationNumber = null;
        String AustralianBusinessNumber = null;
        String OrgName = null;

        if(!String.isEmpty(assesmentType) && !String.isEmpty(APT_WebServiceUtility.ABN) && assesmentType.equalsIgnoreCase(APT_WebServiceUtility.ABN)){
            AustralianBusinessNumber = userinput; //'87009610342';
            if(userinput.length() != 11) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.WEBSERVICE_INVALID_ABN));
                return;
            }
        } else if(!String.isEmpty(assesmentType) && !String.isEmpty(APT_WebServiceUtility.ACN) && assesmentType.equalsIgnoreCase(APT_WebServiceUtility.ACN)){
            OrganisationNumber = userinput;
            if(userinput.length() != 9) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.WEBSERVICE_INVALID_ACN));
                return;
            }
        } else {
            OrgName = userinput;
            if(userinput.length() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.WEBSERVICE_INVALID_INPUT));
                return;
            }
        }

        APT_ServicePartyCustomerService service = new APT_ServicePartyCustomerService();
        
        APT_ServicePartyCustomerService.ABNServices_v1HTTPEndpoint1 endPoint = new APT_ServicePartyCustomerService.ABNServices_v1HTTPEndpoint1();
        endPoint.inputHttpHeaders_x = APT_WebServiceUtility.getinputHttpHeaders();
        endPoint.Header = APT_WebServiceUtility.getOrgIDInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYABN);
        endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
        APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
        if (r2tSystemProperty != null && !String.isEmpty(r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c)) {
            endPoint.endpoint_x = r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SOAP_ENDPOINT_EXCEPTION));
        }
        
        APT_SchemaPartyCustomerService.queryABNResponseType responseService;
        
        APT_SchemaPartyCustomerService.BusinessRegistrationNumber_element BusinessRegistrationNumber = null;
        String BureauReference = null;
        
        showSearchResults = true;
        try {
            responseService = endPoint.queryABN_v1(OrganisationNumber, AustralianBusinessNumber, OrgName, BusinessRegistrationNumber, BureauReference);
            APT_OrgIDWebServiceWrapper.queryABNResponseType orgIdResponse = APT_CompanyBusinessContHelper.parseOrgIDResponseToWrapper(responseService, 0, account.name);
            orgIdResultList = orgIdResponse.OrgIdResult;
            if(orgIdResponse.Error != null && (String.isNotBlank(orgIdResponse.Error.ErrorTypeCode)
                                                    || String.isNotBlank(orgIdResponse.Error.InputContainer)
                                                    || String.isNotBlank(orgIdResponse.Error.ErrorDescriptionTypeCode))){
                                                        
                String errormessage = APT_Constants.ERROR_VEDA_ERROR + APT_Constants.SEPARATOR_COLON + orgIdResponse.Error.ErrorTypeDesc 
                                                + APT_Constants.SEPARATOR_COLON + orgIdResponse.Error.InputContainer 
                                                + APT_Constants.SEPARATOR_COLON + orgIdResponse.Error.ErrorDescriptiontype;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errormessage));
            }
        } Catch(Exception ex) {

            String errorMessage = ex.getMessage().toLowerCase();
            if (errorMessage.contains(APT_Constants.ERROR_SOAP_FAULT)) {
                errorMessage = APT_Constants.VEDA_SERVER_ISSUE;
            } else {
                errorMessage = ex.getMessage();
                System.debug('ex.getMessage(try):' + ex.getMessage());
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
    }

    
    /**
     Method to set fields on account
    **/
    public PageReference doNextForChargeAccount() {
        try {
            /*
            cashAccount.APT_Cust_State__c = account.ShippingState;
            cashAccount.APT_Cust_Postcode__c = account.ShippingPostalCode;
            cashAccount.APT_Cust_Str_no_Name__c = account.ShippingStreet;
            cashAccount.APT_Cust_Str_no_Name_mailing__c = account.BillingStreet;
            cashAccount.APT_Cust_State_mailing__c = account.BillingState;
            cashAccount.APT_Cust_Postcode_mailing__c = account.BillingPostalCode;
            
            
            */
            
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
                    if(mailingAddress != null && String.isNotBlank(mailingAddress.state) && !setValidStates.contains(mailingAddress.state)) {
                        bIsValidState = false;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid State.'));
                    }
                    
                    if(physicaladdress != null && String.isNotBlank(physicaladdress.state) && !setValidStates.contains(physicaladdress.state)) {
                        bIsValidState = false;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid State.'));
                    }
                   
                    if(!bIsValidState) {
                        return null;
                    }
                }
            }
            //940
            
            
            cashAccount.APT_Cust_State_mailing__c = mailingAddress.state;
            cashAccount.APT_Cust_Postcode_mailing__c = mailingAddress.PostCode;
            cashAccount.APT_Cust_Suburb_mailing__c = mailingAddress.city;
            cashAccount.APT_Cust_Str_no_Name_mailing__c = mailingAddress.Line1;
            
            //physical = Shippping
            cashAccount.APT_Cust_State__c = physicalAddress.State;
            cashAccount.APT_Cust_Postcode__c = physicalAddress.PostCode;
            cashAccount.APT_Cust_Suburb__c = physicalAddress.City;
            cashAccount.APT_Cust_Str_no_Name__c = String.isNotBlank(physicalAddress.Line1) ? physicalAddress.Line1.left(25) : APT_Constants.EMPTY_STRING;
            
            //upsert cashAccount;   //1773
            showcashAccount = false;
            showcashAssessment = true;

        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }


}