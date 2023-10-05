/**
 * @author Hasantha Liyanage
 * @date 2023-10-02
 * @group Test
 * @domain BAM
 * @description BAMContactRoleSelector selector Test
 * @changelog
 * 2023-10-02 - Hasantha Liyanage  - Created
 */
@IsTest
private class BAMContactRoleSelector_Test {
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BAMContactRoleSelector selector = BAMContactRoleSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom BAMContactRole__c\\b').matcher(soql).find(), 'Resulting query does not select from BAMContactRole__c');

        Test.stopTest();

    }

    /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BAMContactRoleSelector selector = BAMContactRoleSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
                BAMContactRoleSelector.Options.WITH_CONTACT_APPLICATION
        });
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)ContactApplication__r\\..*?\\bfrom BAMContactRole__c\\b').matcher(soql).find(), 'Resulting query does not select Contact fields');

    }


    /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
    @IsTest
    public static void integrationTest() {
// application, contact, role

        // =====================================
        // Data Preparation
        // =====================================
        //get account
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
        //get products
        List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
        //get BAM Applications
        List<BAMApplication__c> bamApps = ApplicationTestDataFactory.getBamApplications(1,'Business Shop',products[0].Id, true);
        bamApps.addAll(ApplicationTestDataFactory.getBamApplications(1,'Business Support Portal',products[1].Id, true));
        bamApps.addAll(ApplicationTestDataFactory.getBamApplications(1,'Parcel Send',products[1].Id, true));
        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        BAMApplication__c app = BAMTestUtility.createBamApplication('BSP1');
        insert app;
        // create an application role
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
        insert appRole;
        // create an account
        Account testAccount = BAMTestUtility.createTestAccount('legacy');
        insert testAccount;
        // create a Application-Product-Asset
        Asset testAsset = BAMTestUtility.createAsset(testAccount.Id, app.Product__c, true);
        insert testAsset;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, '');
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
    }
}