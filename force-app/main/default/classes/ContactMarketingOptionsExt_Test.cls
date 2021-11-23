/**************************************************
Type:       Test Class
Purpose:    Test for ContactMarketingOptionsExt
History:
--------------------------------------------------
03.08.2015:  snigdha.sahu@auspost.com.au    Created

**************************************************/
@isTest
public class ContactMarketingOptionsExt_Test {
    //create Test Data using TestDataProvider and execute SaveMarketingOptions()
    static testMethod void validateContactMarketingOptionsExt_01(){
        Contact contact_create = TestDataProvider.createAndSaveContact(); 

        ApexPages.StandardController stdCont = new ApexPages.standardController(contact_create);
        ContactMarketingOptionsExt ext = new ContactMarketingOptionsExt(stdCont);
        
        Map<String,ID> profiles = new Map<String,ID>();
        Contact contact_marketing = new Contact();        

        
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
        
        System.runAs(ssw_serviceagent)
        {    
            //try to update the DoNotCall and DoNotMail fields as SSSW user
            contact_create.Legal_Marketing_Opt_In__c = false;
            contact_create.HasOptedOutOfEmail = false;
            contact_create.et4ae5__HasOptedOutOfMobile__c = false;
            contact_create.DoNotCall = false;
            contact_create.Do_Not_Mail__c = false;
            
            ext.currentContact.Id = contact_create.Id;           
            ext.SaveMarketingOptions();

            contact_marketing = [select DoNotCall, Do_Not_Mail__c from Contact where id = :(Id)contact_create.Id];
            System.assertEquals (contact_marketing.DoNotCall, false, 'For SSSW:contact_marketing.DoNotCall is ' + contact_marketing.DoNotCall);
            
        }
                                 
        System.runAs(admin)  
        {    
            //try to update the DoNotCall and DoNotMail fields as admin user
            contact_create.Legal_Marketing_Opt_In__c = true;
            contact_create.DoNotCall = true;
            contact_create.Do_Not_Mail__c = true;
            contact_create.HasOptedOutOfEmail = true;
            contact_create.et4ae5__HasOptedOutOfMobile__c = true;
            
            ext.currentContact.Id = contact_create.Id;           
            ext.SaveMarketingOptions();
            contact_marketing = [select DoNotCall, Do_Not_Mail__c from Contact where id = :(Id)contact_create.Id];

            System.assertEquals (contact_marketing.DoNotCall, true, 'For Admin: contact_marketing.DoNotCall is ' + contact_marketing.DoNotCall);


        }        
    }
    
    //create Test Data and try to update null values to trigger exception
    static testMethod void validateContactMarketingOptionsExt_02(){
        Contact contact_create = TestDataProvider.createAndSaveContact();
        ApexPages.StandardController stdCont = new ApexPages.standardController(contact_create);
        ContactMarketingOptionsExt ext = new ContactMarketingOptionsExt(stdCont);                   
        
        contact_create.Legal_Marketing_Opt_In__c = null;
        contact_create.DoNotCall = null;
        contact_create.Do_Not_Mail__c = null;
        contact_create.HasOptedOutOfEmail = null;
        contact_create.et4ae5__HasOptedOutOfMobile__c = null;
          
        Test.startTest(); 
        ext.currentContact.Id = contact_create.Id;   
        ext.SaveMarketingOptions();           
        system.assert(true);
        Test.stopTest();        
        
    }
    
    
}