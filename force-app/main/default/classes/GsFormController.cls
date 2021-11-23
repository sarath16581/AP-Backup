public class GsFormController {


        //campaign Name For Blank Form Leads
        private final String  campaignNameForBlankFormLeads = 'Green Shoots Blank Form Leads';

        //Campaign Member Statuses
        private final String campaignStatusApplicationFormVisited = 'Application Form Visited';
        private final String campaignStatusApplicationFormSubmitted = 'Application Form Submitted';
        private final String campaignStatusApplicationFormConfirmed = 'Application Form Confirmed';
        //private final String campaignStatusNotInterestedNoCredit = 'Not Interested – No Credit';


    //SystemSettings For Testing Mode
    SystemSettings__c SystemSettings = SystemSettings__c.getOrgDefaults();
    private boolean isTestMode = SystemSettings.GSForm_useTestEmails__c;
    private String testEmail = SystemSettings.GSForm_testEmailAddresses__c;

    list<string> toAddressInternalSalesReferral = new list<string>();


    // The lead being maintained in the form
    private Lead lead;
    // The campaign member referenced in the URL (cross checked to the same lead)
    private CampaignMember campaignMember;
    public String publicId{get{return publicId = publicId==null?'':publicId;}set;}
    public String campaignMemberId{get{return campaignMemberId = campaignMemberId==null?'':campaignMemberId;}set;}

    //Json data
    private GsApplicationFormData applicationData;
    public  GsApplicationFormData getAppData()
    {
        return applicationData = applicationData==null ? new GsApplicationFormData():applicationData;
    }


    private map<String, GsUseCase> useCases = GsUseCaseSetup.useCases;
    private map<String, String> emailsTemplateNameByOfferEmailText = GsUseCaseSetup.emailsTemplateNameByOfferEmailText;
    private GsUseCase currentUseCase = new GsUseCase();

    public GsFormController() {

        //Set header for page rendering and security
        setPageHeaders();

        /*  Chris's Public Id Code, replacing the campaign/lead id version  */
        publicId = ApexPages.currentPage().getParameters().get('pid');
        //also see if there is a campaign member id, this will be used for internal members to access the form
        campaignMemberId = ApexPages.currentPage().getParameters().get('cid');

        initLeadAndCampaignMember(publicId, campaignMemberId);

        // reset t&c to '-select-' option everytime user open the form
        getAppData().termsCreditAccount = '';
        getAppData().termsParcelService = '';
        getAppData().generalTAndC = '';
        getAppData().termsInternationalParcels = '';

        //TODO:change the email to right email
        toAddressInternalSalesReferral.add('salesReferral@auspost.com.au');

    }


    // Accessors - avoiding exposing the Lead to prevent issues with access using guest license
    //    Public Lead getLead() { return lead; }
    public String LeadFirstName {
        get { return lead.FirstName; }
        set { lead.FirstName = value; }
    }
    public String LeadLastName {
        get { return lead.LastName; }
        set { lead.LastName = value; }
    }
    public String LeadCompany {
        get { return lead.Company; }
        set { lead.Company = value; }
    }
    public String LeadTradingName {
        get { return lead.Trading_Name__c; }
        set { lead.Trading_Name__c = value; }
    }
    public String LeadABN {
        get { return lead.ABN__c; }
        set { lead.ABN__c = value; }
    }
    public String LeadWebsite {
        get { return lead.Website; }
        set { lead.Website = value; }
    }
    public String LeadEmail{
        get { return lead.Email; }
        set { lead.Email = value; }
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
        set { lead.Street = value; }
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
        set {
            if(value != null && value.trim() != ''){
                lead.Street = LeadStreet +'\n'+value;
            }
            else{
                lead.Street = LeadStreet;
            }
        }
    }
    public String LeadCity{
        get { return lead.City; }
        set { lead.City = value; }
    }
    public String LeadState{
        get { return lead.State; }
        set { lead.State = value; }
    }
    public String LeadPostalCode{
        get { return lead.PostalCode; }
        set { lead.PostalCode = value; }
    }
    public String LeadNumberOfEmployees{
        get { return lead.NumberOfEmployees.Format(); }
        set { lead.NumberOfEmployees = integer.valueOf(value); }
    }
    public String LeadPhone{
        get { return lead.Phone; }
        set { lead.Phone = value; }
    }
    public String LeadFax{
        get { return lead.Fax; }
        set { lead.Fax = value; }
    }
    public String LeadMobilePhone{
        get { return lead.MobilePhone; }
        set { lead.MobilePhone = value; }
    }
    public String existingCreditAccount{
        get { return lead.Existing_Business_Credit_Account__c ; }
        set { lead.Existing_Business_Credit_Account__c = value; }
    }
    public String applyForCreditAccount{
        get { return lead.Send_Business_Credit_Account_Info__c; }
        set { lead.Send_Business_Credit_Account_Info__c = value;}
    }
    public String accountNumber{
        get { return lead.Account_No__c; }
        set { lead.Account_No__c = value; }
    }
    public Boolean legalMarketingOptIn{
        get{return lead.Legal_Marketing_Opt_In__c; }
        set{ lead.Legal_Marketing_Opt_In__c = value; }
    }




        private void setPageHeaders()
        {
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


        private void initLeadAndCampaignMember(String inPublicId, String inCampaignMemberId)
        {

        system.debug('### initLeadAndCampaignMember ###');
        if (!String.isEmpty(inPublicId)){
        //attempt to access the form using a public id
            try {
                // Read all the fields needed in the form and in this class ((Lead)stdController.getRecord() does not get fields like isConverted)
                campaignMember = [SELECT Id, LeadId, Status from CampaignMember where Public_Id__c = :inPublicId];
                lead = [SELECT Id, OwnerId, ABN__c, IsConverted, Name, LastName, FirstName, Company, Trading_Name__c, Email, Lead_Number__c, Website, JSONApplicationFormData__c, Street, City, State, PostalCode, NumberOfEmployees, Phone, Fax, MobilePhone, Existing_Business_Credit_Account__c, Send_Business_Credit_Account_Info__c, Account_No__c, Date_Submitted__c, LeadSource, Application_Form__c, Legal_Marketing_Opt_In__c FROM Lead WHERE Id = :campaignMember.LeadId];

                    //TODO: Error handling required
                    if(lead.JSONApplicationFormData__c != null && lead.JSONApplicationFormData__c.length() > 0)
                    {
                        applicationData = (GsApplicationFormData) System.JSON.deserialize(lead.JSONApplicationFormData__c, GsApplicationFormData.class);
                    }
                    else
                    {
                        applicationData = new GsApplicationFormData();
                    }

                }
                catch ( Exception e ) {
                    ApexPages.addMessages(e);
                    //TODO: various test caes to define and validate inappropriate access to data is not possible
                    // Note currently if Url has ID which cannot be found this code is not hit and the user ends up at a non authorised page
                    //lead = new Lead();
                    //campaignMember = new CampaignMember();
                }
            }
            else if(userInfo.getUserType() == 'Standard' && !String.isEmpty(inCampaignMemberId)){
                //only allow the user to access the form using a campaign member id if they are an internal SFDC user
                //attempt to access the form using a public id
                try {
                    // Read all the fields needed in the form and in this class ((Lead)stdController.getRecord() does not get fields like isConverted)
                    campaignMember = [SELECT Id, LeadId, Status from CampaignMember where Id = :inCampaignMemberId];
                    lead = [SELECT Id, OwnerId, ABN__c, IsConverted, Name, LastName, FirstName, Company, Trading_Name__c, Email, Lead_Number__c, Website, JSONApplicationFormData__c, Street, City, State, PostalCode, NumberOfEmployees, Phone, Fax, MobilePhone, Existing_Business_Credit_Account__c, Send_Business_Credit_Account_Info__c, Account_No__c, Date_Submitted__c, LeadSource, Application_Form__c, Legal_Marketing_Opt_In__c FROM Lead WHERE Id = :campaignMember.LeadId];

                    //TODO: Error handling required
                    if(lead.JSONApplicationFormData__c != null && lead.JSONApplicationFormData__c.length() > 0)
                    {
                        applicationData = (GsApplicationFormData) System.JSON.deserialize(lead.JSONApplicationFormData__c, GsApplicationFormData.class);
                    }
                    else
                    {
                        applicationData = new GsApplicationFormData();
                    }


                }
                catch ( Exception e ) {
                    ApexPages.addMessages(e);
                    //TODO: various test caes to define and validate inappropriate access to data is not possible
                    // Note currently if Url has ID which cannot be found this code is not hit and the user ends up at a non authorised page
                }
            }
            else{
                //blank form logic in here, we need to create a new lead and assign them to a placeholder campaign
                //TODO: Work Out What Happens when a blank form is accessed?
                system.debug('### Blank Form ###');
                lead = new Lead();
                campaignMember = new CampaignMember();
                applicationData = new GsApplicationFormData();
            }
        }


    // Action called when page is opened to verify URL has not been hacked to access information inappropriately
    public PageReference doCustomLeadCheck()
    {


        PageReference pageRef = null;

        if ( campaignMember == null) {
            // Url contains invalid campaign member reference so redirect
            pageRef = Page.GsForm_BadLead;      //new PageReference('/apex/GsForm_BadLead?Reason=BadCampaignMember');
                        pageRef.getParameters().put('Reason','BadCampaignMember');
            pageRef.setRedirect(false);
        }
        else if(lead == null){
            //There is No Lead
            pageRef =  Page.GsForm_BadLead;     //new PageReference('/apex/GsForm_BadLead?Reason=NoLead');
                        pageRef.getParameters().put('Reason','NoLead');
            pageRef.setRedirect(false);
        }
        else if ( lead.isConverted == true ) {
            // Lead has already been converted so redirect
            pageRef = Page.GsForm_BadLead;      //new PageReference('/apex/GsForm_BadLead?Reason=ConvertedLead');
                        pageRef.getParameters().put('Reason','ConvertedLead');
            pageRef.setRedirect(false);
        }
        else if(campaignMember.Id != null && lead.Id != null){
            // Update campaign member status to reflect the form has been visited (will overwrite any existing status)
            //only do this if there is a campaign member id and lead id
            campaignMember.Status = campaignStatusApplicationFormVisited;
            update campaignMember;

        }
        /* Blocks blank form access
        else
        {
             pageRef = Page.GsForm_BadLead;      //new PageReference('/apex/GsForm_BadLead?Reason=ConvertedLead');
            pageRef.getParameters().put('Reason','BlankForm');
            pageRef.setRedirect(false);
        }
        */
        
        return pageRef;
        }

    //Serialize JSON to the lead field and Select the correct use case
    private void setJSONandUserCasesOnSave()
    {
        //serialize the fields in JSON format
        lead.JSONApplicationFormData__c = JSON.serialize(applicationData);

        if(getAppData().creditAccountNumber!=null)
        {
            lead.Account_No__c = getAppData().creditAccountNumber;
        }

        String caseNumber =    currentUseCase.caseSelection(existingCreditAccount,
                                                            applyForCreditAccount,
                                                            getAppData().creditLimit5000,
                                                            getAppData().parcelsPerYear,
                                                            getAppData().eParcelApplication,
                                                            getAppData().termsCreditAccount,
                                                            getAppData().termsParcelService,
                                                            getAppData().generalTAndC);

        currentUseCase = useCases.get(caseNumber);
    }

        //setnew Campaign Member For Lead - returns false if fails insert
        private boolean setNewCampaignMemberForLead()
        {
            //there is no public id, so generate one
            if(campaignMember.Id == null){
                //make sure the campaign member is correctly configured first
                campaign holdingCampaign; //used to store any Green Shoots leads that haven't come from an email invitation
                try{
                    holdingCampaign = [select id from Campaign where isActive = true and Name = :campaignNameForBlankFormLeads];
                }
                catch(exception e){
                    //couldn't find the campaign, so insert one here.
                    holdingCampaign = new Campaign(Name = campaignNameForBlankFormLeads, isActive = true);
                    insert holdingCampaign;
                    //loop through the Campaign Member Status's and ammend the values
                    CampaignMemberStatus[] memberStatuses = new CampaignMemberStatus[]{};

                    try{
                        memberStatuses = [select id, hasResponded, Label from CampaignMemberStatus where CampaignId = :holdingCampaign.Id and isDefault = false];
                    }
                    catch(exception f){
                        //couldn't find any values, so don't do anything
                        system.debug('No Campaign Memember Status Values Found: '+ f);
                    }

                    delete memberStatuses;
                    //now we have a clear list, rebuild with the values we want.
                    memberStatuses = new CampaignMemberStatus[]{};
                    memberStatuses.add(new campaignMemberStatus(Label = campaignStatusApplicationFormVisited, hasResponded = true, CampaignID = holdingCampaign.Id, sortOrder = 2, isDefault = True));
                    //memberStatuses.add(new campaignMemberStatus(Label = campaignStatusApplicationFormSubmitted, hasResponded = true, CampaignID = holdingCampaign.Id, sortOrder = 3, isDefault = False));
                    //memberStatuses.add(new campaignMemberStatus(Label = campaignStatusApplicationFormConfirmed, hasResponded = true, CampaignID = holdingCampaign.Id, sortOrder = 4, isDefault = False));

                    set<string> memberStatusesFromGsUseCaseSetup = new set<String>();
                    for(GsUseCase uc : GsUseCaseSetup.useCases.values())
                    {
                        if (( uc.cmsvAfterSubmission != null ) && ( uc.cmsvAfterSubmission  != '' ))
                            memberStatusesFromGsUseCaseSetup.add(uc.cmsvAfterSubmission);
                        if (( uc.cmsvAfterProceedAccept != null ) && ( uc.cmsvAfterProceedAccept != '' ))
                            memberStatusesFromGsUseCaseSetup.add(uc.cmsvAfterProceedAccept);
                    }

                    integer i = memberStatuses.size()+1;
                    for(String s : memberStatusesFromGsUseCaseSetup)
                    {
                        i++;
                        memberStatuses.add(new campaignMemberStatus(Label = s, hasResponded = true, CampaignID = holdingCampaign.Id, sortOrder = i, isDefault = false));
                    }

                    insert memberStatuses;

                }
                //at this point we have a lead, a campaign and a no inserted campaign member
                
                
                try{
                    String  queueId =   [Select Q.QueueId, Q.Queue.DeveloperName, Q.Id from QueueSobject Q  where Q.Queue.DeveloperName = 'Managed_Campaigns' and Q.SobjectType='Lead' limit 1].QueueId;
                    System.debug('### queueId:' + queueId);
                    if(queueId!=null && queueId!='')
                        lead.ownerid = queueId;
                    upsert lead;
                }
                catch(exception e){
                    System.debug('### Could not Set lead owner:' + e.getMessage());
                    ApexPages.addMessages(e);
                                        return false;
                }               
                
                campaignMember.LeadId = lead.Id;
                campaignMember.CampaignId = holdingCampaign.Id;
                campaignMember.Status = campaignStatusApplicationFormSubmitted;
                

                try{    
                System.debug('### campaignMember.LeadId' + campaignMember.LeadId);
                System.debug('### campaignMember' + campaignMember);
                    
                    insert campaignMember;
                }
                catch(exception e){
                    ApexPages.addMessages(e);
                                        return false;
                }
            }
            //at this point we should now have a campaign member id, so generate a public id and update the lead/campaign member
            publicId = generatePublicID();
            campaignMember.Public_Id__c = publicId;
            lead.Public_Id__c = publicId;

            try{
                update campaignMember;
                update lead;
                                return true;
            }
            catch(exception e){
                ApexPages.addMessages(e);
                                return false;
            }
        }


   public PageReference submitButton() {

        //setNewCampaignMemberForLead()

        if(publicId==null || publicId =='')
        {           
    
            System.debug('### campaignMember.LeadId' + campaignMember.LeadId);
            System.debug('### campaignMember' + campaignMember);
            if(campaignMember.LeadId == null)
            {
                setNewCampaignMemberForLead();
            }
                else
            {
                publicId = generatePublicID();
                campaignMember.Public_Id__c = publicId;         
                upsert campaignMember;
            }
            
            

        }
        
        lead.Public_Id__c = publicId;
        //Update some lead fields

        // clean up / reset / zero unnecessary data prior to submission
        resetValueBeforeSubmission();

        setJSONandUserCasesOnSave();



        // Richard 19/02 removed as I have seen no requirement to block lead update depending on lead source if(lead.LeadSource == null) lead.LeadSource = 'Green Shoots';
        // Save the lead changes
        try {
            upsert(lead);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }

            // Add activity to record submit
            Task t = new Task( ActivityDate=datetime.now().date(),Subject='Lead submitted the credit and eParce application form', Type='Other', Description='Lead submitted the credit and eParce application form', Status='Completed', WhoId=lead.Id );
            insert t;

        // Having saved the form data into the Lead and into the PDF, navigate to confirmation page
        PageReference pageRef = page.BusinessCustomerApplicationSubmitted;      //new PageReference('/apex/BusinessCustomerApplicationSubmitted');
        pageRef.getParameters().put('value', currentUseCase.thankYouPageMessage);
        pageRef.getParameters().put('pid', publicId);
        System.debug('### pageRef.getParameters():' + pageRef.getParameters());
        
        pageRef.setRedirect(false);
        return pageRef;
    }


    //Save Action
    public string saveMessage{get; set;}
    public string saveColour{get; set;}
    public pageReference saveButton()
    {
        // reset / zero / clean up date prior to saving
        // this function has to be called before setJSONandUserCasesOnSave()
        resetValueBeforeSubmission();

        setJSONandUserCasesOnSave();

        try{
            upsert lead;
            saveMessage = 'Thank you, form saved.';
            saveColour = 'green;';
        }
        catch(exception e){
             saveMessage = 'There was a problem saving your form, please try again.';
             saveColour = 'red;';

             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));

             system.debug('===exception== ' + e.getMessage());
        }
        return null;
    }


    // Cancel action
    public PageReference cancel() {
        //  After Cancel log status change and navigate to confirmation page
        currentUseCase = useCases.get('10');
        campaignMember.Status = currentUseCase.cmsvAfterSubmission;
        update campaignMember;

        pageReference cancelPage = page.BusinessCustomerApplicationSubmitted;
        cancelPage.getParameters().put('value', currentUseCase.thankYouPageMessage);
        return cancelPage;
    }


    //Method to Generate Public Id, Consider Putting in Utility Class if Time.
    public string generatePublicId(){
        Datetime now = System.now();
        String formattednow = now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGMT('HH:mm:ss') + '.' + now.formatGMT('SSS') + 'Z';
        String canonical = campaignMember.Id + formattednow;
        canonical += campaignMember.LeadId;
        Blob bsig = Crypto.generateDigest('MD5',Blob.valueOf(canonical));
        String token = EncodingUtil.base64Encode(bsig);
        if(token.length()>255) {token = token.substring(0,254);}
        return EncodingUtil.urlEncode(token,'UTF-8').replaceAll('%','_');

    }


    // reset dynamic picklist
    public PageReference resetPicklist()
    {
        System.debug('====existingCreditAccount=== ' + existingCreditAccount);
        system.debug('==applicationData.creditAccountNumber 1== ' + getAppData().creditAccountNumber);
        if(existingCreditAccount == 'No')
        {
            getAppData().creditAccountNumber = '';
        }
        else if(existingCreditAccount == 'Yes')
        {
            applyForCreditAccount = '';
            getAppData().creditLimit5000 = '';
        }
        else
        {
            getAppData().creditAccountNumber = '';
            applyForCreditAccount = '';
            getAppData().creditLimit5000 = '';
        }

        if(existingCreditAccount == 'No' && applyForCreditAccount == 'No')
        {
            getAppData().creditLimit5000 = '';
            getAppData().eParcelApplication = '';

            if(getAppData().parcelsPerYear == '500 - 999' || getAppData().parcelsPerYear == '1000 - 4999' || getAppData().parcelsPerYear == '5000 - 9999')
            {
                getAppData().parcelsPerYear = '';
            }
        }

        if(existingCreditAccount == 'No' && applyForCreditAccount == 'Yes' && getAppData().creditLimit5000 == 'Yes')
        {
            getAppData().parcelsPerYear = '';
            getAppData().eParcelApplication = '';
        }

        if(getAppData().parcelsPerYear != '500 - 999' || getAppData().parcelsPerYear != '1000 - 4999' || getAppData().parcelsPerYear != '5000 - 9999')
        {
            getAppData().eParcelApplication = '';
        }

       system.debug('==applicationData.creditAccountNumber 2== ' + getAppData().creditAccountNumber);

        // due to use case conflicts, this is quick solution to clean up eparcel application when it is over 500 parcels per year
        if(getAppData().parcelsPerYear == '1000 - 4999' || getAppData().parcelsPerYear == '5000 - 9999')
        {
                getAppData().eParcelApplication = '';
                this.cleanUpEparcelApp();
        }

        return null;
    }

    // this function does clean up prior to form submission
    private void resetValueBeforeSubmission()
    {

        if(getAppData().businessType!='Trading-trust')
        {
            getAppData().nameOfTrust = '';
            getAppData().nameOfTrustee = '';
            getAppData().abnAcnTrust = '';
        }


        if(this.existingCreditAccount == 'Yes' )
        {
            this.applyForCreditAccount = '';
            this.applicationData.creditLimit5000 = '';
            this.cleanUpCreditAcctApp();

                if(this.applicationData.parcelsPerYear == '500 - 999'
                  || this.applicationData.parcelsPerYear == '1000 - 4999'
                  || this.applicationData.parcelsPerYear == '5000 - 9999')
                {
                if(this.applicationData.eParcelApplication == 'No')
                    {
                            this.cleanUpEparcelApp();
                    }
                }
                else
                {
                    this.applicationData.eParcelApplication = '';
                    this.cleanUpEparcelApp();
                }
        }

        if(this.existingCreditAccount == 'No')
        {
            if(this.applyForCreditAccount == 'No')
            {
                this.applicationData.creditLimit5000 = '';
                this.applicationData.parcelsPerYear = '';
                this.applicationData.eParcelApplication = '';
                this.cleanUpCreditAcctApp();
                this.cleanUpEparcelApp();
            }
            else if(this.applyForCreditAccount == 'Yes')
            {
                if(this.applicationData.creditLimit5000 == 'Yes')
                {
                    this.applicationData.parcelsPerYear = '';
                    this.applicationData.eParcelApplication = '';
                    this.cleanUpCreditAcctApp();
                    this.cleanUpEparcelApp();
                }
                else if(this.applicationData.creditLimit5000 == 'No')
                {
                    if(this.applicationData.parcelsPerYear == 'Less than 500')
                    {
                        this.applicationData.eParcelApplication = '';
                        this.cleanUpEparcelApp();
                    }

                    else if(this.applicationData.parcelsPerYear == '500 - 999'
                      || this.applicationData.parcelsPerYear == '1000 - 4999'
                      || this.applicationData.parcelsPerYear == '5000 - 9999')
                    {
                        if(this.applicationData.eParcelApplication == 'No')
                        {
                            this.cleanUpEparcelApp();
                        }
                    }
                }
            }
        }

        if(!(this.applicationData.eParcelApplication == 'Yes'))
        {
            this.applicationData.termsParcelService = '';
        }

        if(!(this.existingCreditAccount == 'No' && this.applyForCreditAccount == 'Yes' && this.applicationData.creditLimit5000 == 'No'))
        {
            this.applicationData.termsCreditAccount = '';
        }

		// 2013-07-16 Louis Wang (Bluewolf) - Add ECI fields - Added cleanup logic to ensure only correct data are saved.
		if(this.applicationData.parcelsPerYear == '')
		{
			this.applicationData.eciApplication = '';
			this.applicationData.sendParcelsOverseas = '';
			this.applicationData.whichECI = '';
		}

        if(!(this.applicationData.eciApplication == 'Yes'))
        {
            this.applicationData.termsInternationalParcels = '';
        }
    }
    
    public void copyBusinessContactDetailToCreditAccount()
    {
        applicationData.namePD1 = LeadFirstName + ' ' + LeadLastName;
        applicationData.address1PD1 = leadStreet;
        applicationData.address2PD1 = leadStreet2;
        applicationData.cityPD1 = leadCity;
        applicationData.statePD1 = leadState;
        applicationData.postcodePD1 = leadPostalcode;
        
    }
    

    // this function cleans up all fields in credit account application
    private void cleanUpCreditAcctApp()
    {
        this.applicationData.creditAmountRequired= '';
        this.applicationData.companyorBusinessName= '';
        this.applicationData.contactName1= '';
        this.applicationData.contactPositionTitle1= '';
        this.applicationData.phone1= '';
        this.applicationData.email1= '';
        this.applicationData.companyOrBusinessName2= '';
        this.applicationData.contactName2= '';
        this.applicationData.contactPositionTitle2= '';
        this.applicationData.phone2= '';
        this.applicationData.email2= '';
        this.applicationData.companyOrBusinessName3= '';
        this.applicationData.contactName3= '';
        this.applicationData.contactPositionTitle3= '';
        this.applicationData.phone3= '';
        this.applicationData.email3= '';
        this.applicationData.titlePD1= '';
        this.applicationData.namePD1= '';
        this.applicationData.address1PD1= '';
        this.applicationData.address2PD1= '';
        this.applicationData.cityPD1= '';
        this.applicationData.statePD1= '';
        this.applicationData.postcodePD1= '';
        this.applicationData.premisesPD1= '';
        this.applicationData.driversLicensePD1= '';
        this.applicationData.birthDatePD1= '';
        this.applicationData.nameOfSpousePD1= '';
        this.applicationData.titlePD2= '';
        this.applicationData.namePD2= '';
        this.applicationData.address1PD2= '';
        this.applicationData.address2PD2= '';
        this.applicationData.cityPD2= '';
        this.applicationData.statePD2= '';
        this.applicationData.postcodePD2= '';
        this.applicationData.premisesPD2= '';
        this.applicationData.driversLicensePD2= '';
        this.applicationData.birthDatePD2= '';
        this.applicationData.nameOfSpousePD2= '';
        this.applicationData.termsCreditAccount = 'I do not agree';
    }

    // this function cleans up all fields in eparcel application
    private void cleanUpEparcelApp()
    {
       this.applicationData.parcelPickUp = false;
       this.applicationData.parelDropOff = false;

       this.applicationData.principalLC = '';
       this.applicationData.alternativeLC1 = '';
       this.applicationData.alternativeLC2 = '';
       this.applicationData.alternativeLC3 = '';

       this.applicationData.address1PA = '';
       this.applicationData.address2PA = '';
       this.applicationData.cityPA = '';
       this.applicationData.statePA = '';
       this.applicationData.postcodePA = '';

       this.applicationData.mondayPickup = false;
       this.applicationData.tuesdayPickup = false;
       this.applicationData.wednesdayPickup = false;
       this.applicationData.thursdayPickup = false;
       this.applicationData.fridayPickup = false;
       this.applicationData.requestedPickupTime = '';

       this.applicationData.pickupVolume = '';
       this.applicationData.pickupTransportVan = false;
       this.applicationData.pickupTransportTruck = false;
       this.applicationData.pickupPresentationMethodBag = false;
       this.applicationData.pickupPresentationMethodLoose = false;
       this.applicationData.pickupPresentationMethodULD = false;
       this.applicationData.pickupDestinationMetro = false;
       this.applicationData.pickupDestinationState = false;
       this.applicationData.pickupDestinationInterstate = false;
       this.applicationData.pickupDestinationInternational = false;

       this.applicationData.osWinXp = false;
       this.applicationData.osWin7 = false;
       this.applicationData.osMaxOs = false;
       this.applicationData.osOther = '';
       this.applicationData.javaRuntimeV6Above = '';
       this.applicationData.AdobeReaderV8above = '';
       this.applicationData.browserIE7Above = false;
       this.applicationData.browserFF = false;
       this.applicationData.browserSafari = false;
       this.applicationData.browserChrome = false;
       this.applicationData.printerMakeModel  = '';

       this.applicationData.freeOfObstacles = '';
       this.applicationData.designatedLoadingParkingArea = '';
       this.applicationData.noReversing = '';
       this.applicationData.enoughRoom = '';
       this.applicationData.controlledAccess = '';
       this.applicationData.noSlopes = '';

       this.applicationData.noSlipTripFallHazards = '';
       this.applicationData.adequateLighting = '';

       this.applicationData.noAbove16kgs = '';
       this.applicationData.stableBalancedParcel = '';
       this.applicationData.noStairNeeded = '';
       this.applicationData.noMoreThan10meters = '';
       this.applicationData.noShoulderHeight = '';
       this.applicationData.noLift = '';
       this.applicationData.noHazardousOrSharp = '';
       this.applicationData.staffOnSite = '';

       this.applicationData.noMovingVehicles = '';
       this.applicationData.noLoadShiftingEquipment = '';
       this.applicationData.hasFloorTrafficManagementPlan = '';

       this.applicationData.comment  = '';
       this.applicationData.termsParcelService = 'I do not agree';
    }
}