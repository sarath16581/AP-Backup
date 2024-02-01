/**
 * @description Test class for Apex Class- APT_AccountDetails.
 * @author Jetha Ram
 * @date 2016-07-28
 * @changelog
 * 2016-07-28 - Jetha Ram - Created
 * 2024-01-30 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new validation rule in APT_Sub_Account__c.
 */
@isTest
private class APT_AccountDetails_Test 
{
	/** Creating test data **/	
	private static TestMethod void TestMethod1() 
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
			insert ca;
			
			APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Organisation__c = acc.Id;
			chargeAccount.APT_Street_Address_State__c = 'ACT';
			chargeAccount.APT_Business_name__c = 'Test Business Name';
			chargeAccount.APT_ABN__c = '12345678901';
			chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
			chargeAccount.APT_Holding_Company__c = true;
			insert chargeAccount;
			
			APT_Sub_Account__c sa = new APT_Sub_Account__c();
			sa.APT_Organisation__c = acc.Id;
			sa.APT_Charge_Account__c = chargeAccount.Id;
			sa.APT_Street_Address_State__c = 'ACT';
			sa.APT_Postal_Address_State__c = 'ACT';
			sa.APT_Branch__c = 'State Branch';
			sa.APT_Street_Address_Country_Code__c = 'AU';
			sa.APT_Postal_Address_Country_Code__c = 'AU';
			sa.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sa;
			
			Test.StartTest();
			
			ApexPages.currentPage().getParameters().put('Id', ca.Id);
			ApexPages.StandardController sc = new ApexPages.StandardController(ca);
			
			APT_AccountDetails acd = new APT_AccountDetails(sc);
			pagereference pageRef1 = acd.cancel();
			system.assert(pageRef1!=null);
		}
	}
	
	/** Creating test data **/	
	private static TestMethod void TestMethod2() 
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
			insert ca;
			
			APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Organisation__c = acc.Id;
			chargeAccount.APT_Street_Address_State__c = 'ACT';
			chargeAccount.APT_Business_name__c = 'Test Business Name';
			chargeAccount.APT_ABN__c = '12345678901';
			chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
			chargeAccount.APT_Holding_Company__c = true;
			insert chargeAccount;
			
			APT_Sub_Account__c sa = new APT_Sub_Account__c();
			sa.APT_Organisation__c = acc.Id;
			sa.APT_Charge_Account__c = chargeAccount.Id;
			sa.APT_Street_Address_State__c = 'ACT';
			sa.APT_Postal_Address_State__c = 'ACT';
			sa.APT_Branch__c = 'State Branch';
			sa.APT_Street_Address_Country_Code__c = 'AU';
			sa.APT_Postal_Address_Country_Code__c = 'AU';
			sa.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sa;
			
			Test.StartTest();
			
			ApexPages.currentPage().getParameters().put('Id', ca.Id);
			ApexPages.StandardController sc = new ApexPages.StandardController(ca);
			
			APT_AccountDetails acd = new APT_AccountDetails(sc);
			acd.save();
			system.assert(acd.cashAccList!=null);
			system.assert(acd.subAccList!=null);
			system.assert(acd.chargeAccList!=null);
		}
	}
	
	/** Creating test data **/	
	private static TestMethod void TestMethod3() 
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
			insert ca;
			
			APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
			chargeAccount.APT_Organisation__c = acc.Id;
			chargeAccount.APT_Street_Address_State__c = 'ACT';
			chargeAccount.APT_Business_name__c = 'Test Business Name';
			chargeAccount.APT_ABN__c = '12345678901';
			chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
			chargeAccount.APT_Holding_Company__c = true;
			insert chargeAccount;
			
			APT_Sub_Account__c sa = new APT_Sub_Account__c();
			sa.APT_Organisation__c = acc.Id;
			sa.APT_Charge_Account__c = chargeAccount.Id;
			sa.APT_Street_Address_State__c = 'ACT';
			sa.APT_Postal_Address_State__c = 'ACT';
			sa.APT_Branch__c = 'State Branch';
			sa.APT_Street_Address_Country_Code__c = 'AU';
			sa.APT_Postal_Address_Country_Code__c = 'AU';
			sa.APT_Sub_Account_Request_Status__c = 'Draft';
			insert sa;
			
			
			Test.StartTest();
			
			ApexPages.currentPage().getParameters().put('Id', ca.Id);
			ApexPages.StandardController sc = new ApexPages.StandardController(ca);
			
			APT_AccountDetails acd = new APT_AccountDetails(sc);
			pagereference pageRef2 = acd.export();
			system.assert(pageRef2!=null);
			Test.StopTest();
		}
	}
}