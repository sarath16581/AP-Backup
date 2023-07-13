/***
 * @description Registration handler class to manage the OIDC authentication from Auth0 for Customers logging into merchant portal
 * This registration handler will maintain backwards compatibility and leverage the existing FederationIdentifier field
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
 */
global without sharing class MerchantPortalOIDCRegHandler implements Auth.RegistrationHandler, Auth.ConfirmUserRegistrationHandler {
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

		MerchantPortalRegHandlerService service = MerchantPortalRegHandlerService.getInstance();

		// we will supplement the existing attributes with a couple of our own to parse into our user matcher
		// these were previously provided by SAML and are used to feed into our matching and user updates and need to be maintained for backward compatibility
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(data.attributeMap);
		String federationIdentifier = augmentedAttributes.get('federation_identifier');

		// make sure we have all the necessary claims to match a user
		List<String> validationErrors = service.validateAssertion(augmentedAttributes);
		if (!validationErrors.isEmpty()) {
			throw new MerchantPortalRegHandlerService.RegHandlerException('Could not validate attributes: ' + String.join(validationErrors, ', '));
		}

		// return a list of personas based on the cnumber including if one is already marked as the 'primary' (based on the value in the FederationIdentifier field)
		// https://australiapost.jira.com/wiki/spaces/SF/pages/2837905683/Salesforce+Merchant+Portal+Persona+Data+Architecture
		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility(augmentedAttributes.get('cnumber'), Network.getNetworkId());
		List<BAMUserUtility.UserPersona> personas = personaUtility.personas.values();
		System.debug('personas: ' + personas);

		if(personas.isEmpty()) {
			throw new MerchantPortalRegHandlerService.RegHandlerException('A persona could not be found matched for the user');
		} else {
			// loop through and find a match based on federation id if one exists.
			BAMUserUtility.UserPersona matchedPersona = null;
			for(BAMUserUtility.UserPersona persona : personas) {
				if(federationIdentifier.equalsIgnoreCase(persona.federationIdentifier)) {
					matchedPersona = persona;
					break;
				}
			}

			if(matchedPersona == null) {
				matchedPersona = personas[0];
			}

			User matchedUser = new User(Id = matchedPersona.userId);


			// if the persona matched is a merchant portal community user and the users profile is Merchant Portal Community User we need to make the record Active
			// this is because a user record will be created for a contact at the beginning of the BAM provisioning process as an inactive Merchant Portal Community user
			if(!matchedPersona.userActive && BAMUserUtility.MERCHANT_PORTAL_NETWORK_ID == Network.getNetworkId() && BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME.equalsIgnoreCase(matchedPersona.userProfile)) {

				matchedUser.IsActive = true;

				ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{matchedUser});
			}

			return matchedUser;
		}
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
		
		// TODO: Log a Salesforce case to understand why this might be empty...
		// 			I have seen this being empty during development
		if(String.isEmpty(String.valueOf(tpalId))) {
			System.debug('ThirdPartyAccountLink record id is empty!!!');
			System.debug('Returning user id: ' + userId);
			return userId;
		}

		MerchantPortalRegHandlerService service = MerchantPortalRegHandlerService.getInstance();

		// we will supplement the existing attributes with a couple of our own to parse into our user matcher
		// these were previously provided by SAML and are used to feed into our matching and user updates and need to be maintained for backward compatibility
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(data.attributeMap);
		String federationIdentifier = augmentedAttributes.get('federation_identifier');

		// return a list of personas based on the cnumber including if one is already marked as the 'primary' (based on the value in the FederationIdentifier field)
		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility(augmentedAttributes.get('cnumber'), Network.getNetworkId());
		List<BAMUserUtility.UserPersona> personas = personaUtility.personas.values();
		System.debug('personas: ' + personas);

		if(personas.isEmpty()) {
			throw new MerchantPortalRegHandlerService.RegHandlerException('A persona could not be found matched for the user');
		} else {
			// loop through and find a match based on federation id if one exists.
			Id matchedUserId = null;
			Map<Id, BAMUserUtility.UserPersona> userPersonaMappings = new Map<Id, BAMUserUtility.UserPersona>();
			BAMUserUtility.UserPersona matchedPersona = null;
			for(BAMUserUtility.UserPersona persona : personas) {
				userPersonaMappings.put(persona.userId, persona);
				if(federationIdentifier.equalsIgnoreCase(persona.federationIdentifier)) {
					// since the FederationIdentifier field matches, we use this user record to authenticate the user against
					// NOTE: this is irrespective of whether the current ThirdPartyAccountLink record is linked to this user record or not
					// If we need to we revoke access to the TPAL below (if the user matched is different)
					matchedPersona = persona;
					break;
				}
			}

			if(matchedPersona != null) {
				// the FederationIdentifier was matched above
				matchedUserId = matchedPersona.userId;
			} else if(matchedPersona == null && userPersonaMappings.keySet().contains(userId)) {
				// We need to make sure that the user with the ThirdPartyAccountLink is one from the list of valid personas
				// It should always be the case, but this is one extra check to make sure users aren't inadvertantly authenticated to the incorrect user record
				matchedUserId = userId;
			} else {
				throw new MerchantPortalRegHandlerService.RegHandlerException('A persona could not be found matched for the user');
			}

			if(matchedUserId != userId) {
				// The persona we found was different to the user where the TPAL record exists. We need to revoke the current access so Salesforce can associate a new TPAL record
				ThirdPartyAccountLink existingRecord = ThirdPartyAccountLinksSelector.newInstance(0, new Set<SObjectField>{ThirdPartyAccountLink.SsoProviderId}).selectById(new Set<Id>{tpalId})[0];
				Boolean success = ApplicationDatabase.getInstance().revokeTokenAccess(existingRecord.SsoProviderId, data.provider.toLowerCase(), userId, data.identifier);
				if(!success) {
					throw new MerchantPortalRegHandlerService.RegHandlerException('Could not revoke previous access');
				}
			}

			return matchedUserId;
		}
	}

	/**
	 * Internal Salesforce has found a match on the subject in the ThirdPartyAccountLink.
	 * Process any user updates that might be needed
	 */
	global void updateUser(Id userId, Id portalId, Auth.UserData data){
		System.debug('updateUser');

		outputDebugInformation(data);

		User matchedUser = UsersSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
			User.SObjectType => new Set<SObjectField>{User.Id, User.IsActive},
			Profile.SObjectType => new Set<SObjectField>{Profile.Name}
		}).selectById(new Set<Id>{userId}, new Set<Object>{UsersSelector.Options.WITH_PROFILE}).values()[0];

		// if the persona matched is a merchant portal community user and the users profile is Merchant Portal Community User we need to make the record Active
		// this is because a user record will be created for a contact at the beginning of the BAM provisioning process as an inactive Merchant Portal Community user
		if(!matchedUser.IsActive && BAMUserUtility.MERCHANT_PORTAL_NETWORK_ID == Network.getNetworkId() && BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME.equalsIgnoreCase(matchedUser.Profile.Name)) {

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