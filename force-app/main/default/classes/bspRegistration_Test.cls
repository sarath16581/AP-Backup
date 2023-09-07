/*------------------------------------------------------------
Author:        Test User
Company:       Accenture
Description:   Test Class for bspRegistration
History
Feb 27, 2017 - Test User - Created
------------------------------------------------------------*/

@isTest
private class bspRegistration_Test {
	
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

		Database.insert(new CCUSettings__c(
			DeliveryRecordTypeId__c = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId(),
			GeneralRecordTypeId__c = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId(),
			UsernameExtension__c = '.bsp',
			AttachmentSizeLimit__c = 5,
			DoNotShowFileNames__c = 'Do Not Show',
			CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id
		));

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
		
		Contact newCon = new Contact(FirstName = 'Test', LastName = 'User', MobilePhone = '0421546325', Email = 'test@test.com', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
		Database.insert(newCon);
		
		Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User']; 
		User bspUser = new User(Alias = 'bspUser', Email='user@testorg.a', ContactId = newCon.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						  LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
						  
		Database.insert(bspUser);
		
		System.runAs(bspUser){
			Test.startTest();
				Test.setCurrentPage(Page.bspRegistration);
				bspRegistration bspReg = new bspRegistration();
				PageReference pageRef = bspReg.redirect();
			Test.stopTest();
		}
	}
	
	static testMethod void testCreateNewUser() {	        
			Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
			Test.setCurrentPage(Page.bspRegistration);
			Test.startTest();
				bspRegistration bspReg = new bspRegistration();
				bspReg.redirect();
				bspReg.c.FirstName = 'Test';
				bspReg.c.LastName = 'User';
				bspReg.c.Email = 'test@test.com';
				bspReg.c.Phone = '1728394';
				bspReg.businessName = 'Test Org 1';
				bspReg.businessNumber = '6767888';
				bspReg.mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
				bspReg.save();
				System.assert(ApexPages.hasMessages());
				bspReg.businessName = billAccount.Organisation__r.Name;
				bspReg.businessNumber = billAccount.LEGACY_ID__c;
				bspReg.save();
			Test.stopTest();
			
			System.assert([SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE UserName = 'test@test.com.bsp' LIMIT 1] != null);
			System.assert(![SELECT Id FROM CASE].isEmpty());
	}
	
	static testMethod void testCreateNewUserWithCaseError() {
			Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
			Test.setCurrentPage(Page.bspRegistration);
			Test.startTest();
				bspRegistration bspReg = new bspRegistration();
				bspReg.redirect();
				bspReg.c.FirstName = 'Test';
				bspReg.c.LastName = 'User';
				bspReg.c.Email = 'test@test.com';
				bspReg.c.Phone = '1728394';
				bspReg.businessName = billAccount.Organisation__r.Name;
				bspReg.businessNumber = billAccount.LEGACY_ID__c;
				bspReg.mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
				bspReg.save();
			Test.stopTest();
			
			System.assert([SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE UserName = 'test@test.com.bsp' LIMIT 1] != null);
	}
	
	static testMethod void testCreateNewUser_ContactExist() {
			
			Contact newCon = new Contact(FirstName = 'Test', LastName = 'User', MobilePhone = '0421546325', Email = 'test@test.com', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
			Database.insert(newCon);
			
			Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
			Test.setCurrentPage(Page.bspRegistration);
			Test.startTest();
				bspRegistration bspReg = new bspRegistration();
				bspReg.redirect();
				bspReg.c.FirstName = 'Test';
				bspReg.c.LastName = 'User';
				bspReg.c.Email = 'test@test.com';
				bspReg.c.Phone = '1728394';
				bspReg.businessName = billAccount.Organisation__r.Name;
				bspReg.businessNumber = billAccount.LEGACY_ID__c;
				bspReg.mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
				bspReg.save();
				System.assert(ApexPages.hasMessages());
			Test.stopTest();
	}
	
	static testMethod void testCreateNewUser_UserExist() {
			
			Contact newCon = new Contact(FirstName = 'Test', LastName = 'Cont', MobilePhone = '0421546325', Email = 'test@test.com', BillingAccount__c = [SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c = 'P1234567'].Id, AccountId = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'].Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
			Database.insert(newCon);
			
			Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User']; 
			User bspUser = new User(Alias = 'bspUser', Email='test@test.com', ContactId = newCon.Id, EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
							  LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='test@test.com.bsp');
							  
			Database.insert(bspUser);
			
			Billing_Account__c billAccount = [SELECT Id, LEGACY_ID__c, Organisation__r.Name FROM Billing_Account__c WHERE Source_System__c = 'SAP ERP' LIMIT 1];
			Test.setCurrentPage(Page.bspRegistration);
			Test.startTest();
				bspRegistration bspReg = new bspRegistration();
				bspReg.redirect();
				bspReg.c.FirstName = 'Test';
				bspReg.c.LastName = 'User';
				bspReg.c.Email = 'test@test.com';
				bspReg.c.Phone = '1728394';
				bspReg.businessName = billAccount.Organisation__r.Name;
				bspReg.businessNumber = billAccount.LEGACY_ID__c;
				bspReg.mailingAddress = new AddressExtension('Charles St', 'Cuasay Ave', 'Melbourne', 'VIC', '3000', '7123', 'Australia');
				bspReg.save();
				System.assert(ApexPages.hasMessages());
			Test.stopTest();
	}

}