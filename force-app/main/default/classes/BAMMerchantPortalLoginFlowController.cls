public with sharing class BAMMerchantPortalLoginFlowController {

	public Boolean agreeTsAndCs {get;set;}
	public Boolean isError {get;set;}

	public PageReference checkTandC() {
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