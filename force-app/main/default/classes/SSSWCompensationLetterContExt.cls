/**************************************************
Type:       Controller Extension class       
Purpose:    Render compensation email template as letter in the form of a PDF.
Used by:    SSSWCompensationLetter.page

History:
-----------------------------------------------------------------------------------------
14.05.2014    A. Tran (Bluewolf)  Created.
16.11.2015    kalpita.talwadekar@auspost.com.au    Updated the code to check for business and consumer records and 
                                                   send template accordingly.
08.03.2016    eric.shen@auspost.com.au             Remove Account.Name to fix error INVALID_FIELD_FOR_INSERT_UPDATE, Account: bad field names on insert/update call:  AccountId: [ AccountId]
11.06.1018    kalpita.talwadekar@auspost.com.au    updated code for coding standard follow - TDO-221
**************************************************/
public with sharing class SSSWCompensationLetterContExt {
    
    //class variables for email template 
    public transient String htmlBody { get; set; }
    private EmailTemplate emailTemplate;
    private EmailTemplate templateWIthBusinessName;
    //variable to store the related case details
    private Case relatedCase;
    //the current compensation variable
    private Compensation__c compensation;
    //variables to hold account and contact details 
    private Contact contact;
    private Account acc;
    
    /** 
      * @name: SSSWCompensationLetterContExt()
      * @desciption: constructor for class  to initialize all variables
      * @param: ApexPages.StandardController controller
      * @return: NA
      *
      */
    public SSSWCompensationLetterContExt(ApexPages.StandardController controller) {
        //if there is a record passed in the controller page
        if (controller.getRecord() != null) { 
            //set the compensation record
            compensation = (Compensation__c)controller.getRecord();
            
            // query fields on compensatoion based on above controller record
            compensation = [ SELECT Id, Case__c FROM Compensation__c WHERE Id = :compensation.Id LIMIT 1 ];

            // query the releted case FROM compensation record
            relatedCase = [SELECT Id, ContactId, AccountId FROM Case WHERE Id = :compensation.Case__c LIMIT 1];

            // query the email template to be used for compensation record
            emailTemplate = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SSSW_Compensation' LIMIT 1];
            
            //query for new template for business accounts 
            templateWIthBusinessName = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SSSW_Compensation_Business_Name' LIMIT 1];
            
            // Use the case contact if it exists, otherwise use the fictitious contact - SSSW Entitlements.
            // Contact is required for the fake email process (see getBody method).
            // If case contact does exist, query should return 2 items.
            List<Contact> contList = [
                SELECT id, email, FirstName, LastName
                FROM Contact
                WHERE id = :relatedCase.contactId
                OR (FirstName = 'SSSW'
                AND LastName = 'Entitlements')
            ];

            for(Account accnt : [
                 SELECT Id, RecordTypeId
                 FROM Account
                 WHERE Id =:relatedCase.AccountID ]) {
                    acc = accnt;
            }

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
    
    /** 
      * @name: getBody()
      * @desciption: method to create the template body for email send
      * @param: NA
      * @return: NA
      *
      */
    public void getBody() {
        //check if contact email is available
        if (String.isEmpty(contact.Email))  {
            contact.Email = 'unknown@email.com';
            update contact;
        } 
        //query to get consumer record type on account
        String consumerRecTypsId = [SELECT Id
                                    FROM RecordType
                                    WHERE SObjectType='Account'
                                    AND Name='Organisation'
                                    LIMIT 1].Id;
        
        //select for the contact record
        contact = [ SELECT Id, Email,RecordTypeId FROM Contact WHERE Id = :contact.id LIMIT 1][0];
        
        Savepoint sp = Database.setSavepoint();
        try {
            // email send setup
            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();

            //setting the taregt contact object
            sem.setTargetObjectId(contact.Id);

            //check if the record is consumer or business and select template accordingly.
            if( acc!=null && consumerRecTypsId != acc.recordTypeId) {
                sem.setTemplateId(emailTemplate.Id);
            } else {
                sem.setTemplateId(templateWIthBusinessName.Id);
            }

            //relate to the compensation record id on the template
            sem.setWhatId(compensation.Id);
            Messaging.sendEmail(new Messaging.Email[] { sem }); 
            htmlBody = sem.getHtmlBody();
        } catch(Exception e) {
            htmlBody = 'Error generating Letter Content';
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    'SSSWCompensationLetterContExt', 'getBody', null, LoggingLevel.ERROR);
        } finally {
            Database.rollback(sp);
            if (contact.Email == 'unknown@email.com') {
                contact.Email = '';
                update contact;
            } 
        }   
    } 
}