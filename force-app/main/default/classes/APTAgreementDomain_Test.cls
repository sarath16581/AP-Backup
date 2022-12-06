/**
* @description Provides test coverage for APTAgreementDomain
* @author Ken McGuire
* @group Domains
* @domain Apttus__APTS_Agreement__c
* @changelog
* 2022-12-05 - Ken McGuire - Created
*/
@isTest
private class APTAgreementDomain_Test{
    
    @isTest
    private static void TestAgreementDomain() {
        List<Apttus__APTS_Agreement__c> sObjectList = new List<Apttus__APTS_Agreement__c> { new Apttus__APTS_Agreement__c()}; 
        APTAgreementDomain domain = APTAgreementDomain.newInstance(sObjectList);
        domain.registerModules();
        ApplicationTestDataFactory.generateRecordIds(sObjectList);
        System.assertEquals(1, domain.records.size(), 'Expected Agreement Record');
        System.assertEquals(sObjectList[0].Id, domain.records[0].Id, 'Expected agreement record with Id');
    }
}