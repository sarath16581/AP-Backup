/**************************************************
Description:    Controller class to handle the Merchant Portal Home page
History:
--------------------------------------------------
2019-05-27  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class BAMMyApplicationsController {

	/**
     * Retrieve a list of application rules that are configured for the current logged in user has access to
     * This will also only return a list of applications that user organisation has access to.
     */
	@AuraEnabled
	public static String retrieveCurrentUserContactApplications() {
		try {
			List<ApplicationWrapper> output = new List<ApplicationWrapper>();
			Contact con = BAMUserUtility.getUserContact(UserInfo.getUserId());

			// only proceed if the contact is active
			if(BAMUserUtility.CONTACT_STATUS_ACTIVE.equalsIgnoreCase(con.Status__c)) {

				List<BAMApplication__c> applications = BAMUserUtility.getApplicationRolesForAccount(con.AccountId);
				Set<Id> applicationIds = new Set<Id>();
				for (BAMApplication__c app : applications) {
					applicationIds.add(app.Id);
				}

				for (BAMContactApplication__c contactApp : BAMUserUtility.getContactApplicationConfig(con.Id)) {
					if (applicationIds.contains(contactApp.Application__c)) {

						ApplicationWrapper wrapper = new ApplicationWrapper();
						wrapper.applicationId = contactApp.Application__r.Id;
						wrapper.applicationName = contactApp.Application__r.Name;
						wrapper.applicationKey = contactApp.Application__r.AppKey__c;
						wrapper.description = contactApp.Application__r.Description__c;
						wrapper.shortDescription = contactApp.Application__r.ShortDescription__c;
						wrapper.accessUrl = contactApp.Application__r.AccessUrl__c;
						wrapper.launchInNewWindow = contactApp.Application__r.LaunchApplicationInNewWindow__c;
						wrapper.iconRef = contactApp.Application__r.SVGRefId__c;
						wrapper.isActive = BAMUserUtility.contactApplicationIsActive(contactApp);
						wrapper.isPending = BAMUserUtility.contactApplicationIsPendingProvision(contactApp);


						output.add(wrapper);
					}
				}
			}

			return JSON.serialize(output);
		} catch(Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Retrieves current user's contact records information
	 */
	@AuraEnabled
	public static String retrieveUserContactInfo(){
		try {
			Id userId  = UserInfo.getUserId();
			User user = [SELECT Id, Name, Contact.FirstName, Contact.LastName, Contact.Name, Contact.AccountId, ContactId, Contact.Status__c FROM User WHERE Id =: userId];
			return JSON.serialize(user.Contact);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	public class ApplicationWrapper {
		public String applicationName;
		public String applicationKey;
		public Boolean isPending;
		public Boolean isActive;
		public String applicationId;
		public String accessUrl;
		public Boolean launchInNewWindow;
		public String description;
		public String shortDescription;
		public String iconRef;
	}

}