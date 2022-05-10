/**
Description: This apex class is test class for apex class - APT_CalculateDomesticPricingSched.
Created By - Mausam Padhiyar
Created Date - 16th Oct, 2015
Last Modified By -
Last Modified Date -
@changelog
09/05/2022 - Seth Heang - Fix Test class failure due to system.schedule() set in the past
**/
@isTest
private with sharing class APT_CalculateDomesticPricingSched_Test {
    /**
        Creating test data
    **/
    private static testMethod void testMethod1() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        test.startTest();
        
        APT_CalculateDomesticPricingSched.sendEmailAlert('test@example.com', new list<String>{'error1', 'error2'});
        
        Id jobId = system.schedule('Calculate Domestic Pricing', '0 0 0 ? * *', new APT_CalculateDomesticPricingSched());
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
}