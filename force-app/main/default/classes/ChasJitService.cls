/**
* @description Handles all the Jit related capability of the Chas Login Handler
* For more information relating to H&S Jit Login handler, refer to https://australiapost.jira.com/wiki/spaces/SF/pages/961872421/H+S+Jit+Login+Handler+for+on-demand+provisioning
* @author Nathan Franklin
* @date 2020-04-24
* @group Communities
* @tags Service, Chas, Help and Support, H&S, Jit, login, login handler
* @domain Help and Support
* @changelog
*/
public with sharing class ChasJitService {

	@TestVisible
	private static final String ATTRIBUTE_APCN_MAPPING = 'https://saml.auspost.com.au/core/attributes/apcn';

	@TestVisible
	private static final String ATTRIBUTE_CNUMBER_MAPPING = 'https://saml.auspost.com.au/core/attributes/cnumber';

	@TestVisible
	private static final String ATTRIBUTE_USERID_MAPPING = 'https://saml.auspost.com.au/core/attributes/userid';

	// TODO: Get SAML IdP to uplift this to 'User.FirstName'
	@TestVisible
	private static final String ATTRIBUTE_FIRSTNAME_MAPPING = 'https://saml.auspost.com.au/core/attributes/firstName';

	public static final String DEFAULT_LOCALESIDKEY = 'en_AU';
	public static final String DEFAULT_LANGUAGELOCALEKEY = 'en_US';
	public static final String DEFAULT_TIMEZONESIDKEY = 'Australia/Sydney';
	public static final String DEFAULT_EMAILENCODINGKEY = 'UTF-8';

	public static final Map<SObjectField, String> PERSONACCOUNT_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS = new Map<SObjectField, String>{
			Account.FirstName => ATTRIBUTE_FIRSTNAME_MAPPING,
			Account.LastName => 'User.LastName',
			Account.PersonEmail => 'User.Email',
			Account.APCN__pc => ATTRIBUTE_APCN_MAPPING,
			Account.OID_ID__pc => ATTRIBUTE_CNUMBER_MAPPING,
			Account.CRMCSSOID__pc => ATTRIBUTE_USERID_MAPPING
	};

	public static final Map<SObjectField, String> USER_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS = new Map<SObjectField, String>{
			User.FirstName => ATTRIBUTE_FIRSTNAME_MAPPING,
			User.LastName => 'User.LastName',
			User.Email => 'User.Email',
			User.Username => 'User.Username',
			User.FederationIdentifier => 'User.FederationIdentifier',
			User.OID_ID__c => ATTRIBUTE_CNUMBER_MAPPING,
			User.APCN__c => ATTRIBUTE_APCN_MAPPING,
			User.LocaleSidKey => 'User.LocaleSidKey',
			User.LanguageLocaleKey => 'User.LanguageLocaleKey',
			User.TimeZoneSidKey => 'User.TimeZoneSidKey',
			User.EmailEncodingKey => 'User.EmailEncodingKey',
			User.Alias => 'User.Alias'
	};

	/**
	 * Make sure we only update the necessary fields
	 */
	public static final Map<SObjectField, String> USER_SOBJECT_UPDATEABLE_ATTRIBUTE_MAPPINGS = new Map<SObjectField, String>{
			User.FirstName => ATTRIBUTE_FIRSTNAME_MAPPING,
			User.LastName => 'User.LastName',
			User.Email => 'User.Email',
			User.LocaleSidKey => 'User.LocaleSidKey',
			User.LanguageLocaleKey => 'User.LanguageLocaleKey',
			User.TimeZoneSidKey => 'User.TimeZoneSidKey',
			User.EmailEncodingKey => 'User.EmailEncodingKey',
			User.Alias => 'User.Alias'
	};

	/**
	 * Provides a mockable interface for unit testing
	 */
	public static ChasJitService newInstance() {
		return (ChasJitService)Application.Utilities.newInstance(ChasJitService.class);
	}

	/**
	 * Verify that the attributes from the SAML assertion are valid
	 */
	public List<String> validateAssertion(String federationIdentifier, Map<String, String> attributes) {
		List<String> output = new List<String>();

		if(!attributes.containsKey(ATTRIBUTE_FIRSTNAME_MAPPING)) {
			output.add('First Name attribute is missing');
		}
		if(!attributes.containsKey('User.LastName')) {
			output.add('Last Name attribute is missing');
		}
		if(!attributes.containsKey('User.Email')) {
			output.add('Email attribute is missing');
		}
		if(!attributes.containsKey('User.Username')) {
			output.add('Username attribute is missing');
		}
		if(!attributes.containsKey(ATTRIBUTE_APCN_MAPPING)) {
			output.add('APCN attribute is missing');
		}
		if(!attributes.containsKey(ATTRIBUTE_CNUMBER_MAPPING)) {
			output.add('CNumber attribute is missing');
		}
		if(!attributes.containsKey('User.FederationIdentifier')) {
			output.add('Federation Id is invalid');
		}

		// fail early if possible
		if(!output.isEmpty()) {
			return output;
		}

		// make sure username is unique
		// NOTE: this is important since there was already no federation id match given we have entered validateAssertion
		// any new record created would utilise this username
		Map<Id, User> users = UsersSelector.newInstance().selectByUsername(new Set<String>{attributes.get('User.Username')}, new Set<Object>{UsersSelector.Options.FILTER_EXTERNAL_USERS});
		if(!users.isEmpty()) {
			output.add('A user with that username already exists.');
		}

		return output;
	}

	/**
	 * Find or provision a new PersonAccount/User
	 *
	 * As a part of the current SSSW interface,
	 * TIBCO uses the following logic:
	 *
	 *	1)	upsert() on “Account”: to create Customer records records (will use Account.APCN__pc as the external Id)
	 *	2)	query() on “Account”: to get the ContactID of CSSO registered customers
	 *	3)	upsert() on “User”: to create Community (Portal) User records records (will use User.APCN__c as the external Id)
	 *
	 * Since we are trying to achieve the same thing, we will do something similar
	 * 1. Search by PersonAccount first and use existing or create new (Do not update record if match is found)
	 * 2. Check for associated User record and create one if necessary (either Update or Insert attributes from SAML assertion)
	 */
	public User matchOrCreate(String federationId, Map<String, String> attributes) {

		// look for an existing record first, if we find one, we use that and attempt to link a new new user record on it.
		Map<Id, Account> accounts = SSSWAccountsSelector.newInstance().selectByAPCN(new Set<String>{attributes.get(ATTRIBUTE_APCN_MAPPING)}, new Set<Object>{SSSWAccountsSelector.Options.FILTER_PERSON_ACCOUNT_ONLY});

		// prepare the account record to be inserted/updated in Salesforce
		Id personContactId;

		if(accounts.size() == 1) {
			// we found a match grab the associated contact id and try and match the associated User record

			// grab the person contact id since we need it below
			// NOTE: the FILTER_PERSON_ACCOUNT_ONLY force only person account records to be returned so this value will always be populated
			personContactId = accounts.values()[0].PersonContactId;

			System.debug('Existing PersonAccount record found: ' + accounts);
		} else {
			// existing PersonAccount NOT found by APCN
			// so we will create a new one
			Account matchedAccount = (Account)populateRecord(Account.getSObjectType(), attributes, PERSONACCOUNT_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS);
			matchedAccount.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{ChasConstants.PERSON_ACCOUNT_RECORD_TYPE_DEVELOPER_NAME}).values()[0].Id;

			System.debug('Creating new PersonAccount record');
			System.debug('Using these details: ' + matchedAccount);

			// insert the record
			// NOTE: This should trigger the outbound message to sync these details to SAP-CRM (given the outbound message is still active)
			ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{matchedAccount});

			// after the record has been inserted we need to select the PersonContactId so it can be assigned to the user record
			matchedAccount = SSSWAccountsSelector.newInstance().selectById(new Set<Id>{matchedAccount.Id}).values()[0];

			// grab the person contact id since we need it below
			personContactId = matchedAccount.PersonContactId;
		}

		// now the PersonAccount is out of the way we move onto the User record
		// try and find an existing user based on the contact id passed in
		List<User> users = UsersSelector.newInstance().selectByContactId(new Set<Id>{personContactId}).values();

		if(!users.isEmpty()) {
			// found a user that is already linked to the PersonAccount above
			// if we created a PersonAccount above, this will never happen

			// prepare a user record based on the SAML attribute that will either be inserted or updated
			User matchedUser = (User)populateRecord(User.getSObjectType(), attributes, USER_SOBJECT_UPDATEABLE_ATTRIBUTE_MAPPINGS);
			matchedUser.Id = users[0].Id;

			// special condition to set IsActive since it could be a string '1', 'true', 'false', '0' etc...
			if(attributes.containsKey('User.IsActive')) {
				matchedUser.IsActive = isTrue(attributes.get('User.IsActive'));
			}

			System.debug('Existing User record found: ' + users);
			System.debug('Using these details: ' + matchedUser);

			// we need to synchronise the user record with the attributes from SAML assertion
			// NOTE: it's possible if the record details contain completely different data then we may overwrite it by doing this
			//          It's assumed that the data in the db is right and no-one has manually tampered with it
			ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{matchedUser});

			System.debug('matchedUser: ' + matchedUser);
			return matchedUser;
		} else {
			// did not find a user so one needs to be created
			// this will happen if we created a PersonAccount above OR we found an existing PersonAccount already without a user record attached to it
			User matchedUser = (User)populateRecord(User.getSObjectType(), attributes, USER_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS);
			matchedUser.ContactId = personContactId;
			matchedUser.ProfileId = ChasConstants.CONSUMER_COMMUNITY_PROFILE_ID;

			// set the default values if the attributes for these values was not passed in
			if(matchedUser.LocaleSidKey == null) {
				matchedUser.LocaleSidKey = DEFAULT_LOCALESIDKEY;
			}
			if(matchedUser.LanguageLocaleKey == null) {
				matchedUser.LanguageLocaleKey = DEFAULT_LANGUAGELOCALEKEY;
			}
			if(matchedUser.TimeZoneSidKey == null) {
				matchedUser.TimeZoneSidKey = DEFAULT_TIMEZONESIDKEY;
			}
			if(matchedUser.EmailEncodingKey == null) {
				matchedUser.EmailEncodingKey = DEFAULT_EMAILENCODINGKEY;
			}

			// generate the alias for this user
			if(matchedUser.Alias == null) {
				String alias = '';
				if (matchedUser.FirstName == null) {
					alias = matchedUser.LastName;
				} else {
					alias = matchedUser.FirstName.substring(0, 1) + matchedUser.LastName;
				}
				if (alias.length() > 5) {
					alias = alias.substring(0, 5);
				}
				matchedUser.Alias = alias;
			}

			// special condition to set IsActive since it could be a string '1', 'true', 'false', '0' etc...
			if(attributes.containsKey('User.IsActive')) {
				matchedUser.IsActive = isTrue(attributes.get('User.IsActive'));
			}

			System.debug('Creating new User record');
			System.debug('Using these details: ' + matchedUser);

			ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{matchedUser});

			System.debug('matchedUser: ' + matchedUser);
			return matchedUser;
		}
	}

	/**
	 * Update existing User record when a SAML assertion matches to an existing user
	 * NOTE, this will only update a small set of attributes on the user record.
	 */
	public User updateExistingUser(Id userId, String federationId, Map<String, String> attributes) {
		User existingUser = UsersSelector.newInstance().selectById(new Set<Id>{userId}, new Set<Object>{UsersSelector.Options.WITH_CONTACT}).values()[0];

		// populate a user record for update
		User existingUserFromSAML = (User)populateRecord(User.getSObjectType(), attributes, USER_SOBJECT_UPDATEABLE_ATTRIBUTE_MAPPINGS);
		existingUserFromSAML.Id = userId;

		// special condition to set IsActive since it could be a string '1', 'true', 'false', '0' etc...
		if(attributes.containsKey('User.IsActive')) {
			existingUserFromSAML.IsActive = isTrue(attributes.get('User.IsActive'));
		}

		// check if the record is dirty and requires updating
		Boolean isUserDirty = false;
		for(String key : existingUserFromSAML.getPopulatedFieldsAsMap().keySet()) {
			if(existingUser.get(key) != existingUserFromSAML.get(key)) {
				isUserDirty = true;
				break;
			}
		}

		System.debug('existingUserFromSAML: ' + existingUserFromSAML);
		System.debug('existingUser: ' + existingUser);
		System.debug('isUserDirty: ' + isUserDirty);

		// we only want to do a DML if the record is dirty
		// if not, there is no point in updating
		if(isUserDirty) {
			ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{existingUserFromSAML});
		}

		return existingUserFromSAML;
	}

	/**
	 * Populates a new SObject with the attribute values from the SAML assertion
	 */
	private SObject populateRecord(SObjectType sObjectType, Map<String, String> attributes, Map<SObjectField, String> attributeMappings) {
		SObject record = sObjectType.newSObject();
		for(SObjectField field : attributeMappings.keySet()) {
			if(attributes.containsKey(attributeMappings.get(field))) {
				record.put(field, attributes.get(attributeMappings.get(field)));
			}
		}
		return record;
	}

	public static Boolean isTrue(Object value) {
		return (new Set<Object>{'1', 'true', 'TRUE', 'True', true, 1}).contains(value);
	}

}