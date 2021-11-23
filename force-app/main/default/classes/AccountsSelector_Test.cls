/**
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectbyId Method.
 * 2020-05-14 - Disha Kariya - Updated tests for membership query filter
 * 2020-10-18 - Nathan Franklin - Added tests for selectByAccountNumber
 * 2021-08-09 - Seth Heang - Added selectByLikedNameAndPersonAccountOrderByName test coverage
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
*/
@IsTest
public with sharing class AccountsSelector_Test {

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

        AccountsSelector selector = AccountsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');

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

        AccountsSelector selector = AccountsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_RECORDTYPE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

        qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

        qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

        qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom memberships__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select Articles__r child records: '+soql);

        qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Organisation_Roles__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not Organisation_Roles__r child records: '+soql);

        qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES_PROSPECT_KNOWN});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Organisation_Roles__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not Organisation_Roles__r child records: '+soql);

        qb = selector.newQueryBuilder(new Set<Object>{AccountsSelector.Options.WITH_HOLDINGROLE});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)Holding_Role_Reference__r\\..*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');


        Test.stopTest();

    }

    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, false));
        orgAaccounts[0].LEGACY_ID__c ='6000000';
        insert orgAaccounts;
        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
        insert networkFacility;
        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,false)[0];
        insert facilityAccount;

        List<Account> accounts = new List<Account>(ApplicationTestDataFactory.getLPOAccounts(2, orgAaccounts[0].Id, facilityAccount.Id, false));
        insert accounts;
        
        List<Account> consumers = new List<Account>(ApplicationTestDataFactory.getPersonAccounts(2, false));
        consumers[0].FirstName = 'Seth';
        insert consumers;

        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAaccounts[0].Id, false)[0];
        insert personContact;

        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', accounts[0].Id, personContact.Id,  false)[0];
        insert member;

        Map<Id, Account> mappedAccounts = new Map<Id, Account>(orgAaccounts);

        Set<String> accountnumbers = new set<String>{ '6000000'} ;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        AccountsSelector selector = AccountsSelector.newInstance(1);
        Map<Id, Account> results = selector.selectById(mappedAccounts.keySet());
        System.assertEquals(1, results.size(), 'Result count was wrong');

        results = selector.selectByAccountNumber(accountnumbers);
        System.assertEquals(1, results.size(), 'Result count  was wrong');

        results = selector.selectById(mappedAccounts.keySet(), new Set<Object>{AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_OWNER});
        System.assertEquals(1, results.size(), 'Result count was wrong');
        System.assertNotEquals(null, results.values()[0].RecordType, 'Expected RecordType object');
        System.assertNotEquals(null, results.values()[0].Owner, 'Expected Owner object');

        results = selector.selectById(mappedAccounts.keySet(), new Set<Object>{AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS});

        System.assertNotEquals(null, results.values()[0].Memberships__r, 'Expected membership object');

        results = selector.selectByLikedNameAndPersonAccountOrderByName('Seth', true);
        System.assertEquals(1, results.size(), 'Result count was wrong');
        Test.stopTest();

    }
}