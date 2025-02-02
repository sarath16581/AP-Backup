/**
* @description Provides test coverage for APTProposalDomain
* @author Ken McGuire
* @group Domains
* @domain Apttus_Proposal__Proposal__c
* @changelog
* 2022-12-01 - Ken McGuire - Created
*/
@IsTest
private class APTProposalGenericDomain_Test {
    
    @IsTest
    private static void testProposalDomain() {
        List<Apttus_Proposal__Proposal__c> sObjectList = new List<Apttus_Proposal__Proposal__c> { new Apttus_Proposal__Proposal__c()}; 
        APTProposalGenericDomain domain = APTProposalGenericDomain.newInstance(sObjectList);
        domain.registerModules();
        ApplicationTestDataFactory.generateRecordIds(sObjectList);
        System.assertEquals(1, domain.records.size(), 'Expected Proposal Record');
        System.assertEquals(sObjectList[0].Id, domain.records[0].Id, 'Expected proposal record with Id');
    }
}