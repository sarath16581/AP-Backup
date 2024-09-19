/**************************************************
Type:        test class for for AccountRelationshipSelector
History:
--------------------------------------------------
2023-10-02    Ken McGuire - Created
**************************************************/
@isTest
private class AccountRelationshipSelector_Test {

    @testSetup
    static void setupTestData() {
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
        insert accounts;
        AccountRelationship__c relation = new AccountRelationship__c(ParentAccount__c = accounts[0].Id, RelatedAccount__c = accounts[1].Id,Relationship__c='OPC');
        insert relation;
    }

    @isTest
    static void testSelectById() {
        Test.startTest();

        Set<Id> ids = new Set<Id>();
        for(AccountRelationship__c relation : [SELECT Id FROM AccountRelationship__c]) {
            ids.add(relation.Id);
        }

        AccountRelationshipSelector selector = AccountRelationshipSelector.newInstance(10);
        Map<Id, AccountRelationship__c> result = selector.selectById(ids);

        Test.stopTest();

        System.assert(result != null, 'The result should not be null');
        System.assertEquals(ids.size(), result.size(), 'The result size should match the number of test records');
    }

    @isTest
    static void testSelectByIdWithParentAccount() {
        Test.startTest();

        Set<Id> ids = new Set<Id>();
        for(AccountRelationship__c relation : [SELECT Id FROM AccountRelationship__c]) {
            ids.add(relation.Id);
        }

        AccountRelationshipSelector selector = AccountRelationshipSelector.newInstance();
        Map<Id, AccountRelationship__c> result = selector.selectById(ids, new Set<Object> {AccountRelationshipSelector.Options.WITH_PARENT_ACCOUNT});

        Test.stopTest();

        System.assert(result != null, 'The result should not be null');
        System.assertEquals(ids.size(), result.size(), 'The result size should match the number of test records');
    }
    
    @isTest
    static void testSelectByParent() {
        Test.startTest();

        Set<Id> ids = new Set<Id>();
        for(AccountRelationship__c relation : [SELECT ParentAccount__c FROM AccountRelationship__c]) {
            ids.add(relation.ParentAccount__c);
        }

        AccountRelationshipSelector selector = AccountRelationshipSelector.newInstance();
        List<AccountRelationship__c> result = selector.selectByParent(ids);

        Test.stopTest();

        System.assert(result != null, 'The result should not be null');
        System.assertEquals(ids.size(), result.size(), 'The result size should match the number of test records');
    }
    
    @isTest
    static void testSelectByIdWithRelatedAccount() {
        Test.startTest();

        Set<Id> ids = new Set<Id>();
        for(AccountRelationship__c relation : [SELECT Id FROM AccountRelationship__c]) {
            ids.add(relation.Id);
        }

        AccountRelationshipSelector selector = AccountRelationshipSelector.newInstance();
        Map<Id, AccountRelationship__c> result = selector.selectById(ids, new Set<Object> {AccountRelationshipSelector.Options.WITH_RELATED_ACCOUNT});

        Test.stopTest();

        System.assert(result != null, 'The result should not be null');
        System.assertEquals(ids.size(), result.size(), 'The result size should match the number of test records');
    }

    // Add other tests for other methods and scenarios as needed

}