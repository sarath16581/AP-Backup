/**************************************************
Description:    Retrieves the user details of the currently logged in user (if any)
History:
--------------------------------------------------
2019-08-30  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class AdobeAnalyticsInterfaceCmpController {

	/**
	 * Retrieve any user specific user details to pass to adobe analytics
	 */
	@AuraEnabled
	public static WrapperUserDetails retrieveUserDetails() {
		WrapperUserDetails output = new WrapperUserDetails();

		if(UserInfo.getUserId() == null) {
			return output;
		}

		Contact contact = [Select Contact.Id, Contact.APCN__c From User Where Id = :UserInfo.getUserId()].Contact;
		output.isLoggedIn = true;

		if(contact != null) {
			output.apcn = contact.APCN__c;
		}
		return output;
	}

	public class WrapperUserDetails {
		@AuraEnabled public String apcn;
		@AuraEnabled public Boolean isLoggedIn = false;
	}

}