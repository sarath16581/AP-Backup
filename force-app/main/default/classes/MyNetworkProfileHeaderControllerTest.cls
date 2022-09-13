/*------------------------------------------------------------
Author:        Dion Gunn (dion.gunn@auspost.com.au)
Description:   Test class for MyNetworkProfileHeadereController.
History
10-08-2017 - Dion Gunn - Created
08-09.2022 - Naveen Rajanna - REQ2963906 - upgraded to 55 and minor changes for coverage
------------------------------------------------------------*/
@isTest
public without sharing class MyNetworkProfileHeaderControllerTest {

    public static testMethod void testLogout() {       
        
        MyNetworkCommunitySettings__mdt myNetworkSettings = [select Dev_Oracle_IAM_Logout_URL__c, PTEST_Oracle_IAM_Logout_URL__c,
                Stest_Oracle_IAM_Logout_URL__c, Prod_Oracle_IAM_Logout_URL__c, Development_Base_URL__c, PTEST_Base_URL__c,
                STEST_Base_URL__c, Production_Base_URL__c,Production_Retail_Logout_URL__c from MyNetworkCommunitySettings__mdt limit 1];
        
        User myNetworkRetail = myNetworkUser();
        
        System.runAs(myNetworkRetail) {
            //Test DEV Scenario
            MyNetworkProfileHeaderController.baseURL = myNetworkSettings.Development_Base_URL__c;
            System.assert(MyNetworkProfileHeaderController.getRetailLogoutURL().contains(myNetworkSettings.Dev_Oracle_IAM_Logout_URL__c));
            
            //Test PTEST Scenario
            MyNetworkProfileHeaderController.baseURL = myNetworkSettings.PTEST_Base_URL__c;
            System.assert(MyNetworkProfileHeaderController.getRetailLogoutURL().contains(myNetworkSettings.PTEST_Oracle_IAM_Logout_URL__c));
            
            //Test STEST Scenario
            MyNetworkProfileHeaderController.baseURL = myNetworkSettings.STEST_Base_URL__c;
            System.assert(MyNetworkProfileHeaderController.getRetailLogoutURL().contains(myNetworkSettings.Stest_Oracle_IAM_Logout_URL__c));

            //test uname
            MyNetworkProfileHeaderController Userd = MyNetworkProfileHeaderController.uName();
            System.assert(Userd.name.contains(myNetworkRetail.FirstName));
            
            //test retail users logout redirect 
            if(!Util.runningInASandbox && !Test.isRunningTest()) {
            System.assert(MyNetworkProfileHeaderController.getRetailLogoutURL().contains(myNetworkSettings.Production_Retail_Logout_URL__c));
            }
       }
    }

	private static User myNetworkUser() {
    	Profile p = [select Id, Name from Profile where Name = 'MyNetwork Portal'];
    	DateTime userdt = System.now();
    	String username = 't@' + String.valueOf(userdt.getTime()) + '.com';
		User u = new User(
        	UserName = username,
        	FirstName = 'TestFirstName',
        	LastName = 'TestLastName',
        	Alias = 'test',
        	Email = 'test@mynetwork.com',
        	EmailEncodingKey = 'UTF-8',
        	LanguageLocaleKey = 'en_US',
        	LocalesIdKey = 'en_US',
        	TimezonesIdKey = 'America/Los_Angeles',
        	ProfileId = p.Id,
       		MyNetwork_Retail_User__c = true
       	);
        return u;
    }
}