/**
* @description Provides test coverage for APR_Domain
* @author Ken McGuire
* @group Domains
* @domain APR__c
* @changelog
* 2022-12-05 - Ken McGuire - Created
*/
@IsTest
private class APRGenericDomain_Test {
    @IsTest
    private static void TestAPRDomain() {
        List<APR__c> sObjectList = new List<APR__c> { new APR__c()}; 
        APRGenericDomain domain = APRGenericDomain.newInstance(sObjectList);
        domain.registerModules();
        ApplicationTestDataFactory.generateRecordIds(sObjectList);
        System.assertEquals(1, domain.records.size(), 'Expected APR Record');
        System.assertEquals(sObjectList[0].Id, domain.records[0].Id, 'Expected APR record with Id');
    }
}