/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for bspProfileUplift
History
Feb 27, 2017 - David Catindoy - Created 
------------------------------------------------------------*/

@isTest
private class bspProfileUplift_Test {

    @testSetup 
    static void testSetup(){

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.ShippingCity = 'Melbourne'; 
        testAccount.ShippingState = 'VIC';
        testAccount.ShippingPostalCode = '3000';
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);
        
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        Database.insert(testBillingAccList);
        
        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', Phone = '0421546325',
                                     MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', 
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
    static testMethod void testChangePassword() {
        Test.startTest();
                String url = bspProfileUplift.changePassword('Test123','Test123','TestOLD');
        Test.stopTest();
        System.assertEquals(url, 'Success');
    }
    //Jansi commented below method - 18-09-2020
   /* static testMethod void testStatesCountries() {
        Test.startTest();
        		Test.setCurrentPage(Page.bspProfile);
                bspProfileUplift bspProf = new bspProfileUplift();
                bspProf.getStates();
                bspProf.getCountries();
        Test.stopTest();
    }*/
    static testMethod void testProfile() {
        User bspUser = [SELECT Id, Alias, Email, FirstName, LastName, ProfileId, UserRoleId, UserName, ContactId FROM User WHERE Alias = 'bspUser' LIMIT 1];
        System.runAs(bspUser){
            
            Test.startTest();
                Test.setCurrentPage(Page.bspProfile);
                bspProfileUplift bspProf = new bspProfileUplift();
            	bspProfileUplift.UserProfileDetails bUPD =  bspProfileUplift.getUserProfileDetails();
            	bUPD.mailingAddress = new AddressExtension( '111 Bourke Street', '111 Bourke Street',  'Melbourne', 'VIC', '3000', ' ', 'Australia');
                /*AddressExtension mailingAddress = new AddressExtension();
                bUPD.mailingAddress.State = 'VIC';
                bUPD.mailingAddress.line1 = '111 Bourke Street';
                bUPD.mailingAddress.city = 'Melbourne';
                bUPD.mailingAddress.postcode = '3000';
                bUPD.mailingAddress.countryName = 'Australia';
				bUPD.mailingAddress = mailingAddress;*/
                bspProfileUplift.save( JSON.serialize(bUPD.mailingAddress),  bUPD.businessName,  bUPD.businessNumber,  JSON.serialize(bspUser));
            Test.stopTest();
            /** Commented out the following to get around the problem in PRODUCTION.
            Test Class works fine if it is run alone in PRODUCTION, but fails when all tests are run.
            Case need to be raised with Salesforce.  **/
            Contact userCont = [SELECT Id, MailingState, MailingCity, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :bspUser.ContactId];
            System.assertEquals(userCont.MailingState, 'VIC');
            System.assertEquals(userCont.MailingCity, 'Melbourne');
            System.assertEquals(userCont.MailingPostalCode, '3000');
            System.assertEquals(userCont.MailingCountry, 'Australia');
            
        }
    }

}