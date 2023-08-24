/***
 * @description Registration handler class to manage the OIDC authentication from Auth0 for Customers logging into MyPost Business Portal and Business Apps
 * 
 * NOTE: Also implementing Auth.ConfirmUserRegistrationHandler allows us to always make sure the user is authenticating to the correct user record.
 * 		This would be useful due to unforseen data changes, disabled portal users etc...
 * However, as of, 2023-03 I seem to be running into this problem:
 * https://issues.salesforce.com/issue/a028c00000j5kSrAAI/confirmuser-method-in-authconfirmuserregistrationhandler-is-not-working-as-expected
 * As of now, we are implementing the revokeAccess on the old user record on the fly during the confirmUser method which seems to be working
 * 
 * @author Mahesh Parvathaneni
 * @date 2023-08-22
 * @changelog
 */
global without sharing class MPBOIDCRegHandler implements Auth.RegistrationHandler, Auth.ConfirmUserRegistrationHandler {
	global class HandlerException extends Exception { }

	/**
	 * There is no link currently for the user coming from Auth0
	 * This will involve us linking to an eligible user based on the key attributes from the contact and user records.
	 * After the initial match is made a ThirdPartyAccountLink record will be created by Salesforce which will automatically associate this user to the matched User record from this process hence forth
	 * If the ThirdPartyAccountLink record is revoked then next login will trigger the 'createUser' method again
	 */
	global User createUser(Id portalId, Auth.UserData data){
		System.debug('createUser');
		
		outputDebugInformation(data);

		MPBRegHandlerService service = MPBRegHandlerService.getInstance();

		// we will supplement the existing attributes with a couple of our own to parse into our user matcher
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(data.attributeMap);

		// make sure we have all the necessary claims to match a user
		List<String> validationErrors = service.validateAssertion(augmentedAttributes);
		if (!validationErrors.isEmpty()) {
			throw new MPBRegHandlerService.RegHandlerException('Could not validate attributes: ' + String.join(validationErrors, ', '));
		}

		// returns the matched user
		User matchedUser = service.matchUser(augmentedAttributes);

		return matchedUser;
	}

	/**
	 * This is called before updateUser to validate whether or not the matched user based on ThirdPartyAccountLink is the correct user
	 * A matching value in the FederationIdentifier field will always be the authoritative user record to authenticate the user against irrespective of their third party account link. This is how we deal with Personas
	 * NOTE: implementing confirmUser simply allows us to bypass any explicitly linked users to the remote IdP and rematch the user on the fly
	 * 			See: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_Auth_ConfirmUserRegistrationHandler.htm#apex_interface_Auth_ConfirmUserRegistrationHandler
	 */
	global Id confirmUser(Id userId, Id tpalId, Id portalId, Auth.UserData data) {
		System.debug('confirmUser');
		System.debug(userId + ', ' + tpalId);
		
		outputDebugInformation(data);
		
		//As per salesforce (Case #44952215), TPAL Id can be null or empty until the ThirdPartyAccountLink SOQL is executed at least once.
		//This is due to SsoFlowHandler directly checking the virtual entity. Once the SOQL is executed, tpal can be obtained correctly
		//As a workaround, we are executing below to get the tpalId.
		//if tpalId is empty or null, we query the tpalId based on the provider name and userId. 
		//we return the userId if it still doesn't exist
		if(String.isEmpty(String.valueOf(tpalId)) || tpalId == null) {
			//get the existing tpalId for the user based on the provider name and userId
			Map<String, Object> searchParams = new Map<String, Object>{
						'userIds' => userId,
						'providerNames' => data.provider
			};
			List<ThirdPartyAccountLink> exisitngThirdPartyAccountLinks = ThirdPartyAccountLinksSelector.newInstance().search(searchParams, true);
			//make sure we've only one tpalId for the user and provider
			if(exisitngThirdPartyAccountLinks.size() == 1) {
				tpalId = exisitngThirdPartyAccountLinks[0].Id;
			} else {
				return userId;
			}
		}

		MPBRegHandlerService service = MPBRegHandlerService.getInstance();

		// we will supplement the existing attributes with a couple of our own to parse into our user matcher
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(data.attributeMap);

		// attempt to find the existing user
		User foundUser = service.matchUser(augmentedAttributes);

		Id matchedUserId = null;
		if(foundUser != null && foundUser.Id == userId) {
			// the user found based on our key criteria matches the same user linked by thirdpartyaccountlink record.
			// proceed as normal
			matchedUserId = userId;
		} else if (foundUser != null && foundUser.Id != userId) {
			// The user we found was different to the user where the TPAL record exists. We need to revoke the current access so Salesforce can associate a new TPAL record
			ThirdPartyAccountLink existingRecord = ThirdPartyAccountLinksSelector.newInstance(0, new Set<SObjectField>{ThirdPartyAccountLink.SsoProviderId}).selectById(new Set<Id>{tpalId})[0];
			Boolean success = ApplicationDatabase.getInstance().revokeTokenAccess(existingRecord.SsoProviderId, data.provider.toLowerCase(), userId, data.identifier);
			if(!success) {
				throw new MPBRegHandlerService.RegHandlerException('Could not revoke previous access');
			}
			matchedUserId = foundUser.Id;
		} else {
			throw new MPBRegHandlerService.RegHandlerException('The user access could not be confirmed');
		}

		return matchedUserId;
	}

	/**
	 * Internal Salesforce has found a match on the subject in the ThirdPartyAccountLink.
	 * Process any user updates that might be needed
	 */
	global void updateUser(Id userId, Id portalId, Auth.UserData data){
		System.debug('updateUser');

		outputDebugInformation(data);

		User matchedUser = UsersSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
			User.SObjectType => new Set<SObjectField>{User.Id, User.IsActive}
		}).selectById(new Set<Id>{userId}).values()[0];

		//update the user if not active
		if(!matchedUser.IsActive) {
			matchedUser.IsActive = true;
			ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{matchedUser});
		}
	}

	private void outputDebugInformation(Auth.UserData data) {
		System.debug('email = ' + data.email);
		System.debug('fullName = ' + data.fullName);
		System.debug('firstName = ' + data.firstName);
		System.debug('lastName = ' + data.lastName);
		System.debug('identifier = ' + data.identifier);
		System.debug('link = ' + data.link);
		System.debug('locale = ' + data.locale);
		System.debug('provider = ' + data.provider);
		System.debug('username = ' + data.username);
		System.debug('siteLoginUrl = ' + data.siteLoginUrl);
		System.debug('');
		for(String key : data.attributeMap.keySet()) {
			System.debug(key + ' = ' + data.attributeMap.get(key));
		}
		System.debug('Network Id: ' + Network.getNetworkId());
	}
}