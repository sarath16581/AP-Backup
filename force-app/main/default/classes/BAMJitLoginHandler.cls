/**************************************************
Test Class: BAMUserUtility_Test

Description: This JIT handler is responsible for the Persona switching capability offered with the BAM uplift
			 Salesforce represents an individual as a number of separate potential contact records.
			 Each of these contact records represents a 'persona' of an individual.

			 This class does not perform any user provisioning. Its expected that a user record will already exist.
			 It's primary purpose is to catch any instances when the Federation ID has not been set on any of the Personas for an individual
			 If a direct match could not be found (no federation id), then we authenticate the user against the first persona we find and that becomes the default persona until they switch.

			 A User should always exist since a basic Merchant Portal Community User record will be provisioned for any contact onboarding to BAM online services.
			 We do this because we do not know the context of which account to provision a contact/user against when handling a login response using JIT after they log in with SAML IdP since SAML IdP will only send the CNumber to us.
			 NOTE: The normal flow for a user of Merchant Portal is to log into the portal first and clicking on one of their online services (tiles) in the portal... When the log into merchant portal for the first time their login will be activated

			 If the Federation Id has been set then this class should just pass the user through (and activate the user account if needed)
			 In the BAM UI, a context switch capbility is provided which when set will:
			 1. Remove the federation ID from any existing persona's
			 2. Set a new federation ID of the requested persona to switch to
			 3. Redirect the user to CSSO SAML IdP init login page.


			 There are special rules around activating users
			 If the community is Business Portal and the profile of the user is Merchant Portal Community User and the User record is Inactive, the user will be made active
			 If the community is Business Support Portal then we do not activate the account

			 NOTE: This class is NOT responsible for provisioning new users. Its expected that a user record will already exist.

History:
--------------------------------------------------
2019-05-06  nathan.franklin@auspost.com.au  Created
**************************************************/
global class BAMJitLoginHandler implements Auth.SamlJitHandler {

	private class JitException extends Exception{}

	/**
	 * No user record was found with a Federation Id that matches the BAM format
	 * We need to search for a persona and update the Fed Id to log this user in.
	 */
	global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
			String federationIdentifier, Map<String, String> attributes, String assertion) {

		System.debug('BAMJitLoginHandler >> createUser');

		// grab a list of all the possible personas that match the cnumber in the context of the community the user is logging in to.

		System.debug('federationIdentifier: ' + federationIdentifier);

		String cNumber = attributes.get('https://saml.auspost.com.au/core/attributes/cnumber');
		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility(cNumber, communityId);
		List<BAMUserUtility.UserPersona> personas = personaUtility.personas.values();
		System.debug('personas: ' + personas);

		if(personas.isEmpty()) {
			throw new JitException('A persona could not be found matched for the user');
		} else {

			User matchedUser = new User(Id = personas[0].userId, FederationIdentifier = personaUtility.getPersonaFormat());

			if(BAMUserUtility.MERCHANT_PORTAL_NETWORK_ID == communityId && BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME.equalsIgnoreCase(personas[0].userProfile)) {

				// if the persona matched is a merchant portal community user and the users profile is Merchant Portal Community User we need to make the record Active
				// this is because a user record will be created for a contact at the beginning of the BAM provisioning process as an inactive Merchant Portal Community user
				matchedUser.IsActive = true;

			}

			update matchedUser;

			return matchedUser;
		}
	}

	/**
	 * A user was found that matched the federation ID that was passed from the IdP.
	 */
	global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
			String federationIdentifier, Map<String, String> attributes, String assertion) {

		System.debug('BAMJitLoginHandler >> updateUser');

		if(BAMUserUtility.MERCHANT_PORTAL_NETWORK_ID == communityId) {
			System.debug('BAMJitLoginHandler >> Is Merchant Portal Community');

			// if the persona matched is a Merchant Portal community user and the users profile is Merchant Portal Community User we need to make the record Active
			// this is because a user record will be created for a contact at the beginning of the BAM provisioning process as an inactive Merchant Portal Community user
			// NOTE: If the user is trying to log into Merchant Portal with a non Merchant Portal Community User profile and the user record is Inactive, we DO NOT activate the record since they may be deactivated for a reason (Example: Legacy user deactivation prior to BAM)

			User u = [Select IsActive, Profile.Name From User Where Id = :userId];
			if(BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME.equalsIgnoreCase(u.Profile.Name) && !u.IsActive) {
				System.debug('BAMJitLoginHandler >> Merchant Portal User is Inactive');

				u = new User(Id = userId, IsActive = true);
				update u;
			}

		}

	}
}