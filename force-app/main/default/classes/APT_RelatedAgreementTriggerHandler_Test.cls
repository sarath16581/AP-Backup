/**
Description: This test class is for controller - APT_RelatedAgreementTrigger.
Created By - Garvita Rai
Created Date - 22nd Dec, 2015
Last Modified By -
Last Modified Date - 
**/
@isTest
private class APT_RelatedAgreementTriggerHandler_Test{
         /**
        Creating test data
    **/
     private static testMethod void testOprScheduleCreation() {  
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        insert testuser;
        
        //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Label = 'Apttus R2T User'];
        //if(ps != null) {
        //    ps.UserLicenseId = testuser.Id;
        //    update ps;
        //}
        
        //System.runAs(testuser) {  
           Contact con = APT_TestUtils.createContact();
           insert con;
           Apttus__APTS_Agreement__c aptContract1 = APT_TestUtils.createAgreement(con.Id); 
           insert  aptContract1 ;
           Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id); 
           insert  aptContract2;
           system.debug('*** aptContract1 ***'+aptContract1.Id);
           APT_Operational_Schedule__c oprSchedule = new APT_Operational_Schedule__c(APT_Contract__c=aptContract1.Id);
           insert oprSchedule ;
           system.debug('*** oprSchedule Id***'+oprSchedule.Id);
           system.debug('*** oprSchedule APT_Contract__c ***'+oprSchedule.APT_Contract__c);
           system.debug('*** oprSchedule query***'+[SELECT APT_Contract__c FROM APT_Operational_Schedule__c  WHERE Id = :oprSchedule.Id]);
           Apttus__APTS_Related_Agreement__c relAgreement = new Apttus__APTS_Related_Agreement__c (Apttus__APTS_Contract_From__c=aptContract1.Id,Apttus__APTS_Contract_To__c=aptContract2.Id);
           Test.startTest();
           insert relAgreement;
           
           Test.stopTest();
           System.assert(relAgreement != null);
        //}
            
        }
    /**
        Creating test data
    **/     
     private static testMethod void testOprScheduleCreation2() {  
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) { 
           Contact con = APT_TestUtils.createContact();
           insert con;
           Apttus__APTS_Agreement__c aptContract1 = APT_TestUtils.createAgreement(con.Id); 
           insert  aptContract1 ;
           Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id); 
           insert  aptContract2;
           APT_Operational_Schedule__c oprSchedule = new APT_Operational_Schedule__c(APT_Contract__c=aptContract1.Id);
           insert oprSchedule ;
           Apttus__APTS_Related_Agreement__c relAgreement = new Apttus__APTS_Related_Agreement__c (Apttus__APTS_Contract_From__c= null,Apttus__APTS_Contract_To__c=null);
           Test.startTest();
           insert relAgreement;
           
           Test.stopTest();
           System.assert(relAgreement != null);
        }
     }
}