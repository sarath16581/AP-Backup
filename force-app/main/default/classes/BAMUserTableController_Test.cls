@isTest
public class BAMUserTableController_Test {

    private static String LEGACY_ID = '1111';
    private static String TEST_CNUMBER = '1234';

    @isTest
    static void test_NoBAMAccess()
    {
        // create an account
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, TEST_CNUMBER);
        insert testContact;

        User testUser = BAMTestUtility.createBusinessPortalUser(testContact,BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME);
        insert testUser;

        Test.startTest();
        System.runAs(testUser)
        {
            Map<String, Object> mapInit = BAMUserTableController.retrieveUserDetails();
            Boolean isBamUser = (Boolean) mapInit.get(BAMUserTableController.FIELD_IS_BAM_USER);
            System.assertEquals(false, isBamUser, 'Expected to be a No Access, instead got ' + isBamUser);
        }
        Test.stopTest();
    }


    @isTest
    static void test_BAMAccess()
    {
        BAMApplication__c app = BAMTestUtility.createBamApplication(BAMUserTableController.ACCESS_MANAGEMENT);
        app.appKey__c = BAMUserTableController.ACCESS_MANAGEMENT_APP_KEY;
        insert app;
        // create an application role
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
        insert appRole;
        // create an account
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        // create a Application-Product-Asset
        Asset testAsset = BAMTestUtility.createAsset(testAccount.Id, app.Product__c, true);
        insert testAsset;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, TEST_CNUMBER);
        insert testContact;

        // create the junction Contact-Application
        BAMContactApplication__c contactApp = BAMTestUtility.createTestContactApplication(testContact.Id, app.Id);
        insert contactApp;

        // create the contact-role
        BAMContactRole__c contactRole = new BAMContactRole__c();
        contactRole.ContactApplication__c = contactApp.Id;
        contactRole.ApplicationRole__c = appRole.Id;
        contactRole.Status__c = BAMUserTableController.STATUS_ACTIVE;
        insert contactRole;

        User testUser = BAMTestUtility.createBusinessPortalUser(testContact,BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME);
        insert testUser;

        Test.startTest();

        System.runAs(testUser)
        {
            Map<String, Object> mapInit = BAMUserTableController.retrieveUserDetails();
            Boolean isBamUser = (Boolean) mapInit.get(BAMUserTableController.FIELD_IS_BAM_USER);
            System.assertEquals(true, isBamUser, 'Expected to be a BAM User, instead got ' + mapInit);
        }
        Test.stopTest();
    }

    @isTest
    public static void test_initSearch()
    {
        BAMApplication__c app = BAMTestUtility.createBamApplication(BAMUserTableController.ACCESS_MANAGEMENT);
        insert app;
        // create an application role
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
        insert appRole;
        // create an account
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        // create a Application-Product-Asset
        Asset testAsset = BAMTestUtility.createAsset(testAccount.Id, app.Product__c, true);
        insert testAsset;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, TEST_CNUMBER);
        insert testContact;

        // create the junction Contact-Application
        BAMContactApplication__c contactApp = new BAMContactApplication__c();
        contactApp.Contact__c = testContact.Id;
        contactApp.Application__c = app.Id;
        insert contactApp;

        User testUser = BAMTestUtility.createBusinessPortalUser(testContact,BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME);
        insert testUser;

        Test.startTest();

        System.runAs(testUser)
        {


            Map<String, Object> mapResults = BAMUserTableController.searchContactApplicationData(testAccount.Id, 1, 1, '' , true);
            //Contact objContact = (Contact) mapResults.get(BAMUserTableController.FIELD_CONTACT);
            //System.assertEquals(testContact.Id, objContact.Id, 'Expected test Contact Id in search results, instead got ' + objContact.Id);

            List<Map<String, Object>> listSearchResults = (List<Map<String, Object>>) mapResults.get(BAMUserTableController.FIELD_SEARCH_RESULTS);
            System.assertEquals(1, listSearchResults.size(), 'Expected 1 Contact Application, instead, got ' + listSearchResults);

            // search again with parameters
            mapResults = BAMUserTableController.searchContactApplicationData(testAccount.Id, 1, 1, 'abcd' , false);
            listSearchResults = (List<Map<String, Object>>) mapResults.get(BAMUserTableController.FIELD_SEARCH_RESULTS);
            System.assertEquals(0, listSearchResults.size(), 'Expected to return 0 results, instead, got ' + listSearchResults);
        }

        Test.stopTest();
    }


    @isTest
    public static void test_activateUser()
    {
        BAMApplication__c app = BAMTestUtility.createBamApplication(BAMUserTableController.ACCESS_MANAGEMENT);
        app.appKey__c = BAMUserTableController.ACCESS_MANAGEMENT_APP_KEY;
        insert app;
        // create an application role
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
        insert appRole;
        // create an account
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        // create a Application-Product-Asset
        Asset testAsset = BAMTestUtility.createAsset(testAccount.Id, app.Product__c, true);
        insert testAsset;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, TEST_CNUMBER);
        insert testContact;

        // create the junction Contact-Application
        BAMContactApplication__c contactApp = BAMTestUtility.createTestContactApplication(testContact.Id, app.Id);
        insert contactApp;

        BAMContactRole__c contactRole = BAMTestUtility.createTestContactRole(contactApp.Id, appRole.Id);
        insert contactRole;

        // insert a non-accessible contact
        Account account2 = BAMTestUtility.createTestAccount(LEGACY_ID);
        account2.Name = 'no access';
        insert account2;
        Contact contactNoAccess = BAMTestUtility.createTestContact(account2.Id, TEST_CNUMBER);
        contactNoAccess.FirstName += '2';
        contactNoAccess.LastName += '2';
        contactNoAccess.Email = 'test2@test.com';
        insert contactNoAccess;

        User testUser = BAMTestUtility.createBusinessPortalUser(testContact,BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME);
        insert testUser;

        Test.startTest();

        System.runAs(testUser)
        {
            Id contactId = testContact.Id;

            // Create Custom Settings 
            Database.insert(new AusPostSettings__c(Name = 'BAM_PROVISION_REQUEST', URL2__c = 'dummy_URL'));
            Database.insert(new AusPostSettings__c(Name = 'BAM_DEPROVISION_REQUEST', URL2__c = 'dummy_URL'));
            BAMIntegrationUtility.testingDoNotSend = true;

            // deactivate
            Map<String, Object> mapResults = BAMUserTableController.deactivateContact(contactId);
            String sResult = (String) mapResults.get(BAMUserTableController.FIELD_RESULT);
            System.assertEquals(BAMUserTableController.RESULT_OK, sResult, 'Expected deactivation ok, got ' + mapResults);

            List<Contact> contacts = [Select Id, Status__c FROM Contact WHERE Id=:contactId];
            Contact contactResult = contacts[0];
            System.assertEquals(BAMUserTableController.STATUS_INACTIVE, contactResult.Status__c, 'Expected Contact status inactive, got ' + contactResult);

            // reactivate
            mapResults = BAMUserTableController.reactivateContact(contactId);
            contacts = [Select Id, Status__c FROM Contact WHERE Id=:contactId];
            contactResult = contacts[0];
            System.assertEquals(BAMUserTableController.STATUS_ACTIVE, contactResult.Status__c, 'Expected Contact status inactive, got ' + contactResult);

            // simulate no access
            mapResults = BAMUserTableController.deactivateContact(contactNoAccess.Id);
            sResult = (String) mapResults.get(BAMUserTableController.FIELD_RESULT);
            System.assertEquals(BAMUserTableController.RESULT_ERROR, sResult, 'Expected deactivation ERROR, got ' + mapResults);
            mapResults = BAMUserTableController.reactivateContact(contactNoAccess.Id);
            sResult = (String) mapResults.get(BAMUserTableController.FIELD_RESULT);
            System.assertEquals(BAMUserTableController.RESULT_ERROR, sResult, 'Expected reactivation ERROR, got ' + mapResults);
        }

        Test.stopTest();
    }

}