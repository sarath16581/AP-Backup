/**************************************************
Type:       Lightning Utility Controller Test class (LightningUtilityController)
History:
--------------------------------------------------
28-May-2018: Hasantha.Liyanage@auspost.com.au created
2023-08-28	Naveen Rajanna	REQ3286437 - Changed api version and removed hard coded URL to use apex methods to generate URL
**************************************************/
@isTest
public class LightningUtilityController_Test {

	@testSetup
	static void setupTest(){
		//inserting custom settings for url retrival
		AusPostSettings__c auSetting = new AusPostSettings__c(Name = 'VF_Iframe_Instance_URL', URL__c = System.URL.getSalesforceBaseUrl().toExternalForm());
		insert auSetting;
		//inserting custom settings for enable cache
		CacheSettings__c setting = new CacheSettings__c (CacheEnabled__c = true);
		insert setting;
	}

	/**
	 * These tests are just to get the coverage
	 */
	public static testMethod void LightningUtilityController_Test() {
		LightningUtilityController ctrl = new LightningUtilityController();
		// tests for retrieve field labels
		LightningUtilityController.getSObjectFieldLabels(new List<String>{'Account.Type'});
		// test for retrieve picklist values
		LightningUtilityController.getSObjectFieldPicklistValues(new List<String>{'Account.Type'});
		// test for retrieve custom setting values by name
		LightningUtilityController.getSystemCustomSettingListByName('AusPostSettings__c','VF_Iframe_Instance_URL');
	}

}