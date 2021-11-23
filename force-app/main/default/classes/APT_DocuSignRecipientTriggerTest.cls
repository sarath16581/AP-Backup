/**
* Description: This apex class is test class for apex trigger - APT_DocuSignRecipientTrigger.
* Created By - Mahesh Patel
* Created Date - 8th Dec, 2020
**/
@isTest
private class APT_DocuSignRecipientTriggerTest 
{
    @TestSetup
    static void testDataSetup(){
        //Get Profile
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        //Create User
        User user = APT_TestUtil2.createUser(profile.Id);
        insert user;
        System.Assert(user.Id != null);

        //Create Contact
        Contact contact = APT_TestUtils.createContact();
        insert contact;

        //Create Agreement
        Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(contact.Id);
        insert agreement;
        System.Assert(agreement.Id != null); 
    }

    @IsTest
    static void testMaxOneContactUserRecipientsValidation() 
    {
        User user = [SELECT Id FROM User LIMIT 1];

        System.runAs(user)
        {
            //Fetch Contact
            Contact contact = [SELECT Id FROM Contact LIMIT 1];

            //Fetch Agreement
            Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

            Test.StartTest();

            //Create DocuSign Recipients
            Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipContact = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_CONTACT, contact.Id, null, 'Test FName', 'Test LName', 'testuser@auspost.com');
            insert docSignRecipContact;
            system.assert(docSignRecipContact.Id !=null);

            Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipUser = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_USER, null, user.Id, 'Test FName', 'Test LName', 'testuser@auspost.com');
            insert docSignRecipUser;
            system.assert(docSignRecipUser.Id !=null);

            Test.StopTest();
        }
    }

    @IsTest
    static void testEmailRecordUpdateFromContactToUser() 
    {
        User user = [SELECT Id FROM User LIMIT 1];

        System.runAs(user)
        {
            //Fetch Contact
            Contact contact = [SELECT Id FROM Contact LIMIT 1];

            //Fetch Agreement
            Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

            Test.StartTest(); 

            //Create DocuSign Recipients
            Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipEmail = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL, contact.Id, user.Id, 'Test FName', 'Test LName', 'testuser@test.com');
            insert docSignRecipEmail;
            system.assert(docSignRecipEmail.Id != null);

            //Update DocuSign Recipients
            docSignRecipEmail.Apttus_DocuApi__Email__c = 'testuser@auspost.com';
            update docSignRecipEmail;

            Apttus_DocuApi__DocuSignDefaultRecipient2__c updatedRecord = [SELECT Apttus_DocuApi__Email__c FROM Apttus_DocuApi__DocuSignDefaultRecipient2__c WHERE Id =:docSignRecipEmail.Id LIMIT 1];

            system.assertEquals('testuser@auspost.com',updatedRecord.Apttus_DocuApi__Email__c); 

            Test.StopTest();
        }
    }

    @IsTest
    static void testEmailRecordUpdateFromUserToContact() 
    {
        User user = [SELECT Id FROM User LIMIT 1];

        System.runAs(user)
        {
            //Fetch Contact
            Contact contact = [SELECT Id FROM Contact LIMIT 1];

            //Fetch Agreement
            Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

            Test.StartTest(); 

            //Create DocuSign Recipients
            Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipEmail = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL, contact.Id, user.Id, 'Test FName', 'Test LName', 'testuser@auspost.com');
            insert docSignRecipEmail;
            system.assert(docSignRecipEmail.Id != null);

            //Update DocuSign Recipients
            docSignRecipEmail.Apttus_DocuApi__Email__c = 'testuser@test.com';
            update docSignRecipEmail;

            Apttus_DocuApi__DocuSignDefaultRecipient2__c updatedRecord = [SELECT Apttus_DocuApi__Email__c FROM Apttus_DocuApi__DocuSignDefaultRecipient2__c WHERE Id =:docSignRecipEmail.Id LIMIT 1];

            system.assertEquals('testuser@test.com',updatedRecord.Apttus_DocuApi__Email__c); 

            Test.StopTest();
        }
    }

    @IsTest
    static void testException() 
    {
        User user = [SELECT Id FROM User LIMIT 1];

        System.runAs(user)
        {
            Test.StartTest(); 

            try
            {
                //Fetch Agreement
                Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

                //Create DocuSign Recipients
                Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipEmail = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL, null, null, null, null, null);
                insert docSignRecipEmail;

                //Update DocuSign Recipients
                docSignRecipEmail.Apttus_DocuApi__Email__c = 'testuser@test.com';
                update docSignRecipEmail;
            }
            catch(Exception ex)
            {
                System.assert(ex.getMessage().contains('error'), ex.getMessage());            
            }

            Test.StopTest();
        }
    }
}