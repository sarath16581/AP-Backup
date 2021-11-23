public class GsFormUnsubscribeController {

    // Email fields needed to control sending email to the priority database team in a test site or not
    list<string> priorityDatabaseTeam = new list<string>();
    private String emailTemplateDeveloperName = 'Priority_Database_Update_Required_due_to_Unsubscribe';
    SystemSettings__c SystemSettings = SystemSettings__c.getOrgDefaults();
    private boolean isTestMode = SystemSettings.GSForm_useTestEmails__c;
    private String testEmail = SystemSettings.GSForm_testEmailAddresses__c;

    // The lead related to the form
    private Lead lead;
    // The campaign member referenced in the URL (cross checked to the same lead)    
    private CampaignMember campaignMember;
    
    public GsFormUnsubscribeController() {
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

        /*  Public Id Code */
        String publicId = ApexPages.currentPage().getParameters().get('pid');
        if (String.isEmpty(publicId)){
            // Lead must be identified to be updated for unsubscribe
            lead = new Lead();
            campaignMember = new CampaignMember();
            ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, 'The unsubscribe URL is missing a required parameter' ));
        }
        else {
            try {
                // Read all the fields needed in the form and in this class ((Lead)stdController.getRecord() does not get fields like isConverted)
                campaignMember = [SELECT Id, LeadId, Status from CampaignMember where Public_Id__c = :publicId];
                lead = [SELECT Id, OwnerId, ABN__c, IsConverted, Name, LastName, Company, Trading_Name__c, Email, Lead_Number__c, Website, Date_Submitted__c, Application_Form__c FROM Lead WHERE Id = :campaignMember.LeadId];
            } 
            catch ( Exception e ) { 
                ApexPages.addMessages(e);
                ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, 'The unsubscribe URL is missing a valid parameter' ));
                lead = new Lead(); 
                campaignMember = new CampaignMember();
            }
        }
        
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
            // Add activity to record the lead has unsubscribed
            Task t = new Task( ActivityDate=datetime.now().date(),Subject='Lead unsubscribed and requested email opt-out', Type='Other', Description='This Lead just visited validated their email address and confirmed they wish to proceed with the credit and eParcel application form', Status='Completed', WhoId=lead.Id );
            insert t;
                
            // Update campaign member status to reflect the form has been visited (will overwrite any existing status)
            campaignMember.Status = 'Not Interested – Unsubscribed';
            update campaignMember;

            // Flag lead as having opted out which can if required drive internal workflow
            lead.Legal_Marketing_Opt_In__c = false;
            update lead;       
            ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.INFO, 'You have successfully unsubscribed.' ));

            // Send email to priority database team (or test team in sandbox)
			list<String> toCCAddress = null;
            if(isTestMode){
				toCCAddress = new list<String>();
				System.debug(testEmail);
                priorityDatabaseTeam.addAll(testEmail.split(';'));
				toCCAddress.add('Prioritydatabase@auspost.com.au.greenshoots');
            } else {
                priorityDatabaseTeam.add('Prioritydatabase@auspost.com.au');
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
            try {
                mail.setUseSignature(false);
                mail.setToAddresses(priorityDatabaseTeam);
                mail.setTargetObjectId(lead.Id);
                mail.setInReplyTo( 'noreply@auspost.com.au' );
				
			    if(toCCAddress!=null)
			    	mail.setCcAddresses(toCCAddress);
			    
				
                Id templateId = [select id from EmailTemplate where DeveloperName = :emailTemplateDeveloperName limit 1].Id;
                mail.setTemplateID(templateId);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            catch(exception e) {
                ApexPages.addMessages(e);
                system.debug('There was a problem sending the call to email to the priority database team: '+ e);
            }   
        }
        
        return pageRef;
   }
}