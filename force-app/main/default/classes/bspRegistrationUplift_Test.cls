/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for bspRegistrationUplift
History
Feb 27, 2017 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class bspRegistrationUplift_Test {
    
    @testSetup static void testSetup(){
        
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);
        
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        //testBillingAccList[0].Organisation__c = testAccount.Id;
        testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[1].LEGACY_ID__c = '123456';
        //testBillingAccList[1].Organisation__c = testAccount.Id;
        Database.insert(testBillingAccList);
        
        //Database.insert(new CCUSettings__c(UsernameExtension__c = '.bsp', AttachmentSizeLimit__c = 5, DoNotShowFileNames__c = 'Do Not Show', CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id));
        Database.insert(new CCUSettings__c(DeliveryRecordTypeId__c = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId(), 
                                               GeneralRecordTypeId__c = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId(), 
                                               UsernameExtension__c = '.bsp', AttachmentSizeLimit__c = 5, DoNotShowFileNames__c = 'Do Not Show', 
                                               CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id));


        // BAM Specific functionality
        // creation of a product that is linked to the customer record to ensure BSP is enabled for the customer
        Product2 bspProduct = new Product2(Name = 'BSP');
        insert bspProduct;
        BAMApplication__c app = new BAMApplication__c(AppKey__c = 'BSP', ConfigurationModel__c = 'Per Customer', Product__c = bspProduct.Id, ServiceType__c = 'Salesforce', Status__c = 'Active');
        insert app;

        List<BAMApplicationRole__c> appRoles = new List<BAMApplicationRole__c>{
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Super Admin', ShowOrganisation__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Admin', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'User', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active')
        };
        insert appRoles;
        
    }

	static testMethod void testExistingUser() {

        Contact newCon = new Contact(FirstName = 'Davide', LastName = 'Catindoye', MobilePhone = '0421546324', Phone = '0421546324', Email = 'davidcatindoy@gmail.co.in', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
        Database.insert(newCon);

        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User']; 
        User bspUser = new User(Alias = 'bspUser', Email='davidcatindoy@gmail.co.in', ContactId = newCon.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='davidcatindoy@gmail.com.bsp');
                          
        Database.insert(bspUser);
        
        AddressExtension mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
        Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];            
        try{
            Test.startTest();
                Contact newCon1 = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546324', Phone = '0421546324', Email = 'davidcatindoy@gmail.com', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
                bspRegistrationUplift.save(JSON.serialize(mailingAddress), billAccount.Organisation__r.Name, billAccount.LEGACY_ID__c, JSON.serialize(newCon1));	
            Test.stopTest();
        } catch(Exception e) {
            System.assert(e!=null);
            System.debug('error' + e);
        }
	}
	
	static testMethod void testCreateNewUser() {
            Billing_Account__c billAccount = [SELECT Id, Organisation__r.Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
            Contact newCon = new Contact(FirstName = 'David x', LastName = 'Catindoy x', MobilePhone = '0421549999', Phone = '0421546325', Email = 'davidcatindoyxx@gmail.com', BillingAccount__c = billAccount.Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
            Database.insert(newCon);
            AddressExtension mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');

            Test.startTest();
                bspRegistrationUplift.save(JSON.serialize(mailingAddress), billAccount.Organisation__r.Name, billAccount.LEGACY_ID__c, JSON.serialize(newCon));
            Test.stopTest();
            
            System.assert([SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE UserName = 'davidcatindoyxx@gmail.com.bsp' LIMIT 1] != null);
            System.assert(![SELECT Id FROM CASE].isEmpty());
	}
    static testMethod void testCreateNewUser_ContactExist() {
        	Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Phone = '0421546325', Email = 'davidcatindoy@gmail.com', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
            Database.insert(newCon);
        	//inserting a duplicate contact without Billing Account
	        Contact newCon1 = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Phone = '0421546325', Email = 'davidcatindoy@gmail.com.bsp', Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
            Database.insert(newCon1);
        	//Contact c = [SELECT id, FirstName, LastName, Phone, Email FROM CONTACT LIMIT 1];
            AddressExtension mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');


	        Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];            
        	try{
                Test.startTest();
					bspRegistrationUplift.save(JSON.serialize(mailingAddress), billAccount.Organisation__r.Name, billAccount.LEGACY_ID__c, JSON.serialize(newCon));	
                Test.stopTest();
            } catch(Exception e) {
                System.assert(e!=null);
                System.debug('error' + e);
            }
	}
	static testMethod void testCreateNewUser_badBillingAccount() {
            Billing_Account__c billAccount = [SELECT Id, Organisation__r.Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
            Contact newCon = new Contact(FirstName = 'David x', LastName = 'Catindoy x', MobilePhone = '0421549999', Phone = '0421546325', Email = 'davidcatindoyxx@gmail.com', BillingAccount__c = billAccount.Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
            Database.insert(newCon);
            AddressExtension mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');

            try {
                Test.startTest();
                    bspRegistrationUplift.save(JSON.serialize(mailingAddress), 'badBillingAccountName', 'badAccountLegacyID', JSON.serialize(newCon));
                Test.stopTest();            
            } catch(Exception e) {
                System.assertEquals(e.getMessage(),'Your account is not created. Please provide the right Business Name and Business Credit Account.');
            }
    }  
    
    static testmethod void testGetCountries() {
		CountryCodes__c countriesCodes = new CountryCodes__c(name='Australia', Alpha2__c='AU', Alpha3__c='AUS', Numeric__c=36);
		insert countriesCodes;
		test.startTest();
        List<bspRegistrationUplift.SelectOptionCustom> countries = bspRegistrationUplift.getCountries();
        System.assertEquals(countries[0].label, 'Australia');
		test.stopTest();
	}
	/*
	static testMethod void testCreateNewUserWithCaseError() {
	        Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
	        //Test.setCurrentPage(Page.bspRegistrationUplift);
            Test.startTest();
                //bspRegistrationUplift bspReg = new bspRegistrationUplift();
                bspRegistrationUplift.c.FirstName = 'David';
                bspRegistrationUplift.c.LastName = 'Catindoy';
                bspRegistrationUplift.c.Email = 'davidcatindoy@gmail.com';
                bspRegistrationUplift.c.Phone = '1728394';
                bspRegistrationUplift.businessName = billAccount.Organisation__r.Name;
                bspRegistrationUplift.businessNumber = billAccount.LEGACY_ID__c;
                bspRegistrationUplift.mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
                bspRegistrationUplift.save(JSON.serialize(bspRegistrationUplift.mailingAddress), bspRegistrationUplift.businessName, bspRegistrationUplift.businessNumber, JSON.serialize(bspRegistrationUplift.c));
            Test.stopTest();
            
            System.assert([SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE UserName = 'davidcatindoy@gmail.com.bsp' LIMIT 1] != null);
            System.assert([SELECT Id FROM CASE].isEmpty());
	}
	
	
	
	static testMethod void testCreateNewUser_UserExist() {
	        
	        Contact newCon = new Contact(FirstName = 'Test', LastName = 'Cont', MobilePhone = '0421546325', Email = 'test@test.com', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
            Database.insert(newCon);
            
            Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User']; 
            User bspUser = new User(Alias = 'bspUser', Email='davidcatindoy@gmail.com', ContactId = newCon.Id, EmailEncodingKey='UTF-8', LastName='Catindoy', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='davidcatindoy@gmail.com.bsp');
                              
            Database.insert(bspUser);
            
	        Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
	        //Test.setCurrentPage(Page.bspRegistrationUplift);
            Test.startTest();
                //bspRegistrationUplift bspReg = new bspRegistrationUplift();
                //bspReg.redirect();
                bspRegistrationUplift.c.FirstName = 'David';
                bspRegistrationUplift.c.LastName = 'Catindoy';
                bspRegistrationUplift.c.Email = 'davidcatindoy@gmail.com';
                bspRegistrationUplift.c.Phone = '1728394';
                bspRegistrationUplift.businessName = billAccount.Organisation__r.Name;
                bspRegistrationUplift.businessNumber = billAccount.LEGACY_ID__c;
                bspRegistrationUplift.mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
                bspRegistrationUplift.save(JSON.serialize(bspRegistrationUplift.mailingAddress), bspRegistrationUplift.businessName, bspRegistrationUplift.businessNumber, JSON.serialize(bspRegistrationUplift.c));
                //System.assert(ApexPages.hasMessages());
            Test.stopTest();
	}  */

}