/**
* @author Shashwat Nath
* @date 2017-04-10
* @group SecurePay Project
* @tag SendWelcome Pack Controller
* @tag APMS Application
* @domain SecurePay Project
* @description Test class for SendWelcomePackController class
* NOTE: This class is used by SendWelcomePack VF Page upon clicking "Send Welcome Pack" from APMS Application Detail Page. 
* 2017-04-10 - Shashwat Nath - Created
* 2021-01-28 - Dheeraj Mandavilli - Updated logic to related to multicurrency feature enablement in SecurePay Project.
*/

@IsTest
public class SendWelcomePackControllerTest{
    /* Test Method for bulk approvals */
    @testSetup static void setup() {
        Application__c app = new Application__c();
        app.SecurePayMerchantID5__c = '1234';
        insert app;
        
    }
    public static testmethod void updateApplicationPositiveTest() {
        //This test method for the update scenario when the new customer clicks on "Send Weclome Pack" Button for first time. 
        List<Application__c> applicationRec = [Select ID FROM Application__c LIMIT 1];
        
        Test.StartTest();
        ApexPages.StandardController stndctrl = new ApexPages.StandardController(applicationRec[0]);
        SendWelcomePackController cntrlr = new SendWelcomePackController(stndctrl);
        SendWelcomePackController.updateApplication(applicationRec[0].id); 
        Test.StopTest();
        List<Application__c> updatedApplicationRec = [Select ID,IsWelcomePackSent__c,Are_Multicurrency_Details_Sent__c,Opt_for_Multicurrency__c,Existing_Customer_Adding_Multicurrency__c FROM Application__c where id=:applicationRec[0].id LIMIT 1];
        if(!updatedApplicationRec.isEmpty()){
            system.assertEquals(updatedApplicationRec[0].IsWelcomePackSent__c,true);
            if(updatedApplicationRec[0].Opt_for_Multicurrency__c == 'Yes' && updatedApplicationRec[0].Existing_Customer_Adding_Multicurrency__c == false ){
                system.assertEquals(updatedApplicationRec[0].Are_Multicurrency_Details_Sent__c,true);
            }
            
        }
        
    }
    public static testmethod void updateApplicationNegativeTest() {
        //This test method for the exception scenario when the a new customer clicks on "Send Weclome Pack" Button again after the
        //first welcomepack was sent.  
        List<Application__c> applicationRec = [Select ID FROM Application__c LIMIT 1];
        applicationRec[0].IsWelcomePackSent__c = true;
        applicationRec[0].Are_Multicurrency_Details_Sent__c = true;
        try
        {
            update applicationRec;
            Test.StartTest();
            SendWelcomePackController.updateApplication(applicationRec[0].id); 
            Test.StopTest();
        }
        catch(Exception e) 
        {  
            System.Assert(e.getMessage().contains(Label.welcomePackEmailSent)); 
        }
        
    }
    
    public static testmethod void updateApplicationPositiveTest2() {
        //This test method for the regression scenario when the a new customer clicks on "Send Weclome Pack" after uncheking the Iswelcomesent 
        // And MulticurrencyDetailssent fields.  
        List<Application__c> applicationRec = [Select ID FROM Application__c LIMIT 1];
        applicationRec[0].IsWelcomePackSent__c = false;
        applicationRec[0].Existing_Customer_Adding_Multicurrency__c = false;
        applicationRec[0].Opt_for_Multicurrency__c = 'Yes';
        applicationRec[0].Are_Multicurrency_Details_Sent__c = false;
        try
        {
            update applicationRec;
            Test.StartTest();
            SendWelcomePackController.updateApplication(applicationRec[0].id); 
            Test.StopTest();
        }
        catch(Exception e) 
        {
            System.Assert(e.getMessage().contains('Exception Found'));
        }
        List<Application__c> updatedApplicationRec = [Select ID,IsWelcomePackSent__c,Are_Multicurrency_Details_Sent__c,Opt_for_Multicurrency__c,Existing_Customer_Adding_Multicurrency__c FROM Application__c where id=:applicationRec[0].id LIMIT 1];
        if(!updatedApplicationRec.isEmpty()){
            system.assertEquals(updatedApplicationRec[0].IsWelcomePackSent__c,true);
            if(updatedApplicationRec[0].Opt_for_Multicurrency__c == 'Yes' && updatedApplicationRec[0].Existing_Customer_Adding_Multicurrency__c == false ){
                system.assertEquals(updatedApplicationRec[0].Are_Multicurrency_Details_Sent__c,true);
            }
            
        }
    }
    
    public static testmethod void updateApplicationNegativeTest2() {
        //This test method for the exception scenario when an existing customer opted for multicurrency, clicks on "Send Weclome Pack"
        //again after the first welcomepack with multicurrency deatails was sent.
        List<Application__c> applicationRec = [Select ID FROM Application__c LIMIT 1];
        applicationRec[0].IsWelcomePackSent__c = true;
        applicationRec[0].Existing_Customer_Adding_Multicurrency__c = true;
        applicationRec[0].Are_Multicurrency_Details_Sent__c = true;
        try
        {
            update applicationRec;
            
            Test.StartTest();
            SendWelcomePackController.updateApplication(applicationRec[0].id); 
            Test.StopTest();
        }
        catch(Exception e) 
        {
            System.Assert(e.getMessage().contains(Label.multicurrencyDetailsSent));
        }
        
    }
}