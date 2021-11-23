/*
 * Class to test
 * AJ 16 Aug 2019 - Set email on second contact create to dummy email2 in various test to prevent duplicate rule error
 */
@isTest
public class BAMUserController_Test {

    private static String DUMMY_CNUMBER = 'c1234';
    private static String DUMMY_FIRST_NAME = 'DummyFirstName';
    private static String DUMMY_LAST_NAME = 'DummyLastName';
    private static String DUMMY_EMAIL = 'dummy@test.email';
    private static String DUMMY_EMAIL2 = 'dummy2@test.email';

    @TestSetup
    static void makeCustomSettingAndUser(){
        User u = TestDataProvider.createTestUsers();
        u.Username = System.currentTimeMillis() + u.Username;
        insert u;

        MerchantPortalSettings__c setting = new MerchantPortalSettings__c();
        setting.ContactOwnerUsername__c = u.Username;
        insert setting;
    }

    @isTest
    static void test_savePrimaryBillingAccount(){
        // // create the test setup
        BAMApplication__c testApp = BAMTestUtility.createBamApplication('AJ Org');
        insert testApp;

        Account testAccount = BAMTestUtility.createTestAccount('1234');
        insert testAccount;

        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, '');
        insert testContact;

        Billing_Account__c testBillingAccount = BAMTestUtility.createTestBillingAccount(testAccount.Id, 'Kwik-E-Mart');
        insert testBillingAccount;

        
        Boolean bResult = BAMUserController.savePrimaryBillingAccount(testBillingAccount.Id, testContact.Id);
        // querying athe contact record
        Contact queriedCon = [SELECT Id, BillingAccount__c FROM Contact WHERE ID =: testContact.Id];
        System.assertEquals(true, bResult, 'savePrimaryBillingAccount() Expected true, got: ' + bResult);
        // assert that the test billing account was set as the primary billing accoutn for the test contact
        System.assertEquals(testBillingAccount.Id, queriedCon.BillingAccount__c);
    }

    @isTest
    static void test_retrieveContact() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        String sResult = BAMUserController.retrieveContactData(contactId);
        System.assertNotEquals('', sResult, 'retrieveContactData() Expected Contact JSON returned, got: ' + sResult);
        Contact parsedContact = (Contact) JSON.deserialize(sResult, Contact.class);
        System.assertEquals(contactId, parsedContact.Id);
    }

    @isTest 
    static void test_getContactRolesForContact() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conRoleId = recordIdMap.get('conrole'); 
        List<BAMContactRole__c> contactRoles = BAMUserController.getContactRolesForContact(contactId);
        System.assertEquals(contactRoles.size(), 1);
        System.assertEquals(conRoleId, contactRoles[0].Id);
    }

    @isTest 
    static void test_getLinkedEntitiesForContactRoles() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id conRoleId = recordIdMap.get('conrole'); 
        //Get contact role Id
        Id billingAccountLinkedEntityId = recordIdMap.get('billingaccle');
        List<BAMLinkedEntity__c> billingAccountLinkedEntities = BAMUserController.getLinkedEntitiesForContactRoles(new Set<Id>{conRoleId});
        System.assertEquals(billingAccountLinkedEntities.size(), 1);
        System.assertEquals(billingAccountLinkedEntityId, billingAccountLinkedEntities[0].Id);
    }

    @isTest 
    static void test_getExistingAccessAndRolesWithLinkedEntitiesForContact() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conRoleId = recordIdMap.get('conrole'); 
        Map<Id,BAMUserController.BAMDataWrapper> contactRoleMap = BAMUserController.getExistingAccessAndRolesWithLinkedEntitiesForContact(contactId);
        System.assertEquals(contactRoleMap.size(), 1);
        BAMContactRole__c conRole = (BAMContactRole__c) contactRoleMap.get(conRoleId).record;
        System.assertEquals(conRoleId, conRole.Id);
    }

    @isTest 
    static void test_getActiveAccessAndRolesWithLinkedEntitiesForContact() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conRoleId = recordIdMap.get('conrole'); 
        Map<Id,BAMUserController.BAMDataWrapper> contactRoleMap = BAMUserController.getActiveAccessAndRolesWithLinkedEntitiesForContact(contactId);
        System.assertEquals(contactRoleMap.size(), 1);
        BAMContactRole__c conRole = (BAMContactRole__c) contactRoleMap.get(conRoleId).record;
        System.assertEquals(conRoleId, conRole.Id);
        System.assertEquals('Active', conRole.Status__c);
    }

    @isTest 
    static void test_retrieveUserInformation() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        // get org oid 
        Id orgId = recordIdMap.get('acc');
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conRoleId = recordIdMap.get('conrole'); 
        // Get portal user Id
        Id businessPortalUserId = recordIdMap.get('User');
        User businessPortalUser = [SELECT Id FROM User WHERE Id =: businessPortalUserId];
        System.runAs(businessPortalUser) {
            String sResult = BAMUserController.retrieveUserInformation();
            System.assertNotEquals('', sResult, 'retrieveUserInformation() Expected user data JSON returned, got: ' + sResult);
            BAMUserController.UserDataWrapper userData = (BAMUserController.UserDataWrapper) JSON.deserialize(sResult, BAMUserController.UserDataWrapper.class);
            System.assertEquals(orgId, userData.orgId);
            System.assertEquals(contactId, userData.loggedInUserContactId);
            System.assertEquals(false, userData.isBAMUser);
        }
    }

    @isTest
    static void test_retrieveSuperAdmins() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        Id orgId = recordIdMap.get('acc');
        Id contactId = recordIdMap.get('con');

        // creating BAM User who we will run this test as
        Contact bamUserContact = BAMTestUtility.createTestContact(orgId, DUMMY_CNUMBER);
        bamUserContact.Email = DUMMY_EMAIL2;
        bamUserContact.FirstName = 'Jammy Sim';
        insert bamUserContact;

        BAMApplication__c bamApp = BAMTestUtility.createBamApplication('BAM');
        bamApp.appKey__c ='BAM';
        insert bamApp;

        Asset prod = BAMTestUtility.createAsset(orgId, bamApp.Product__c, true);
        insert prod;

        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(bamApp);
        appRole.Role__c = BAMUserUtility.ACCESS_MANAGEMENT_SUPER_ADMIN;
        insert appRole;

        BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(bamUserContact.Id, bamApp.Id);
        insert conApp;

        BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;

        User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        portalUser.Username = System.currentTimeMillis() + portalUser.Username;
        insert portalUser;

        // mock page state
        List<Map<String, Object>> mockPageState = new List<Map<String, Object>>();

        // creating different org
        Account testAccount = BAMTestUtility.createTestAccount('1234');
        insert testAccount;




        // Get portal user Id
        Id businessPortalUserId = recordIdMap.get('User');
        User businessPortalUser = [SELECT Id FROM User WHERE Id =: businessPortalUserId];
        System.runAs(businessPortalUser) {
            String sResult = BAMUserController.retrieveSuperAdmins(orgId);
            System.assertNotEquals('', sResult, 'retrieveUserInformation() Expected user data JSON returned, got: ' + sResult);
            List<BAMUserController.AdminDataWrapper> admins = (List<BAMUserController.AdminDataWrapper>) JSON.deserialize(sResult, List<BAMUserController.AdminDataWrapper>.class);
            System.assertNotEquals(0, admins.size());
        }
    }

    @isTest 
    static void test_retrieveContactApplicationsWithLatestExternalOnboardingRequests() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conAppId = recordIdMap.get('conapp');

        String sResult = BAMUserController.retrieveContactApplicationsWithLatestExternalOnboardingRequests(contactId);
        System.assertNotEquals('', sResult, 'retrieveContactApplicationsWithLatestExternalOnboardingRequests() Expected Contact Aplications JSON returned, got: ' + sResult);
        List<BAMContactApplication__c> contactApps = (List<BAMContactApplication__c>) JSON.deserialize(sResult, List<BAMContactApplication__c>.class);
        System.assertEquals(contactApps.size(), 1);
        System.assertEquals(conAppId, contactApps[0].Id);
    }

    @isTest 
    static void test_retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conAppId = recordIdMap.get('conapp');

        String sResult = BAMUserController.retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests(contactId);
        System.assertNotEquals('', sResult, 'retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests() Expected Contact Aplications JSON returned, got: ' + sResult);
        List<BAMContactApplication__c> contactApps = (List<BAMContactApplication__c>) JSON.deserialize(sResult, List<BAMContactApplication__c>.class);
        System.assertEquals(contactApps.size(), 1);
        System.assertEquals(conAppId, contactApps[0].Id);
        System.assertEquals('Active', contactApps[0].Status__c);
    }

    @isTest 
    static void test_retrieveAplicationData() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        //Get contact Id
        Id orgId = recordIdMap.get('acc'); 
        //Get contact role Id
        Id billingAccId = recordIdMap.get('ba');
        // get Applicaiton Id 
        Id appId = recordIdMap.get('app');
        // get Applicaiton Role Id 
        Id appRoleId = recordIdMap.get('approle');

        String sResult = BAMUserController.retrieveAplicationData(orgId);
        System.assertNotEquals('', sResult, 'retrieveAplicationData() Expected Aplication data JSON returned, got: ' + sResult);
        BAMUserController.ApplicationDataWrapper appData = (BAMUserController.ApplicationDataWrapper) JSON.deserialize(sResult, BAMUserController.ApplicationDataWrapper.class);
        // assert correct billing account is populated in application data wrapper
        System.assertEquals(1, appData.billingAccounts.size());
        System.assertEquals(billingAccId, appData.billingAccounts[0].Id);
        // assert correct app with the correct application role is included in the app data wrapper
        System.assertEquals(1, appData.applicationsWithRoles.size());
        System.assertEquals(appId, appData.applicationsWithRoles[0].Id);
        System.assertEquals(1, appData.applicationsWithRoles[0].ApplicationRoles__r.size());
        System.assertEquals(appRoleId, appData.applicationsWithRoles[0].ApplicationRoles__r[0].Id);
    }


    @isTest
    static void test_saveAccessChanges_throwsExceptionIfRunByNonBamUser() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        Id orgId = recordIdMap.get('acc'); 
        Id contactId = recordIdMap.get('con');
        // creating User who we will run this test as (this user is not given BAM access for this test)
        Contact bamUserContact = BAMTestUtility.createTestContact(orgId, '');
        bamUserContact.Email = DUMMY_EMAIL2;
        bamUserContact.FirstName = 'Dark Cloud';
        insert bamUserContact;
       
        User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        insert portalUser;
        
        // mock page state
        List<Map<String, Object>> mockPageState = new List<Map<String, Object>>();

        Contact testContact = [SELECT Id, FirstName, LastName, Email, AccountId, BillingAccount__c FROM Contact WHERE Id =:contactId];
        // creating contact data 
        BAMUserController.ContactDataWrapper contactData = new BAMUserController.ContactDataWrapper();
        contactData.Id = testContact.Id;

        Test.startTest();
        System.runAs(portalUser) {
            try {
                String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
                BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            } catch (AuraHandledException e) {
                System.debug(e.getMessage());
                System.debug(e.getTypeName());
                System.assert(e.getMessage().contains('You do not have access to Access Management'), 'expected error message to contain \'You do not have access to Access Management \' but got :'+e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void test_saveAccessChanges_throwsExceptionForInvalidContact() {
               //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        Id orgId = recordIdMap.get('acc'); 
        Id contactId = recordIdMap.get('con');

        // creating BAM User who we will run this test as
        Contact bamUserContact = BAMTestUtility.createTestContact(orgId, DUMMY_CNUMBER);
        bamUserContact.Email = DUMMY_EMAIL2;
        bamUserContact.FirstName = 'White Cloud';
        insert bamUserContact;

        BAMApplication__c bamApp = BAMTestUtility.createBamApplication('BAM');
        bamApp.appKey__c ='BAM';
        insert bamApp;

        Asset prod = BAMTestUtility.createAsset(orgId, bamApp.Product__c, true);
        insert prod;
        
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(bamApp);
        insert appRole;

        BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(bamUserContact.Id, bamApp.Id);
        insert conApp;
        
        BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;
       
        User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        portalUser.Username = System.currentTimeMillis() + portalUser.Username;
        insert portalUser;
        
        // mock page state
        List<Map<String, Object>> mockPageState = new List<Map<String, Object>>();
 
        // creating different org
        Account testAccount = BAMTestUtility.createTestAccount('1234');
        insert testAccount;

        Contact testContact = [SELECT Id, FirstName, LastName, Email, AccountId, BillingAccount__c FROM Contact WHERE Id =:contactId];
        // creating contact data
        BAMUserController.ContactDataWrapper contactData = new BAMUserController.ContactDataWrapper();
        contactData.Id = testContact.Id;
        contactData.FirstName = testContact.FirstName;
        contactData.LastName = testContact.LastName;
        contactData.Email = testContact.Email;
        contactData.orgId = testAccount.Id;
    
        Test.startTest();
        System.runAs(portalUser) {
            try {
                String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
                BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('You do not have access to the user you are trying to edit.'), 'expected error message to contain \'You do not have access to the user you are trying to edit.\' but got :'+e.getMessage());
            }
            // setting up an inactive contact
            contactData.orgId = orgId;
            testContact.Status__c = 'Inactive';
            update testContact;
            try {
                String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
                BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('The user you are trying to edit has been deactivated.'), 'expected error message to contain \'The user you are trying to edit has been deactivated.\' but got :'+e.getMessage());
            }

            testContact.Status__c = 'Active';
            update testContact;
            // test for when a contact with dulpicate First Name Last Name and Email exists in org
            try {
                String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
                BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('User\'s details have already been registered'), 'expected error message to contain \'User\'s details have already been registered\' but got :'+e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void test_saveAccessChanges_userCantRemoveTheirOwnAccessToBAM() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        Id orgId = recordIdMap.get('acc');
        Id billingAccId = recordIdMap.get('ba');
        Id appId = recordIdMap.get('app');
        Id appRoleId = recordIdMap.get('approle');

        // creating BAM User who we will run this test as
        Contact bamUserContact = BAMTestUtility.createTestContact(orgId, '');
        bamUserContact.Email = DUMMY_EMAIL2;
        bamUserContact.FirstName = 'John Doe';
        insert bamUserContact;

        BAMApplication__c bamApp = BAMTestUtility.createBamApplication('BAM');
        bamApp.appKey__c ='BAM';
        insert bamApp;

        Asset prod = BAMTestUtility.createAsset(orgId, bamApp.Product__c, true);
        insert prod;
        
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(bamApp);
        insert appRole;

        BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(bamUserContact.Id, bamApp.Id);
        insert conApp;
        
        BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;
       
        User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        insert portalUser;
        
        // mock page state
        List<Map<String, Object>> mockPageState = new List<Map<String, Object>>();
        // creating mock BAM app state in client
        Map<String, Object> mockAppState = new Map<String, Object>();
        mockAppState.put('Id', bamApp.Id);
        mockAppState.put('selectedAppRoleId', appRole.Id);
        mockAppState.put('selectedBillingAccountIds',new List<String>{billingAccId});
        mockPageState.add(mockAppState);

        // creating contact data 
        BAMUserController.ContactDataWrapper contactData = new BAMUserController.ContactDataWrapper();
        contactData.FirstName = DUMMY_FIRST_NAME;
        contactData.LastName = DUMMY_LAST_NAME;
        contactData.Email = DUMMY_EMAIL;
        contactData.orgId = orgId;

        Test.startTest();
        System.runAs(portalUser) {
            // Create user with BAM access
            String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
            BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            
            // test that exception is thrown if user tries to remove their own access to BAM
            mockPageState[0].put('selectedAppRoleId', BAMUserController.NO_ACCESS_IDENTIFIER_STRING);
            try {
                Id contactId = [SELECT Id, Name, Email FROM Contact WHERE Email =: DUMMY_EMAIL].Id;
                contactData.Id = contactId;

                // removing pending status from external onboarding request
                List<BAMContactApplication__c> conApps = [SELECT Id, Contact__c FROM BAMContactApplication__c WHERE Contact__c=:contactId];
                System.assertEquals(1, conApps.size());
                BAMExternalOnboardingRequest__c eob = [SELECT Id, Status__c, Error__c
                            FROM BAMExternalOnboardingRequest__c
                            WHERE RecordTypeId =: BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
                            AND Contact_Application__c =: conApps[0].Id
                            ORDER BY CreatedDate DESC
                            LIMIT 1 ];
                eob.Status__c = 'Error';
                update eob;

                accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
                accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('You can\'t remove your own access'), 'expected error message to contain \'You can\'t remove your own access\' but got :'+e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void test_saveAccessChanges_forNewContact() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        Id orgId = recordIdMap.get('acc');
        Id billingAccId = recordIdMap.get('ba');
        Id appId = recordIdMap.get('app');
        Id appRoleId = recordIdMap.get('approle');

        // creating BAM User who we will run this test as
        Contact bamUserContact = BAMTestUtility.createTestContact(orgId, '');
        bamUserContact.Email = DUMMY_EMAIL2;
        bamUserContact.FirstName = 'Sammy Sim';
        insert bamUserContact;

        BAMApplication__c bamApp = BAMTestUtility.createBamApplication('BAM');
        bamApp.appKey__c ='BAM';
        insert bamApp;

        Asset prod = BAMTestUtility.createAsset(orgId, bamApp.Product__c, true);
        insert prod;
        
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(bamApp);
        insert appRole;

        BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(bamUserContact.Id, bamApp.Id);
        insert conApp;
        
        BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;
       

        User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        portalUser.Username = System.currentTimeMillis() + portalUser.Username;
        insert portalUser;
        
        // mock page state
        List<Map<String, Object>> mockPageState = new List<Map<String, Object>>();
        // creating mock BAM app state in client
        Map<String, Object> mockAppState = new Map<String, Object>();
        mockAppState.put('Id', bamApp.Id);
        mockAppState.put('selectedAppRoleId', appRole.Id);
        mockAppState.put('selectedBillingAccountIds',new List<String>{billingAccId});
        mockPageState.add(mockAppState);

        // creating contact data 
        BAMUserController.ContactDataWrapper contactData = new BAMUserController.ContactDataWrapper();
        contactData.FirstName = DUMMY_FIRST_NAME;
        contactData.LastName = DUMMY_LAST_NAME;
        contactData.Email = DUMMY_EMAIL;
        contactData.orgId = orgId;

        Test.startTest();
        System.runAs(portalUser) {
            // Run method being tested
            String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
            BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            System.assert(accessSaveResult.success);

            Id contactId = [SELECT Id, Name, Email FROM Contact WHERE Email =: DUMMY_EMAIL].Id;
            // assert that new access records were created
            List<BAMContactApplication__c> conApps = [SELECT Id, Contact__c FROM BAMContactApplication__c WHERE Contact__c=:contactId];
            System.assertEquals(1, conApps.size());
            List<BAMContactRole__c> conRoles= [SELECT Id, ContactApplication__r.Contact__c FROM BAMContactRole__c WHERE ContactApplication__r.Contact__c=:contactId];
            System.assertEquals(1, conRoles.size());
            List<BAMLinkedEntity__c> linkedEntities = [SELECT Id, ContactRole__r.ContactApplication__r.Contact__c FROM BAMLinkedEntity__c WHERE ContactRole__r.ContactApplication__r.Contact__c=:contactId];
            System.assertEquals(1, linkedEntities.size());
        }
        Test.stopTest();
    }


    @isTest
    static void test_saveAccessChanges_forEditingAccess() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        Id orgId = recordIdMap.get('acc');
        Id billingAccId = recordIdMap.get('ba');
        Id appId = recordIdMap.get('app');
        Id appRoleId = recordIdMap.get('approle');

        // creating 'User' app role to assign to later
        BAMApplication__c appRecord = [SELECT Id FROM BAMApplication__c WHERE Id =: appId];
        BAMApplicationRole__c userAppRole = BAMTestUtility.createApplicationRole(appRecord, 'User');
        insert userAppRole;

        // creating a billing account that the user will be given acess to later
        Billing_Account__c billingAcccount = BAMTestUtility.createTestBillingAccount(orgId, 'BA');
        insert billingAcccount;

        // creating BAM User who we will run this test as
        Contact bamUserContact = BAMTestUtility.createTestContact(orgId, '');
        bamUserContact.Email = DUMMY_EMAIL2;
        bamUserContact.FirstName = 'John Wick';
        insert bamUserContact;

        BAMApplication__c bamApp = BAMTestUtility.createBamApplication('BAM');
        bamApp.appKey__c ='BAM';
        insert bamApp;

        Asset prod = BAMTestUtility.createAsset(orgId, bamApp.Product__c, true);
        insert prod;
        
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(bamApp);
        insert appRole;

        BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(bamUserContact.Id, bamApp.Id);
        insert conApp;
        
        BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;
       
        User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        insert portalUser;
        
        // mock page state
        List<Map<String, Object>> mockPageState = new List<Map<String, Object>>();
        // creating mock BAM app state in client
        Map<String, Object> mockAppState = new Map<String, Object>();
        mockAppState.put('Id', appId);
        mockAppState.put('selectedAppRoleId', appRoleId);
        mockAppState.put('allowBSPConsignmentSearch', true);
        mockAppState.put('selectedBillingAccountIds',new List<String>{billingAccId});
        mockPageState.add(mockAppState);

        // creating contact data 
        BAMUserController.ContactDataWrapper contactData = new BAMUserController.ContactDataWrapper();
        contactData.FirstName = DUMMY_FIRST_NAME;
        contactData.LastName = DUMMY_LAST_NAME;
        contactData.Email = DUMMY_EMAIL;
        contactData.orgId = orgId;
        contactData.primaryBillingAccountId = billingAccId;

        Test.startTest();
        System.runAs(portalUser) {
            // create new user with app access
            String accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
            BAMUserController.AccessChangeResultsWrapper accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
            
            // assert that correct primary billing account was populated on contact record
            Contact con = [SELECT Id, Name, Email, BillingAccount__c FROM Contact WHERE Email =: DUMMY_EMAIL];
            System.assertEquals(billingAccId, con.BillingAccount__c);

            Id contactId = con.Id;
            // assert that new access records were created
            List<BAMContactApplication__c> conApps = [SELECT Id, BSPCanViewAllConsignments__c, Contact__c FROM BAMContactApplication__c WHERE Contact__c=:contactId];
            System.assertEquals(1, conApps.size());
            System.assertEquals(true, conApps[0].BSPCanViewAllConsignments__c);
            List<BAMContactRole__c> conRoles= [SELECT Id, ContactApplication__r.Contact__c FROM BAMContactRole__c WHERE ContactApplication__r.Contact__c=:contactId];
            System.assertEquals(1, conRoles.size());
            List<BAMLinkedEntity__c> linkedEntities = [SELECT Id, ContactRole__r.ContactApplication__r.Contact__c FROM BAMLinkedEntity__c WHERE ContactRole__r.ContactApplication__r.Contact__c=:contactId];
            System.assertEquals(1, linkedEntities.size());


            // removing pending status from external onboarding request
            BAMExternalOnboardingRequest__c eob = [SELECT Id, Status__c, Error__c
                        FROM BAMExternalOnboardingRequest__c
                        WHERE RecordTypeId =: BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
                        AND Contact_Application__c =: conApps[0].Id
                        ORDER BY CreatedDate DESC
                        LIMIT 1 ];
            eob.Status__c = 'Error';
            update eob;

            // change users role to app 
            contactData.Id = contactId;

            mockAppState = new Map<String, Object>();
            mockAppState.put('Id', appId);
            mockAppState.put('selectedAppRoleId', userAppRole.Id);
            mockAppState.put('allowBSPConsignmentSearch', true);
            mockAppState.put('selectedBillingAccountIds',new List<String>{billingAccId, billingAcccount.Id});
            mockPageState[0] = mockAppState;
            accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
            accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);
           

            // assert that relevant access records were changed
            conApps = [SELECT Id, Contact__c FROM BAMContactApplication__c WHERE Contact__c=:contactId];
            System.assertEquals(1, conApps.size());
            conRoles= [SELECT Id, ApplicationRole__c, Status__c, ContactApplication__r.Contact__c FROM BAMContactRole__c WHERE ContactApplication__r.Contact__c=:contactId];
            System.assertEquals(1, conRoles.size());
            System.assertEquals(userAppRole.Id, conRoles[0].ApplicationRole__c);
            System.assertEquals('Pending', conRoles[0].Status__c);
            linkedEntities = [SELECT Id, ContactRole__r.ContactApplication__r.Contact__c FROM BAMLinkedEntity__c WHERE ContactRole__r.ContactApplication__r.Contact__c=:contactId];
            System.assertEquals(2, linkedEntities.size());

            // removing pending status from external onboarding request
            eob = [SELECT Id, Status__c, Error__c
                        FROM BAMExternalOnboardingRequest__c
                        WHERE RecordTypeId =: BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
                        AND Contact_Application__c =: conApps[0].Id
                        ORDER BY CreatedDate DESC
                        LIMIT 1 ];
            eob.Status__c = 'Error';
            update eob;

            // remove user's access
            mockAppState = new Map<String, Object>();
            mockAppState.put('Id', appId);
            mockAppState.put('allowBSPConsignmentSearch', true);
            mockAppState.put('selectedAppRoleId', BAMUserController.NO_ACCESS_IDENTIFIER_STRING);
            mockPageState[0] = mockAppState;
            
            accessSaveResultString = BAMUserController.saveAccessChanges(JSON.serialize(contactData), mockPageState);
            accessSaveResult = (BAMUserController.AccessChangeResultsWrapper) JSON.deserialize(accessSaveResultString, BAMUSerController.AccessChangeResultsWrapper.class);

            // assert that the contact app record was marked for deletion
            conApps = [SELECT Id, Contact__c, Pending_Delete__c FROM BAMContactApplication__c WHERE Contact__c=:contactId];
            System.assertEquals(1, conApps.size());
            System.assertEquals(true, conApps[0].Pending_Delete__c);
        }
        Test.stopTest();
    }

    @isTest
    static void test_createUserUsingFlow(){
        Account testAccount = BAMTestUtility.createTestAccount('1234');
        insert testAccount;

        Contact bamUserContact = BAMTestUtility.createTestContact(testAccount.Id, '');
        insert bamUserContact;

        Id userId = BAMUserController.createUserUsingFlow(bamUserContact.Id);

        User createdUser = [SELECT Id, Name, ContactId FROM User WHERE ContactId =: bamUserContact.Id];
        System.assertEquals(createdUser.Id, userId)  ;
    }
}