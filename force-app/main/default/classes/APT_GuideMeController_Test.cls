/**
This apex class is test class for APT_GuideMeController.
Created By - Mausam Padhiyar
Created Date - 9th Oct, 2015
Last Modified By -
Last Modified Date -
**/
@isTest
private with sharing class APT_GuideMeController_Test {
    /**
        Creating Test Data
    **/
   private static testMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {        
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            insert r2tSystemProperties;
            
            //create organisation
            Account testOrganisation = APT_TestUtils.createOrganisation();
            insert testOrganisation;
            
            //create opportunity
            Opportunity testOppty = APT_TestUtils.createOpportunity(testOrganisation.Id);
            insert testOppty;
            
            ApexPages.currentPage().getParameters().put('accountId', testOrganisation.Id);
            ApexPages.currentPage().getParameters().put('opportunityId', testOppty.Id);
            
            APT_GuideMeController controller = new APT_GuideMeController();
            
            test.startTest();
            
            PageReference pgRef = controller.doRedirect();
            
            
            test.stopTest();
            system.assert(pgRef != null);
        }
    }
    /**
        Creating Test Data
    **/    
   private static testMethod void testMethod2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {       
            APT_GuideMeController controller = new APT_GuideMeController();
            
            test.startTest();
            
            PageReference pgRef = controller.doRedirect();
            
        
            test.stopTest();  
            system.assert(pgRef == null);
        }
    }
}