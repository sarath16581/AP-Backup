/*
--------------------------------------- History --------------------------------------------------
24.04.2020    Hara Sahoo    Modified Added Case comment creation
*/
@isTest
//Test Data Factory for Customer Community (Conversation Hub)project.
public without sharing class cpTestDataFactory {

        //Test Data Factory for Customer Community (Conversation Hub)project - Account Object
        public Account getAccount() {
            Account acc = new Account(name = 'TEST ACCOUNT');
            return acc;
        }

        //Test Data Factory for Customer Community (Conversation Hub)project - Contact Object
        public Contact getContact(id accountId){
                Contact con = new Contact(AccountId = accountId, lastname = 'lastname', FirstName = 'Firstname', Email = 'testUser@Mailinator.com', Phone = '3625147890', MailingState ='State',
                                        MailingStreet = 'Street', MailingCity= 'City', MailingPostalCode = '123456', MailingCountry = 'Country');
                return con;
        }

        //Test Data Factory for Customer Community (Conversation Hub)project - User Object
        public User getCommunityUser(Id profileId, Id contactId,String testemail,String cmtyNickName) {
                 String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
                 Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
                 String uniqueName = randomInt + dateString;
                 User pusr = new User(profileId = profileId, username = uniqueName+testemail, email = uniqueName+testemail,
                                   emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                   languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                                   alias='cspu', lastname='lastname', CommunityNickname = uniqueName+cmtyNickName, contactId = contactId);
                return pusr;
        }

        //Test Data Factory for Customer Community (Conversation Hub)project - User Profile
        public User getUser(Id profileId,String testemail) {
                String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
                Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
                String uniqueName = dateString + randomInt;
                User usr = new User(profileId = profileId, username = uniqueName+testemail, email = uniqueName+testemail,
                                   emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                   languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                                   alias='cspu', lastname='lastname');
                return usr;
        }

        //Case Record Type
        public String getRecordType(String objectType, String recordTypeDeveloperName){
                String objRecordTypeId = [Select Id From RecordType  Where SobjectType =: objectType and DeveloperName =: recordTypeDeveloperName limit 1].id;
                return objRecordTypeId;
        }
    
        //Create case Record
        public Case getCase(String RecordTypeId, String accountId){
                Case caseRec = new Case();
                caseRec.RecordTypeId = RecordTypeId;
                caseRec.AccountId = accountId;
                caseRec.Call_Purpose__c = 'HR Enquiry';
                caseRec.Subject = 'Test case subject';
                caseRec.Status = 'New';
                return caseRec;
        }

        //Create case comment-Added on 24/04/2020
        public CaseComment getCaseComment ( String messageBody, String caseId)
        {
                CaseComment cs = new CaseComment();
                cs.ParentId= caseId;
                cs.IsPublished= false;
                cs.CommentBody=messageBody;
                return cs;
        }
        
    
}