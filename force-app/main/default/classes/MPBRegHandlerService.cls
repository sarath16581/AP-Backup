/**
 * @description Service class for low level functions for MyPost Business integrated experiences requiring authentication via OIDC
 * @author Mahesh Parvathaneni
 * @date 2023-08-22
 * @changelog
 */
public inherited sharing class MPBRegHandlerService {

	/**
	 * Provides a mockable interface for unit testing
	 */
	public static MPBRegHandlerService getInstance() {
		return (MPBRegHandlerService)Application.Utilities.getInstance(MPBRegHandlerService.class);
	}

	public Map<String, String> getAugmentedAttributes(Map<String, String> attributes) {
		Map<String, String> output = new Map<String, String>();
		output.putAll(attributes);

		String cNumber = String.valueOf(attributes.get(Label.AttributeCNumberMapping));
		output.put('cnumber', cNumber); // this is to maintain backwards compatibility of the millions of existing records we have

		return output;
	}

	/**
	 * Verify that the attributes are valid
	 */
	public List<String> validateAssertion(Map<String, String> attributes) {
		List<String> output = new List<String>();

		if(!attributes.containsKey('given_name')) {
			output.add('First Name attribute is missing');
		}
		if(!attributes.containsKey('family_name')) {
			output.add('Last Name attribute is missing');
		}
		if(!attributes.containsKey('email')) {
			output.add('Email attribute is missing');
		}
		if(!attributes.containsKey(Label.AttributeCNumberMapping) || !attributes.containsKey('cnumber')) {
			output.add('CNumber attribute is missing');
		}

		return output;
	}

	/**
	 * @description This method returns the user with the below matching critieria
	 * The cNumber from Auth0 matches with the associated contact of user
	 * The Asset related to Contact is PSRTandC
	 * Contact status is active for the user
	 * User is active
	 * User profile is MyPost Business Help & Support Community user
	 * 
	 * @param  augmentedAttributes UserData attribute map
	 * @return	matched user
	 */
	public User matchUser(Map<String, String> augmentedAttributes) {
		User matchedUser;
		String cNumber = augmentedAttributes.get('cnumber');

		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('isPersonAccount', false);
		searchParams.put('contactCNumbers', cNumber);
		searchParams.put('contactStatuses', 'Active');
		searchParams.put('isActive', true);
		searchParams.put('profileNames', BspConstants.MPB_COMMUNITY_PROFILE_NAME);

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			Contact.SObjectType => new Set<SObjectField>{Contact.Id, Contact.Status__c, Contact.OID_ID__c},
			User.SObjectType => new Set<SObjectField>{User.Id, User.IsActive, User.ContactId}
		};

		Set<Object> selectorOptions = new Set<Object>{
			UsersSelector.Options.WITH_CONTACT
		};

		Map<Id, User> queryResults = new Map<Id, User>(UsersSelector.newInstance(0, fieldOverrides).search(searchParams, selectorOptions, true));

		// this is an extra paranoid check to make sure we force the right users
		for(Id uId: queryResults.keySet()) {
			User u = queryResults.get(uId);
			//make sure contact cNumber exists and cNumber returned is same as attribute map and contact status is active
			if(String.isBlank(u.contact.OID_ID__c) || !cNumber.equalsIgnoreCase(u.contact.OID_ID__c) || !('Active'.equalsIgnoreCase(u.Contact.Status__c))) {
				queryResults.remove(uId);
			}
		}

		List<User> users = queryResults.values();

		if (!users.isEmpty()) {
			//get the contacts associated to all the users and check any PSRTandC assets related to contact
			Map<Id, User> contactIdToUserMap = new Map<Id, User>();
			for (User user : users) {
				contactIdToUserMap.put(user.ContactId, user);
			}

			Map<String, Object> assetSearchParams = new Map<String, Object>{
				'contactIds' => contactIdToUserMap.keySet(),
				'assetNames' => 'PSRTandC'
			};
			Set<SObjectField> assetFieldOverrides = new Set<SObjectField>{ Asset.Id, Asset.ContactId };
			List<Asset> assets = AssetsSelector.newInstance(assetFieldOverrides).search(assetSearchParams, true);

			if (!assets.isEmpty()) {
				List<User> assetMatchedUsers = new List<User>();
				//filter the users that has the assets matching
				for (Asset asset : assets) {
					if (contactIdToUserMap.containsKey(asset.contactId)) {
						assetMatchedUsers.add(contactIdToUserMap.get(asset.ContactId));
					}
				}

				Map<Id, User> assetMatchedUserMap = new Map<Id, User>(assetMatchedUsers);

				if(!assetMatchedUserMap.isEmpty()) {
					// final check is to make sure user has access to the specified community by checking the network member
					Map<String, Object> memberSearchParams = new Map<String, Object>{
						'memberIds' => assetMatchedUserMap.keySet(),
						'networkIds' => Network.getNetworkId()
					};

					for(NetworkMember member : NetworkMembersSelector.newInstance().search(memberSearchParams, true)) {
						if(assetMatchedUserMap.containsKey(member.MemberId)) {
							//assign the matched user
							matchedUser = assetMatchedUserMap.get(member.MemberId);
							break;
						} 
					}
				}
			}
		}

		//throw an exception if we don't find a matched user
		if (matchedUser == null) {
			throw new RegHandlerException('Could not find a match for an existing user.');
		}

		return matchedUser;
	}

	public class RegHandlerException extends Exception{}
}