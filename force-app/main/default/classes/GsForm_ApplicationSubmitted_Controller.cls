public class GsForm_ApplicationSubmitted_Controller {
   
   
    //SystemSettings For Testing Mode
    SystemSettings__c SystemSettings = SystemSettings__c.getOrgDefaults();
    private boolean isTestMode = SystemSettings.GSForm_useTestEmails__c;
    private String testEmail = SystemSettings.GSForm_testEmailAddresses__c;
    list<string> toAddressInternalSalesReferral = new list<string>();
    
    private map<String, GsUseCase> useCases = GsUseCaseSetup.useCases;
    private map<String, String> emailsTemplateNameByOfferEmailText = GsUseCaseSetup.emailsTemplateNameByOfferEmailText;
    private GsUseCase currentUseCase = new GsUseCase();
    private String salesReferralEmailAddress = 'DLCSAcquisitionSales@auspost.com.au';

    private GsApplicationFormData applicationData;
    public  GsApplicationFormData getAppData()
    {
        return applicationData = applicationData==null ? new GsApplicationFormData():applicationData;
    }
    
 
    private Lead lead;
    private CampaignMember campaignMember;
 
    public GsForm_ApplicationSubmitted_Controller(){

        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');
 
        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');

        status = ApexPages.currentPage().getParameters().get('value');
        string publicId = ApexPages.currentPage().getParameters().get('pid');

        setMessage();
        
        
        if(publicId!=null)
        {
        campaignMember = [SELECT Id, LeadId, Status from CampaignMember where Public_Id__c = :publicId limit 1];
        lead = [SELECT  Id,
                        OwnerId,
                        ABN__c,
                        IsConverted,
                        Name,
                        LastName,
                        FirstName,
                        Company,
                        Trading_Name__c,
                        Email,
                        Lead_Number__c,
                        Website,
                        JSONApplicationFormData__c,
                        Street,
                        City,
                        State,
                        PostalCode,
                        NumberOfEmployees,
                        Phone,
                        Fax,
                        MobilePhone,
                        Existing_Business_Credit_Account__c,
                        Send_Business_Credit_Account_Info__c,
                        Account_No__c,
                        Date_Submitted__c,
                        LeadSource,
                        Application_Form__c,
                        Legal_Marketing_Opt_In__c
                FROM    Lead
                WHERE   Id = :campaignMember.leadId];   


                if(lead.JSONApplicationFormData__c != null && lead.JSONApplicationFormData__c.length() > 0)
                {
                    applicationData = (GsApplicationFormData) System.JSON.deserialize(lead.JSONApplicationFormData__c, GsApplicationFormData.class);
                }
                else
                {
                   applicationData = new GsApplicationFormData();
                }


             setJSONandUserCases();
                     
        }
        
    }

    public String status{get; set;}

    public String msg{get; set;} //The main thank you message
    public String banner{get; set;} //The section in the banner with the Post logo
    public String header{get; set;} //The main header outside the content box
    public String title {get; set;} //The title at the top of the content box
    



        private Blob getPDF(Lead inLead)
        {
            // Create PDF version of the form (http://blog.jeffdouglas.com/2010/07/14/attach-a-pdf-to-a-record-in-salesforce/)
            //PageReference pdf = new PageReference('/apex/GsForm_CustomerAcquisitionForm_v003_PDF?ID=' + lead.Id + '&ln=' + lead.Lead_Number__c + '&cm=' + campaignMember.Id);
    
            System.debug('!!!JSONApplicationFormData__c:' + inLead.JSONApplicationFormData__c);
    
            PageReference pdf = Page.BusinessCustomerApplicationPdf;
            pdf.getParameters().put('id', inLead.Id);
            pdf.getParameters().put('ln', inLead.Lead_Number__c);
    
            Blob body;
            try {
                // returns the output of the page as a PDF
                body = pdf.getContent();
            } catch (VisualforceException e) {
                // Note first attempt failed "Creating the PDF equivalent of the form failed Exception common.page.PageInterruptException, Cyclical server-side forwards detected: /apex/GsForm_CustomerAcquisitionForm_v002_PDF?inline=1"
                // so had to clone the controller to avoid that error, after which the PDF creation worked
                body = Blob.valueOf('Creating the PDF equivalent of the form failed ' + e.GetMessage() );
            }
    
            return body;
        }


        private Messaging.EmailFileAttachment createEmailFileAttachmentPDFFromBlob(Blob inBody, String FileName)
        {
                Messaging.EmailFileAttachment emailAttach = new Messaging.EmailFileAttachment();
                emailAttach.setContentType('application/pdf');
                emailAttach.setFileName(FileName);
                emailAttach.setInline(false);
                emailAttach.Body = inBody;
                return emailAttach;
        }

        private Messaging.EmailFileAttachment createEmailFileAttachmentFromStaticResourceByName(String staticResourceName, String attachmentName, Boolean attachFileToRecord, String parentRecordId)
        {
            try{
                List<StaticResource> staticResource = [Select body, name from StaticResource where Name = :staticResourceName limit 1];
                if ( staticResource.size() == 1 ) {
                    Messaging.EmailFileAttachment emailAttach = new Messaging.EmailFileAttachment();
                    emailAttach.setContentType('application/pdf');
                    emailAttach.setFileName(attachmentName);
                    emailAttach.setInline(false);
                    emailAttach.Body = staticResource[0].body;

                    if(attachFileToRecord)
                    {
                            Attachment fileAttach = new Attachment();
                            fileAttach.Body = staticResource[0].body;
                            fileAttach.Name = staticResource[0].Name;
                            fileAttach.IsPrivate = false;
                            fileAttach.ParentId = parentRecordId;
                            insert fileAttach;
                    }


                    return emailAttach;
                }
                else
                {
                    return null;
                }
            }
            catch(Exception ex)
            {
                System.debug('File ' + attachmentName + 'could not be attached to the email of the record ' + parentRecordId );
                return null;
            }
        }




    public void sendEmailsOut()
    {   
        if(lead == null)
            return;
        
       Blob body = getPDF(lead);


         //TODO: when deploying don't forget the lead layout "Lead Layout" needs the notes and attachments related list exposed
        // Attach the pdf to the lead
        Attachment attach = new Attachment();
        attach.Body = body;
        attach.Name = 'Application Form.pdf';
        attach.IsPrivate = false;
        attach.ParentId = lead.Id;
        attach.ContentType = ('application/pdf');
        insert attach;

        Messaging.EmailFileAttachment emailAttachPdfForm = createEmailFileAttachmentPDFFromBlob(body,'Application Form.pdf');


        if ( lead.Email != null ) {


            System.debug('### currentUseCase.wfSalesReferal:' + currentUseCase.wfSalesReferal);
            System.debug('### currentUseCase.AcknowledgementEmail:' + currentUseCase.AcknowledgementEmail);


            //Sales referral emails
            if(currentUseCase.wfSalesReferal)
            {   
                
                toAddressInternalSalesReferral.add(salesReferralEmailAddress);
                
                system.debug('### isTestMode:' + isTestMode);
                list<String> toCCAddress = null;
                if(isTestMode)
                {
                    toCCAddress = new list<String>();
                    for(string s : toAddressInternalSalesReferral)
                    {
                        toCCAddress.add(s + '.greenshoots');
                    }
                    
                    toAddressInternalSalesReferral.clear();
                    toAddressInternalSalesReferral.addAll(testEmail.split(';'));
                    system.debug('### isTestMode toAddress:' + toAddressInternalSalesReferral);
                }

                if(toAddressInternalSalesReferral!=null)
                {
                    List<Messaging.EmailFileAttachment> objEmailAttachments = new List<Messaging.EmailFileAttachment>();
                    objEmailAttachments.add(emailAttachPdfForm);
                    sendEmail(toAddressInternalSalesReferral, 'Green_Shoots_Internal_Sales_Referral',objEmailAttachments, lead.id,toCCAddress);
                }
            }


        if(currentUseCase.AcknowledgementEmail)
        {
            List<Messaging.EmailFileAttachment> objEmailAttachments = new List<Messaging.EmailFileAttachment>();
            System.debug('### currentUseCase.attchApplicationResponse:' + currentUseCase.attchApplicationResponse);
            if(currentUseCase.attchApplicationResponse)
            {
                    objEmailAttachments.add(emailAttachPdfForm);
            }

            System.debug('### currentUseCase.attchCreditAccountTC:' + currentUseCase.attchCreditAccountTC);
            if(currentUseCase.attchCreditAccountTC)
            {
                    Messaging.EmailFileAttachment emailAttach = createEmailFileAttachmentFromStaticResourceByName('BusinessCreditAccountTermsAndConditions','Australia Post Business Credit Account terms and conditions.pdf', true, lead.id);
                    objEmailAttachments.add(emailAttach);
            }

            System.debug('### currentUseCase.attchEParcelTC:' + currentUseCase.attchEParcelTC);
            if(currentUseCase.attchEParcelTC)
            {
                    Messaging.EmailFileAttachment emailAttach = createEmailFileAttachmentFromStaticResourceByName('TermsAndConditionsOfCarriage','eParcel Service Terms and Conditions of Carriage.pdf', true, lead.id);
                    objEmailAttachments.add(emailAttach);
            }

            System.debug('### currentUseCase.attchBonusOfferTC:' + currentUseCase.attchBonusOfferTC);
            if(currentUseCase.attchBonusOfferTC)
            {
                    Messaging.EmailFileAttachment emailAttach = createEmailFileAttachmentFromStaticResourceByName('TermsAndConditionsBonusOffers','Bonus offer terms and conditions.pdf', true, lead.id);
                    objEmailAttachments.add(emailAttach);
            }

            System.debug('### currentUseCase.attchParcelRateCard:' + currentUseCase.attchParcelRateCard);
            if(currentUseCase.attchParcelRateCard)
            {
                    Messaging.EmailFileAttachment emailAttach = createEmailFileAttachmentFromStaticResourceByName( 'eParcelPriceSchedule','ATTACHMENT A.pdf', true, lead.id);
                    objEmailAttachments.add(emailAttach);
            }

			// 2013-07-30 Attach Internation T&C if eciApplication is selected
            System.debug('### getAppData().eciApplication = ' + getAppData().eciApplication);
            if(getAppData().eciApplication == 'Yes')
            {
                    Messaging.EmailFileAttachment emailAttach = createEmailFileAttachmentFromStaticResourceByName( 'InternationalTermsOfCarriage','International Terms of Carriage 2013.pdf', true, lead.id);
                    objEmailAttachments.add(emailAttach);
            }

            System.debug('### objEmailAttachments.size():' + objEmailAttachments.size());

            list<String> emails = new list<String>();
            emails.add(lead.Email);
            sendEmail(emails,emailsTemplateNameByOfferEmailText.get(currentUseCase.offerEmailText),objEmailAttachments, lead.id, null);
        }


        }
        
        campaignMember.Status = currentUseCase.cmsvAfterSubmission;
        update campaignMember;
        
}


        private void sendEmail(list<string> toAddress, String emailTemplateDeveloperName, list<Messaging.EmailFileAttachment> attachments, String TargetObjectId, list<string> toCCAddress)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            try{
                mail.setUseSignature(false);
                mail.setToAddresses(toAddress);
                mail.setTargetObjectId(TargetObjectId);
                mail.setInReplyTo( 'noreply@auspost.com.au' );
                
                
                System.debug('### toCCAddress:' + toCCAddress);
                if(toCCAddress!=null)
                    mail.setCcAddresses(toCCAddress);
                
                
                Id templateId = [select id from EmailTemplate where DeveloperName = :emailTemplateDeveloperName limit 1].Id;
                mail.setTemplateID(templateId);

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


    private void setJSONandUserCases()
    {
        //serialize the fields in JSON format
        lead.JSONApplicationFormData__c = JSON.serialize(applicationData);

        if(getAppData().creditAccountNumber!=null)
        {
            lead.Account_No__c = getAppData().creditAccountNumber;
        }

        String caseNumber =    currentUseCase.caseSelection(lead.Existing_Business_Credit_Account__c,
                                                            lead.Send_Business_Credit_Account_Info__c,
                                                            getAppData().creditLimit5000,
                                                            getAppData().parcelsPerYear,
                                                            getAppData().eParcelApplication,
                                                            getAppData().termsCreditAccount,
                                                            getAppData().termsParcelService,
                                                            getAppData().generalTAndC);

        currentUseCase = useCases.get(caseNumber);
    }

    public void setMessage(){

        // Default content
        banner = 'Customer application received';
        header = 'Customer application received';
        title = 'Thank you';
        msg = 'Thank you, your application has been received';
        

        IF(status == 'success'){
            //Set the text for msg scenario A (use cases 1,3)
            msg = 'Thank you for your details. A sales representative will be in touch with you shortly to discuss the best options for your business.';
        }
        Else IF(status == 'result'){
            //Set the text for msg scenario B (use cases 2)
            msg = 'Thank you for providing your details. Our existing parcel deals are available for new Australia Post Business Credit Account customers only.  To find out about other Australia Post products and services that may be helpful for your business, <a href="http://auspost.com.au/business-solutions.html">click here</a>.';
        }
        Else IF(status == 'received'){
            //Set the text for msg scenario C (use case 4)
            msg = 'Thank you for your acceptance. We will now process your Australia Post Business Credit Account application. Based on your selected parcel volumes, we recommend the Click and Send solution. Click and Send is a convenient online lodgement tool that is integrated with Delivery Choices, tracking and signature features.  To start the Click and Send registration process, <a href="https://www.clickandsend.com.au/home/NISS_frm_home.php?sz_Client=AustraliaPost">click here</a>.';
        }
        Else IF(status == 'confirmed'){
            //Set the text for msg scenario D (use case 5)
            msg = 'Thank you for your acceptance. We will now process your Australia Post Business Credit Account application. Once processed, you will receive an email from us confirming your application details.';
        }
        Else IF(status == 'submitted'){
            //Set the text for msg scenario E (use case 6)
            msg = 'Thank you for your acceptance. Based on your selected parcel volumes, we recommend our eParcel service. eParcel is a convenient online lodgement system that is integrated with Delivery Choices, tracking and signature features. We will now process your Australia Post Business Credit Account application and your eParcel application. Once processed, you will receive an email from us confirming your application details.';
        }
        Else IF(status == 'lodged'){
            //Set the text for msg scenario F (use case 7)
            msg = 'Thank you for your acceptance. As you have an existing Australia Post Business Credit Account and based on your selected parcel volumes, you may be interested in our Click and Send solution which you can register for using your existing credit account. Click and Send is a convenient online lodgement tool that is integrated with delivery choices, tracking and signature features.  To find out more about Click and Send, <a href="http://auspost.com.au/parcels-mail/click-and-send.html">click here</a>.';
        }
        Else IF(status == 'eParcel'){
            //Set the text for msg scenario M (use case 8)
            msg = 'Thank you for providing your details. Based on your selected parcel volumes, we recommend our eParcel service. eParcel is a convenient online lodgement system that is integrated with Delivery Choices, tracking and signature features.  To find out about other Australia Post products and services that may be helpful for your business, <a href="http://auspost.com.au/business-solutions.html">click here</a>.';
        }        
        Else IF(status == 'applied'){
            //Set the text for msg scenario G (use case 9)
            msg = 'Thank you for your acceptance. Based on your selected parcel volumes, we recommend our eParcel service. eParcel is a convenient online lodgement system that is integrated with Delivery Choices, tracking and signature features. We will now process your eParcel application and you will receive and email from from us shortly confirming your application details.';
        }
        Else IF(status == 'disagree'){
            //Set the text for msg scenario X (use cases 12,13)
            banner = 'Customer application cancelled';
            header = 'Customer application cancelled';
            msg = 'Thank you for your interest in Australia Post services. Unfortunately we are unable to proceed with your application for an Australia Post Business Credit Account or an eParcel service as you have not accepted the terms and conditions of the application. Should you change your mind, you can submit your application by clicking the link in the email provided.';
        }
        Else IF(status == 'cancel'){
            //Set the text for msg scenario Y (cance) (use case 10)
            msg = 'Thank you for your interest in Australia Post services. Should you change your mind, you can submit your application by clicking the link in the email provided.';
            banner = 'Customer application cancelled';
            header = 'Customer application cancelled';
            title = 'If you change your mind...';
        }
    }
}