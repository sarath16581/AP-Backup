/***
 * @description Registration handler class to manage the OIDC authentication from Azure
 *
 * This is built since Auth. Providers need a Registration handler in order to enable SSO
 * NOTE: This same registration handler should be able to be used for all Azure OIDC auth scenarios
 * NOTE: This handler leverages FederationIdentifier field only for the initial matching to a user. (This is used in createUser)/
 *		  After that, a link is created based on the subject claim from the IdP in the ThirdPartyAccountLink.
 *		  Any subsequent matching would be based on ThirdPartyAccountLink (when updateUser is fired)
 *
 * @author Nathan Franklin
 * @date 2022-04-22
 * @changelog
 * 2022-11-08 - Nathan Franklin - Increased API version
 */
global with sharing class AzureOIDCRegistrationHandler implements Auth.RegistrationHandler {
	global class HandlerException extends Exception { }

	/**
	 * Attempt to match to an existing user. There is no provisioning currently supported in this handler
	 */
	global User createUser(Id portalId, Auth.UserData data){
		System.debug('createUser');
		System.debug(data);
		// System.debug(portalId);

		// System.debug('email = ' + data.email);
		// System.debug('fullName = ' + data.fullName);
		// System.debug('firstName = ' + data.firstName);
		// System.debug('lastName = ' + data.lastName);
		// System.debug('identifier = ' + data.identifier);
		// System.debug('link = ' + data.link);
		// System.debug('locale = ' + data.locale);
		// System.debug('provider = ' + data.provider);
		// System.debug('username = ' + data.username);
		// System.debug('siteLoginUrl = ' + data.siteLoginUrl);
		// System.debug('portalId = ' + portalId);
		// System.debug('');
	
		// for(String key : data.attributeMap.keySet()) {
		// 	System.debug(key + ' = ' + data.attributeMap.get(key));
		// }

		System.debug('Network Id: ' + Network.getNetworkId());

		String email = data.attributeMap.get('email');

		// default to the traditional way of getting network id,
		// for custom auth providers, the sfdc_networkid field is not set but we can use Network.getNetworkId()
		// This reg hander is used by both standard and custom auth providers
		String networkId = data.attributeMap.get('sfdc_networkid');
		if(String.isEmpty(networkId)) {
			networkId = Network.getNetworkId();
		}

		// based on the network we are authenticating the user into, we need to know which federation identifier field to use on the user object.
		// this field is then used as the matching field when comparing the subject in the claim to a valid user record
		//NOTE: This also works where network is null (meaning they are logging into CRM core)
		List<SSOAttributeMapping__mdt> mappings = SSOAttributeMappingsSelector.newInstance(1).selectByNetworkIds(new Set<String>{networkId});
		if(mappings.isEmpty()) {
			throw new HandlerException('Could not find a matching Federation Identifier');
		}

		// grab the subject value based on the mapping attribute name
		String subjectValue = data.attributeMap.get(mappings[0].SubjectAttribute__c);

		// grab the federation field to match our subject against
		// currently this will always be a field on the User object.
		SObjectField federationIdentifierField = User.SObjectType.getDescribe().fields.getMap().get(mappings[0].FederationField__c);

		// we always make sure there is a subject value to match on to avoid matching to a random user
		if(String.isEmpty(subjectValue)) {
			throw new HandlerException('Subject is empty');
		}

		// grab the user based on federation id making sure they actually have access to the community requesting authentication
		// note that if there is no community context, 'networkId' will be null the user will be matched by federationIdentifier only
		Map<String, Object> params = new Map<String, Object>{
			'federationIds' => subjectValue,
			'federationField' => federationIdentifierField,
			'isActive' => true
		};
		if(!String.isEmpty(networkId)) {
				params.put('networkIds', (Id)networkId);
		}

		List<User> users = UsersSelector.newInstance().search(params, true);
		if(users.isEmpty()) {
			throw new HandlerException('Could not find matching user: ' + subjectValue);
		} else {
			return users[0];
		}
	}

	/**
	 * Internal Salesforce has found a match on the subject in the ThirdPartyAccountLink.
	 * Since we aren't doing any provisioning or updating there is nothing needed here
	 */
	global void updateUser(Id userId, Id portalId, Auth.UserData data){
		System.debug('updateUser');
		System.debug(data);

		// do nothing since we aren't doing any data updates
	}
}