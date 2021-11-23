/*
    @Author      :  Snigdha.Sahu@auspost.com.au
    @Name        :  RetailSMBEmailHelper
    @Date        :  10/05/2016
    @Description :  Controller for RetailSMBKnowledgeEmail. 
*/


public with sharing class RetailSMBEmailHelper
{
    public static String email{get;set;}
    public static String fileparam{get;set;}
    public static String file{get;set;}
     
    
    public static void sendEmail() 
    {       
     
     system.debug(' Check Params ' + apexpages.currentpage().getParameters());
     
     try{
     
             fileparam = apexpages.currentpage().getParameters().get('fileparam');
             file = fileparam.substring(fileparam .lastIndexOf('=') + 1);
             //file = apexpages.currentpage().getParameters().get('file');
             
             system.debug(' Check file id  ' + file );
             
             Document document = [select id, name, body, contenttype, type from Document where id = :file];          
                
             
             Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
             efa.setContentType(document.contentType);     
             efa.setFileName(document.name +'.'+ document.type);
             efa.setInline(false);            
             efa.Body = document.body ;
             
             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
             //mail.setTemplateId('00XO0000000EVNA');     
             mail.setToAddresses(new String[] {email});
             mail.setBccSender(false);
             mail.setSubject('SMB Business Guide');
             mail.setHtmlBody('<p><font><span style="color:#535664"><b>Hello, </b></span></font></p><p><font><span style="color:#535664">Greetings from <b>Australia Post!</b></span></font></p><p><font><span style="color:#535664">Thank you for contacting us for your business needs. It was a pleasure to serve you. Please find attached the relevant documentation as discussed.</span></font></p>');
             mail.setUseSignature(false);
             mail.setReplyTo('donotreply@auspost.com.au');
             mail.setSenderDisplayName('AustraliaPost');
             //mail.setOrgWideEmailAddressId('0D290000000PCzf/e');
             mail.setSaveAsActivity(false);    
             mail.setFileAttachments(new Messaging.EmailFileattachment[]{efa});
         
             Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Email sent.Thank you!'));
              
             return;
         }         
         catch(System.EmailException ex)
         {
               ex.getMessage(); 
         }
      
          

    }  
}