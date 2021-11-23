@isTest
private class BatchableAccountAPCNUpdater_Test {

    static testMethod void testBatch() {
        Account a = TestDataProvider.createPersonAccount('test', Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        a.APCN__pc = '123456';
        insert a;
        
        Test.startTest();
        BatchableAccountAPCNUpdater.run();
        Test.stopTest();
        
        System.assertEquals('123456', [SELECT APCN__c FROM Account WHERE Id = :a.Id].APCN__c);
    }
}