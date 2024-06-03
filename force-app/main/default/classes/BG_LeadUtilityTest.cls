/****************************************************************************************
Author:		Jansi
Company:		CRMIT Solutions
Description:	Test class to cover BG_LeadUtility functionality
History:
-----------------------------------------------------------------------------------------
17.02.2020	  Jansi (CRMIT Solutions)			Test class created
13-03-2020	  Jansi							  Added 'leadCreationWithStandardRecordType' method
02-06-2020	  Jansi							  Added BG_LeadUtility.assignLeadOwner(new List<Id>{l.Id});
30-08-2020	  Arjun.Singh@auspost.com.au		 Modified methods to overcome incorporate newly added validation rule
05-11-2020	  Suman Gunaganti					Added test method for HVS Sales Cadence logic 
05-10-2021	  Seth Heang			 Uplift SF API version to 52 and fix test class failure due to new validation rule
05-02-2024		Talib Raza 							INC2217553 - Uplift to version 59
08-05-2024 - Ranjeewa Silva - Updated test after removing duplicate address validation in code.
*****************************************************************************************/
@isTest
public class BG_LeadUtilityTest {
	
	@testSetup
	static void setupTestData() {
		SystemSettings__c testCS = SystemSettings__c.getInstance();
		testCS.Disable_Triggers__c = FALSE;
		UPSERT testCS;
		
		  
		// Create users for further use
		Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		
		Profile bgBaseProfile = [SELECT Id FROM Profile WHERE Name = 'BG Base'];

		User user1 = new User(
			Alias = 'testname', Email = 'test@auspost.com.au',
			EmailEncodingKey = 'UTF-8', LastName = 'xTesting', LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
			TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestX@auspost.com.au.def',
			EmployeeNumber = '10000'
		);
		insert user1;
		System.runas(user1){
			
			User bgUser = new User(
				Alias = 'bgcore', Email = 'bgcoreuser12345@auspost.com.au',
				EmailEncodingKey = 'UTF-8', LastName = 'xTesting123', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
				TimeZoneSidKey = 'America/Los_Angeles', UserName = 'bgcoreuser12345@auspost.com.au.def',
				EmployeeNumber = '10009'
			);
			insert bgUser;
			
			String bgcorePermissionSetId = [SELECT Id FROM PermissionSet WHERE Name='BG_Core' LIMIT 1].Id ;
			//--Create a user
			PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = bgcorePermissionSetId, AssigneeId = bgUser.Id);
			insert psa;
		}
		
		User user2 = new User(
			Alias = 'testname', Email = 'test@auspost.com.au',
			EmailEncodingKey = 'UTF-8', LastName = 'yTesting', LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
			TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestY@auspost.com.au',
			EmployeeNumber = '10001'
		);
		insert user2;
		
		User user3 = new User(
			Alias = 'testRun', Email = 'test@auspost.com.au',
			EmailEncodingKey = 'UTF-8', LastName = 'zTesting', LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
			TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestZ@auspost.com.au',
			EmployeeNumber = '10002'
		);
		insert user3;
			   
		User bgSalesUser = new User(
			Alias = 'bgcore', Email = 'bgsale9009@auspost.com.au',
			EmailEncodingKey = 'UTF-8', LastName = 'bgsalesLname', LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US', ProfileId = bgBaseProfile.Id, isActive = true,
			TimeZoneSidKey = 'America/Los_Angeles', UserName = 'bgsale9009@auspost.com.au',
			EmployeeNumber = '12009'
		);
		insert bgSalesUser;
		
		// Create territory assignment matrices
		// Matrix with both low threshold and high threshold
		Territory_Assignment_Matrix__c matrixWithBothThreshold = new Territory_Assignment_Matrix__c();
		matrixWithBothThreshold.Post_Code__c = '3006';
		matrixWithBothThreshold.Product__c = 'Australia Post - Parcel Services';
		matrixWithBothThreshold.Sales_Team__c = 'Acquisition Team';
		matrixWithBothThreshold.Sales_Team_Member__c = user1.id;
		matrixWithBothThreshold.Low_Threshold_Amount__c = 40000.01;
		matrixWithBothThreshold.High_Threshold_Amount__c = 80000;
		insert matrixWithBothThreshold;
		
		// Matrix without high threshold
		Territory_Assignment_Matrix__c matrixWithoutHighThresh = new Territory_Assignment_Matrix__c();
		matrixWithoutHighThresh.Post_Code__c = '3161';
		matrixWithoutHighThresh.Product__c = 'Australia Post - Mail Services';
		matrixWithoutHighThresh.Sales_Team__c = 'Acquisition Team';
		matrixWithoutHighThresh.Sales_Team_Member__c = user2.id;
		matrixWithoutHighThresh.Low_Threshold_Amount__c = 40000.01;
		insert matrixWithoutHighThresh;
		
		ConfigSetting__c configSetting = new ConfigSetting__c(
			OpportunityDriverDefaultUserId__c = user3.Id
		);
		
		insert configSetting;
		
		//create products
		List<Product2> productList = new List<Product2>();
		Product2 bundle1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('International Bundle', TRUE);
		productList.add(bundle1);
		
		Product2 bundle2 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Road Express - STE', TRUE);
		productList.add(bundle2);
		
		Product2 bundle3 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('eParcel Express', TRUE);
		productList.add(bundle3);
		
		Product2 bundle4 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Boxes and Bags Others', TRUE);
		productList.add(bundle4);
		
		insert productList;
		
		//Create your pricebook entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry = new PricebookEntry();
		
		List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
		for(Product2 testProd : productList){
			pbEntry = new PricebookEntry();
			pbEntry.Pricebook2Id = pricebookId;
			pbEntry.Product2Id = testProd.Id;
			pbEntry.UnitPrice = 100.00;
			pbEntry.IsActive = true;
			pbEntryList.add(pbEntry);
		}
		
		insert pbEntryList;
  
	}
	
  
	
	/**
* SCENARIO: The Lead's estimated value is lower than territory's lower threshold.
* */
	@isTest
	static void LeadUtility_assignSalesRep_lowerThanTerritoryLowThreshold() {
		RecordType bgRecordType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Lead' AND Name = 'BG_Standard' limit 1];
		User bgCoreUser = [Select Id FROM User WHERE Email='bgcoreuser12345@auspost.com.au'];
		Lead l = new Lead();
		Test.startTest();
		System.runAs(bgCoreUser){
			
			l.firstname = 'lowerThanLowThreshold';
			l.lastname = 'ln';
			l.PostalCode = '3006';
			l.RecordTypeId = bgRecordType.Id;
			l.Company ='Test';
			l.Product__c = 'Australia Post - Parcel Services';
			l.Opportunity_Initial_Estimate__c = 40000;
			l.ABN__c='53004085616';
			l.email= 'abc@gmail.com';
			l.phone= '0456717340';
			l.Address_Validated__c = true; 
			l.PostalCode = '3006';
			l.street = 'TestStreet';
			l.City = 'TestCity';
			l.State = 'TestState';
			
			insert l;
			
			l.Status = 'Qualified';
			l.Qualification_Completed__c =true;
			l.Customer_Type__c = 'New Customer';
			l.CNA_Status__c = 'Completed';
			update l;
			
			//-- Executing 'lead mapping'incase PB will fail 
			BG_LeadUtility.assignLeadOwner(new List<Id>{l.Id});
		}
		Test.stopTest();
		
		l = [SELECT Id, OwnerId from Lead WHERE Id = :l.Id];

		String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;
		System.assertEquals(defaultSalesRep, l.OwnerId,
							'BG_LeadUtility_assignSalesRep_smallerThanTerritoryLowThreshold : defaultSalesResp should be assigned if the estimate is too low');
	}
	
	/**
* SCENARIO: The Lead's estimated value is higher than territory's high threshold.
* */
	@isTest
	static void LeadUtility_assignSalesRep_higherThanTerritoryHighThreshold() {
		
		RecordType bgRecordType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Lead' AND Name = 'BG_Standard' limit 1];
		User bgCoreUser = [Select Id FROM User WHERE Email='bgcoreuser12345@auspost.com.au'];

		Lead l = new Lead();
		Test.startTest();
		System.runAs(bgCoreUser){
			
			l.firstname = 'lowerThanLowThreshold';
			l.lastname = 'ln';
			l.PostalCode = '3006';
			l.RecordTypeId = bgRecordType.Id;
			l.Company ='Test';
			l.Product__c = 'Australia Post - Parcel Services';
			l.Opportunity_Initial_Estimate__c = 80000.01;
			l.ABN__c='53004085616';
			l.email= 'abc@gmail.com';
			l.phone= '0456717340'; 
			l.Address_Validated__c = true;
			l.PostalCode = '3006';
			l.street = 'TestStreet';
			l.City = 'TestCity';
			l.State = 'TestState';
			
			insert l;
			
			l.Status = 'Qualified';
			l.Customer_Type__c = 'New Customer';
			l.Qualification_Completed__c =true;
			l.CNA_Status__c = 'Completed';
			update l;
			
			//-- Executing 'lead mapping'incase PB will fail in test Context (If BG Core Permission set is not present in ORG)
			BG_LeadUtility.assignLeadOwner(new List<Id>{l.Id}); 
			
		}
		Test.stopTest();
		
		l = [SELECT Id, OwnerId from Lead WHERE Id = :l.Id];
		String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;
		System.assertEquals(defaultSalesRep, l.OwnerId,
							'LeadUtility_assignSalesRep_higherThanTerritoryHighThreshold : defaultSalesResp should be assigned if the estimate is too high');
	}
	
	/**
* SCENARIO: The Lead's estimated value is within the territory's threshold.
* */
	@isTest
	static void OpportunityUtility_assignSalesRep_fitsThreshold() {
		
		RecordType bgRecordType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Lead' AND Name = 'BG_Standard' limit 1];
		User bgCoreUser = [Select Id FROM User WHERE Email='bgcoreuser12345@auspost.com.au'];
		Lead l = new Lead();
		Test.startTest();
		System.runAs(bgCoreUser){
			//-- insert Lead
			l.firstname = 'lowerThanLowThreshold';
			l.lastname = 'ln';
			l.PostalCode = '3006';
			l.RecordTypeId = bgRecordType.Id;
			l.Company ='Test';
			l.street = 'TestStreet';
			l.City = 'TestCity';
			l.State = 'TestState';
			l.Product__c = 'Australia Post - Parcel Services';
			l.Opportunity_Initial_Estimate__c = 80000;
			l.ABN__c='53004085616'; 
			l.email= 'abc@gmail.com';
			l.phone= '0456717340';
			l.Address_Validated__c = true;
			l.PostalCode = '3006';
			
			insert l;
			
			//--Update Lead
			l.Status = 'Qualified';
			l.Customer_Type__c = 'New Customer';
			l.Qualification_Completed__c =true;
			l.CNA_Status__c = 'Completed';
			update l;
			
			//-- Executing 'lead mapping'(If BG Core Permission set is not present in ORG)
			BG_LeadUtility.assignLeadOwner(new List<Id>{l.Id}); 
			
		}
		Test.stopTest();
		
		l = [SELECT Id, OwnerId from Lead WHERE Id = :l.Id];
		User salesTeamMember = [SELECT Id FROM User WHERE Username = 'auTestX@auspost.com.au.def'];
		
		System.assertEquals(salesTeamMember.Id, l.OwnerId,
							'LeadUtility_assignSalesRep_fitsThreshold : opportunity should be assigned to the sales team');
	}
	
	/**
* SCENARIO: If Lead is created with 'Standard' recordtype then updating it to 'BG_Standard' recordtype
* */
	@isTest
	static void leadCreationWithStandardRecordType() {
		List<RecordType> recordTypeList = [SELECT Id, DeveloperName FROM RecordType where SobjectType ='Lead' and DeveloperName IN('Standard','BG_Standard')];
		String standardRecTypeId;
		String bgStandardRecTypeId;
		
		for(RecordType recType:recordTypeList){
			if(recType.DeveloperName == 'Standard'){
				standardRecTypeId = recType.Id;
			}else if(recType.DeveloperName == 'BG_Standard'){
				bgStandardRecTypeId = recType.Id;
			}
		}
		Test.startTest();
		Lead l = new Lead();
		l.FirstName = 'fn_firstName';
		l.LastName='ln_lastName';
		l.PostalCode = '3006';
		l.Company ='Test';
		l.street = 'TestStreet';
		l.City = 'TestCity';
		l.State = 'TestState';
		l.Product__c = 'Australia Post - Parcel Services';
		l.Opportunity_Initial_Estimate__c = 80000;
		l.ABN__c='53004085616'; 
		l.email= 'abc@gmail.com';
		l.phone= '0456717340';
		l.Address_Validated__c = true;
		l.PostalCode = '3006';
		l.recordTypeId =standardRecTypeId;
		insert l;
		
		Lead insertedLead = [SELECT ID, RecordTypeId FROM Lead WHERE ID=:l.Id];
		
		System.assertEquals(bgStandardRecTypeId, insertedLead.RecordTypeId, 'Lead RecordType should be "BG_Standard" type');
		Test.stopTest();
	}

	/**
* SCENARIO: Validating Lead before Qualification
* */
	@isTest
	static void testValidateLeadFields(){
		Lead l = new Lead();
		l.firstName = 'testFirstName';
		l.lastName = 'testLastName';
		l.email = 'test@example.com';
		l.phone = '0400809987';
		l.leadsource = 'email';
		l.status = 'In Progress';
		l.recordTypeId = Schema.sObjectType.lead.getRecordTypeInfosByName().get('BG_Standard').getRecordTypeId();
		insert l;

		l.Status = 'Qualified';
		l.FirstName = Null;
		l.LastName = Null;
		l.Phone = Null;
		Test.startTest();
		try {
			update l;
		} catch (Exception e) {
			System.assert(e.getMessage().contains('Please provide First Name, Last Name, Customer Type and either \'Phone or Mobile\''));
		}
		Test.StopTest();
	}
	/**
	 * SCENARIO: Sales Cadence trigger for In Progress and Qualified leads
	 */
	@isTest
	static void testSalescadenceTriggerProcess(){
		User bgSalesUser = [Select Id FROM User WHERE Email='bgsale9009@auspost.com.au'];
		
		Lead l = new Lead();
		l.firstName = 'testFirstName';
		l.lastName = 'testLastName';
		l.email = 'test@example.com';
		l.phone = '0400809987';
		l.leadsource = 'email';
		l.status = 'In Progress';
		l.recordTypeId = Schema.sObjectType.lead.getRecordTypeInfosByName().get('BG_Standard').getRecordTypeId();
		insert l;
		Test.startTest();
			l.OwnerId = bgSalesUser.Id;
			update l;
		Test.stopTest();
	}
		/**
	 * SCENARIO: Remove disqualified leads from cadence
	 */
	@isTest
	static void testremoveLeadsFromCadence(){
		User bgSalesUser = [Select Id FROM User WHERE Email='bgsale9009@auspost.com.au'];

		Lead l = new Lead();
		l.firstName = 'testFirstName';
		l.lastName = 'testLastName';
		l.email = 'test@example.com';
		l.phone = '0400809987';
		l.leadsource = 'email';
		l.status = 'In Progress';
		l.recordTypeId = Schema.sObjectType.lead.getRecordTypeInfosByName().get('BG_Standard').getRecordTypeId();
		l.OwnerId = bgSalesUser.Id;
		insert l;
		Test.startTest();
			l.status = 'Disqualified';
			l.Disqualified_Lead_Reason__c = 'Other';
			update l;
		Test.stopTest();
	}
}