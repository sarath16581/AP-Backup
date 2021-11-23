/***
 * @description This Jit handler is current used by Help and Support to enable provisioning users when a user tries to login where their account does not already exist
 * This custom login handler is necessary since auto provisioning of personaccounts is currently not supported.
 * Additionally, the ability to update custom fields on Account and Contact is currently also not supported
 *
 * This scenario is used where a record already exists in the IdP but the registration details have not propagated down to Salesforce
 * This includes scenarios such as when a user registers for MPB and then attempts to use those credentials and log into consumer H&S
 * Since business contacts no longer propagate down to SF as person accounts, this login handler is necessary to provision the access
 *
 * For more information relating to H&S Jit Login handler, refer to https://australiapost.jira.com/wiki/spaces/SF/pages/961872421/H+S+Jit+Login+Handler+for+on-demand+provisioning
 * @author Nathan Franklin
 * @date 2020-04-24
 * @group Communities
 * @tags Service, Chas, Help and Support, H&S, Jit, login, login handler
 * @domain Help and Support
 * @changelog
 */
global class ChasJitLoginHandler implements Auth.SamlJitHandler {

	private class JitException extends Exception{}

	/**
	 * Called when a user tries to login to the community and no match was found
	 */
	global User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {

		System.debug(federationIdentifier);

		for (String key : attributes.keySet()) {
			System.debug(key + ' = ' + attributes.get(key));
		}

		// verify the SAML assertion has the correct details
		ChasJitService service = ChasJitService.newInstance();

		// make sure that the assertion has all the necessary attributes to provision a new user
		List<String> validationErrors = service.validateAssertion(federationIdentifier, attributes);
		if (!validationErrors.isEmpty()) {
			throw new JitException('Could not validate assertion attributes: ' + String.join(validationErrors, ', '));
		}

		// this will either find a match to an existing PersonAccount and User
		// or create a new one when if no match if found
		User matchedUser = service.matchOrCreate(federationIdentifier, attributes);

		return matchedUser;
	}

	/**
	 * Called when a user logs in and a matching User record was found (normally by Fed id)
	 */
	global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
		// force an update of the user record with the attributes received from the SAML assertion
		// most likely this will do things like activate the user account if it's inactive
		System.debug(federationIdentifier);

		for(String key : attributes.keySet()) {
			System.debug(key + ' = ' + attributes.get(key));
		}

		// trigger a small update the the user record to keep the details in sync with the IdP
		ChasJitService service = ChasJitService.newInstance();
		service.updateExistingUser(userId, federationIdentifier, attributes);
	}
}