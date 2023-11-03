/**
 * @description Handles all the Jit related capability of the Chas Login Handler
 * 				This class is used by the OIDC registration handler to either match an existing or create a new user and form a link between 
 * 					the IdP and Salesforce (through ThirdPartyAccountLink object). Note Salesforce manages this behind the scenes.
 * 				The '2' signifies a replacement of the original class which couldn't be overridden with new capability during deployment since it was still in use
 * @author Nathan Franklin
 * @date 2023-03-16
 * @changelog
 * 2023-08-01 Mahesh Parvathaneni - Added validation for backwards compabitibility for user federation id in updateForExistingUser method
 * 2023-08-31 Mahesh Parvathaneni - Added fieldOverrides for the UsersSelector
 * 2023-09-19 - Mahesh Parvathaneni - removed variable ATTRIBUTE_CNUMBER_MAPPING, ATTRIBUTE_APCN_MAPPING
 * 2023-10-25 - Mahesh Parvathaneni - Refactor to use IsInactiveCustomer__pc instead of is_Inactive_Customer__pc
 */
public with sharing class ChasRegHandlerService {

	public static final String DEFAULT_LOCALESIDKEY = 'en_AU';
	public static final String DEFAULT_LANGUAGELOCALEKEY = 'en_US';
	public static final String DEFAULT_TIMEZONESIDKEY = 'Australia/Sydney';
	public static final String DEFAULT_EMAILENCODINGKEY = 'UTF-8';

	public static final Map<SObjectField, String> PERSONACCOUNT_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS = new Map<SObjectField, String>{
		Account.FirstName => 'given_name',
		Account.LastName => 'family_name',
		Account.PersonEmail => 'email',
		Account.APCN__pc => Auth0OIDCAuthProvider.ATTRIBUTE_APCN_MAPPING,
		Account.OID_ID__pc => Auth0OIDCAuthProvider.ATTRIBUTE_CNUMBER_MAPPING,
		Account.CRMCSSOID__pc => 'augmented_email_uppercase' // defined in reg handler
	};

	public static final Map<SObjectField, String> USER_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS = new Map<SObjectField, String>{
		User.FirstName => 'given_name',
		User.LastName => 'family_name',
		User.Email => 'email',
		User.Username => 'augmented_username', // defined in reg handler
		User.FederationIdentifier => 'augmented_username' // defined in reg handler
		
		// This could be used in downstream reporting or integrations??
		// User.OID_ID__c => ATTRIBUTE_CNUMBER_MAPPING, // not sure why this is needed... the authoritative attributes should exist on the contact record only
		// User.APCN__c => ATTRIBUTE_APCN_MAPPING // not sure why this is needed... the authoritative attributes should exist on the contact record only
	};

	/**
	 * Make sure we only update the necessary fields
	 */
	public static final Map<SObjectField, String> USER_SOBJECT_UPDATEABLE_ATTRIBUTE_MAPPINGS = new Map<SObjectField, String>{
		User.FirstName => 'given_name',
		User.LastName => 'family_name',
		User.Email => 'email',
		User.Username => 'augmented_username', // defined in reg handler
		User.FederationIdentifier => 'augmented_username' // defined in reg handler
	};

	/**
	 * Provides a mockable interface for unit testing
	 */
	public static ChasRegHandlerService newInstance() {
		return (ChasRegHandlerService)Application.Utilities.newInstance(ChasRegHandlerService.class);
	}

	public static Map<String, String> getAugmentedAttributes(String federationIdentifier, Map<String, String> attributes) {
		Map<String, String> output = new Map<String, String>();
		output.putAll(attributes);

		output.put('augmented_email_uppercase', String.valueOf(attributes.get('email')).toUpperCase());
		output.put('augmented_username', federationIdentifier); // this is to maintain backwards compatibility of the millions of existing records we have

		return output;
	}

	public static String generateFederationIdentifier(String email) {
		String sandboxSuffix = Application.Cache.organizationInfo.isSandbox == true ? '.' + Application.Cache.organizationInfo.sandboxName : '';
		return String.valueOf(email) + '.community' + sandboxSuffix;
	}

	/**
	 * Verify that the attributes are valid
	 */
	public List<String> validateAssertion(String federationIdentifier, Map<String, String> attributes) {
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
		if(!attributes.containsKey('augmented_username')) {
			output.add('Username attribute is missing');
		}
		if(!attributes.containsKey(Auth0OIDCAuthProvider.ATTRIBUTE_APCN_MAPPING)) {
			output.add('APCN attribute is missing');
		}
		if(!attributes.containsKey(Auth0OIDCAuthProvider.ATTRIBUTE_CNUMBER_MAPPING)) {
			output.add('CNumber attribute is missing');
		}

		// fail early if possible
		if(!output.isEmpty()) {
			return output;
		}

		return output;
	}

	/**
	 * Find or provision a new PersonAccount/User
	 * 
	 * the APCN for a consumer user is the authoritative attribute for a user logging in.
	 * NOTE: Reasons a user would not exist as a consumer (person account):
	 * 1. Error with integration where person account wasn't created
	 * 2. User registered with business product holdings and then decided to use their business credentials to log into consumer portal
	 * 3. Race condition - user registered and instantly tried to log in to consumer portal (normally it would be they signed up as a part of the login process)
	 */
	public User matchOrCreate(String federationId, Map<String, String> attributes) {

		// look for an existing records first
		Map<SObjectType, SObject> existingRecords = getExistingRecords(attributes);

		Id personContactId;
		Account personAccountRecord;
		User personUserRecord;

		if(existingRecords.get(Account.SObjectType) != null) {
			// we found the person account record
			personAccountRecord = (Account)existingRecords.get(Account.SObjectType);
			personContactId = personAccountRecord.PersonContactId;

			//throw an error if it is inactive customer
			if(personAccountRecord.IsInactiveCustomer__pc != null && personAccountRecord.IsInactiveCustomer__pc) {
				throw new RegHandlerException('Customer is Inactive');
			}

		} else {
			// couldn't find the person account record so one must be created
			// NOTE: createPersonAccount performs a DML 
			personAccountRecord = createPersonAccount(attributes);
			personContactId = personAccountRecord.PersonContactId;
		}

		if(existingRecords.get(User.SObjectType) != null) {
			// we found a matching user from the person account record
			personUserRecord = (User)existingRecords.get(User.SObjectType);

			if(!userIsFederatedMatch(personUserRecord, federationId)) {
				throw new RegHandlerException('Could not find a federated match for an existing user.');
			}

			// update the user if it's necessary
			return updateForExistingUser(personUserRecord, attributes);
		} else {
			personUserRecord = getNewUserSObject(personContactId, attributes);
			return personUserRecord;
		}
	}

	/**
	 * Method will attempt to grab both the person account and user records if they exist based on the attributes passed in
	 */
	public Map<SObjectType, SObject> getExistingRecords(Map<String, String> attributes) {
		Map<SObjectType, SObject> output = new Map<SObjectType, SObject>();
		
		String existingAPCN = attributes.get(Auth0OIDCAuthProvider.ATTRIBUTE_APCN_MAPPING);
		if(String.isEmpty(existingAPCN)) {
			throw new RegHandlerException('APCN attribute is empty');
		}

		// look for an existing record first, if we find one, we use that and attempt to link a new new user record on it.
		Map<Id, Account> accounts = SSSWAccountsSelector.newInstance().selectByAPCN(new Set<String>{existingAPCN}, new Set<Object>{SSSWAccountsSelector.Options.FILTER_PERSON_ACCOUNT_ONLY});

		if(accounts.size() == 1) {
			// we found a match grab the associated contact id and try and match the associated User record
			output.put(Account.SObjectType, accounts.values()[0]);
			
			// grab the person contact id since we need it below
			// NOTE: the FILTER_PERSON_ACCOUNT_ONLY force only person account records to be returned so this value will always be populated
			Id personContactId = accounts.values()[0].PersonContactId;

			System.debug('Existing PersonAccount record found: ' + accounts);

			//field overrides
			Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				User.SObjectType => UsersSelector.getAuthenticationSObjectFieldList(),
				Account.SObjectType => new Set<SObjectField>{Account.IsInactiveCustomer__pc}
			};

			// now the PersonAccount is out of the way we move onto the User record
			// try and find an existing user based on the contact id passed in
			List<User> users = UsersSelector.newInstance(0, fieldOverrides).selectByContactId(new Set<Id>{personContactId}, new Set<Object>{ UsersSelector.Options.WITH_COMMUNITY_ACCOUNT }).values();

			if(!users.isEmpty()) {
				// found a user that is already linked to the PersonAccount above
				output.put(User.SObjectType, users[0]);

				System.debug('Existing User record found: ' + users);
			}
		}

		return output;
	}

	/**
	 * Create a new person account record for use with the community the user is logging into
	 * This is invoked where a person account record could not be found based on the matching criteria
	 */
	public Account createPersonAccount(Map<String, String> attributes) {
		Account matchedAccount = (Account)populateRecord(Account.getSObjectType(), attributes, PERSONACCOUNT_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS);
		matchedAccount.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{ChasConstants.PERSON_ACCOUNT_RECORD_TYPE_DEVELOPER_NAME}).values()[0].Id;

		System.debug('Creating new PersonAccount record');
		System.debug('Using these details: ' + matchedAccount);

		// insert the record
		// NOTE: This should trigger the outbound message to sync these details to SAP-CRM (thats if the outbound message is still active) - 2023-03
		ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{matchedAccount});

		// after the record has been inserted we need to select the PersonContactId so it can be assigned to the user record
		matchedAccount = SSSWAccountsSelector.newInstance().selectById(new Set<Id>{matchedAccount.Id}).values()[0];

		return matchedAccount;
	}

	/**
	 * Update existing User record when a ThirdPartyAccountLink record is matched
	 * NOTE, this will only update a small set of attributes on the user record.
	 */
	public User updateForExistingUser(Id userId, Map<String, String> attributes) {
		//field overrides
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			User.SObjectType => UsersSelector.getAuthenticationSObjectFieldList(),
			Account.SObjectType => new Set<SObjectField>{Account.IsInactiveCustomer__pc}
		};

		User existingUser = UsersSelector.newInstance(0, fieldOverrides).selectById(new Set<Id>{userId}, new Set<Object>{ UsersSelector.Options.WITH_COMMUNITY_ACCOUNT }).values()[0];
		return updateForExistingUser(existingUser, attributes);
	}

	/**
	 * Update existing User record when a ThirdPartyAccountLink record is matched
	 * NOTE, this will only update a small set of attributes on the user record.
	 */
	public User updateForExistingUser(User userRecord, Map<String, String> attributes) {
		
		// make sure that the user has not been disabled and disconnected from the person account
		if(!userRecord.IsPortalEnabled) {
			throw new RegHandlerException('User is configured incorrectly. Not a portal user.');
		}

		if(!userIsFederatedMatch(userRecord, attributes.get('augmented_username'))) {
			throw new RegHandlerException('Could not find a federated match for an existing user.');
		}

		//throw an error if it is inactive customer
		Boolean isInactiveCustomer = userRecord?.Contact?.Account?.IsInactiveCustomer__pc;
		if(isInactiveCustomer != null && isInactiveCustomer) {
			throw new RegHandlerException('Customer is Inactive');
		}

		// populate a user record for update
		// this is so we can compare the data in the existing user record against the claims from the IdP
		User claimsGeneratedUserRecord = (User)populateRecord(User.getSObjectType(), attributes, USER_SOBJECT_UPDATEABLE_ATTRIBUTE_MAPPINGS);
		claimsGeneratedUserRecord.Id = userRecord.Id;

		// auto activate the user
		// NOTE: If the user needs to be disabled then this should occur at the IdP level for now....
		// Further consideration should be given as to whether this stacks up or not....
		claimsGeneratedUserRecord.IsActive = true;

		// check if the record is dirty and requires updating
		Boolean isUserDirty = false;
		for(String key : claimsGeneratedUserRecord.getPopulatedFieldsAsMap().keySet()) {
			if(userRecord.get(key) != claimsGeneratedUserRecord.get(key)) {
				isUserDirty = true;
				break;
			}
		}

		System.debug('claimsGeneratedUserRecord: ' + claimsGeneratedUserRecord);
		System.debug('userRecord: ' + userRecord);
		System.debug('isUserDirty: ' + isUserDirty);

		// we need to synchronise the user record with the claims from oidc
		// NOTE: it's possible if the record details contain completely different data then we may overwrite it by doing this
		//		 It's assumed that the data in the db is right and no-one has manually tampered with it
		if(isUserDirty) {
			ApplicationDatabase.getInstance().dmlUpdate(new List<User>{claimsGeneratedUserRecord});
		}

		return claimsGeneratedUserRecord;
	}

	/**
	 * When the JIT process requires a new user we use this method to create the SObject variable
	 * NOTE: This method does not perform a DML operation and leaves it up to the caller to decide
	 * In a createUser reg handler context, internal salesforce will handle the DML,
	 * This may also be called in other places, in which it's the callers responsibily to insert the user
	 */
	public User getNewUserSObject(Id personContactId, Map<String, String> attributes) {
		User personUserRecord = (User)populateRecord(User.getSObjectType(), attributes, USER_SOBJECT_CREATEABLE_ATTRIBUTE_MAPPINGS);
		personUserRecord.ContactId = personContactId;
		personUserRecord.ProfileId = ChasConstants.CONSUMER_COMMUNITY_PROFILE_ID;

		// set the default values 
		personUserRecord.LocaleSidKey = DEFAULT_LOCALESIDKEY;
		personUserRecord.LanguageLocaleKey = DEFAULT_LANGUAGELOCALEKEY;
		personUserRecord.TimeZoneSidKey = DEFAULT_TIMEZONESIDKEY;
		personUserRecord.EmailEncodingKey = DEFAULT_EMAILENCODINGKEY;
		personUserRecord.IsActive = true;

		// generate the alias for this user
		if(personUserRecord.Alias == null) {
			String alias = '';
			if (personUserRecord.FirstName == null) {
				alias = personUserRecord.LastName;
			} else {
				alias = personUserRecord.FirstName.substring(0, 1) + personUserRecord.LastName;
			}
			if (alias.length() > 5) {
				alias = alias.substring(0, 5);
			}
			personUserRecord.Alias = alias;
		}

		System.debug('Creating new User record');
		System.debug('Using these details: ' + personUserRecord);

		// NOTE: we don't need to trigger a DML insert since the JIT process will manage this for us
		System.debug('personUserRecord: ' + personUserRecord);
		return personUserRecord;
	}

	/**
	 * Allows us to check if federation id matches the user record passed in.
	 * This provides a centralised location for performing this logic
	 */
	public Boolean userIsFederatedMatch(User userRecord, String federationId) {
		System.debug(userRecord.FederationIdentifier + ' = ' + federationId);
		return federationId.equalsIgnoreCase(userRecord.FederationIdentifier); 
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

	public class RegHandlerException extends Exception{}
}