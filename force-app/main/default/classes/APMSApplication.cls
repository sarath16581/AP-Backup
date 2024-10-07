/**
* @author Louis Wang (Bluewolf)
* @date 2014-02-24
* @group Secure Pay Feature
* @tag Controller
* @tag APMS_Application__c
* @domain SecurePay Integration Project
* @description Controller for visualforce page APMSApplication.
* NOTE: This class is used by Application VF Page from SecurePay Site. 
* 2014-02-24 - Louis Wang (Bluewolf) - Created
* 2015-05-10 - scherukuwada@salesforce.com - Added Sharing
* 2015-08-25 - eric.shen@auspost.com.au - Change Opportunity closed date to one month later than created date.
* 2015-09-10 - eric.shen@auspost.com.au - create a custom setting Revenue Percentage, this will be the multiplier for opportunity product unit price as requested by Chelsea O'Reilly
* 2015-11-23 - kalpita.talwadekar@auspost.com.au - updated the oppty line item to have start and end date as they are now mandatory 
* 2020-11-18 - dheeraj.mandavilli@auspost.com.au - Added new fields on Secure Pay form to support Multi Currency feature on Secure Pay Application.
*/

public without sharing class APMSApplication 
{

    private static final integer STARTING_SECTION = 0;
    private static final boolean DEV_MODE = false;
    
    private boolean isDevMode;
    public Application__c app {get;set;}
    public Application__c fetchedApp {get;set;}
    public integer section {get;set;}    
    public string LandingPageError_OldAcct {get;set;}
    public string LandingPageError_NewAcct {get;set;}    
    public string InputAbnOrAcn {get;set;}
    private Account existingAcct {get;set;}
    
    public boolean showContactPositionOtherFlag {get; set;}
    public boolean showPrincipal1PositionOtherFlag {get; set;}
    public boolean showPrincipal2PositionOtherFlag {get; set;}
    public boolean showTrusteeFlag {get;set;}
    public string principal1DOB {get;set;}
    public string principal2DOB {get;set;}
    public string contactPhone {get;set;}
    public string contactMobile {get;set;} 
    public string contactFax {get;set;}
    public boolean showAPMerchantFlag {get; set;}
	public boolean showMulticurrencyFlag {get;set;}
    public boolean showSecurePayMerchantFlag {get;set;}
    public boolean showShoppingCartOtherFlag {get;set;}
    public string businessDesc {get;set;}

    public string sfdcBaseURL {get;set;}
    public APMSApplication topController {get;set;}
    public APMSApplication gettheController()
    {
        return this; 
    }

    // custom made style for input field when there is validation error 
    public static final string STYLE_RED_BORDER = 'border: 1px solid #dc1928;';
    public static final string EMAIL_STYLECLASS = 'email-textbox';
    public static final string ERROR_LINE = '<p style="display:block; color:#dc1928; margin:0; ">Please enter a value.</p>';
    public string landingPage_OldAcct_AcctNo_ErrorStyle {get;set;}
    public string landingPage_OldAcct_Abn_ErrorStyle {get;set;}    
    public string dateBusinessCommenced_ErrorStyle {get;set;}
    public string abn_ErrorStyle {get;set;}
    public string acn_ErrorStyle {get;set;}
    public string dob1_ErrorStyle {get;set;}
    public string dob2_ErrorStyle {get;set;}
    public string nameOnCCStatement_ErrorStyle {get;set;}
    public string totalPercentage_ErrorStyle {get;set;}
    public string contactPhone_ErrorStyle {get;set;}
    public string contactMobile_ErrorStyle {get;set;}
    public string contactFax_ErrorStyle {get;set;}
    public string principal2Signatory_ErrorStyleClass {get;set;}
    public string principal2Signatory_ErrorStyle {get;set;}
    public string businessDesc_ErrorStyle {get;set;}
    public string tc_ErrorStyle {get;set;}
    public string daysPaidInAdvance_ErrorStyle {get;set;}
    public string errormsg_ErrorStyle {get;set;}
    
    public AddressExtension businessAddress {get;set;}    
    public AddressExtension mailingAddress {get;set;}
    public AddressExtension principal1Address {get;set;}
    public AddressExtension principal2Address {get;set;}

    private Id apmsOpportunityOwnerId;
    private Id accountRecordTypeId;
    private Id contactRecordTypeId;
    private string httpsRedirect;
    private double  revenuepercentage;    // 03-Sep-15 Eric Shen define revenue percentage for custom setting
    public APMSSetting__c configSetting {get;set;}
    
    public APMSApplication(APMSQasComponent controller)
    {
        // This constructor will be called by VF Component (for QAS predictive search)
    }
  
    public APMSApplication(ApexPages.StandardController controller) 
    {    
        //Set header for page rendering and security for IE8
        setPageHeaders();

        section = STARTING_SECTION;
        isDevMode = DEV_MODE;

        string appId = ApexPages.currentPage().getParameters().get('Id');
        string appEmail = ApexPages.currentPage().getParameters().get('AppEmail');

        if(appId!=null && appId!='' && appEmail!=null && appEmail!='')
        {
            appId = EncodingUtil.urlDecode(appId, 'UTF-8');
            appEmail = EncodingUtil.urlDecode(appEmail, 'UTF-8');
            
            list<Application__c> appList = [SELECT Id, Name, ContactEmail__c, isExistingAusPostBusinessAccount__c,
                                                    HowDoYouFindUs__c, SelectedPricePlan__c ,TotalAnnualTurnoverProjected__c
                                            FROM Application__c 
                                            WHERE Id =: appId AND ContactEmail__c =: appEmail LIMIT 1];
            if(appList.size() == 0)
            {
                app = new Application__c();
            }
            else
            {
                app = appList[0];

                // if there is application id, then divert it to section 5
                section = 5;
                
                // fetch params from Custom Setting
                fetchCustomSettings();        
                
                // exit the function so app is not modified by subsequent code
                return;
            }
        }
        else
        {
            app = new Application__c();
        }
        businessAddress = new AddressExtension();
        mailingAddress = new AddressExtension();
        principal1Address = new AddressExtension();
        principal2Address = new AddressExtension();

        showContactPositionOtherFlag = false;
        showPrincipal1PositionOtherFlag = false;
        showPrincipal2PositionOtherFlag = false;
        showAPMerchantFlag = false;
        showSecurePayMerchantFlag = false;   
        showShoppingCartOtherFlag = false;
        showTrusteeFlag = false;     

        app.isExistingAusPostBusinessAccount__c = null;

        // fetch params from Custom Setting
        fetchCustomSettings();        

        // default the selected plan based on custom setting above
        app.SelectedPricePlan__c = configSetting.PlanAPlanNameText__c;
    }

    private void fetchCustomSettings()
    {
        // fetch params from Custom Setting
        configSetting = APMSSetting__c.getInstance();
        apmsOpportunityOwnerId = configSetting.ApmsCoordinator__c; 
        accountRecordTypeId = configSetting.AccountRecordTypeId__c;
        contactRecordTypeId = configSetting.ContactRecordTypeId__c;
        httpsRedirect = configSetting.HttpsRedirection__c;
        revenuepercentage=configSetting.Revenue_Percentage__c/100;  // 03-Sep-15 Eric Shen  pass revenue percentage from custom setting
    }

    public PageReference securePage()
    {
        // this function redirects to https protocol
        sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        integer firstSemiColonPos = sfdcBaseURL.indexOf(':');
        string protocolString = sfdcBaseURL.substring(0,firstSemiColonPos);

        if(protocolString!='https')
        {       
            string secureURL = 'https' + sfdcBaseURL.substring(firstSemiColonPos) + httpsRedirect;
            PageReference securePage = new PageReference(secureURL);
            securePage.setRedirect(true);
            return securePage;  
        }
        else
        {   
            return null;
        }  
    }

    private void setPageHeaders()
    {
        // the following code resolved IE8/9 mis-aligned rendering issue

        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');

        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');

    }

    private List<SelectOption> getPicklistValues(string picklistFieldName, boolean blankEntryRequired, string blankEntryLabel)
    {
        // this function generates picklist values
        Schema.sObjectType sobject_type = application__c.getSObjectType();        
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();       
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        
        List<Schema.PicklistEntry> pick_list_values = field_map.get(picklistFieldName).getDescribe().getPickListValues();        
        List<selectOption> options = new List<selectOption>();
        if(blankEntryRequired == true)
        {
            options.add(new SelectOption('', blankEntryLabel));
        }
        for (Schema.PicklistEntry a : pick_list_values) 
        {
            options.add(new selectOption(a.getLabel(), a.getValue()));
        }
        return options;

    }        

    public List<SelectOption> getOrganisationType()
    {
        return getPicklistValues('OrganisationType__c', true, 'Please select');
    }
    
    public List<SelectOption> getIndustryType()
    {
        return getPicklistValues('IndustryType__c', true, 'Please select');
    }
    
    public List<SelectOption> getContactPositionTitle()
    {
        return getPicklistValues('ContactPositionTitle__c', true, 'Please select');
    }

    public List<SelectOption> getPrincipal1PositionTitle()
    {
        return getPicklistValues('Principal1PositionTitle__c', true, 'Please select');
    }

    public List<SelectOption> getPrincipal2PositionTitle()
    {
        return getPicklistValues('Principal2PositionTitle__c', true, 'Please select');
    }

    public List<SelectOption> getShoppingCart()
    {
        return getPicklistValues('ShoppingCart__c', true, 'Please select');
    }

    public List<SelectOption> getHowDoYouFindUs()
    {
        return getPicklistValues('HowDoYouFindUs__c', true, 'Please select');
    }

    public List<SelectOption> getDateBusinessCommencedMonth()
    {
        return getPicklistValues('DateBusinessCommencedMonth__c', true, 'Month');
    }
    
    public List<SelectOption> getLocationState()
    {
        // This will be used for LocationState__c, PostalState__c, 
        return getPicklistValues('LocationState__c', true, 'State');
    }
      

    public List<SelectOption> getSelectedPricePlan()
    {
        // 2014-08 The plan name should come from custom setting
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption(configSetting.PlanAPlanNameText__c, configSetting.PlanAPlanNameText__c));
        return options;
    }   
    
    public List<SelectOption> getIsGSTRegistered()
    {
        return getPicklistValues('IsGSTRegistered__c', false, null);
    }      
       
    public List<SelectOption> getIsBusinessATrust()
    {
        return getPicklistValues('IsBusinessATrust__c', false, null);
    }      

    public List<SelectOption> getPrincipal1Premises()
    {
        return getPicklistValues('Principal1Premises__c', false, null);
    }      
    
    public List<SelectOption> getPrincipal2Premises()
    {
        return getPicklistValues('Principal2Premises__c', false, null);
    }          

    public List<SelectOption> getIsExistingAPMSMerchantID()
    {
        return getPicklistValues('isExistingAPMSMerchantID__c', false, null);
    }      

    public List<SelectOption> getIsExistingSecurePayMerchantID()
    {
        return getPicklistValues('isExistingSecurePayMerchantID__c', false, null);
    }      

    public List<SelectOption> getIsMerchantFacilityTerminatedPreviously()
    {
        return getPicklistValues('isMerchantFacilityTerminatedPreviously__c', false, null);
    }      

    public List<SelectOption> getIsMerchantFacilityWithAnotherProvider()
    {
        return getPicklistValues('isMerchantFacilityWithAnotherProvider__c', false, null);
    }
          
    public List<SelectOption> getIsMainBusinessOperatedInAustralia()
    {
        return getPicklistValues('isMainBusinessOperatedInAustralia__c', false, null);
    }
    
    public List<SelectOption> getIsMerchantFacilityToBeUsedByOthers()
    {
        return getPicklistValues('isMerchantFacilityToBeUsedByOthers__c', false, null);
    }      

    public List<SelectOption> getIsYourSystemsMonitorCCTransactions()
    {
        return getPicklistValues('isYourSystemsMonitorCCTransactions__c', false, null);
    }      

    public List<SelectOption> getIsProcessPaymentsForAnotherBusiness()
    {
        return getPicklistValues('isProcessPaymentsForAnotherBusiness__c', false, null);
    } 

    public List<SelectOption> getOptforMulticurrency()
    {
        return getPicklistValues('Opt_for_Multicurrency__c', false, null);
    }	

    public void Start_ExistingAccount()
    {
        //Set header for page rendering and security for IE8
        setPageHeaders();    
    
        LandingPageError_NewAcct = '';
        LandingPageError_OldAcct = '';

        // reset all the custom made red border on input fields
        resetErrorStyle();
        
        list<Account> accts;
        
        // check if mandatory fields "Account Number" and "ABN or ACN" contains values
        // Note: this is server side checking, and it would only be applicable if someone manipulated the client side validation
        if(app.APCustomerNumber__c==null || app.APCustomerNumber__c=='')
        {
            LandingPageError_OldAcct = 'Please enter the required information.';
            landingPage_OldAcct_AcctNo_ErrorStyle = STYLE_RED_BORDER;
        }        
        
        if(InputAbnOrAcn==null || InputAbnOrAcn=='')
        {
            LandingPageError_OldAcct = 'Please enter the required information.';
            landingPage_OldAcct_Abn_ErrorStyle = STYLE_RED_BORDER;
        }
        
        if(app.APCustomerNumber__c.length()<2 && LandingPageError_OldAcct=='')
        {
            LandingPageError_OldAcct = 'Account number must have 2 or more characters.';
            landingPage_OldAcct_AcctNo_ErrorStyle = STYLE_RED_BORDER;           
        }
        
        if(app.APCustomerNumber__c.length()>10 && LandingPageError_OldAcct=='')
        {
            LandingPageError_OldAcct = 'Account number must not exceed 10 characters.';
            landingPage_OldAcct_AcctNo_ErrorStyle = STYLE_RED_BORDER;           
        }        

        if(nvl(app.SelectedPricePlan__c,'')=='' && LandingPageError_OldAcct=='')
        {
            LandingPageError_OldAcct = 'Please select a Price plan.';   
        }

        if(LandingPageError_OldAcct=='')
        {
                // search for Account record based on APCustomer__c and InputAbnOrAcn
                list<Billing_Account__c> baccts = [SELECT Id, Organisation__c 
                                                       FROM Billing_Account__c
                                                       WHERE Legacy_Id__c = : app.APCustomerNumber__c
                                                            AND (Organisation__r.ABN__c = : InputAbnOrAcn
                                                            OR Organisation__r.ACN__c = : InputAbnOrAcn)
                                                                       LIMIT 1];

                if(baccts.size()==0)
                {
                    LandingPageError_OldAcct = 'We are unable to find a match in this instance. Please proceed as a new merchant or contact us for further resolution.';   
                    landingPage_OldAcct_AcctNo_ErrorStyle = STYLE_RED_BORDER;
                    landingPage_OldAcct_Abn_ErrorStyle = STYLE_RED_BORDER;              
                }
                else
                {
                    // fetch the account record
                    accts = [SELECT Id, ABN__c, ACN__c, Name, Organisation_Trading_Name__c,
                                         Industry, Website, Email__c,
                                         ShippingStreet, ShippingCity, ShippingState, ShippingPostalcode, ShippingCountry, Shipping_DPID__c, 
                                         BillingStreet, BillingCity, BillingState, BillingPostalcode, BillingCountry, Billing_DPID__c
                            FROM Account
                            WHERE Id = : baccts[0].Organisation__c];
                    // just in case Organisation__c can still be blank to master-detail relationship
                    if(accts.size()!=1)
                    {
                        LandingPageError_OldAcct = 'We are unable to find a match in this instance. Please proceed as a new merchant or contact us for further resolution.';   
                        landingPage_OldAcct_AcctNo_ErrorStyle = STYLE_RED_BORDER;
                        landingPage_OldAcct_Abn_ErrorStyle = STYLE_RED_BORDER;              
                    }                                                         
                }
        }                                       

        if(LandingPageError_OldAcct!='')
        {
            // display the error message
            AddVfMessage(LandingPageError_OldAcct);             
        }
        else
        {
                // fetch the Account and move to next section
            existingAcct = accts[0];
            copyAcctToFetchedApp();
            updateAppWithFetchedApp();
            nextSection();
        }
    }

    public void resetForNewAndOld()
    {
        //reset field values when switching between new and existing customer in landing page
        app.APCustomerNumber__c = '';
        inputAbnOrAcn = '';
        app.PromotionCode__c = '';
        app.OrganisationType__c = '';
        resetErrorStyle();
    }

    private void resetErrorStyle()
    {
        // this function clear out all the custom made red border input field style
        landingPage_OldAcct_Abn_ErrorStyle = '';
        landingPage_OldAcct_AcctNo_ErrorStyle = '';
            dateBusinessCommenced_ErrorStyle = '';
            abn_ErrorStyle = '';
            acn_ErrorStyle = '';

            dob1_ErrorStyle = '';
            dob2_ErrorStyle = '';
            nameOnCCStatement_ErrorStyle = '';
            totalPercentage_ErrorStyle = '';  
            contactPhone_ErrorStyle = '';
            contactMobile_ErrorStyle = '';   
            contactFax_ErrorStyle = ''; 
            principal2Signatory_ErrorStyleClass = ''; 
            principal2Signatory_ErrorStyle = '';
            businessDesc_ErrorStyle = '';
            tc_ErrorStyle = '';
            daysPaidInAdvance_ErrorStyle = '';
            errormsg_ErrorStyle = '';
    }

    private void CopyAcctToFetchedApp()
    {
        // application with fetched account data
        fetchedApp = new Application__c();
        fetchedApp.ABN__c = existingAcct.ABN__c;
        fetchedApp.ACN__c = existingAcct.ACN__c;
        fetchedApp.FullLegalCompanyName__c = existingAcct.Name;
        if(nvl(existingAcct.Organisation_Trading_Name__c,'') != '')
        {
            fetchedApp.IsTradeUnderDifferentName__c = true;
            fetchedApp.RegisteredBusinessTradingAs__c = existingAcct.Organisation_Trading_Name__c;
        }
        // Industry is not required to be fetched
        //fetchedApp.IndustryType__c = existingAcct.Industry;    
        fetchedApp.BusinessWebsite__c = existingAcct.website;
        fetchedApp.BusinessEmailAddress__c = existingAcct.email__c;

        fetchedApp.LocationStreet__c    = existingAcct.ShippingStreet;
        fetchedApp.LocationSuburb__c    = existingAcct.ShippingCity;
        fetchedApp.LocationState__c     = existingAcct.ShippingState;
        fetchedApp.LocationPostcode__c  = existingAcct.ShippingPostalcode;
        fetchedApp.LocationCountry__c   = existingAcct.ShippingCountry;
        fetchedApp.LocationDPID__c      = existingAcct.Shipping_DPID__c;
        fetchedApp.PostalStreet__c      = existingAcct.BillingStreet;
        fetchedApp.PostalSuburb__c      = existingAcct.BillingCity; 
        fetchedApp.PostalState__c       = existingAcct.BillingState;
        fetchedApp.PostalPostcode__c    = existingAcct.BillingPostalcode;
        fetchedApp.PostalCountry__c     = existingAcct.BillingCountry;  
        fetchedApp.PostalDPID__c        = existingAcct.Billing_DPID__c;
        
        string appLocationAddress = getLocationAddress();
        string appPostalAddress = getPostalAddress();
        if((appPostalAddress != '') && (appLocationAddress != appPostalAddress))
        {
            fetchedApp.IsMailingDiffToLocation__c = true;
        }  
    }
    
    public string getLocationAddress()
    {
        // sample address format: Kelco House, Level 5  364 Kent Street, SYDNEY  NSW  2000
        string output = '';
        
        if(fetchedApp == null)
        {
            output = '';
        }        
        else if(nvl(fetchedApp.LocationStreet__c,'')!='')
        {
            output = fetchedApp.LocationStreet__c 
                        + ', ' + fetchedApp.LocationSuburb__c.toUpperCase()
                        + '  ' + fetchedApp.LocationState__c.toUpperCase()
                        + '  ' + fetchedApp.LocationPostcode__c;
            
        }
        return output;
    }
    
    public string getPostalAddress()
    {
        // sample address format: Kelco House, Level 5  364 Kent Street, SYDNEY  NSW  2000
        string output = '';
        
        if(fetchedApp == null)
        {
            output = '';
        }
        else if(nvl(fetchedApp.PostalStreet__c,'')!='')
        {
            output = fetchedApp.PostalStreet__c 
                        + ', ' + fetchedApp.PostalSuburb__c.toUpperCase()
                        + '  ' + fetchedApp.PostalState__c.toUpperCase()
                        + '  ' + fetchedApp.PostalPostcode__c;
            
        }
        return output;
    }    

    public string getROLocationAddress()
    {
        // sample address format: Kelco House, Level 5  364 Kent Street, SYDNEY  NSW  2000
        // this function is used for Section 4 Readonly mode
        string output = '';
        
        if(nvl(app.LocationStreet__c,'')!='')
        {
            output = app.LocationStreet__c 
                        + ', ' + nvl(app.LocationSuburb__c.toUpperCase(),'')
                        + '  ' + nvl(app.LocationState__c.toUpperCase(),'')
                        + '  ' + nvl(app.LocationPostcode__c,'');
            
        }
        return output;
    }

    public string getROPostalAddress()
    {
        // sample address format: Kelco House, Level 5  364 Kent Street, SYDNEY  NSW  2000
        // this function is used for Section Readonly mode
        string output = '';
        
        if(nvl(app.PostalStreet__c,'')!='')
        {
            output = app.PostalStreet__c 
                        + ', ' + nvl(app.PostalSuburb__c.toUpperCase(),'')
                        + '  ' + nvl(app.PostalState__c.toUpperCase(),'')
                        + '  ' + nvl(app.PostalPostcode__c,'');
            
        }
        return output;
    } 
    
    public string getROPrincipal1Address()
    {
        // sample address format: Kelco House, Level 5  364 Kent Street, SYDNEY  NSW  2000
        // this function is used for Section 4 Readonly mode
        string output = '';
        
        if(nvl(app.Principal1Street__c,'')!='')
        {
            output = app.Principal1Street__c 
                        + ', ' + nvl(app.Principal1Suburb__c.toUpperCase(),'')
                        + '  ' + nvl(app.Principal1State__c.toUpperCase(),'')
                        + '  ' + nvl(app.Principal1Postcode__c,'');
            
        }
        return output;
    }
       
    public string getROPrincipal2Address()
    {
        // sample address format: Kelco House, Level 5  364 Kent Street, SYDNEY  NSW  2000
        // this function is used for Section 4 Readonly mode
        string output = '';
        
        if(nvl(app.Principal2Street__c,'')!='')
        {
            output = app.Principal2Street__c 
                        + ', ' + nvl(app.Principal2Suburb__c.toUpperCase(),'')
                        + '  ' + nvl(app.Principal2State__c.toUpperCase(),'')
                        + '  ' + nvl(app.Principal2Postcode__c,'');
            
        }
        return output;
    }
      
    private void initialiseNewApp()
    {
        // reset fetchedApp, so every fields on vf becomes editable again 
        fetchedApp = new Application__c();
    
        // reset app, so it does not carry other data
        string appSelectedPricePlan = app.SelectedPricePlan__c;
        string appExistingBusinessAccount = app.isExistingAusPostBusinessAccount__c;
        string appBusinessType = app.OrganisationType__c;
        string appPromotionCode = app.PromotionCode__c;
        app = new Application__c();
        app.SelectedPricePlan__c = appSelectedPricePlan;
        app.isExistingAusPostBusinessAccount__c = appExistingBusinessAccount;
        app.OrganisationType__c = appBusinessType;
        app.PromotionCode__c = appPromotionCode;            
    }
            
    private void updateAppWithFetchedApp()
    {
        // denormalise the existing app field values as deep clone will overwrite all the values
        string appSelectedPricePlan = app.SelectedPricePlan__c;
        string appExistingBusinessAccount = app.isExistingAusPostBusinessAccount__c;
        string appCreditAccountNo = app.APCustomerNumber__c;
        string appPromotionCode = app.PromotionCode__c;
        
        app = fetchedApp.clone(false,true,false,false);
        app.SelectedPricePlan__c = appSelectedPricePlan;
        app.isExistingAusPostBusinessAccount__c = appExistingBusinessAccount;
        app.APCustomerNumber__c = appCreditAccountNo;
        app.PromotionCode__c = appPromotionCode;    
    }
    
    public void Start_NewAccount()
    {
        //Set header for page rendering and security for IE8
        setPageHeaders();
            
        LandingPageError_NewAcct = '';
        LandingPageError_OldAcct = '';        

        // reset all the custom made red border on input fields
        resetErrorStyle();

        // javascript will take care of mandatory fields of "Business type", 
        //  so there is no need to check them again here.       

        if(nvl(app.selectedPricePlan__c,'') == '')
        {
            LandingPageError_NewAcct = 'Please select a Price plan.';
            AddVfMessage(LandingPageError_NewAcct);         
        }
        else
        {            
            initialiseNewApp();            
            
            nextSection();
        }
    }
    
    private void AddVfMessage(string InfoDetail)
    {
        apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Info,InfoDetail);
        apexpages.addMessage(msg);            
    }    
    
    public void diffToLocationReset()
    {
        if(app.IsMailingDiffToLocation__c == false)
        {
                // if checkox is not ticked, then clear out the pre-entered value
                app.PostalStreet__c = '';
                app.PostalSuburb__c = '';
                app.PostalState__c = '';
                app.PostalPostcode__c = '';
                app.PostalDPID__c = '';
                app.PostalCountry__c = '';
        }
    }
    
    public void nextSection()
    {
        setPageHeaders();
        
        string sectionError = '';
        
        resetErrorStyle();
        
        if(section == 1)
        {
            if(nvl(app.DateBusinessCommencedYear__c,'')!='' && nvl(app.DateBusinessCommencedMonth__c,'')!='')
            {
                // check if DateBusinessCommencedYear is 4 character
                if(app.DateBusinessCommencedYear__c.length()!=4)
                {
                        dateBusinessCommenced_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Please enter a valid value for Date business commenced.';
                 }               

                try
                {
                    // use date.parse to check whether the format for date is correct
                    Date dateBusinessCommenced = date.parse('01/' + app.DateBusinessCommencedMonth__c + '/' + app.DateBusinessCommencedYear__c);

                    // converting 2 strings to date. 
                    // AusPost UI requirement to separate and only capture Month and Year component of Date Business Commenced
                    Integer daysBetween = dateBusinessCommenced.daysBetween(date.today());
                    if(daysBetween < 0)
                    {
                        dateBusinessCommenced_ErrorStyle = STYLE_RED_BORDER;
                        sectionError = 'Date business commenced must be in the past.';
                    }
                }
                catch(Exception ex)
                {
                    dateBusinessCommenced_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Please enter a valid value for Date business commenced.';
                }
            }
            
            if(nvl(app.ACN__c,'')!='' && sectionError=='')
            {
                system.debug('xxx app.ACN__c =' + app.ACN__c);
                // check if ACN is 9 characters
                if(app.ACN__c.length()!=9)
                {
                        acn_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Please enter a valid ACN of 9 digits.';                     
                }
            }               
            
            if(nvl(app.ABN__c,'')!='' && sectionError=='')
            {
                // check if ABN is 11 characters
                if(app.ABN__c.length()!=11)
                {
                        abn_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Please enter a valid ABN of 11 digits.';                     
                    //app.ABN__c.addError('Please enter a valid ABN of 11 digits.');
                }
            }           

            if(nvl(businessDesc,'')!='' && sectionError=='')
            {
                // Workaround for IE8 error when description of business operations is longer than 250 char
                if(businessDesc.length() > 250)
                {
                        businessDesc_ErrorStyle = STYLE_RED_BORDER;
                        sectionError = 'Description of business operations cannot exceed 250 characters.';
                }
                else
                {
                    app.DescriptionOfBusinessOperation__c = businessDesc;
                }
            }    
            
            if(sectionError=='')
            {
                // CR03 if OrgType is Sole Trader, then set IsAuthorisedSignatory to true. 
                //     OrgType can either be defined in landing or section1 
                app.isAuthorisedSignatory__c = false;
                if(app.OrganisationType__c.toLowerCase()=='sole trader')
                {
                   app.isAuthorisedSignatory__c = true; 
                   system.debug('xxx app.isAuthorisedSignatory__c = ' + app.IsAuthorisedSignatory__c);
                }
                else
                {
                    // CR04 Always set isPrincipal1AuthorisedSignatory to true (except when it is sole trader, leave it alone)
                    app.isPrincipal1AuthorisedSignatory__c = true;
                }                   
                
                if(fetchedApp!=null)
                {
                    if(fetchedApp.LocationStreet__c!=null)
                    {
                        // if it is existing account, then address could come from Account
                        app.LocationStreet__c = fetchedApp.LocationStreet__c;
                        app.LocationSuburb__c = fetchedApp.LocationSuburb__c;
                        app.LocationState__c = fetchedApp.LocationState__c;
                        app.LocationPostcode__c = fetchedApp.LocationPostcode__c;            
                        app.LocationDPID__c = fetchedApp.LocationDPID__c;
                        app.LocationCountry__c = fetchedApp.LocationCountry__c;       
                    }
                    else
                    {
                        // fetch data from QAS component
                        app.LocationStreet__c = businessAddress.line1;
                        app.LocationSuburb__c = businessAddress.city;
                        app.LocationState__c = businessAddress.state;
                        app.LocationPostcode__c = businessAddress.postcode;            
                        app.LocationDPID__c = businessAddress.dpid;
                        app.LocationCountry__c = businessAddress.country;       
                    }

                    if(fetchedApp.PostalStreet__c!=null)
                    {
                        // if it is existing account, then address could come from Account
                        app.PostalStreet__c = fetchedApp.PostalStreet__c;
                        app.PostalSuburb__c = fetchedApp.PostalSuburb__c;
                        app.PostalState__c = fetchedApp.PostalState__c;
                        app.PostalPostcode__c = fetchedApp.PostalPostcode__c;
                        app.PostalDPID__c = fetchedApp.PostalDPID__c;
                        app.PostalCountry__c = fetchedApp.PostalCountry__c;
                    }
                    else
                    {
                        // fetch data from QAS component                        
                        app.PostalStreet__c = mailingAddress.line1;
                        app.PostalSuburb__c = mailingAddress.city;
                        app.PostalState__c = mailingAddress.state;
                        app.PostalPostcode__c = mailingAddress.postcode;
                        app.PostalDPID__c = mailingAddress.dpid;                                                
                        app.PostalCountry__c = mailingAddress.country;
                    }
                }
                else 
                {               
                    // fetch all data from QAS component
                    app.LocationStreet__c = businessAddress.line1;
                    app.LocationSuburb__c = businessAddress.city;
                    app.LocationState__c = businessAddress.state;
                    app.LocationPostcode__c = businessAddress.postcode;            
                    app.LocationDPID__c = businessAddress.dpid;
                    app.LocationCountry__c = businessAddress.country;
                            
                    app.PostalStreet__c = mailingAddress.line1;
                    app.PostalSuburb__c = mailingAddress.city;
                    app.PostalState__c = mailingAddress.state;
                    app.PostalPostcode__c = mailingAddress.postcode;
                    app.PostalDPID__c = mailingAddress.dpid;
                    app.PostalCountry__c = mailingAddress.country;
                }
            }
        }
        else if(section == 2) 
        {
            if(nvl(principal1DOB,'')!='')
            {
                // check the length to be 10, otherwise it will also accept dd/mm/yy as well as dd/mm/yyyy
                if(principal1DOB.length()!=10)
                {
                    dob1_ErrorStyle = STYLE_RED_BORDER;
                    sectionError  = 'Please review the format for Date of birth';
                }
                else
                {
                        try                
                        {
                            // converting string to date. 
                            // In visualforce, cannot bind date field as inputField, as current date hyperlink will be shown by default.
                            // AusPost has specific style guideline so this is not allowed.
                            app.Principal1DOB__c = date.parse(principal1DOB);
        
                        }
                        catch(Exception ex)
                        {
                            dob1_ErrorStyle = STYLE_RED_BORDER;
                            sectionError  = 'Please review the format for Date of birth';
                        }
                        
                        if(sectionError=='')
                        {
                            date tday = date.today();
                            date years18Later = app.Principal1DOB__c.addYears(18);
                            integer daysBetween = tday.daysBetween(years18Later);
                            if(daysBetween>0)
                            {
                                dob1_ErrorStyle = STYLE_RED_BORDER;
                                sectionError  = 'Date of birth must be a date at least 18 years in the past.';                              
                            }
                        }
                }
                system.debug('xxx Principal1DOB = ' + Principal1DOB);
                system.debug('xxx app.Principal1DOB__c = ' + app.Principal1DOB__c);                   
            }  

            if(nvl(principal2DOB,'')!='' && sectionError=='')
            {
                // check the length to be 10, otherwise it will also accept dd/mm/yy as well as dd/mm/yyyy
                if(principal2DOB.length()!=10)
                {
                    dob2_ErrorStyle = STYLE_RED_BORDER;
                    sectionError  = 'Please review the format for Date of birth';
                }
                else
                {               
                        try                
                        {
                            // converting string to date. 
                            // In visualforce, cannot bind date field as inputField, as current date hyperlink will be shown by default.
                            // AusPost has specific style guideline so this is not allowed.
                            app.Principal2DOB__c = date.parse(principal2DOB);                    
                        }
                        catch(Exception ex)
                        {
                            dob2_ErrorStyle = STYLE_RED_BORDER;
                            sectionError  = 'Please review the format for Date of birth';
                        }

                        if(sectionError=='')
                        {
                            date tday = date.today();
                            date years18Later = app.Principal2DOB__c.addYears(18);
                            integer daysBetween = tday.daysBetween(years18Later);
                            if(daysBetween>0)
                            {
                                dob2_ErrorStyle = STYLE_RED_BORDER;
                                sectionError  = 'Date of birth must be a date at least 18 years in the past.';                              
                            }
                        }
                }
                system.debug('xxx Principal2DOB = ' + Principal2DOB);
                system.debug('xxx app.Principal2DOB__c = ' + app.Principal2DOB__c);                   
            }  
            
            if(nvl(contactPhone,'')!='' && sectionError=='')
            {
                // APMS CR03 - Validation to restrict to 10 digits (domestic phone numbers only, mobile or landline)
                // ensure this field only contains numbers with no space
                boolean isValid = Pattern.matches('^[0-9]*$', contactPhone);
                
                // ensure this field is 10 digits
                if(contactPhone.length()!=10)
                {
                        isValid = false;
                }
                
                if(isvalid == false)
                {
                    contactPhone_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Phone numbers must have exactly 10 digits with no other characters or spaces.';
                    app.ContactPhone__c = null;
                }
                else
                {
                        // pass the value to app now. VF InputField cannot do max length for Phone field, and only InputText can. 
                        app.ContactPhone__c = contactPhone;
                }
            }

            if(nvl(contactMobile,'')!='' && sectionError=='')
            {
                // APMS CR03 - Validation to restrict to 10 digits (domestic phone numbers only, mobile or landline)
                // ensure this field only contains numbers with no space
                boolean isValid = Pattern.matches('^[0-9]*$', contactMobile);
                
                // ensure this field is 10 digits
                if(contactMobile.length()!=10)
                {
                    isValid = false;
                }
                
                if(isvalid == false)
                {
                    contactMobile_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Phone numbers must have exactly 10 digits with no other characters or spaces.';
                    app.ContactMobile__c = null;
                }
                else
                {
                    // pass the value to app now. VF InputField cannot do max length for Phone field, and only InputText can. 
                    app.ContactMobile__c = contactMobile;
                }

            }

            if(nvl(contactFax,'')!='' && sectionError=='')
            {
                // APMS CR03 - Validation to restrict to 10 digits (domestic phone numbers only, mobile or landline)
                // ensure this field only contains numbers with no space
                boolean isValid = Pattern.matches('^[0-9]*$', contactFax);
                
                // ensure this field is 10 digits
                if(contactFax.length()!=10)
                {
                    isValid = false;
                }
                
                if(isvalid == false)
                {
                    contactFax_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Fax numbers must have exactly 10 digits with no other characters or spaces.';
                    app.ContactFax__c = null;
                }
                else
                {
                    // pass the value to app now. VF InputField cannot do max length for Phone field, and only InputText can. 
                    app.ContactFax__c = contactFax;
                }

            }            
            
            if(app.isPrincipal2AuthorisedSignatory__c==true && nvl(app.ContactSignatoryEmail2__c,'')=='' && sectionError=='')
            {
                // if checkbox is ticked but email is blank, error out
                principal2Signatory_ErrorStyleClass = EMAIL_STYLECLASS;
                principal2Signatory_ErrorStyle = STYLE_RED_BORDER;
                sectionError = 'Please enter the Email address.';
            }    

            if(sectionError=='')
            {
                // CR03 clear out email field if checkbox not ticked  
                if(app.isPrincipal2AuthorisedSignatory__c==false)
                {
                   app.ContactSignatoryEmail2__c = null;
                }
                

                if(app.OrganisationType__c.toLowerCase()!='sole trader')
                {
                    // CR03 if not sole trader, copy ContactEmail to Signatory3, if checkbox is ticked
                    if(app.IsAuthorisedSignatory__c==true)
                    {
                           app.ContactSignatoryEmail3__c = app.ContactEmail__c;
                    } 
                }
                else
                {
                    // CR03 if sole trader, copy Contact info to Principal1. Note app.IsAuthorisedSignatory__c is always ticked.
                    app.Principal1FirstName__c = app.ContactFirstName__c;
                    app.Principal1LastName__c = app.ContactLastName__c;
                    app.Principal1PositionTitle__c = app.ContactPositionTitle__c;
                    app.Principal1PositionTitleOther__c = app.ContactPositionTitleOther__c;
                    app.ContactSignatoryEmail1__c = app.ContactEmail__c;
                }
                
                // fetch data from QAS component
                app.Principal1Street__c = principal1Address.line1;
                app.Principal1Suburb__c = principal1Address.city;
                app.Principal1State__c = principal1Address.state;
                app.Principal1Postcode__c = principal1Address.postcode;
                app.Principal1DPID__c = principal1Address.dpid;
                app.Principal1Country__c = principal1Address.country;
        
                app.Principal2Street__c = principal2Address.line1;
                app.Principal2Suburb__c = principal2Address.city;
                app.Principal2State__c = principal2Address.state;
                app.Principal2Postcode__c = principal2Address.postcode;
                app.Principal2DPID__c = principal2Address.dpid;
                app.Principal2Country__c = principal2Address.country;
            }                       
        }
        else if(section == 3)
        {
            if(nvl(app.isExistingSecurePayMerchantID__c,'')!='')
            {
               if(compareStringLowerCase(app.isExistingSecurePayMerchantID__c,'yes') && nvl(app.isExistingAPMSMerchantId__c,'')=='')
               {
                   // somehow javascript will clear out error message every time it is re-rendered, so this is a workaround
                   errormsg_ErrorStyle = ERROR_LINE;
                   sectionError = 'Please enter the required information.';
               }
            }
            
            if(nvl(app.NameOnCCStatement__c,'')!='' && sectionError=='')
            {
                // ensure this field only contains alphabetic and apostrophe
                // 2014-07 CR04 - allows for alphanumeric, apostrophe, slash, bracket and hypen
                boolean isValid = Pattern.matches('^[a-zA-Z0-9 \' / ( ) -]*$', app.NameOnCCStatement__c);
                
                if(isvalid == false)
                {
                        nameOnCCStatement_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Please review the format for "Business name to appear on your customers credit card statement"';
                }
            }
            

            if(app.CCChargedInAdvancePercentage__c!=null && sectionError=='')
            {
                if(app.CCChargedInAdvancePercentage__c>0 && app.CCChargedInAdvanceDaysInAdvance__c==null)
                {
                    // if "Payment received in advance" is 0% then "Enter days paid in advance" is not mandatory    
                    daysPaidInAdvance_ErrorStyle = STYLE_RED_BORDER;
                    sectionError = 'Please enter the required information.';
                }
            } 
            
            system.debug('xxx app.CCSameDayProcessingPercentage__c = ' + app.CCSameDayProcessingPercentage__c);
            system.debug('xxx app.CCChargedInAdvancePercentage__c = ' + app.CCChargedInAdvancePercentage__c);
            system.debug('xxx app.CCChargedInArrearsPercentage__c = ' + app.CCChargedInArrearsPercentage__c);
            
            decimal totalPercentage = app.CCSameDayProcessingPercentage__c + app.CCChargedInAdvancePercentage__c + app.CCChargedInArrearsPercentage__c;
            system.debug('xxx totalPercentage = ' + totalPercentage);
            if(totalPercentage != 100 && sectionError=='')
            {
                totalPercentage_ErrorStyle = STYLE_RED_BORDER;
                sectionError = 'The receiving credit card payments must equal 100%';
            }
            
            if(sectionError=='')
            {
                if(compareStringLowerCase(app.isExistingSecurePayMerchantID__c,'no'))
                {
                    // if the previous question is No, then set it to No
                    app.isExistingAPMSMerchantId__c = 'No';
                    app.SecurePayMerchantID__c = '';
                }
            }
			
			if(sectionError=='')
            {
                if(compareStringLowerCase(app.Opt_for_Multicurrency__c,'no'))
                {
                    // if the previous question is No, then set it to No
                    app.Avg_Foreign_Currency_Transaction_Value__c = null;
                    app.Avg_Foreign_Currency_Transactions_Mthly__c = null;
                    app.Annual_Foreign_Currency_Turnover__c = null;
                }
            }
        }         
            
        if(nvl(sectionError,'')!='')
        {
            AddVfMessage(sectionError);
        }
        else
        {
            if(isDevMode)
            {
                if(section==1)
                {
                    // jump from Section 1 to section 4 to save time from data entry
                    section=4;
                }
                else
                {
                    section++;
                }
            }
            else
            {
                section++;
            }
        }
    }

    public void prevSection()
    {
        //Set header for page rendering and security for IE8
        setPageHeaders();
            
        section--;
    }

    public boolean getHasNextButton()
    {
        boolean output = true;
        if(section == 4 || section == 5)
        {
            output = false;
        }
        return output;
    }

    public boolean getHasPrevButton()
    {
        // business details page will not have previous button anymore.
        boolean output = true;
        if(section == 1 || section == 5)
        {
            output = false;
        }
        return output;
    }

    public boolean getHasSubmitButton()
    {
        boolean output = false;
        if(section == 4)
        {
            output = true;
        }
        return output;
    }

    private string nvl(string initialString, string blankString)
    {
        string output = '';
        if(initialString == null || initialString == '')
        {
            output = blankString;
        }
        else
        {
            output = initialString;
        }
        return output;
    }

    public void ShowHideContactPositionOther()
    {
        system.debug('xxx before showContactPositionOtherFlag = ' + showContactPositionOtherFlag);
        showContactPositionOtherFlag = false;
        app.ContactPositionTitleOther__c = null;        
        if(compareStringLowerCase(app.ContactPositionTitle__c,'other'))
        {
            showContactPositionOtherFlag = true;
        }
        system.debug('xxx after showContactPositionOtherFlag = ' + showContactPositionOtherFlag);
    }
    
    public void ShowHidePrincipal1PositionOther()
    {
        showPrincipal1PositionOtherFlag = false;
        app.Principal1PositionTitleOther__c = null;        
        if(compareStringLowerCase(app.Principal1PositionTitle__c,'other'))
        {
            showPrincipal1PositionOtherFlag = true;
        }
    }

    public void ShowHidePrincipal2PositionOther()
    {
        showPrincipal2PositionOtherFlag = false;
        app.Principal2PositionTitleOther__c = null;     
        if(compareStringLowerCase(app.Principal2PositionTitle__c,'other'))
        {
            showPrincipal2PositionOtherFlag = true;
        }
    }  

    public void showHideSecurePayMerchant()
    {
        showSecurePayMerchantFlag = false;
        app.SecurePayMerchantID__c = null;
        if(compareStringLowerCase(app.isExistingSecurePayMerchantID__c,'yes'))        
        {
            showSecurePayMerchantFlag = true;
        }
    }
	
	public void showHideMulticurrencyFields()
    {
        showMulticurrencyFlag = false;
        app.Avg_Foreign_Currency_Transaction_Value__c = null;
        app.Avg_Foreign_Currency_Transactions_Mthly__c =null;
        app.Annual_Foreign_Currency_Turnover__c = null;
        
        if(compareStringLowerCase(app.Opt_for_Multicurrency__c,'yes'))        
        {
            showMulticurrencyFlag = true;
        }
    }

    public void ShowHideShoppingCartOther()
    {
        showShoppingCartOtherFlag = false;
        app.ShoppingCartOther__c = null;
        if(compareStringLowerCase(app.ShoppingCart__c,'other'))
        {
            showShoppingCartOtherFlag = true;
        }
    }

    public void showHideTrustee()
    {
        showTrusteeFlag = false;
        app.Trustee1__c = null;        
        if(compareStringLowerCase(app.OrganisationType__c,'trading trust'))
        {
            showTrusteeFlag = true;
        }
    }
        
    public boolean compareStringLowerCase(string sourceString, string targetString)
    {
        // this function compare strings in lower case
        boolean output = false;
        if(nvl(sourceString,'')!='' && sourceString.toLowerCase()==targetString)
        {
                output = true;
        }
        return output;
    }
    
    public PageReference saveApp()
    {
        // User can submit then click browser reload button to re-submit the applicaiton form.
        // Workaround is to reset all the variables by navigating to the same page and run through constructor again

        //Set header for page rendering and security for IE8
        setPageHeaders();

        // move the client side check to server side for the terms and condition checkbox
        resetErrorStyle();
        if(!app.isConsentReadAndAccept__c)
        {
            tc_ErrorStyle = ERROR_LINE;
            string sectionError = 'Please enter the required information.';

            AddVfMessage(sectionError);
            return null;
        }

        // create all the records on submit
        boolean isDmlError = createAppRecords();

        if(isDmlError == false)
        {
            String URL = ApexPages.CurrentPage().GetURL();
            if(URL.contains('?'))
            {
                URL = URL.substring(0,URL.indexOf('?'));
            }
            PageReference currentPage = new PageReference(URL);
            currentPage.getParameters().put('Id',app.Id);
            currentPage.getParameters().put('appEmail',app.ContactEmail__c);
            currentPage.setRedirect(true);            
            return currentPage;
        }
        else
        {
            return null;
        }
        
    }      

        
    private boolean createAppRecords()
    {
        // Submit button is clicked
        // - link/create Account to Application
        // - create Contact and link to Account
        // - create Opportunity and link to Application
        // - create Opportunity Product and link to Opportunity
        // - link Pricing Plan to Application
        SavePoint sp = Database.setSavepoint();
                
        boolean isDmlError = false;
        boolean isNewAccount = false;

        // Account could be existing or new
        Account acct;
        // Create new contact
        Contact cont = new Contact();
        // Create new opportunity
        Opportunity oppty = new Opportunity();
        // Create new Opportunity Product
        OpportunityLineItem oppProduct = new OpportunityLineItem();
        
        PricebookEntry pbe;
        
        if(existingAcct == null)
        {
            isNewAccount = true;
            // if not exist, then create a prospect account
            acct = new Account();            
            acct.Name = app.FullLegalCompanyName__c;
            acct.Organisation_Trading_Name__c = app.RegisteredBusinessTradingAs__c;
            acct.ABN__c = app.ABN__c;
            acct.ACN__c = app.ACN__c;
            acct.Type = 'Small Business';
            //acct.Email__c = app.BusinessEmailAddress__c;          // CR04-additional change - not to populate to Account record, as Org Email cannot be allowed to be a personal email address.
            acct.Website = app.BusinessWebsite__c;
            acct.ShippingStreet = app.LocationStreet__c;
            acct.ShippingCity = app.LocationSuburb__c;
            acct.ShippingState = app.LocationState__c;
            acct.ShippingPostalCode = app.LocationPostcode__c;            
            acct.Shipping_DPID__c = app.LocationDPID__c;            // Application Location has DPID. Postal has no DPID as QAS does not handle PO Box.
            acct.ShippingCountry = app.LocationCountry__c;

            if(app.IsMailingDiffToLocation__c)
            {
                // if different address is ticked, then set Acct Billing address with the mailing address
                acct.BillingStreet = app.PostalStreet__c;
                acct.BillingCity = app.PostalSuburb__c;
                acct.BillingState = app.PostalState__c;
                acct.BillingPostalCode = app.PostalPostcode__c;
                acct.Billing_DPID__c = app.PostalDPID__c;               // QAS is now implemented for Postal address as it handles PO Box now.
                acct.BillingCountry = app.PostalCountry__c;
            }
            else
            {
                // otherwise, Acct Billing address is Registered Office Address
                acct.BillingStreet = app.LocationStreet__c;
                acct.BillingCity = app.LocationSuburb__c;
                acct.BillingState = app.LocationState__c;
                acct.BillingPostalCode = app.LocationPostcode__c;            
                acct.Billing_DPID__c = app.LocationDPID__c; 
                acct.BillingCountry = app.LocationCountry__c;
            }

            if(accountRecordTypeId!=null)
            {
                // if there is value from Custom setting, then assign the new account to that record type
                acct.RecordTypeId = accountRecordTypeId;
            }

            try
            {
                insert acct;
            }
            catch(Exception ex)
            {
                isDmlError = true;
                ApexPages.addMessages(ex);
                system.debug('xxx Exception caught - insert acct'); 
                Database.rollback(sp);          
            }
        } 
        else
        {
            acct = existingAcct;
        }      

        if(isDmlError == false)
        {
            // use the first contact in Business contact detail section on the application form to create Contact record 
            cont.AccountId = acct.Id;

            cont.FirstName = app.ContactFirstName__c;
            cont.LastName = app.ContactLastName__c;

            // there is requirement to map JobTitle and TitleGroup based on application position
            map<string, string> jobTitleMap = new map<string, string>();
            jobTitleMap.put('Director', 'Director');
            jobTitleMap.put('Manager', 'Manager');
            jobTitleMap.put('Office Manager', 'Admin/Office Manager');
            jobTitleMap.put('Owner', 'Proprietor/Owner');
            jobTitleMap.put('Secretary', 'Admin/Office Staff');
            jobTitleMap.put('Financial Controller', 'Finance Manager');
            jobTitleMap.put('Other', 'Other');

            string jobTitle = app.ContactPositionTitle__c; 
            if(compareStringLowerCase(app.ContactPositionTitle__c,'other'))
            {
                jobTitle = app.ContactPositionTitleOther__c;                
            }
            cont.Title = jobTitle;
            if(jobTitleMap.ContainsKey(app.ContactPositionTitle__c))
            { 
                cont.Function_Group__c = jobTitleMap.get(app.ContactPositionTitle__c);
            }            

            cont.MobilePhone = app.ContactMobile__c;
            cont.Phone = app.ContactPhone__c;
            cont.Fax = app.ContactFax__c;
            cont.Email = app.ContactEmail__c;

            // Contact Physical address is Registered Office Address
            cont.OtherStreet = app.LocationStreet__c;
            cont.OtherCity = app.LocationSuburb__c;
            cont.OtherState = app.LocationState__c;
            cont.OtherPostalCode = app.LocationPostcode__c;            
            cont.Other_DPID__c = app.LocationDPID__c; 
            cont.OtherCountry = app.LocationCountry__c;
            
            if(app.IsMailingDiffToLocation__c)
            {
                // if different address is ticked, then set Contact Billing address with the mailing address
                cont.MailingStreet = app.PostalStreet__c;
                cont.MailingCity = app.PostalSuburb__c;
                cont.MailingState = app.PostalState__c;
                cont.MailingPostalCode = app.PostalPostcode__c;
                cont.Mailing_DPID__c = app.PostalDPID__c;
                cont.MailingCountry = app.PostalCountry__c;
            }
            else
            {
                // otherwise, Contact Billing address is Registered Office Address
                cont.MailingStreet = app.LocationStreet__c;
                cont.MailingCity = app.LocationSuburb__c;
                cont.MailingState = app.LocationState__c;
                cont.MailingPostalCode = app.LocationPostcode__c;            
                cont.Mailing_DPID__c = app.LocationDPID__c; 
                cont.MailingCountry = app.LocationCountry__c;
            }

            if(app.IsLikeToReceiveAPInfo__c)
            {
                // if promotions and offers flag is checked, then the following must be set
                cont.Privacy_Marketing_Opt_Out__c = 'NO';
            }
            else
            {
                // if promotions and offers flag is not checked, then the following must be set
                cont.Privacy_Marketing_Opt_Out__c = 'YES';
            }

            if(contactRecordTypeId!=null)
            {
                // if there is value from Custom setting, then assign the new contact to that record type
                cont.RecordTypeId = contactRecordTypeId;
            }

            if(apmsOpportunityOwnerId!=null)
            {
                cont.OwnerId = apmsOpportunityOwnerId;
            }

            try
            {
                insert cont;
            }
            catch(Exception ex)
            {
                isDmlError = true;
                ApexPages.addMessages(ex);
                system.debug('xxx Exception caught - insert cont');  
                Database.rollback(sp);
            }
        }

        if(isDmlError == false)
        {
                try
                {
                    app.Account__c = acct.Id;
                    insert app;
                }
                catch(Exception ex)
                {
                    isDmlError = true;
                    ApexPages.addMessages(ex);
                    system.debug('xxx Exception caught - insert app');  
                    Database.rollback(sp);
                }
        }
        
        if(isDmlError == false)
        {
            oppty.ApplicationId__c = app.Id;
            oppty.AccountId = acct.Id;
            oppty.StageName = 'Qualify';
          //  oppty.CloseDate = system.today();  28-08-15 Eric Shen  Make the close date 30 days later than created date requested by Jason Gould
        
          oppty.CloseDate = system.today().addMonths(1);  //28-08-15 Eric Shen  adjust close date to a month later requested by Jason Gould
          
            if(isNewAccount == true)
            {
                oppty.Type = 'New Customer';
            }
            else
            {
                oppty.Type = 'Existing Customer';   
            }
            oppty.Name = acct.Name + ' - APMS';
            oppty.Offering_Type__c = 'Product';
            oppty.IsAPMSApplication__c = true;

            try
            {
                insert oppty;
            }
            catch(Exception ex)
            {
                isDmlError = true;
                ApexPages.addMessages(ex);              
                system.debug('xxx Exception caught - insert oppty');
                Database.rollback(sp);  
            }
        }

        if(isDmlError == false)
        {
            // need to use different transactioin to update Opp.OwnerId, as there is a Opportunity after insert trigger that updates initial OwnerId. 
            if(apmsOpportunityOwnerId!=null)
            {
                // 2014-07-24 CR04 - Opportunity owner will be a dedicated user defined in Custom Setting
                oppty.OwnerId = apmsOpportunityOwnerId;

                try
                {
                    update oppty;
                }
                catch(Exception ex)
                {
                    isDmlError = true;
                    ApexPages.addMessages(ex);              
                    system.debug('xxx Exception caught - update oppty');
                    Database.rollback(sp);  
                }
            }
        }

        if(isDmlError == false)
        {
            // if all the data are setup correctly, there should be no error
            // Note: app.SelectedPricePlan__c is a picklist (application form can only accept 3 hard coded price plan)
            //          app.PricePlan__c is a lookup
            //          Due to difference in field length, only first 10 character of picklist value is used to fetch the lookup value.
            // 2014-07 CR04 - Submitted application will be link to 'PlanA' Pricing Plan by default.

            try
            {
                PricingPlan__c pricingPlan = [SELECT Id, Product__c FROM PricingPlan__c 
                                                WHERE PricingPlan__c = : configSetting.LinkedPlanName__c];
                system.debug('xxx pricingPlan.Id = ' + pricingPlan.Id);
                
                //fetch the PricebookEntryId with the given Product to associate with
                pbe = [SELECT Id, UnitPrice FROM PricebookEntry 
                                        WHERE Product2Id = : pricingPlan.Product__c LIMIT 1];
                system.debug('xxx pbe.Id = ' + pbe.Id);
                
                app.PricingPlan__c = pricingPlan.Id;
                system.debug('xxx here app.PricingPlan__c = ' + app.PricingPlan__c);
            }
            catch(Exception ex)
            {
                isDMLError = true;
                ApexPages.addMessages(ex);              
                system.debug('xxx Exception caught - manipulate admin data');   
                Database.rollback(sp);              
            }           
        }

        if(isDmlError == false)
        {
            app.Opportunity__c = oppty.Id;
            try
            {
                update app;             
            }
            catch(Exception ex)
            {
                isDmlError = true;
                ApexPages.addMessages(ex);              
                system.debug('xxx Exception caught - update app');  
                Database.rollback(sp);
            }
        }       
                
        if(isDmlError == false)
        {       
           	system.debug('***** SETTING CLASSIFICATION INSIDE APMSAPPLICATION ');
            if(isNewAccount == true)
            {
                oppProduct.Classification__c = 'New Business - One Off';
            }
            else
            {
                oppProduct.Classification__c = 'Growth';
            }
            oppProduct.Quantity = 1;
            oppProduct.Contract_Product__c = 'Yes';
            oppProduct.OpportunityId = oppty.Id;
            oppProduct.PricebookEntryId = pbe.Id;
            //added by Kalpita for revenue start and end date
            oppProduct.Contract_Start_Date__c = oppty.CloseDate;
            oppProduct.Contract_End_Date__c = oppty.CloseDate + 365;
           // oppProduct.UnitPrice = pbe.UnitPrice;  03-Sep-15 Eric Shen   Reclaculate unit price to reflect Application project revenue
           
           oppProduct.UnitPrice = revenuepercentage* app.TotalAnnualTurnoverProjected__c; //03-Sep-15 Eric Shen   Reclaculate unit price to reflect Application project revenue

            try
            {
                insert oppProduct;  
            }
            catch(Exception ex)
            {
                isDmlError = true;
                ApexPages.addMessages(ex);
                system.debug('xxx Exception caught - insert oppProduct');   
                Database.rollback(sp);          
            }

        }

        return isDmlError;

    } 
    
    public void SaveAppFeedback()
    {
        // Due to UI requirement, feedback will only be entered after the application form is submitted
        // save it individually.
        try
        {
            update app;
        }
        catch(Exception ex)
        {
            // do nothing, as there is no way for the end user to fix it..
        }
    }
    
}