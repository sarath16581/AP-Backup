/**
 * @description Test class for Apex Class- APT_exportAccountDetailCtrl.
 * @author Jetha Ram
 * @date 2016-07-28
 * @changelog
 * 2016-07-28 - Jetha Ram - Created
 * 2024-01-30 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new validation rule in APT_Sub_Account__c.
 */
@isTest
private class APT_exportAccountDetailCtrl_Test 
{
	/** Creating test data **/	
	private static TestMethod void TestCashChargeSubAccount() 
	{
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {   
			
			//Create Account
			Account acc = APT_TestUtils.createOrganisation();
			acc.Type = 'Charge Account + Sub Account';
			acc.ACN__c = '123456789';
			acc.LEGACY_ID__c = '1001';
			insert acc;
			
			acc.LEGACY_ID__c = '60992317';
			update acc;
			
			APT_Cash_Account__c ca = new APT_Cash_Account__c();
			ca.APT_Organisation__c = acc.Id;
			ca.APT_Cust_Name__c = 'Test Customer';
			ca.APT_Cust_Email__c = 'jechoudhary@apttus.com';
			ca.APT_Cust_State__c = 'ACT';
			ca.APT_ABN__c = '12345678901';
			ca.APT_ACN__c = '123456789';
			ca.APT_Selected__c = true;
			insert ca;
			
			APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Organisation__c = acc.Id;
			chargeAccount.APT_Street_Address_State__c = 'ACT';
			chargeAccount.APT_Business_name__c = 'Test Business Name';
			chargeAccount.APT_ABN__c = '12345678901';
			chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
			chargeAccount.APT_Holding_Company__c = true;
			chargeAccount.APT_Selected__c = true;
			insert chargeAccount;
			
			APT_Sub_Account__c sa = new APT_Sub_Account__c();
			sa.APT_Organisation__c = acc.Id;
			sa.APT_Charge_Account__c = chargeAccount.Id;
			sa.APT_Street_Address_State__c = 'ACT';
			sa.APT_Postal_Address_State__c = 'ACT';
			sa.APT_Branch__c = 'State Branch';
			sa.APT_Street_Address_Country_Code__c = 'AU';
			sa.APT_Postal_Address_Country_Code__c = 'AU';
			sa.APT_Selected__c = true;
			sa.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sa;
			
			Test.StartTest();
			ApexPages.currentPage().getParameters().put('Id', acc.Id);
			
			APT_exportAccountDetailCtrl acd = new APT_exportAccountDetailCtrl();
			system.assert(acd.cashAccList!=null);
			system.assert(acd.subAccList!=null);
			system.assert(acd.chargeAccList!=null);
		}
	}
	
	private static TestMethod void TestLodgePoint() 
	{
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) 
		{   
			//Create Contact
			Contact con = APT_TestUtils.createContact();
			insert con;
			
			//Create Account
			Account acc = APT_TestUtils.createOrganisation();
			acc.Type = 'Charge Account + Sub Account';
			acc.ACN__c = '123456789';
			acc.LEGACY_ID__c = '60000000';
			insert acc;
			
			acc.LEGACY_ID__c = '60000000';
			update acc;
			
			APT_Cash_Account__c ca = new APT_Cash_Account__c();
			ca.APT_Organisation__c = acc.Id;
			ca.APT_Cust_Name__c = 'Test Customer';
			ca.APT_Cust_Email__c = 'jechoudhary@apttus.com';
			ca.APT_Cust_State__c = 'ACT';
			ca.APT_ABN__c = '12345678901';
			ca.APT_ACN__c = '123456789';
			ca.APT_Selected__c = true;
			insert ca;
			
			APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Organisation__c = acc.Id;
			chargeAccount.APT_Street_Address_State__c = 'ACT';
			chargeAccount.APT_Business_name__c = 'Test Business Name';
			chargeAccount.APT_ABN__c = '12345678901';
			chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
			chargeAccount.APT_Holding_Company__c = true;
			chargeAccount.APT_Selected__c = true;
			insert chargeAccount;
			
			APT_Sub_Account__c sa = new APT_Sub_Account__c();
			sa.APT_Organisation__c = acc.Id;
			sa.APT_Charge_Account__c = chargeAccount.Id;
			sa.APT_Street_Address_State__c = 'ACT';
			sa.APT_Postal_Address_State__c = 'ACT';
			sa.APT_Branch__c = 'State Branch';
			sa.APT_Street_Address_Country_Code__c = 'AU';
			sa.APT_Postal_Address_Country_Code__c = 'AU';
			sa.APT_Selected__c = true;
			sa.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sa;
		
			List<Account> accs = [SELECT Id, LEGACY_ID__c FROM Account];
			RecordType aptNwkRecordType = [SELECT Id, Name FROM RecordType WHERE DeveloperName = 'Delivery_1' AND sObjectType = 'Network__c' limit 1];

		
			//Create Network
			Network__c aptNwk = APT_TestUtils.createNetwork();
			aptNwk.Post_Code__c = '1000';
			aptNwk.Status__c = 'Open';

			// Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
			aptNwk.APT_Business_Unit__c = '10000000';
			aptNwk.Business_Unit__c = '10000000';
			aptNwk.RecordTypeID = aptNwkRecordType.ID; 
			insert aptNwk;
				
			String idd = aptNwk.ID;
			aptNwk = [Select id,Org_ID__c,Name,APT_DWS_ID__c,Post_Code__c,Status__c,State__c,
							 APT_eParcel_Enabled__c,Business_Unit__c,RecordTypeID,APT_Transport_Capability__c,
							 APT_MCAT__c,APT_Threshold_Categories__c,APT_Comments__c from Network__c where id =: idd];
		
			//Create Agreement
			Apttus__APTS_Agreement__c agID = APT_TestUtils.createAgreement(con.id);
			agID.Name = 'agId';
			insert agID;
			
			APT_Promo_Post_allowed_Lodgements__c objPromo = new  APT_Promo_Post_allowed_Lodgements__c();
			objPromo.Name = 'Promo Post';
			objPromo.APT_Post_code__c = '1000';
			insert objPromo;
			
			APT_Default_Billing_Account_Products__c objBAP = new APT_Default_Billing_Account_Products__c();
			objBAP.Name = 'Promo Post';
			insert objBAP;
			
			//Create Lodgement Zone
			APT_Lodgement_Zone__c lodZone= APT_TestUtils.getLodgementZone('Lodgement','Test');
			lodZone.APT_Post_Code_Start__c = 1;
			lodZone.APT_Post_Code_End__c = 9999;
			insert lodZone;
			
			//Create Billing Account 
			Billing_Account__c bacct = new Billing_Account__c();
			bacct.Legacy_Id__c = '60000000';
			bacct.Organisation__c = acc.Id;
			insert bacct; 
			
			//Create Agreement Lodgement Point
			APT_Agreement_Lodgement_Point__c objALP1 = APT_TestUtils.createLodgementPoint(acc.id,agID.id,aptNwk.id,lodZone.id,'Promo Post',bacct.id);
			objALP1.APT_Status__c = 'Active';
			objALP1.APT_Charge_Account__c = chargeAccount.ID;
			objALP1.APT_Cash_Account__c = ca.ID;
			objALP1.APT_Sub_Account__c = sa.ID;
			insert objALP1;

			//Create Second Agreement Lodgement Point
			APT_Agreement_Lodgement_Point__c objALP2 = APT_TestUtils.createLodgementPoint(acc.id,agID.id,aptNwk.id,lodZone.id,'Promo Post',bacct.id);
			objALP2.APT_Status__c = 'Active';
			objALP2.APT_Charge_Account__c = chargeAccount.ID;
			objALP2.APT_Cash_Account__c = ca.ID;
			objALP2.APT_Sub_Account__c = sa.ID;
			insert objALP2;
				
			Test.StartTest();
			
			ApexPages.currentPage().getParameters().put('Id', acc.Id);
			
			APT_exportAccountDetailCtrl acd = new APT_exportAccountDetailCtrl();
			System.assert(acd.agreementLPList != null);
		}
	}
	private static TestMethod void TestInstanceVariable() 
	{
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {   
			
			//Create Account
			Account acc = APT_TestUtils.createOrganisation();
			acc.Type = 'Charge Account + Sub Account';
			acc.ACN__c = '123456789';
			acc.LEGACY_ID__c = '1001';
			insert acc;
			
			acc.LEGACY_ID__c = '60992317';
			update acc;
			
			APT_Cash_Account__c ca = new APT_Cash_Account__c();
			ca.APT_Organisation__c = acc.Id;
			ca.APT_Cust_Name__c = 'Test Customer';
			ca.APT_Cust_Email__c = 'jechoudhary@apttus.com';
			ca.APT_Cust_State__c = 'ACT';
			ca.APT_ABN__c = '12345678901';
			ca.APT_ACN__c = '123456789';
			ca.APT_Selected__c = true;
			insert ca;
			
			APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Organisation__c = acc.Id;
			chargeAccount.APT_Street_Address_State__c = 'ACT';
			chargeAccount.APT_Business_name__c = 'Test Business Name';
			chargeAccount.APT_ABN__c = '12345678901';
			chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
			chargeAccount.APT_Holding_Company__c = true;
			chargeAccount.APT_Selected__c = true;
			insert chargeAccount;
			
			APT_Sub_Account__c sa = new APT_Sub_Account__c();
			sa.APT_Organisation__c = acc.Id;
			sa.APT_Charge_Account__c = chargeAccount.Id;
			sa.APT_Street_Address_State__c = 'ACT';
			sa.APT_Postal_Address_State__c = 'ACT';
			sa.APT_Branch__c = 'State Branch';
			sa.APT_Street_Address_Country_Code__c = 'AU';
			sa.APT_Postal_Address_Country_Code__c = 'AU';
			sa.APT_Selected__c = true;
			sa.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sa;
			
			Test.StartTest();
			
			ApexPages.currentPage().getParameters().put('Id', acc.Id);
			
			APT_exportAccountDetailCtrl acd = new APT_exportAccountDetailCtrl();
			Boolean isExcel = acd.isExcel;
			Boolean isCsv = acd.isCsv;
			String xlsHeader = acd.xlsHeader;
			
			System.assert(isExcel == null);
			System.assert(isCsv == null);
			System.assert(xlsHeader == APT_constants.strHeader);
		}
	}
}