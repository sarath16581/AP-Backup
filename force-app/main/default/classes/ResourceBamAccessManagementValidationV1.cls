/**************************************************
Description :               Webservice to validate the requested contact can be onboarded to the BAM Access Management App
Custom Metadatatype :       ResourceAPI__mdt
/api/1.0/bam/accessmanagement/validate (contact id in Request Body)

History:
--------------------------------------------------
2019-07-02  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class ResourceBamAccessManagementValidationV1 extends ResourceAPIService.IApi {
	/**
     * Handle the provisioning validation request for Access Management
     * Camunda is expecting either a 204 response if the validation was successful or a 500 with an error response if the validation failed.
     */
	public override ResourceAPIService.IResourceResponse post() {

		try {
			// check to make sure the logged in user has access to be able to make these calls
			if(!BAMUserUtility.currentUserHasBAMApiAccess()){
				return new AccessManagementValidationApiSynchronousResourceResponse(500, 'Error', '500', Label.BAMBSP_No_Access);
			} else {

				// In case on multiple validation error , need to pass all errors.
				List<String> errors = new List<String>();

				String requestContactId;

				//Contact ID and primaryBilling account sourced from the JSON body
				Map<String, Object> results = null;
				Map<String, Object> contactAttributes = null;
				User requestedUser = null;

				// catch an errors with parsing the body
				try {
					results = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
					contactAttributes = (Map<String, Object>)results.get('contact');
					if(contactAttributes == null) contactAttributes = new Map<String, Object>();

					requestContactId  = String.valueOf(contactAttributes.get('id'));
				} catch(Exception ex) {} // do nothing

				// catch any 'validation' system errors.
				try {
					if (!String.isEmpty(requestContactId)) {
						// retrieve the user details
						requestedUser = BAMUserUtility.retrieveContactUserDetail(requestContactId);

						//validate the contact that was passed in to ensure a BSP account can be provisioned against it.
						errors.addAll(validateUser(requestedUser));

					} else {
						errors.add(Label.BAMBSP_User_Record_Not_Found);
					}

					// if there are errors then we need to feed these back via an asynchronous response (the synchronous response will still return a 204 acknowledgement)
					if (errors.isEmpty()) {
						return new AccessManagementValidationApiSynchronousResourceResponse(204, 'Fulfilled');
					} else {
						System.debug(errors);
						return new AccessManagementValidationApiSynchronousResourceResponse(500, 'Error', '500', String.join(errors, '\n'));
					}
				} catch(Exception ex) {
					return new AccessManagementValidationApiSynchronousResourceResponse(500, 'Error', '500', ex.getMessage());
				}
			}
		} catch(Exception e) {
			return new AccessManagementValidationApiSynchronousResourceResponse(500, 'Error', '500', e.getMessage());
		}
	}

	/**
	 * validate the User can be onboarded to access management.
	 */
	public static List<String> validateUser(User matchedUser) {
		List<String> errors = new List<String>();

		if(matchedUser == null || matchedUser.ContactId == null) {
			errors.add(Label.BAMBSP_User_Record_Not_Found);
		} else {

			// check whether contact's org has application asset
			if (!accessManagementAssetExists(matchedUser.Contact.AccountId)) {
				errors.add('Access Management application is not available to your Organisation'); // TODO <-- custom label
			}

			// Check contact is active and not a person account
			if ('Active'.equalsIgnoreCase(matchedUser.Contact.Status__c) == false || matchedUser.Contact.IsPersonAccount == true) {
				errors.add(Label.BAMBSP_Contact_Not_Active);
			}

			// ensure this user will not exceed the maximum number of users allowed to be onboarded to Access Management
			if(getAccessManagementUserCount(matchedUser.Contact) >= BAMUserUtility.ACCESS_MANAGEMENT_MAX_PER_ORG) {
				errors.add('Your organisation has reached the maximum allowed number of ' + BAMUserUtility.ACCESS_MANAGEMENT_MAX_PER_ORG + ' admins'); // TODO <-- custom label
			}

		}

		return errors;
	}

	/**
	 *  Validate whether the requested contact's Organisation has BSP App Asset
	 */
	public static Boolean accessManagementAssetExists(Id accountId){
		Integer i = [Select Count() FROM BAMApplication__c
					WHERE Status__c = 'Active'
					AND AppKey__c = :BAMUserUtility.ACCESS_MANAGEMENT_APP_KEY
					AND Product__c IN (Select Product2Id From Asset Where Status = 'Active' And AccountId = :accountId)];
		return (i > 0);
	}

	/**
	 * Return a count of the number of contacts that have an active or pending provisioning for a super admin for the Access Management application
	 * This excludes the current user if they already have access since provisioning again won't increase the overall count.
	 */
	public static Integer getAccessManagementUserCount(Contact contact) {
		Integer counter = [
				Select Count() From BAMContactRole__c
				Where ContactApplication__r.Contact__r.AccountId = :contact.AccountId
				And ContactApplication__r.Application__r.AppKey__c = :BAMUserUtility.ACCESS_MANAGEMENT_APP_KEY
				And ApplicationRole__r.Role__c = :BAMUserUtility.ACCESS_MANAGEMENT_SUPER_ADMIN
				And Status__c In ('Active', 'Pending')
				And ContactApplication__r.Status__c In ('Active', 'Pending')
				And ContactApplication__r.Contact__r.Status__c = 'Active'
				And ContactApplication__r.Contact__c != :contact.Id
		];
		return counter;
	}

	public class AccessManagementValidationApiSynchronousResourceResponse extends ResourceAPIService.IResourceResponse {

		public AccessManagementValidationApiSynchronousResourceResponse(Integer responseCode, String status) {
			this(responseCode, status, '', '');
		}

		public AccessManagementValidationApiSynchronousResourceResponse(Integer responseCode, String status, String errorCode, String errorMessage) {
			output.put('status', status);

			if(!String.isEmpty(errorCode)) {
				output.put('code', errorCode);
			}

			if(!String.isEmpty(errorMessage)) {
				output.put('message', errorMessage);
			}

			this.responseCode = responseCode;
		}
	}
}