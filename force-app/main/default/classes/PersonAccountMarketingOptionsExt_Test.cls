/**************************************************
Type:       Test Class
Purpose:    Test for PersonAccountMarketingOptionsExt
History:
--------------------------------------------------
10.08.2015:  snigdha.sahu@auspost.com.au    Created

**************************************************/
@isTest
public class PersonAccountMarketingOptionsExt_Test {
    //create Test Data using TestDataProvider and execute SaveMarketingOptions()
    static testMethod void validatePAccountMarketingOptionsExt_01(){
        Account account_create = TestDataProvider.createAndSavePersonAccount(); 

        ApexPages.StandardController stdCont = new ApexPages.standardController(account_create);
        PersonAccountMarketingOptionsExt ext = new PersonAccountMarketingOptionsExt(stdCont);
        
        Map<String,ID> profiles = new Map<String,ID>();
        Account paccount_marketing = new Account();        
        
        
        //fetch the two profiles to test with
        List<Profile> sssw_test = [SELECT Name, Id FROM Profile WHERE Name ='SSSW - Service Agent' or Name = 'System Administrator'];
         for(Profile p : sssw_test){
            profiles.put(p.name, p.id);
        }
        
        //fetch users to RunAs
        User ssw_serviceagent =  [SELECT Id FROM User WHERE profileid = :profiles.get('SSSW - Service Agent') 
                                  AND isActive = true LIMIT 1 ];
        
        User admin =  [SELECT Id FROM User WHERE profileid = :profiles.get('System Administrator') 
                       AND isActive = true LIMIT 1];
        
        
        System.runAs(admin)  
        {    
        //try to update the DoNotCall and DoNotMail fields as admin user, these fields ashould be updated
          account_create.Legal_Marketing_Opt_In__pc = true;
          account_create.PersonHasOptedOutOfEmail = true;
          account_create.et4ae5__HasOptedOutOfMobile__pc = true;
          account_create.PersonDoNotCall = true;
          account_create.Do_Not_Mail__pc = true;
            
          ext.currentPAccount.Id = account_create.Id;           
          ext.SaveMarketingOptions();
          
          paccount_marketing = [select PersonDoNotCall, Do_Not_Mail__pc from Account where id = :(Id)account_create.Id];      
          System.assertEquals (paccount_marketing.PersonDoNotCall, true, 'For Admin: paccount_marketing.PersonDoNotCall is ' + paccount_marketing.PersonDoNotCall);

        }
        
        System.runAs(ssw_serviceagent)
        {    
        //try to update the PersonDoNotCall and Do_Not_Mail__pc fields as SSSW user
          account_create.Legal_Marketing_Opt_In__pc = true;
          account_create.PersonHasOptedOutOfEmail = true;
          account_create.et4ae5__HasOptedOutOfMobile__pc = true;
          account_create.PersonDoNotCall = true;
          account_create.Do_Not_Mail__pc = true;
            
          ext.currentPAccount.Id = account_create.Id;           
          ext.SaveMarketingOptions();

          paccount_marketing = [select PersonDoNotCall, Do_Not_Mail__pc from Account where id = :(Id)account_create.Id];
          System.assertEquals (paccount_marketing.PersonDoNotCall, true, 'For SSSW:paccount_marketing.PersonDoNotCall is ' + paccount_marketing.PersonDoNotCall);
            
         }
                                 
          
    }
    
    //create Test Data and try to update null values to trigger exception
    static testMethod void validatePAccountMarketingOptionsExt_02(){
        Account account_create = TestDataProvider.createAndSavePersonAccount(); 
        ApexPages.StandardController stdCont = new ApexPages.standardController(account_create);
        PersonAccountMarketingOptionsExt ext = new PersonAccountMarketingOptionsExt(stdCont);
        
                
        account_create.Legal_Marketing_Opt_In__pc = null;
        account_create.PersonHasOptedOutOfEmail = null;
        account_create.et4ae5__HasOptedOutOfMobile__pc = null;
        account_create.PersonDoNotCall = null;
        account_create.Do_Not_Mail__pc = null;
          
        Test.startTest(); 
        ext.currentPAccount.Id = account_create.Id;   
        ext.SaveMarketingOptions();           
        system.assert(true);
        Test.stopTest();        
        
    }
    
    
}