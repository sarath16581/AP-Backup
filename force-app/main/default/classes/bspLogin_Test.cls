/*------------------------------------------------------------
Author:        Vinothraja
Company:       CRMIT Solutions
Description:   Test Class for bspLogin
History
Sep 09, 2020 - Vinothraja - Created
------------------------------------------------------------*/
@isTest
private class bspLogin_Test {
    @testSetup 
    static void testSetup(){

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.ShippingCity = 'Sydney';
        testAccount.ShippingState = 'NSW';
        testAccount.ShippingPostalCode = '2170';
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);
        
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        Database.insert(testBillingAccList);
        
        Contact newCon = new Contact(FirstName = 'Vinoth', LastName = 'Raja', Phone = '0449222334',
                                     MobilePhone = '0449222334', Email = 'vinothraja@gmail.com', 
                                     BillingAccount__c = testBillingAccList[0].Id, 
                                     AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, 
                                     Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
        Database.insert(newCon);

        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User']; 
        User u = new User(Alias = 'bspUser', Email='user@testorg.a', ContactId = newCon.Id, EmailEncodingKey='UTF-8', 
                          FirstName = 'BSP', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
                          
        Database.insert(u);
    
    }

	@isTest
    static void testForgotPassword() {
        User bspUser = [SELECT Id, Email, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        Test.startTest();
            bspLogin.forgotPassword(bspUser.UserName);
        Test.stopTest();
    }
	@isTest
    static void testForgotPasswordWrongUserName() {
        //User bspUser = [SELECT Id, Email, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        try {
            Test.startTest();
            bspLogin.forgotPassword('WrongUsername');
        	Test.stopTest();
        } catch(Exception error) {
            System.Assert(error.getMessage().contains('Error occured, please contact your System Administrator'));
        }
    }
	@isTest
    static void testForgotPasswordInvalidUserName() {
        //User bspUser = [SELECT Id, Email, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        try {
            Test.startTest();
            bspLogin.forgotPassword('');
        	Test.stopTest();
        } catch(Exception error) {
            System.Assert(error.getMessage().contains('Invalid username'));
        }
    }
	@isTest
    static void testSavePasswordandLogin() {
        User bspUser = [SELECT Id, Email, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        Test.startTest();
            bspLogin.savePassword(bspUser.id, 'newPassword17@@', 'newPassword17@@' , bspUser.Email);
            String url = bspLogin.login( bspUser.UserName, 'newPassword17@@' );
        	System.debug('url -->' + url);
        Test.stopTest();
        System.assert(url == 'Success');
        
    }
    
    @isTest
    static void testWrongSavePassword() {
        User bspUser = [SELECT Id, Email, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        try {
            Test.startTest();
            bspLogin.savePassword(bspUser.id, 'newPassword17', 'newPassword17' , bspUser.Email);
            Test.stopTest();
        } catch(Exception error) {
            System.Assert(error.getMessage().contains('INVALID_NEW_PASSWORD'));
        }
    }
	@isTest
    static void testLoginWrongUserName() {
        //User bspUser = [SELECT Id, Email, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
        try {
            Test.startTest();
            String url = bspLogin.login( '', 'newPassword17@@' );
        	Test.stopTest();
        } catch(Exception error) {
            System.Assert(error.getMessage().contains('Invalid username'));
        }
    }    
}