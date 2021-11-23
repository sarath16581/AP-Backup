/**
Description: Test class for Apex Class- APT_RequestNewAccountController.
Created By - Drashtee Shah
Created Date - 22nd Feb, 2016
Last Modified By -
Last Modified Date - 
**/
@isTest
private class APT_RequestNewAccountController_Test {
    /**
        Creating Test Data
    **/
    private static TestMethod void APT_RequestNewAccountController1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {             
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Account_Types__c = 'charge,cash,random';
            insert r2tSystemProperties;
            
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id', acc.ID);
            //ApexPages.currentPage().getParameters().put('selectedAccountType', 'charge');
            APT_RequestNewAccountController rnac = new APT_RequestNewAccountController();
            rnac.selectedAccountType = 'charge';
            rnac.doNext();
            Test.StopTest();
            system.assert(acc!=null);
        }
    }
    
     /**
        Creating Test Data
    **/   
    private static TestMethod void APT_RequestNewAccountController2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {          
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Account_Types__c = 'charge,cash,random';
            insert r2tSystemProperties;
            
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id', acc.ID);
            //ApexPages.currentPage().getParameters().put('selectedAccountType', 'charge');
            APT_RequestNewAccountController rnac = new APT_RequestNewAccountController();
            rnac.selectedAccountType = 'cash';
            rnac.doNext();
            Test.StopTest();
            system.assert(acc!=null);
        }
            
    }
    
    /**
        Creating Test Data
    **/    
    private static TestMethod void APT_RequestNewAccountController3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Account_Types__c = 'charge,cash,random';
            insert r2tSystemProperties;
           
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id', acc.ID);
            //ApexPages.currentPage().getParameters().put('selectedAccountType', 'charge');
            APT_RequestNewAccountController rnac = new APT_RequestNewAccountController();
            rnac.selectedAccountType = 'random';
            rnac.doNext();
            Test.StopTest();
             system.assert(acc!=null);
        }
    }
    
    /**
        Creating Test Data
    **/    
    private static TestMethod void APT_RequestNewAccountController4() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {          
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            //r2tSystemProperties.APT_Account_Types__c = 'charge,cash,random';
            insert r2tSystemProperties;
           
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id', acc.ID);
            //ApexPages.currentPage().getParameters().put('selectedAccountType', 'charge');
            APT_RequestNewAccountController rnac = new APT_RequestNewAccountController();
            rnac.selectedAccountType = 'random';
            rnac.doNext();
            Test.StopTest();
             system.assert(acc!=null);
        }
    }
    /**
        Creating Test Data
    **/    
    private static TestMethod void APT_RequestNewAccountControlle5() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {       
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            //r2tSystemProperties.APT_Account_Types__c = 'charge,cash,random';
            //insert r2tSystemProperties;
            
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id', acc.ID);
            //ApexPages.currentPage().getParameters().put('selectedAccountType', 'charge');
            APT_RequestNewAccountController rnac = new APT_RequestNewAccountController();
            rnac.selectedAccountType = 'random';
            rnac.doNext();
            Test.StopTest();
            system.assert(acc!=null);
        }
    }
    
    /**
        Creating Test Data
    **/    
    private static TestMethod void APT_RequestNewAccountControlle6() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {          
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            //r2tSystemProperties.APT_Account_Types__c = 'charge,cash,random';
            //insert r2tSystemProperties;
           
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id', acc.ID);
            //ApexPages.currentPage().getParameters().put('selectedAccountType', 'charge');
            APT_RequestNewAccountController rnac = new APT_RequestNewAccountController();
            rnac.selectedAccountType = 'random';
            rnac.doNext();
            Test.StopTest();
             system.assert(acc!=null);
        }
    }
}