/***
 * @author Disha kariya
 * @date 2020-08-24
 * @group Tests
 * @tag Selector
 * @tag Network Response SObject
 * @domain Core
 * @description Test Class covering NetworkResponsesSelector
 * @changelog
 * 2020-08-24 - Disha Kariya - Created
 */
@IsTest
public with sharing class NetworkResponsesSelector_Test {

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

        NetworkResponsesSelector selector = NetworkResponsesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        // make sure there is RecordType.DeveloperName condition
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Network_Response__c\\b').matcher(soql).find(), 'Resulting query does not select from Network Response');

        selector = NetworkResponsesSelector.newInstance();
        qb = selector.newQueryBuilder(new Set<Object>{NetworkResponsesSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();

        // make sure there is Owner
        System.assertEquals(true, Pattern.compile('(?ism)Owner.*?\\bfrom Network_Response__c\\b').matcher(soql).find(), 'Resulting query does not select from Owner');

        //Test for field override
        selector = NetworkResponsesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                Network_Response__c.SObjectType => new Set<SObjectField>{Network_Response__c.Case_Comments__c, Network_Response__c.Id}
        });
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Case_Comments__c.*?\\bfrom Network_Response__c\\b').matcher(soql).find(), 'Resulting query does not select Case_Comments__c field: ' + soql);

        selector = NetworkResponsesSelector.newInstance(0, new Set<SObjectField>{Network_Response__c.Case_Comments__c, Network_Response__c.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Case_Comments__c.*?\\bfrom Network_Response__c\\b').matcher(soql).find(), 'Resulting query does not select Case_Comments__c field: ' + soql);

        selector = NetworkResponsesSelector.newInstance(new Set<SObjectField>{Network_Response__c.Case_Comments__c, Network_Response__c.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Case_Comments__c.*?\\bfrom Network_Response__c\\b').matcher(soql).find(), 'Resulting query does not select Case_Comments__c field: ' + soql);

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

        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;

        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
        insert contact;
        Case cases = ApplicationTestDataFactory.getCases(1, new List<Id>{contact.Id, contact.Id}, false)[0];
        insert cases;

        Network__c network = ApplicationTestDataFactory.getNetworks(1, false)[0];
        insert network;

        Network_Response__c networkResponse = ApplicationTestDataFactory.getNetworkResponses(1, network.Id, cases.Id, false)[0];
        insert networkResponse;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        NetworkResponsesSelector selector = NetworkResponsesSelector.newInstance(20);
        Map<Id, Network_Response__c> results = selector.selectById(new Set<Id>{networkResponse.Id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');


        Test.stopTest();

    }
}