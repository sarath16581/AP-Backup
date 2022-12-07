/**
* @description Provides test coverage for APTSAPContractsDomain
* @author Ken McGuire
* @group Domains
* @domain APT_SAP_Contracts__c
* @changelog
* 2022-12-01 - Ken McGuire - Created
*/
@isTest
private class APTSAPContractsDomain_Test {
    
	@isTest
	private static void testAPTSAPContractsDomain() {
        List<APT_SAP_Contracts__c> sObjectList = new List<APT_SAP_Contracts__c> { new APT_SAP_Contracts__c()}; 
		APTSAPContractsDomain domain = APTSAPContractsDomain.newInstance(sObjectList);
    	domain.registerModules();
        ApplicationTestDataFactory.generateRecordIds(sObjectList);
        System.assertEquals(1, domain.records.size(), 'Expected SAP contract record');
		System.assertEquals(sObjectList[0].Id, domain.records[0].Id, 'Expected SAP contact record with Id');
	}
}