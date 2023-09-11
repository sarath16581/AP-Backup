/***
 * @description Registration handler class to manage the OIDC authentication from Auth0 for Customers logging into consumer experiences
 * This registration handler will maintain backwards compatibility and leverage the existing FederationIdentifier field with 
 * 
 * NOTE: Also implementing Auth.ConfirmUserRegistrationHandler allows us to always make sure the user is authenticating to the correct user record.
 * 		This would be useful due to unforseen data changes, disabled portal users etc...
 * However, as of, 2023-03 I seem to be running into this problem:
 * https://issues.salesforce.com/issue/a028c00000j5kSrAAI/confirmuser-method-in-authconfirmuserregistrationhandler-is-not-working-as-expected
 * As of now, we are implementing the revokeAccess on the old user record on the fly during the confirmUser method which seems to be working
 * 
 * @author Nathan Franklin
 * @date 2023-02-28
 * @changelog
 * 2023-08-01 Mahesh Parvathaneni - Commented the implementation for Auth.ConfirmUserRegistrationHandler
 */
global with sharing class ChasOIDCRegistrationHandler implements Auth.RegistrationHandler {
	global class HandlerException extends Exception { }

	/**
	 * There is no link currently for the user coming from Auth0
	 * This will involve us linking to an eligible user based on the FederationIdentifier of the user record.
	 * After the initial match is made a ThirdPartyAccountLink record will be created by Salesforce which will automatically associate this user to the matched User record from this process hence forth
	 * If the ThirdPartyAccountLink record is revoked then next login will trigger the 'createUser' method again
	 */
	global User createUser(Id portalId, Auth.UserData data){
		System.debug('createUser');
		
		outputDebugInformation(data);

		ChasRegHandlerService service = ChasRegHandlerService.newInstance();
		String federationIdentifier = ChasRegHandlerService.generateFederationIdentifier(String.valueOf(data.attributeMap.get('email')));

		// we will supplement the existing attributes with a couple of our own to parse into our user matcher
		// these were previously provided by SAML and are used to feed into our matching and user updates and need to be maintained for backward compatibility
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationIdentifier, data.attributeMap);

		// make sure we have all the necessary claims to provision a new user
		List<String> validationErrors = service.validateAssertion(federationIdentifier, augmentedAttributes);
		if (!validationErrors.isEmpty()) {
			throw new ChasRegHandlerService.RegHandlerException('Could not validate attributes: ' + String.join(validationErrors, ', '));
		}

		// this will do one of the following:
		// 1. Match PersonAccount w/ User
		// 2. Match PersonAccount and attach a new User record
		// This method does not do an INSERT dml for the user, we leave that up to Salesforce to manage
		//		It may, however, do an update DML to an existing user if a match is found since Salesforce does not automatically handle an UPDATE dml scenario
		User matchedUser = service.matchOrCreate(federationIdentifier, augmentedAttributes);

		return matchedUser;
	}

	//  NOTE: This is commented for now as we think the scenario ThirdPartyAccountLink mismatch couldn't happen for a matched user,
	//  and the backwards compatibility for users federation id will be validated in updateUser method. we can revisit in the future if
	//  confirmUser method is required then implement the Auth.ConfirmUserRegistrationHandler
	// /**
	//  * This is called before updateUser to validate whether or not the matched user based on ThirdPartyAccountLink is the correct user
	//  * For backwards compatibility, we always need to force a match based on the users federation id (via the person account APCN).
	//  * NOTE: implementing confirmUser simply allows us to bypass any explicitly linked users to the remote IdP and rematch the user on the fly
	//  * 			See: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_Auth_ConfirmUserRegistrationHandler.htm#apex_interface_Auth_ConfirmUserRegistrationHandler
	//  * We use this method only to invalidate an old disabled community user record where there is an existing 
	//  */
	// global Id confirmUser(Id userId, Id tpalId, Id portalId, Auth.UserData data) {
	// 	System.debug('confirmUser');
	// 	System.debug(userId + ', ' + tpalId);
		
	// 	outputDebugInformation(data);
		
	// 	// TODO: Log a Salesforce case to understand why this might be empty...
	// 	// 			I have seen this being empty during development
	// 	if(String.isEmpty(String.valueOf(tpalId))) {
	// 		System.debug('ThirdPartyAccountLink record id is empty!!!');
	// 		System.debug('Returning user id: ' + userId);
	// 		return userId;
	// 	}

	// 	ChasRegHandlerService service = ChasRegHandlerService.newInstance();
		
	// 	String federationIdentifier = ChasRegHandlerService.generateFederationIdentifier(String.valueOf(data.attributeMap.get('email')));		
		
	// 	// we will supplement the existing attributes with a couple of our own to parse into our user matcher
	// 	// these were previously provided by SAML and are used to feed into our matching and user updates and need to be maintained for backward compatibility
	// 	Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationIdentifier, data.attributeMap);

	// 	// attempt to find the existing person account and person user records
	// 	Map<SObjectType, SObject> searchResults = service.getExistingRecords(augmentedAttributes);

	// 	Boolean revokePreviousAccess = false;
	// 	User foundUser = (User)searchResults.get(User.SObjectType);
	// 	if(foundUser != null && foundUser.Id == userId) {
	// 		// the user found based on the person account search criteria matches the same user linked by thirdpartyaccountlink record.
	// 		// proceed as normal
	// 		return userId;
	// 	} else if(foundUser != null) {
	// 		// a user was found, however its not a match with the userid passed in
	// 		revokePreviousAccess = true;
	// 	} else {
	// 		// there was no user record found, the existing link must be linked to an old user
	// 		revokePreviousAccess = true;
	// 	}

	// 	// check if the current thirdpartyaccountlink record is wrong and needs to be revoked to allow the user belong to the matched personaccount to be authenticated against
	// 	// per the class description, see https://issues.salesforce.com/issue/a028c00000j5kSrAAI/confirmuser-method-in-authconfirmuserregistrationhandler-is-not-working-as-expected
	// 	// for more info as to why this is necessary here
	// 	if(revokePreviousAccess) {
	// 		ThirdPartyAccountLink existingRecord = ThirdPartyAccountLinksSelector.newInstance(0, new Set<SObjectField>{ThirdPartyAccountLink.SsoProviderId}).selectById(new Set<Id>{tpalId})[0];
	// 		Boolean success = ApplicationDatabase.getInstance().revokeTokenAccess(existingRecord.SsoProviderId, data.provider.toLowerCase(), userId, data.identifier);
	// 		if(!success) {
	// 			throw new ChasRegHandlerService.RegHandlerException('Could not revoke previous access');
	// 		}
	// 	}

	// 	System.debug('foundUser: ' + foundUser);
	// 	System.debug('federationIdentifier: ' + federationIdentifier);

	// 	if(foundUser != null) {
	// 		// this is the user we should be authenticating against
	// 		// we only do this is the current user's federation id matches

	// 		// we only authenticate to the new user record if the fed id matches
	// 		if(!service.userIsFederatedMatch(foundUser, federationIdentifier)) {
	// 			throw new ChasRegHandlerService.RegHandlerException('Could not find a federated match for the existing user.');
	// 		}

	// 		return foundUser.Id;
	// 	}

	// 	// For now if we can't find a person account record or user record, we will simply throw an error
	// 	// This would be because of the following scenario:
	// 	// 1. Person account / user record initial created (createUser) and linked with TPAL
	// 	// 2. Data is manually manipulated, (record deleted, user disabled etc... ) and the existing TPAL was not revoked
	// 	// 3. The data was not corrected either by integration or manually OR the TPAL was not manually revoked on the original user record 
	// 	// In this scenario we won't do anything since we don't know why the data is incorrect so it's best to throw an error
	// 	// This should be looked at as a part of the Account Offboarding work.
	// 	throw new ChasRegHandlerService.RegHandlerException('The user access could not be confirmed');
	// }

	/**
	 * Internal Salesforce has found a match on the subject in the ThirdPartyAccountLink.
	 * Process any user updates that might be needed
	 */
	global void updateUser(Id userId, Id portalId, Auth.UserData data){
		System.debug('updateUser');

		outputDebugInformation(data);

		ChasRegHandlerService service = ChasRegHandlerService.newInstance();

		String federationIdentifier = ChasRegHandlerService.generateFederationIdentifier(String.valueOf(data.attributeMap.get('email')));

		// we will supplement the existing attributes with a couple of our own to parse into 
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationIdentifier, data.attributeMap);
		
		// trigger an update of the attributes of the matched user record if required
		service.updateForExistingUser(userId, augmentedAttributes);
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