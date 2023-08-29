/**
 * 
 * @changelog
 * 2023-08-16 - Mahesh Parvathaneni - Executing the ThirdPartyAccountLink SOQL for running user for a workaround in MerchantPortalOIDCRegHandler 
 */

public with sharing class BAMMerchantPortalLoginFlowController {

	public Boolean agreeTsAndCs {get;set;}
	public Boolean isError {get;set;}

	public PageReference checkTandC() {
		//prime the thirdparty account links for the login user, so for the  subsequent logins we make sure 
		//confirmUser method in MerchantPortalOIDCRegHandler has always tpalId. This is due to the bug in salesforce (Case #44952215), 
		//TPAL Id can be null or empty until the ThirdPartyAccountLink SOQL is executed at least once.
		//This is due to SsoFlowHandler directly checking the virtual entity. Once the SOQL is executed, tpal can be obtained correctly
		List<ThirdPartyAccountLink> tpals = ThirdPartyAccountLinksSelector.newInstance(0, new Set<SObjectField>{ThirdPartyAccountLink.Id}).selectByUser(new Set<Id>{UserInfo.getUserId()});

		List<User> users = [Select Merchant_Portal_T_C_Last_Accepted__c From User Where Id = :UserInfo.getUserId()];
		Id networkId = Network.getNetworkId();

		if(networkId == null || networkId != BAMUserUtility.MERCHANT_PORTAL_NETWORK_ID || users.isEmpty() || !String.isEmpty(String.valueOf(users[0].Merchant_Portal_T_C_Last_Accepted__c))) {
			return Auth.SessionManagement.finishLoginFlow();
		} else {
			return null;
		}
	}

	public PageReference submit() {
		if(!agreeTsAndCs) {
			isError = true;
		} else {
			isError = false;
		}

		if(!isError) {
			return acceptConditions();
		} else {
			return null;
		}
	}

	/**
	 * Called once the button to accept t's and c's has been clicked
	 */
	public PageReference acceptConditions() {
		User u = new User(Id = UserInfo.getUserId(), Merchant_Portal_T_C_Last_Accepted__c = DateTime.now());
		update u;

		return Auth.SessionManagement.finishLoginFlow();
	}

}