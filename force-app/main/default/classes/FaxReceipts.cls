/**************************************************
Type:       Inbound email handle Class for for Fax Receipts
Purpose:    
Used By:    ALMHandler 
History;
--------------------------------------------------
3.12.2014  C. Andronaco (Bluewolf)  Created.
11.02.2016  Paul                    Added logs to check email header.
12.02.2016  Paul                    To better control failed and successful faxes, changed the body of text email to a custom label 
**************************************************/

global class FaxReceipts implements Messaging.InboundEmailHandler {  

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        
        system.debug('**email:' + email);
        system.debug('**header:' + email.headers);
        system.debug('**subject:' + email.subject);
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
                        
        String tempFaxID = '';
        
        String temp = String.escapeSingleQuotes(email.subject);
        Integer faxIDIndex = temp.indexOf('Fax:');
        
        if (faxIDIndex >= 0)
        {
            tempFaxID = temp.substring(faxIDIndex+4, faxIDIndex+22);
            system.debug('FaxID:' + tempFaxID);
                        
            List<Fax__c> existingFaxes = [SELECT Id, FaxReceipt__c from Fax__c WHERE id = :tempFaxID];
        
            if (existingFaxes.size() > 0)
            {
                //Append Receipt to existing Fax. 
                for(Fax__c fax: existingFaxes)
                {
                
                    String myBody;
                        
                    if(!String.isEmpty(email.htmlBody))
                    {
                        myBody = email.htmlBody;
                    }
                    else
                    {
                        myBody = email.plainTextBody;
                    }                  
                
                    fax.FaxReceipt__c = myBody;
                    
                    if(!myBody.contains(label.FaxDelivered) )//to control what is coming in for failed and successful faxes
                    //if(!myBody.contains('SENT - The message was delivered.') && !myBody.contains('<td width="15%"><p align="left">SENT</td>') )
                    {
                        fax.Error__c = true;
                    }
                }
                
                update existingFaxes;
            }
        }
        
        return result;  
    }
}