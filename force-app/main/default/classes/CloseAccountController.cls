/**
* @author SteveL
* @date 2024-01-19
* @description This is the controller class for the closeAccount lwc

* @changelog
* 2024-01-19 - SteveL - Created
*/
public inherited sharing class CloseAccountController {

	@AuraEnabled
	public static String getBaseUrl(){
		return Close_Account_Base_URL__c.getOrgDefaults().Base_URL__c;
	}

	@AuraEnabled
	public static String getAPCN(String accId){
		return AccountsSelector.newInstance().selectById(new Set<Id>{accId}).get(accId).APCN__c;
	}
}