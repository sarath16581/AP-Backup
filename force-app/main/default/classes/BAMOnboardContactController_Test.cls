/***
 * @description
 * @author Victor Cheng
 * @date 2019-06-27
 * @group Merchant Portal
 * @changelog
 * 2019-08-12    ajudd@salesforce.com Added BAM Record Type Id conditions
 * 2020-05-25 - Nathan Franklin - added changes to support new structures
 * 2023-07-188 - Mahesh Parvathaneni - updated test test_saveProvisionRequestsCreateUser
 */
@isTest
public class BAMOnboardContactController_Test {
    static String LEGACY_ID = 'legacy';
    static String TEST_CNUMBER = '1234';

    private static Map<String, Object> makeAppStatePayload(Id applicationId,
            Id upsertRoleId, List<String> upsertEntities,
            Id destructiveRoleId, List<String> destructiveEntities
    )
    {
        Map<String, Object> appState = new Map<String, Object>();
        appState.put(BAMOnboardContactController.FIELD_ID, applicationId);

        // add the upsert
        List<Map<Object, Object>> listUpserts = new List<Map<Object, Object>>();
        if(null != upsertRoleId)
        {
            Map<Object, Object> objUpsert = new Map<Object, Object>();
            objUpsert.put(BAMOnboardContactController.FIELD_APPLICATION, applicationId);
            objUpsert.put(BAMOnboardContactController.FIELD_APPLICATION_ROLE, upsertRoleId);
            objUpsert.put(BAMOnboardContactController.FIELD_SELECTED_ENTITIES, upsertEntities);
            listUpserts.add(objUpsert);
        }
        appState.put(BAMOnboardContactController.FIELD_UPSERT, listUpserts);

        // add the destructive
        List<Map<Object, Object>> listDestructive = new List<Map<Object, Object>>();
        if(null != destructiveRoleId)
        {
            Map<Object, Object> objDestructive = new Map<Object, Object>();
            objDestructive.put(BAMOnboardContactController.FIELD_APPLICATION, applicationId);
            objDestructive.put(BAMOnboardContactController.FIELD_APPLICATION_ROLE, destructiveRoleId);
            objDestructive.put(BAMOnboardContactController.FIELD_SELECTED_ENTITIES, destructiveEntities);
            listDestructive.add(objDestructive);
        }
        appState.put(BAMOnboardContactController.FIELD_DESTRUCTIVE, listDestructive);

        return appState;
    }

    @istest
    static void test_deprovisionApplication()
    {
        // Create Custom Settings 
        Database.insert(new AusPostSettings__c(Name = 'BAM_PROVISION_REQUEST', URL2__c = 'dummy_URL'));
        Database.insert(new AusPostSettings__c(Name = 'BAM_DEPROVISION_REQUEST', URL2__c = 'dummy_URL'));
        BAMIntegrationUtility.testingDoNotSend = true;
        
        BAMApplication__c app = BAMTestUtility.createBamApplication('BSP1');
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


        Test.startTest();

        Map<String, Object> mapResults = BAMOnboardContactController.deprovisionApplication(testContact.Id, app.Id);
        System.debug('BAM_onboardingCmpCC_Test::test_deprovisionApplication() results = ' + mapResults);

        BAMContactApplication__c contactAppResults = [SELECT Id, Pending_Delete__c
        FROM BAMContactApplication__c
        WHERE Id =: contactApp.Id];
        System.assertEquals(true, contactAppResults.Pending_Delete__c, 'Expected Contact Application to be pending delete, instead got ' + contactAppResults);

        // delete the contact and run it again to simulate no access
        Id contactId = testContact.Id;
        delete testContact;
        mapResults = BAMOnboardContactController.deprovisionApplication(contactId, app.Id);
        String sMsg = (String) mapResults.get(BAMOnboardContactController.FIELD_MESSAGE);
        System.assertEquals(BAMOnboardContactController.MSG_NO_ACCESS, sMsg, 'Expected an error message');

        Test.stopTest();
    }


    /*
    @isTest
    static void test_sendToCamunda()
    {
        try{

            Test.startTest();

            Map<String,Object> objPayload = new Map<String, Object>();
            objPayload.put('test', 'something');

            BAMOnboardContactController.sendToCamunda(JSON.serialize(objPayload));

            Test.stopTest();
        }
        catch(Exception ex)
        {

        }
    }
    
     */

    /*
    @isTest
    static void test_NoAccessLoad()
    {
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, TEST_CNUMBER);
        insert testContact;

        // delete the contact to simulate no access
        delete testContact;

        // test results
        Test.startTest();
        Map<String, Object> mapResults = BAMOnboardContactController.loadInitialState(testContact.Id);
        System.debug('BAM_onboardingCmpCC_Test::test_NoAccessLoad() results = ' + mapResults);

        String sMsg = (String) mapResults.get(BAMOnboardContactController.FIELD_MESSAGE);
        System.assertEquals(BAMOnboardContactController.MSG_NO_ACCESS, sMsg, 'Expected an error message');

        mapResults = BAMOnboardContactController.saveProvisionRequests(testContact.Id, new List<Map<String, Object>> ());
        sMsg = (String) mapResults.get(BAMOnboardContactController.FIELD_MESSAGE);
        System.assertEquals(BAMOnboardContactController.MSG_NO_ACCESS, sMsg, 'Expected an error message');
        Test.stopTest();
    }*/

    @isTest
    static void test_loadInitialState()
    {
        BAMApplication__c app = BAMTestUtility.createBamApplication('BSP1');
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

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        // create an External Onboarding Request
        BAMExternalOnboardingRequest__c extObReq = new BAMExternalOnboardingRequest__c();
        extObReq.Contact__c = testContact.Id;
        extObReq.Contact_Application__c = contactApp.Id;
        extObReq.Status__c = 'Pending';
        extObReq.RecordTypeId = bamExtObRTId;
        insert extObReq;

        // test results
        Test.startTest();
        Map<String, Object> mapResults = BAMOnboardContactController.loadInitialState(testContact.Id);

        System.debug('BAM_onboardingCmpCC_Test::test_loadInitialState() results = ' + mapResults);

        Contact contactResult = (Contact) mapResults.get(BAMOnboardContactController.FIELD_CONTACT);
        System.assertEquals(testContact.Id, contactResult.Id, 'Expected contact to be returned, result = ' + contactResult);

        Map<String, BAMContactApplication__c> mapRequests = (Map<String, BAMContactApplication__c>) mapResults.get(BAMOnboardContactController.FIELD_CONTACT_APPLICATIONS);
        System.assertEquals(1, mapRequests.values().size(), 'Expected 1 contact application, result = ' + mapResults);
        System.assertEquals(1, mapRequests.values()[0].BAM_External_Onboarding_Requests__r.size(), 'Expected 1 external onboarding request, result = ' + mapResults);


        Test.stopTest();
    }


    @isTest
    static void test_saveProvisionRequestsCreateUser() {
        // Create Custom Settings 
        Database.insert(new AusPostSettings__c(Name = 'BAM_PROVISION_REQUEST', URL2__c = 'dummy_URL'));
        Database.insert(new AusPostSettings__c(Name = 'BAM_DEPROVISION_REQUEST', URL2__c = 'dummy_URL'));
        BAMIntegrationUtility.testingDoNotSend = true;
        
        BAMApplication__c app = BAMTestUtility.createBamApplication('BSP1');
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


        Billing_Account__c testBillingAccount = BAMTestUtility.createTestBillingAccount(testAccount.Id, 'Test Billing Account 1');
        Billing_Account__c testBillingAccount2 =BAMTestUtility.createTestBillingAccount(testAccount.Id, 'Test Billing Account 2');
        //testBillingAccount2.Name = 'Test Billing Account 2';
        insert new List<Billing_Account__c> {testBillingAccount, testBillingAccount2};


        // SIMULATE Client Side send
        List<Map<String, Object>> pageState = new List<Map<String, Object>> ();


        // billing accounts
        List<String> listUpsertEntities = new List<String>();
        listUpsertEntities.add(testBillingAccount.Id);
        listUpsertEntities.add(testBillingAccount2.Id);

        Map<String, Object> appStateTest1 = makeAppStatePayload(app.Id, appRole.Id, listUpsertEntities, null, null);
        pageState.add(appStateTest1);

        // test results
        Test.startTest();
        Map<String, Object> mapResults = BAMOnboardContactController.saveProvisionRequests(testContact.Id, pageState, testBillingAccount.Id);
        System.debug('BAM_onboardingCmpCC_Test::test_saveProvisionRequestsCreateUser() results = ' + mapResults);
        Contact contactResult = (Contact) mapResults.get(BAMOnboardContactController.FIELD_CONTACT);
        System.assertEquals(testContact.Id, contactResult.Id, 'Expected contact to be returned, result = ' + contactResult);

        Id contactId = testContact.Id;
        Id applicationId = app.Id;
        Id billingAccountId = testBillingAccount.Id;

        // TEST 1: Add a role with 2 billing accounts
        List<User> addedUsers = [
                SELECT Id
                FROM User
                WHERE ContactId =: contactId
                LIMIT 1
        ];
        System.assertEquals(1, addedUsers.size(), 'SAVE TEST 1:Expected a User to be created, result = ' + addedUsers);

        List<BAMContactApplication__c> addedContactApplications = [
                SELECT Id, Application__c
                FROM BAMContactApplication__c
                WHERE Contact__c = :contactId
                AND Application__c = :applicationId
        ];
        System.assertEquals(1, addedContactApplications.size(), 'SAVE TEST 1:Expected a contact application to be added, result = ' + addedContactApplications);
        List<BAMContactRole__c> addedContactRoles = [
                SELECT Id,
                (
                        SELECT Id, BillingAccount__c
                        FROM LinkedEntities__r
                )
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__c = :contactId
                AND ContactApplication__r.Application__c = :applicationId
        ];
        System.assertEquals(1, addedContactRoles.size(), 'SAVE TEST 1:Expected a contact role to be added, result = ' + addedContactRoles);
        BAMContactRole__c addedContactRole = addedContactRoles[0];
        System.assertEquals(2, addedContactRole.LinkedEntities__r.size(), 'SAVE TEST 1:Expected 2 linked entities to be added, result = ' + addedContactRole.LinkedEntities__r);
        // END TEST 1

        // TEST 2: save again, removing one Billing Account
        Map<String, Object> appStateTest2 = makeAppStatePayload(app.Id, appRole.Id, new List<String> {testBillingAccount.Id}, null, null);
        pageState = new List<Map<String, Object>> {appStateTest2};

        BAMOnboardContactController.saveProvisionRequests(testContact.Id, pageState, testBillingAccount.Id);
        addedContactRoles = [
                SELECT Id,
                (
                        SELECT Id, BillingAccount__c, Pending_Delete__c
                        FROM LinkedEntities__r
                        WHERE Pending_Delete__c = false
                )
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__c = :contactId
                AND ContactApplication__r.Application__c = :applicationId
        ];
        System.assertEquals(1, addedContactRoles.size(), 'SAVE TEST 2:Expected a contact role to be added, result = ' + addedContactRoles);
        addedContactRole = addedContactRoles[0];
        System.assertEquals(1, addedContactRole.LinkedEntities__r.size(), 'SAVE TEST 2:Expected 1 linked entities to be left, result = ' + addedContactRole.LinkedEntities__r);
        // END TEST 2


        // TEST 3: save again, removing the last created role
        Map<String, Object> appStateTest3 = makeAppStatePayload(app.Id, null, null, appRole.Id, new List<String> {testBillingAccount.Id});
        pageState = new List<Map<String, Object>> {appStateTest3};
        Map<String, Object> mapDestructive = BAMOnboardContactController.saveProvisionRequests(testContact.Id, pageState, testBillingAccount.Id);
        List<BAMContactRole__c> resultContactRoles = [
                SELECT Id,
                (
                        SELECT Id, BillingAccount__c
                        FROM LinkedEntities__r
                        WHERE BillingAccount__c =: billingAccountId
                )
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__c = :contactId
                AND ContactApplication__r.Application__c = :applicationId
        ];
        System.assertEquals(0, resultContactRoles.size(), 'SAVE TEST 3:Expected Contact roles to be removed, result = ' + resultContactRoles);

		// TEST 4: save again, adding a filter to billing account and selected billing accounts not match with the filter
		// exception to be thrown
		app.BillingAccountFilter__c = '{"Source_System__c": "TEAM","Credit_Status__c": false}';
		update app;

		Map<String, Object> appStateTest4 = makeAppStatePayload(app.Id, appRole.Id, new List<String> {testBillingAccount.Id}, null, null);
        pageState = new List<Map<String, Object>> {appStateTest4};
		Boolean exceptionThrown = false;
		try{
			BAMOnboardContactController.saveProvisionRequests(testContact.Id, pageState, testBillingAccount.Id);
		} catch(Exception ex) {
			exceptionThrown = true;
		}
		System.assertEquals(true, exceptionThrown, 'There should be an exception thrown');

        Test.stopTest();
    }

    @isTest
    static void test_saveProvisionRequestRemoveAccess()
    {
        // Create Custom Settings 
        Database.insert(new AusPostSettings__c(Name = 'BAM_PROVISION_REQUEST', URL2__c = 'dummy_URL'));
        Database.insert(new AusPostSettings__c(Name = 'BAM_DEPROVISION_REQUEST', URL2__c = 'dummy_URL'));
        BAMIntegrationUtility.testingDoNotSend = true;
        
        BAMApplication__c app = BAMTestUtility.createBamApplication('BSP1');
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


        Billing_Account__c testBillingAccount = BAMTestUtility.createTestBillingAccount(testAccount.Id, 'Test Billing Account 1');
        Billing_Account__c testBillingAccount2 =BAMTestUtility.createTestBillingAccount(testAccount.Id, 'Test Billing Account 2');
        insert new List<Billing_Account__c> {testBillingAccount, testBillingAccount2};


        // SIMULATE Client Side send
        List<Map<String, Object>> pageState = new List<Map<String, Object>> ();

        // billing accounts
        List<String> listUpsertEntities = new List<String>();
        listUpsertEntities.add(testBillingAccount.Id);
        listUpsertEntities.add(testBillingAccount2.Id);

        Map<String, Object> appStateAdd = makeAppStatePayload(app.Id, appRole.Id, listUpsertEntities, null, null);
        pageState.add(appStateAdd);


        // test results
        Test.startTest();
        Id contactId = testContact.Id;
        Id roleId = appRole.Id;

        Map<String, Object> mapAdd = BAMOnboardContactController.saveProvisionRequests(testContact.Id, pageState, testBillingAccount.Id);
        System.debug('BAM_onboardingCmpCC_Test::test_saveProvisionRequestRemoveAccess() Add results = ' + mapAdd);
        Contact contactResult = (Contact) mapAdd.get(BAMOnboardContactController.FIELD_CONTACT);
        System.assertEquals(testContact.Id, contactResult.Id, 'Expected contact to be returned, result = ' + contactResult);

        // set it to active
        List<BAMContactRole__c> rolesAdded = [SELECT Id
        FROM BAMContactRole__c
        WHERE ApplicationRole__c =:roleId
        ];
        rolesAdded [0].Status__c = BAMOnboardContactController.STATUS_ACTIVE;
        update rolesAdded;

        Map<String, Object> appStateRemove= makeAppStatePayload(app.Id, null, null, appRole.Id, listUpsertEntities);
        pageState.clear();
        pageState.add(appStateRemove);
        Map<String, Object> mapRemove = BAMOnboardContactController.saveProvisionRequests(testContact.Id, pageState, testBillingAccount.Id);
        System.debug('BAM_onboardingCmpCC_Test::test_saveProvisionRequestRemoveAccess() Remove results = ' + mapRemove);


        List<BAMContactRole__c> roleResults = [
                SELECT Id, Status__c, Pending_Delete__c
                FROM BAMContactRole__c
                WHERE ContactApplication__r.Contact__c = :contactId
                AND ApplicationRole__c =:roleId
        ];
        System.debug('resulting Roles:' + roleResults);
        System.assertEquals(true, roleResults[0].Pending_Delete__c, 'Expected to be pending delete');

        Test.stopTest();
    }

}