/**************************************************
Type:       Inbound email handle Class for Case Object
Purpose:    
Used By:    SSSWFaxEmailService
History:
--------------------------------------------------
13.12.2013  A. Tran (Bluewolf)  Created.
**************************************************/

global class SSSWFaxHandler implements Messaging.InboundEmailHandler {  

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
                
        RecordType rt = [select Id from RecordType where DeveloperName='Inbound' and SObjectType='Fax__c'];
        
        Fax__c fax = new Fax__c(
            Name = 'Fax - ' + DateTime.now().format('dd-MM-yyyy hh:mm:ss a'),
            To__c = envelope.toAddress,
            From__c = envelope.fromAddress,
            Subject__c = email.subject,
            Body__c = email.plainTextBody,
            RecordTypeId = rt.Id);
        
        try {
            // Save attachments, if any
            List<Attachment> attachments = new List<Attachment>();
            
            if (email.textAttachments != null) {
                for (Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments) {
                  Attachment attachment = new Attachment();
                 
                  attachment.Name = tAttachment.fileName;
                  attachment.Body = Blob.valueOf(tAttachment.body);
                  //attachment.ParentId = fax.Id;
                  attachments.add(attachment);
                }
            }
            if (email.binaryAttachments != null) {
                for (Messaging.InboundEmail.BinaryAttachment bAttachment : email.binaryAttachments) {
                  Attachment attachment = new Attachment();
                 
                  attachment.Name = bAttachment.fileName;
                  attachment.Body = bAttachment.body;
                  //attachment.ParentId = fax.Id;
                  attachments.add(attachment);                  
                }
            }
                                    
            // insert Fax if email attachments are ok
            insert fax;
            
            // update attachments with parentId, that is the fax Id just inserted
            for (Attachment a : attachments) {
                a.ParentId = fax.Id;
            }
            insert attachments;
                        
        } catch (Exception e) {
            // TODO: what to do if Fax cannot be created, e.g. email back to sender 
        }
    
        return result;  
    }
}