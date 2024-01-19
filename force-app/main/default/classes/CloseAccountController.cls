/**
* @author SteveL
* @date 2024-01-19
* @description This is the controller class for the closeAccount lwc

* @changelog
* 2024-01-19 - SteveL - Created
*/
public inherited sharing class CloseAccountController {
	private static final String DEFAULT_BASE_URL = 'http://hxaix23.hq.auspost.com.au:50000/irj/go/km/docs/SAP_AusPost_Web_Content/Enterprise/Display/PortalUniqueRedirectSecure.html?URL=sapfes.hq.auspost.com.au/sap/bc/ui5_ui5/sap/zcs_cac/index.html#/apcn/';

	@AuraEnabled
	public static String getBaseUrl(){
		String baseUrl = Close_Account_Base_URL__c.getOrgDefaults().Base_URL__c;
		return baseUrl == null ? DEFAULT_BASE_URL : baseUrl;
	}

	@AuraEnabled
	public static String getAPCN(String accId){
		return AccountsSelector.newInstance().selectById(new Set<Id>{accId}).get(accId).APCN__c;
	}
}