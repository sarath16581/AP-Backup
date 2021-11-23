public with sharing class GsSendEmailController {
    
    
    //Send Email Page References Standard Controller.
    public CampaignMember cm{get; set;}
    //used to control if the send email page should be visible.
    public boolean showPage{get; set;}
    public boolean isError{get; set;}
    public boolean emailSent{get; set;}

    //contructor, using standard campaign member controller
    public GsSendEmailController(ApexPages.StandardController controller) {
        emailSent = false;
        cm = (CampaignMember)controller.getRecord();
        //do some quality checking of the campaign member/lead records.
        if(cm.Id == null){
            //the page wasn't loaded correctly, there is no Campaign Member with a Lead
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There is no Campaign Member.'));
        }
        else if(cm.LeadId == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The Campaign Member referenced is not associated to a Lead.'));
            isError = true;
        }
        else if(cm.Lead.Email == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The Campaign Member does not have an email address.'));
            isError = true;
        }
        else{
            //Everything looks ok so far, so show the page.
            isError = false;
        }   
    }
    
    
    //Method to Deliver Email to Lead.
    public pageReference sendEmail(){
    
        //generate a public id
        string publicId = generatePublicId();
        //boolean to track update status of Campaign Member & Lead
        boolean sendEmail = true;
        
        //update the lead and the campaign member record
        Lead l = new Lead(Id = cm.LeadId, Public_Id__c = publicId);
        cm.Public_Id__c = publicId;
        try{
            //update the campaign member and lead with a public id
            update cm;
            update l;
        }
        catch(exception e){
            system.debug('There was an error updating the Lead of Campaign Member: '+e);
            //as the records weren't updated, throw an error to the page and don't send the email.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The Email was not sent due to errors: '+e));
            sendEmail = false;
        }
        
        //load the correct template and send
        //Only send the email if there are no errors updating the Campaign Member & Lead with the public Id.
        if(sendEmail){
            // Create the email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setUseSignature(false);
            mail.setTargetObjectId(cm.LeadId);

            //Load The Correct Email Template and set the correct object for merge fields.
            Id templateId;
            try{
                templateId = [select id from EmailTemplate where DeveloperName = 'Greenshoots_Invitation_Email' limit 1].Id;
                mail.setTemplateID(templateId);
            }
            catch(exception e){
                //the template could not be found.
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The Email Template could not be found, please contact the System Administrator.'));
            }
             
            //TODO: If possible control the sender visible name and address as with this it shows up as no-reply@auspost.com.au <richard.clarke@auspost.com.au>
            mail.setInReplyTo( 'no-reply@auspost.com.au' );
            mail.setReplyTo('no-reply@auspost.com.au');
            mail.setSenderDisplayName('no-reply@auspost.com.au');

            // Send the email
            if(sendEmail){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Email Sent Successfully.'));
                emailSent = true; // To remove send email button to avoid sending more than once
                //Other Updates to the Campaign Member Here
                cm.Status = 'Interested - Invitation Email Sent';
                update cm;          
            }
        }
        
        return null;
    }


    
    //Method to Generate Public Id, Consider Putting in Utility Class if Time.
    public string generatePublicId(){
        Datetime now = System.now();
        String formattednow = now.formatGMT('yyyy-MM-dd') + 'T' + now.formatGMT('HH:mm:ss') + '.' + now.formatGMT('SSS') + 'Z';
        String canonical = cm.Id + formattednow;
        canonical += cm.LeadId;
        Blob bsig = Crypto.generateDigest('MD5',Blob.valueOf(canonical));
        String token = EncodingUtil.base64Encode(bsig);
        if(token.length()>255) {token = token.substring(0,254);}
        return EncodingUtil.urlEncode(token,'UTF-8').replaceAll('%','_');
    
    }

}