/* @author Mav3rik
 * @date 2020-10-27
 * @group Lead
 * @tag Lead
 * @domain Core
 * @description Test class for LPOLeadController
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
@IsTest
public class LPOLeadController_Test {

    /**
     * Data Preparation for Creating a Partner Community User
     */
    static User createPartnerCommunityUser(String alias, String email, String username, String communityNickname) {
        // Create community user account
        Account acc = new Account(Name='TestP', OwnerId = UserInfo.getUserId());
        insert acc;

        // Create community user contact
        Contact communityUserContact = new Contact(
            FirstName = 'Test',
            LastName = 'P',
            AccountId = acc.Id,
            Email = email
        );
        insert communityUserContact;

        // Get user profile
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User' LIMIT 1];
        // Create the user
        User newUser = new User(
            Alias = alias, Email = email, 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = userProfile.Id, 
            TimeZoneSidKey='Australia/Sydney', UserName = userName,
            CommunityNickname=communityNickname, EmployeeNumber='1234567',
            ContactId = communityUserContact.Id
        );
        insert newUser;
        return newUser;
    }

    /**
     * Test when all validations passed and inserts the Lead Record
     */
    @IsTest
    static void test_saveLead_positive() {
        Lead givenLead = new Lead();
        givenLead.FirstName = 'John';
        givenLead.LastName = 'Smith';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';

        Test.startTest();
        String leadRecordId = LPOLeadController.saveLead(givenLead);
        Test.stopTest();

        System.assert(leadRecordId != null, 'The record should be inserted and returns a Lead Record ID');
    }

    /**
     * Test when there is an exception and the Lead Record is not inserted
     */
    @IsTest
    static void test_saveLead_negative() {
        Lead givenLead = new Lead();
        givenLead.FirstName = '===================================================================================================Some string which is longer than 255 characters================================================================================================================';
        givenLead.LastName = '===================================================================================================Some string which is longer than 255 characters================================================================================================================';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';

        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            String leadRecordId = LPOLeadController.saveLead(givenLead);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test when there is a Lead Duplicate
     */
    @IsTest
    static void test_saveLead_duplicate() {
        User partnerCommunityUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p');

        Contact givenContact = new Contact();
        givenContact.FirstName = 'John';
        givenContact.LastName = 'Smith';
        givenContact.Email = 'john.smith@example.com';
        givenContact.Phone = '5554443332';
        insert givenContact;

        Lead givenLead = new Lead();
        givenLead.FirstName = 'John';
        givenLead.LastName = 'Smith';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';

        Test.startTest();
        String leadRecordId = LPOLeadController.saveLead(givenLead);
        Test.stopTest();

        System.assert(leadRecordId != null, 'The record should be inserted and returns a Lead Record ID despite being a duplicate');
    }

    /**
     * Test when the saveLead input is null
     */
    @IsTest
    static void test_saveLead_null() {
        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            String leadRecordId = LPOLeadController.saveLead(null);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test when the saveLead input is empty
     */
    @IsTest
    static void test_saveLead_empty() {
        Lead emptyLead = new Lead();

        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            String leadRecordId = LPOLeadController.saveLead(emptyLead);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test when all validations passed and the Lead Record is updated
     */
    @IsTest
    static void test_updateLead_positive() {
        Lead givenLead = new Lead();
        givenLead.FirstName = 'John';
        givenLead.LastName = 'Smith';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';
        insert givenLead;

        Lead leadToUpdate = new Lead();
        leadToUpdate.Id = givenLead.Id;
        leadToUpdate.FirstName = 'Jane';
        leadToUpdate.LastName = 'Doe';
        leadToUpdate.Email = 'jane.doe@example.com';
        leadToUpdate.Phone = '1112223334';

        Test.startTest();
        Lead actualLead = LPOLeadController.updateLead(leadToUpdate);
        Test.stopTest();

        System.assertEquals(actualLead.FirstName, leadToUpdate.FirstName, 'The correct FirstName should be the new value');
        System.assertEquals(actualLead.LastName, leadToUpdate.LastName, 'The correct LastName should be the new value');
        System.assertEquals(actualLead.Email, leadToUpdate.Email, 'The correct Email should be the new value');
        System.assertEquals(actualLead.Phone, leadToUpdate.Phone, 'The correct Phone should be the new value');
    }

    /**
     * Test when there is an exception and the Lead Record is not updated
     */
    @IsTest
    static void test_updateLead_negative() {
        Lead givenLead = new Lead();
        givenLead.FirstName = 'John';
        givenLead.LastName = 'Smith';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';
        insert givenLead;

        Lead leadToUpdate = new Lead();
        leadToUpdate.Id = givenLead.Id;
        leadToUpdate.FirstName = '===================================================================================================Some string which is longer than 255 characters================================================================================================================';
        leadToUpdate.LastName = '===================================================================================================Some string which is longer than 255 characters================================================================================================================';
        leadToUpdate.Email = 'jane.doe@example.com';
        leadToUpdate.Phone = '1112223334';

        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            Lead actualLead = LPOLeadController.updateLead(leadToUpdate);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test when the updateLead input is null
     */
    @IsTest
    static void test_updateLead_null() {
        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            Lead actualLead = LPOLeadController.updateLead(null);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test when the updateLead input is empty
     */
    @IsTest
    static void test_updateLead_empty() {
        Lead emptyLead = new Lead();
        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            Lead actualLead = LPOLeadController.updateLead(emptyLead);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * returns record according to idlist
     */
    @IsTest
    static void test_getDuplicateRecordDetails_lead_success() {
        Lead givenLead = new Lead();
        givenLead.FirstName = 'John';
        givenLead.LastName = 'Smith';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';
        insert givenLead;
        List<SObject> results = new List<Sobject>();

        Test.startTest();
        results = LPOLeadController.getDuplicateRecordDetails(new List<Id>{givenLead.Id});
        Test.stopTest();

        System.assert(results.size() != 0, 'There should one lead in the list');
    }
    @IsTest
    static void test_getDuplicateRecordDetails_contact_success() {
        Contact givenContact = new Contact();
        givenContact.FirstName = 'John';
        givenContact.LastName = 'Smith';
        givenContact.Email = 'john.smith@example.com';
        givenContact.Phone = '5554443332';
        insert givenContact;
        List<SObject> results = new List<Sobject>();

        Test.startTest();
        results = LPOLeadController.getDuplicateRecordDetails(new List<Id>{givenContact.Id});
        Test.stopTest();

        System.assert(results.size() != 0, 'There should one contact in the list');
    }
    @IsTest
    static void test_getDuplicateRecordDetails_account_success() {
        Account givenAccount = new Account();
        givenAccount.Name = 'John Smith';
        insert givenAccount;
        List<SObject> results = new List<Sobject>();

        Test.startTest();
        results = LPOLeadController.getDuplicateRecordDetails(new List<Id>{givenAccount.Id});
        Test.stopTest();

        System.assert(results.size() != 0, 'There should one account in the list');
    }

    /**
     * test if exceptions is returned when duplicates are detected
     */
    @IsTest
    static void test_checkDuplicates_some() {
        User partnerCommunityUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p');

        Contact givenContact = new Contact();
        givenContact.FirstName = 'John';
        givenContact.LastName = 'Smith';
        givenContact.Email = 'john.smith@example.com';
        givenContact.Phone = '5554443332';
        givenContact.MailingStreet = 'Smith Street';
        givenContact.MailingPostalCode = '1234';

        Lead givenLead = new Lead();
        givenLead.FirstName = 'John';
        givenLead.LastName = 'Smith';
        givenLead.Email = 'john.smith@example.com';
        givenLead.Phone = '5554443332';

        Test.startTest();
        Boolean isExceptionFound = false;
        System.runAs(partnerCommunityUser) {
            insert givenContact;
            try {
                LPOLeadController.checkDuplicates(givenLead);
            } catch(Exception e) {
                isExceptionFound = true;
            }
        }
        Test.stopTest();
        
        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test if true is returned when there are no duplciates found
     */
    @IsTest
    static void test_checkDuplicates_none() {
        User partnerCommunityUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p');

        Contact givenContact = new Contact();
        givenContact.FirstName = 'John';
        givenContact.LastName = 'Smith';
        givenContact.Email = 'john.Smith@example.com';
        givenContact.Phone = '5554443332';
        givenContact.MailingStreet = 'Smith Street';
        givenContact.MailingPostalCode = '1234';

        Lead givenLead = new Lead();
        givenLead.FirstName = 'Mary';
        givenLead.LastName = 'Sue';
        givenLead.Email = 'mary.sue@example.com';
        givenLead.Phone = '1234567890';

        Test.startTest();
        Boolean success;
        System.runAs(partnerCommunityUser) {
            insert givenContact;
            success = LPOLeadController.checkDuplicates(givenLead);
        }
        Test.stopTest();

        System.assertEquals(true, success);
    }
}