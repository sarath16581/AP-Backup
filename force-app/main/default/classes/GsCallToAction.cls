public with sharing class GsCallToAction {

    //Email addresses
    private map<String,String> eParcelInstallationTeamEmails = new map<String,String>();
    private map<String,String> contractManagementTeamEmails = new map<String,String>();
    private String creditManagementTeamEmail = 'DLHQCreditMgmtCreditAssessment@auspost.com.au';
    private String customerDataTeam = 'dlhqcdmcreditupdates@auspost.com.au';
    private String eParcelcustomercreation = 'eParcelcustomercreation@auspost.com.au';
    private String dlhqcdmcreditupdates ='dlhqcdmcreditupdates@auspost.com.au';

    //SystemSettings For Testing Mode 
    SystemSettings__c SystemSettings = SystemSettings__c.getOrgDefaults();
    private boolean isTestMode = SystemSettings.GSForm_useTestEmails__c;
    private String testEmail = SystemSettings.GSForm_testEmailAddresses__c;

    private String ep; //eparcel Application
    private String cr; //credit Application
    private String st; //state
    private Attachment pdfAttachment; //attachemnt Id
    private Lead lead;
    private Map<String, EmailTemplate> emailTemplateIdByDeveloperNameMap;

 
    private map<String, GsUseCase> useCases = GsUseCaseSetup.useCases;
    private GsUseCase currentUseCase = new GsUseCase();


    private GsApplicationFormData applicationData;


    public GsCallToAction(Lead inLead, Attachment inAttachment, Map<String,EmailTemplate> inEmailTemplateIdByDeveloperNameMap)
    {

        lead = inLead;
        pdfAttachment = inAttachment;
        emailTemplateIdByDeveloperNameMap = inEmailTemplateIdByDeveloperNameMap;

        try
        {
            applicationData = (GsApplicationFormData) System.JSON.deserialize(lead.JSONApplicationFormData__c, GsApplicationFormData.class);
            
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
        catch(exception ex){
            System.debug('Lead JSON could not be deserialized:' + ex.getMessage());
        }

        


        ep = applicationData.eParcelApplication; //eparcel Application
        cr = lead.Send_Business_Credit_Account_Info__c; //credit Application
        st = lead.State; //state

        system.debug('### ep : ' + ep);
        system.debug('### cr : ' + cr);
        system.debug('### st : ' + st);
        system.debug('### pdfAttachment : ' + pdfAttachment);


        //DLs
        eParcelInstallationTeamEmails.put('WA','wa.e-businesssupport@auspost.com.au');
        eParcelInstallationTeamEmails.put('QLD','eParcelsupportqld@auspost.com.au');

        eParcelInstallationTeamEmails.put('SA','eparcelsasupport@auspost.com.au');
        eParcelInstallationTeamEmails.put('NT','eparcelsasupport@auspost.com.au'); //same as SA

        eParcelInstallationTeamEmails.put('NSW','nsw.eparcelsupport@auspost.com.au');
        eParcelInstallationTeamEmails.put('ACT','nsw.eparcelsupport@auspost.com.au'); //same as NSW

        eParcelInstallationTeamEmails.put('VIC','DLVICeParcels@auspost.com.au');
        eParcelInstallationTeamEmails.put('TAS','DLVICeParcels@auspost.com.au'); //same as Vic


        contractManagementTeamEmails.put('WA','DLWAContractsManagement@auspost.com.au');
        contractManagementTeamEmails.put('QLD','DLQLDContractManagement@auspost.com.au');

        contractManagementTeamEmails.put('SA','DLSAContractManagement@auspost.com.au');
        contractManagementTeamEmails.put('NT','DLSAContractManagement@auspost.com.au');//same as SA

        contractManagementTeamEmails.put('NSW','ContractManagement@auspost.com.au');
        contractManagementTeamEmails.put('ACT','ContractManagement@auspost.com.au'); //same as NSW

        contractManagementTeamEmails.put('VIC','DLVicCustomerContractManagement@auspost.com.au');
        contractManagementTeamEmails.put('TAS','DLVicCustomerContractManagement@auspost.com.au'); //same as Vic
    }



    public void sendCallToActionEmail()
    {

        system.debug('### sendCallToActionEmail called');

        ep = ep == null || ep==''?'No':ep;
        cr = cr == null || cr==''?'No':cr;

        system.debug('### ep:' + ep);
        system.debug('### cr:' + cr);


        String emailTemplateDeveloperName;
        list<string> toAddress = new list<string>();




        //Set email template
        if( currentUseCase.wfCallToActionCredit &&
            currentUseCase.wfCallToActionEParcel)
        {
            emailTemplateDeveloperName = 'Green_Shoots_Internal_new_credit_account_and_setting_up_eParcel';
        }
        else if(!currentUseCase.wfCallToActionCredit &&
                currentUseCase.wfCallToActionEParcel)
        {
            emailTemplateDeveloperName = 'Green_Shoots_Internal_eParcel_for_an_existing_customer';
        }               
        else if(currentUseCase.wfCallToActionCredit)
        {
            emailTemplateDeveloperName = 'Green_Shoots_Internal_new_credit_account_not_eParcel';
        }   
        
        
        
        
        //add the email address
        if(currentUseCase.wfCallToActionCredit)
        {
            toAddress.add(creditManagementTeamEmail);
            toAddress.add(eParcelcustomercreation);
            toAddress.add(dlhqcdmcreditupdates);
        }
        if(currentUseCase.wfCallToActionCustData)   
        {
            toAddress.add(customerDataTeam);
            toAddress.add(eParcelcustomercreation);
            toAddress.add(dlhqcdmcreditupdates);
        }
        if( currentUseCase.wfCallToActionEParcel &&
            eParcelInstallationTeamEmails.containsKey(st))
        {
        toAddress.add(eParcelInstallationTeamEmails.get(st));
        }
        if( currentUseCase.wfCallToActionContract &&
            contractManagementTeamEmails.containsKey(st))
        {
            toAddress.add(contractManagementTeamEmails.get(st));
        }           
        if(currentUseCase.wfBHActivatePickups)
        {
            if( lead.Hub_Catchment__c != null &&
                lead.Hub_Catchment__c != '')
            {
                    
                
                toAddress.add(lead.Hub_Catchment__c.Trim().replace(' ','').toLowerCase() + 'businesshub@auspost.com.au');
            }
        }
        
        //send email
        if(toAddress.size()>0)
        {
            sendEmail(emailTemplateDeveloperName, toAddress);   
        }
        
    }


    private void sendEmail(String emailTemplateDeveloperName, list<string> toAddress)
    {

        system.debug('### emailTemplateDeveloperName:' + emailTemplateDeveloperName);
        system.debug('### toAddress:' + toAddress);

        system.debug('### isTestMode:' + isTestMode);
        list<String> toCCAddress = null;
        if(isTestMode)
        {
            toCCAddress = new list<String>();
            for(string s : toAddress)
            {
                toCCAddress.add(s + '.greenshoots');
            }           
            
            toAddress.clear();
            toAddress.addAll(testEmail.split(';'));
            system.debug('### isTestMode toAddress:' + toAddress);
        }

        if(toAddress==null)
        {
            return;
        }


            list<Messaging.EmailFileAttachment> attachments = new list<Messaging.EmailFileAttachment>();

            system.debug('### Preparing Attachments');
            if(pdfAttachment!=null){
                try{
                    Messaging.EmailFileAttachment emailAttachPdfForm = new Messaging.EmailFileAttachment();
                    emailAttachPdfForm.setContentType('application/pdf');
                    emailAttachPdfForm.setFileName(pdfAttachment.Name);
                    emailAttachPdfForm.setInline(false);
                    emailAttachPdfForm.Body = pdfAttachment.body;
                    attachments.add(emailAttachPdfForm);
                }
                catch(exception e){
                    //the template could not be found.
                    system.debug('There was a problem creating email attachment: '+ e);
                }
            }

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            system.debug('### pdfAttachment:' + pdfAttachment);
            if(pdfAttachment!=null)
            {
 
                try{

                    if(!emailTemplateIdByDeveloperNameMap.containsKey(emailTemplateDeveloperName))
                    {
                        //the template could not be found.
                        system.debug('Email template \'' +  emailTemplateDeveloperName +'\' could not be found');
                        return;
                    }

                    
                    

                    mail.setUseSignature(false);
                    mail.setToAddresses(toAddress);
                    //mail.setTargetObjectId(lead.Id);
                    

                    mail.setInReplyTo( 'noreply@auspost.com.au' );
                    
                   if(toCCAddress!=null)
                        mail.setCcAddresses(toCCAddress);
                    
                    EmailTemplate templateEmail = emailTemplateIdByDeveloperNameMap.get(emailTemplateDeveloperName);

                    
                    //mail.setTemplateID(templateEmail.Id);
                    
                    mail.setSubject(templateEmail.subject);
                    mail.setHtmlBody(getHTMLBody(templateEmail));
                    
                    if(attachments.size()>0)
                    {
                        mail.setFileAttachments( attachments  );
                    }
                    
                    // Send the email
                    System.debug('### mail:' + mail);
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   

                    
                    
                }
                catch(exception e){
                    system.debug('There was a problem sending the call to action email: '+ e);
                }
            }
    }

private String getHTMLBody(EmailTemplate templateEmail)
{

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                    mail.setUseSignature(false);
                    mail.setToAddresses(new String[]{'temp@auspost.com'});
                    mail.setTargetObjectId(lead.Id);
                    mail.setSaveAsActivity(false);

                    mail.setInReplyTo( 'noreply@auspost.com.au' );
                    
                    

                    mail.setTemplateID(templateEmail.Id);

               Savepoint sp = Database.setSavepoint();
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
               Database.rollback(sp);
                    
            return mail.getHTMLBody();

}





}