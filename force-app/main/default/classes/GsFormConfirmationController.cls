public with sharing class GsFormConfirmationController {

    // The lead related to the form
    private Lead lead;
    // The campaign member referenced in the URL (cross checked to the same lead)    
    private CampaignMember campaignMember;
    
    private GsApplicationFormData applicationData;
    private map<String, GsUseCase> useCases = GsUseCaseSetup.useCases;
    private GsUseCase currentUseCase = new GsUseCase();
    
    public GsFormConfirmationController() {
//ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.INFO, 'In GsFormConfirmationController' ));
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
        
        String publicId = ApexPages.currentPage().getParameters().get('pid');
        if (String.isEmpty(publicId)){
            // Pre-condition for showing the form pre-filled is the lead and campaign member Id are provided and they match
            lead = new Lead();
        }
        else{
            try {
                // Read all the fields needed in the form and in this class ((Lead)stdController.getRecord() does not get fields like isConverted)
                campaignMember = [SELECT Id, LeadId, Status from CampaignMember where Public_Id__c = :publicId];
                lead = [SELECT Id, Send_Business_Credit_Account_Info__c, Existing_Business_Credit_Account__c,  OwnerId, ABN__c, IsConverted, Name, LastName, Company, Trading_Name__c, Email, Lead_Number__c, Website, JSONApplicationFormData__c, Date_Submitted__c, Application_Form__c FROM Lead WHERE Id = :campaignMember.LeadId];
                             
                } 
                catch ( Exception e ) { 
                    ApexPages.addMessages(e);
                    //TODO: various test caes to define and validate inappropriate access to data is not possible
                    // Note currently if Url has ID which cannot be found this code is not hit and the user ends up at a non authorised page
                    lead = new Lead(); 
                    campaignMember = new CampaignMember();
                }
            }
        
        
                if(lead.JSONApplicationFormData__c != null && lead.JSONApplicationFormData__c.length() > 0)
                {
                    applicationData = (GsApplicationFormData) System.JSON.deserialize(lead.JSONApplicationFormData__c, GsApplicationFormData.class);
                }
                else
                {
                   applicationData = new GsApplicationFormData();
                }
        
                String caseNumber =    currentUseCase.caseSelection(lead.Existing_Business_Credit_Account__c,
                                                            lead.Send_Business_Credit_Account_Info__c,
                                                            applicationData.creditLimit5000,
                                                            applicationData.parcelsPerYear,
                                                            applicationData.eParcelApplication,
                                                            applicationData.termsCreditAccount,
                                                            applicationData.termsParcelService,
                                                            applicationData.generalTAndC);

        	currentUseCase = useCases.get(caseNumber);
        
    }

    // Action called when page is opened to verify URL has not been hacked to access information inappropriately
    public PageReference doCustomLeadCheck(){
         PageReference pageRef = null;
        //String leadNumberUrl = ApexPages.currentPage().getParameters().get('ln');       
        if ( campaignMember == null || campaignMember.Id == null ) {
            // Url contains invalid campaign member reference so redirect
            pageRef = new PageReference('/apex/GsForm_BadLead?Reason=BadCampaignMember');
            pageRef.setRedirect(false);
        }
        else if(lead == null || lead.Id == null){
            //There is No Lead
            pageRef = new PageReference('/apex/GsForm_BadLead?Reason=NoLead');
            pageRef.setRedirect(false);
        }
        else if ( lead.isConverted == true ) {
            // Lead has already been converted so redirect
            pageRef = new PageReference('/apex/GsForm_BadLead?Reason=ConvertedLead');
            pageRef.setRedirect(false);
        }
        else {
            // Update campaign member status to reflect the form has been visited (will overwrite any existing status)
            if(currentUseCase.cmsvAfterProceedAccept != null
            	&& currentUseCase.cmsvAfterProceedAccept != '')
            {
            	campaignMember.Status = currentUseCase.cmsvAfterProceedAccept;
            }
            else
            {
            	campaignMember.Status = 'Application Form Confirmed';
            }
            //remove the public id for security reasons
            
            /* Uncomment below for added security */
            //campaignMember.Public_Id__c = null;
            update campaignMember;
            }
        
        return pageRef;
   }
}