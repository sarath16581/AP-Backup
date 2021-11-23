/**************************************************
Type:       Controller Extension class       
Purpose:    Renders PDF from an Email Template by preparing an email
            to send to retrieve the email's content then rolling back
            the database before email is sent.
Used by:    SSSW_Case_FaxTemplate.page
History:
-------------------------------------------------- 
29.04.2014  A. Tran (Bluewolf)  Created.
**************************************************/

public with sharing class SSSWCaseEmailTemplateContExt {
    
    private static final String GENERAL_TEMPLATE = 'SSSW_Case_GeneralTemplate';
    
    public transient String htmlBody { get; set; }
    private EmailTemplate emailTemplate;
    private Case thisCase;
    private Contact contact;
    private string UNKNOWN_EMAIL = 'unknown@email.com';
    
    
    public SSSWCaseEmailTemplateContExt(ApexPages.StandardController controller) {
        
        if (controller.getRecord() != null) {
            thisCase = (Case)controller.getRecord();
            
            thisCase = [SELECT Id, ContactId, EnquirySubType__c,Type,Network__c,EscalationEmail__c  FROM Case WHERE Id = :thisCase.Id LIMIT 1];
            
            // Use the correct email template if it exists, otherwise use the general email template.
            // If correct template does exist, query should return 2 items
            String templateName = 'SSSW Case ' + thisCase.EnquirySubType__c;
            List<EmailTemplate> tempList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE Name = :templateName OR DeveloperName = :GENERAL_TEMPLATE];
            if (tempList.size() > 1) {
                for (EmailTemplate et : tempList) {
                    if (et.DeveloperName != GENERAL_TEMPLATE) {
                        emailTemplate = et;
                    }
                }
            } else if (tempList.size() == 1) {
                emailTemplate = tempList[0];
            }
            
            // Use the case contact if it exists, otherwise use the fictitious contact - SSSW Entitlements.
            // Contact is required for the fake email process (see getBody method).
            // If case contact does exist, query should return 2 items.
            List<Contact> contList = [select id, email, FirstName, LastName from contact where id = :thisCase.contactId OR (FirstName = 'SSSW' AND LastName = 'Entitlements')];
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
            contact.Email = UNKNOWN_EMAIL;
            update contact;
        } 
        contact = [select Id, Email from Contact where Id = :contact.id limit 1][0];        
        
        Savepoint sp = Database.setSavepoint();
        try {
                
            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
            sem.setTargetObjectId(contact.id);
            sem.setTemplateId(emailTemplate.Id);
            sem.setWhatId(thisCase.Id);
            Messaging.sendEmail(new Messaging.Email[] { sem });
            
            htmlBody = sem.getHtmlBody().replace(UNKNOWN_EMAIL, '');
        } catch(Exception ex) {
            // nothing
        } finally {
            Database.rollback(sp);
            if (contact.Email == UNKNOWN_EMAIL)
            {
                contact.Email = '';
                update contact;
            }           
        }
    } 
}