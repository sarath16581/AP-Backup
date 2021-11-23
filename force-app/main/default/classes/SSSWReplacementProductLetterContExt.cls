/**************************************************
Type:       Controller Extension class       
Purpose:    Render compensation email template as letter in the form of a PDF.
Used by:    SSSWReplacementProductLetter.page
History:
-------------------------------------------------- 
25.09.2014  SK copied from A.T (Bluewolf)  Created.
**************************************************/

public with sharing class SSSWReplacementProductLetterContExt {
    
    public transient String htmlBody { get; set; }
    private EmailTemplate emailTemplate;
    private Case relatedCase;
    private Compensation__c compensation;
    private Contact contact;
    //Added for REQ1437329
    private EmailTemplate templateWIthBusinessName; 
    private Account acc;
    //Added for REQ1437329
    
    public SSSWReplacementProductLetterContExt(ApexPages.StandardController controller) {
        
        if (controller.getRecord() != null) {
            compensation = (Compensation__c)controller.getRecord();
            
            compensation = [SELECT Id, Case__c FROM Compensation__c WHERE Id = :compensation.Id LIMIT 1];
            
            relatedCase = [SELECT Id, ContactId,AccountId FROM Case WHERE Id = :compensation.Case__c LIMIT 1];
            
            emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SSSW_Replacement_Product_Letter' LIMIT 1];
            
            //Added for REQ1437329
            templateWIthBusinessName = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SSSW_Replacement_Product_Letter_with_Business_Name' LIMIT 1];
            for(Account accnt : [Select Id, RecordTypeId from Account where Id =:relatedCase.AccountID ]) {
                acc = accnt;
            }
            //Added for REQ1437329
            
            // Use the case contact if it exists, otherwise use the fictitious contact - SSSW Entitlements.
            // Contact is required for the fake email process (see getBody method).
            // If case contact does exist, query should return 2 items.
            List<Contact> contList = [select id, email, FirstName, LastName from contact where id = :relatedCase.contactId OR (FirstName = 'SSSW' AND LastName = 'Entitlements')];
            if (contList.size() > 1) {
                for (Contact c : contList) {
                    if (!(c.FirstName == 'SSSW' && c.LastName == 'Entitlements')) {
                        contact = c; 
                    }
                }
            } else if (contList.size() == 1) {
                contact = contList[0];
            }
        }
    }
    
    public void getBody() {
        
		if (String.isEmpty(contact.Email))
        {
            contact.Email = 'unknown@email.com';
            update contact;
        } 
        
        //Added for REQ1437329
         String consumerRecTypsId = [Select Id from RecordType where SObjectType='Account' and Name='Organisation' limit 1].Id;
        //Added for REQ1437329
		
        contact = [select Id, Email from Contact where Id = :contact.id limit 1][0];		
		
        Savepoint sp = Database.setSavepoint();
        try
        {
            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();

            sem.setTargetObjectId(contact.Id);
            //Added for REQ1437329 - check if the record is consumer or business and select template accordingly.
            if( acc!=null && consumerRecTypsId != acc.recordTypeId) {
            sem.setTemplateId(emailTemplate.Id);
            }
            else
            {
            sem.setTemplateId(templateWIthBusinessName.Id);
            }
            //Added for REQ1437329
            sem.setWhatId(compensation.Id);
            Messaging.sendEmail(new Messaging.Email[] { sem }); 
            htmlBody = sem.getHtmlBody();
        }
        catch(Exception e) {
            htmlBody = 'Error generating Letter Content';
        } finally {
            Database.rollback(sp);
			if (contact.Email == 'unknown@email.com')
	        {
	            contact.Email = '';
	            update contact;
	        } 			
        }   
    }     
}