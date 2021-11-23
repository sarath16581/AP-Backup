public class GsPdfFormController {

    // The lead being maintained in the form
    private Lead lead;
    // The campaign member referenced in the URL (cross checked to the same lead)    
   // private CampaignMember campaignMember;
    
    private GsApplicationFormData applicationData; //Json data

    public  GsApplicationFormData getAppData()
    {
        return applicationData = applicationData==null ? new GsApplicationFormData():applicationData;
    }
    
    public GsPdfFormController() {
        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" /> 
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');
        
        // If an existing Lead so verify if ID is provided the lead record can be read, is not converted and has a matching Lead Number
        String leadIdUrl = ApexPages.currentPage().getParameters().get('id');
     //   String campaignMemberIdUrl = ApexPages.currentPage().getParameters().get('cm');
       
            try {
                 system.debug('----leadId1--- ' + leadIdUrl);               

                // Read all the fields needed in the form and in this class ((Lead)stdController.getRecord() does not get fields like isConverted)
                lead = [SELECT Id, ABN__c, IsConverted, Street, Name, City, State, PostalCode, LastName, Company, NumberOfEmployees, Trading_Name__c, Phone, Fax, MobilePhone, 
                                  Existing_Business_Credit_Account__c, Send_Business_Credit_Account_Info__c, Account_No__c, Email, Lead_Number__c, Website, JSONApplicationFormData__c,
                                  FirstName, Legal_Marketing_Opt_In__c 
                                FROM Lead 
                                WHERE Id = :leadIdUrl];
                     
                   system.debug('----leadId2--- ' + lead + ' === ' + leadIdUrl);
       
                if(lead.JSONApplicationFormData__c.length() > 0)
                {
                    applicationData = (GsApplicationFormData) System.JSON.deserialize(lead.JSONApplicationFormData__c, GsApplicationFormData.class);
               system.debug('----leadId3--- ' + lead + ' === ' + leadIdUrl);
                }
                else
                {
                    applicationData = new GsApplicationFormData();
                system.debug('----leadId4--- ' + lead + ' === ' + leadIdUrl);
                }
            } 
            catch ( Exception e ) { 
                ApexPages.addMessages(e);
                system.debug('----leadId5--- ' + e.getMessage());
                system.debug('----leadId6--- ' + lead + ' === ' + leadIdUrl);
            }
    }
       
    // Accessors - avoiding exposing the Lead to prevent issues with access using guest license
    //    Public Lead getLead() { return lead; }
    public String LeadFirstName {
        get { return lead.FirstName; }
    }    
    public String LeadLastName {
        get { return lead.LastName; }
    }
    public String LeadCompany {
        get { return lead.Company; }
    }
    public String LeadTradingName {
        get { return lead.Trading_Name__c; }
    }
    public String LeadABN {
        get { return lead.ABN__c; }
    }
    public String LeadWebsite {
        get { return lead.Website; }
    }
    public String LeadEmail{
        get { return lead.Email; }
    }
    //Lead street accessors split in to 2 fields and combined to sit in the multi line text box.
    public String LeadStreet{
        get { 
            if(lead.Street != null && lead.Street.indexOf('\n') != -1){
                //is on 2 or more lines
                return lead.Street.substring(0, lead.Street.indexOf('\n'));          
            }
            else{
              return lead.Street;   
            }
          }
    }
    public String LeadStreet2{
        get { 
        
        if(lead.Street != null && lead.Street.indexOf('\n') != -1){
            //is on 2 lines
            return lead.Street.substring(lead.Street.indexOf('\n'), Lead.Street.length());     
        }
        else{
            return '';
        }
        }
    }
    public String LeadCity{
        get { return lead.City; }
    }
    public String LeadState{
        get { return lead.State; }
    }
    public String LeadPostalCode{
        get { return lead.PostalCode; }
    }
    public String LeadNumberOfEmployees{
        get { return lead.NumberOfEmployees.Format(); }
    }
    public String LeadPhone{
        get { return lead.Phone; }
    }
    public String LeadFax{
        get { return lead.Fax; }
    }
    public String LeadMobilePhone{
        get { return lead.MobilePhone; }
    }
    public String existingCreditAccount{
        get { return lead.Existing_Business_Credit_Account__c ; }
    }
    public String applyForCreditAccount{
        get { return lead.Send_Business_Credit_Account_Info__c; }
    }    
    public String accountNumber{
        get { return lead.Account_No__c; }
    }

    //Transport Fields TBD
    public String TrusteeName{
        get { return lead.JSONApplicationFormData__c; }
    }
 
    // Temporary simulators for true/false checkboxes
    public Boolean checkBoxTrue {
        get { return true; }
    }
    
    
    public string legalMarketingOptIn{
        get
        {
                if(lead.Legal_Marketing_Opt_In__c)
                {
                   return 'True'; 
                }
                else
                {
                   return 'False'; 
                }
        }
    }
    
    /*public String legalMarketingOptIn{
        get
        {
            if(lead.Legal_Marketing_Opt_In__c)
            {
                return 'I agree';
            }
            else
            {
                return 'I do not agree';
            }
        }
        set
        {
            if(value == 'I agree')
            {
                lead.Legal_Marketing_Opt_In__c = true;
            }
            else if(value == 'I do not agree')
            {
               lead.Legal_Marketing_Opt_In__c = false; 
            }
        }
    }*/
    
    // variables used in PDF
    public string soleTraderCheckboxPdf{get{return String.valueOf(getAppData().soleTraderCheckbox).capitalize();}}
    public string companyCheckboxPdf{get{return String.valueOf(getAppData().companyCheckbox).capitalize();} }
    public string tradingTrustCheckboxPdf{get{return String.valueOf(getAppData().tradingTrustCheckbox).capitalize();} }
    public string partnershipCheckboxPdf{get{return String.valueOf(getAppData().partnershipCheckbox).capitalize();} }
    public string govAuthCheckboxPdf{get{return String.valueOf(getAppData().govAuthCheckbox).capitalize();} }
    public string localGovCheckboxPdf{get{return String.valueOf(getAppData().soleTraderCheckbox).capitalize();} }
    public string intCusCheckboxPdf{get{return String.valueOf(getAppData().intCusCheckbox).capitalize();} }
    
    //eParcel Application
    public string parcelPickUpPdf{get{return String.valueOf(getAppData().parcelPickUp).capitalize();} }
    public string parelDropOffPdf{get{return String.valueOf(getAppData().parelDropOff).capitalize();} }
    
    //Pickup Dropoff Times
    public string mondayPickupPdf{get{return String.valueOf(getAppData().mondayPickup).capitalize();} }
    public string tuesdayPickupPdf{get{return String.valueOf(getAppData().tuesdayPickup).capitalize();} }
    public string wednesdayPickupPdf{get{return String.valueOf(getAppData().wednesdayPickup).capitalize();} }
    public string thursdayPickupPdf{get{return String.valueOf(getAppData().thursdayPickup).capitalize();} }
    public string fridayPickupPdf{get{return String.valueOf(getAppData().fridayPickup).capitalize();} }
    
    //Transport & Volume Details
    public string pickupVolumePdf{get{return String.valueOf(getAppData().pickupVolume).capitalize();} }
    public string pickupTransportVanPdf{get{return String.valueOf(getAppData().pickupTransportVan).capitalize();} }
    public string pickupTransportTruckPdf{get{return String.valueOf(getAppData().pickupTransportTruck).capitalize();} }
    public string pickupPresentationMethodBagPdf{get{return String.valueOf(getAppData().pickupPresentationMethodBag).capitalize();} }
    public string pickupPresentationMethodLoosePdf{get{return String.valueOf(getAppData().pickupPresentationMethodLoose).capitalize();} }
    public string pickupPresentationMethodULDPdf{get{return String.valueOf(getAppData().pickupPresentationMethodULD).capitalize();} }
    public string pickupDestinationMetroPdf{get{return String.valueOf(getAppData().pickupDestinationMetro).capitalize();} }
    public string pickupDestinationStatePdf{get{return String.valueOf(getAppData().pickupDestinationState).capitalize();} }
    public string pickupDestinationInterstatePdf{get{return String.valueOf(getAppData().pickupDestinationInterstate).capitalize();} }
    public string pickupDestinationInternationalPdf{get{return String.valueOf(getAppData().pickupDestinationInternational).capitalize();} }
    
    // Computer Hardware and Software
    public string osWinXpPdf{get{return String.valueOf(getAppData().osWinXp).capitalize();}}
    public string osWin7Pdf{get{return String.valueOf(getAppData().osWin7).capitalize();}}
    public string osMaxOsPdf{get{return String.valueOf(getAppData().osMaxOs).capitalize();}}
    
    public string browserIE7AbovePdf{get{return String.valueOf(getAppData().browserIE7Above).capitalize();}}
    public string browserFFPdf{get{return String.valueOf(getAppData().browserFF).capitalize();}}
    public string browserSafariPdf{get{return String.valueOf(getAppData().browserSafari).capitalize();}}
    public string browserChromePdf{get{return String.valueOf(getAppData().browserChrome).capitalize();}}
    
    //string Values for Terms Acceptance / Marketing
    public string termsCreditAccountPdf{get{return String.valueOf(getAppData().termsCreditAccount).capitalize();} }
    public string termsParcelServicePdf{get{return String.valueOf(getAppData().termsParcelService).capitalize();} }
    //the var below should map to Legal_Marketing_Opt_In__c on the lead, but can't access the controller atm (CW Aprika)
    public string marketingOptInPdf{get{return String.valueOf(getAppData().marketingOptIn).capitalize();} }
    
        //Credit account details
    public string austPostCreditAccountCustomerPdf{get{return String.valueOf(getAppData().austPostCreditAccountCustomer).capitalize();}}
    public string creditAccountNumberPdf{get{return String.valueOf(getAppData().creditAccountNumber).capitalize();}}
    public string applyForCreditAcctPdf{get{return String.valueOf(getAppData().applyForCreditAcct).capitalize();}}
}