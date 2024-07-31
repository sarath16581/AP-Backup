/**
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag User SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId,selectbyUserName and selectByContactId Methods
 * 2021-03-02 - Alvin Zhou - Updated - selectActiveuserByProfileName and add the Current_Owner_Role__c to the related list
 * 2022-02-24 - Nathan Franklin - Added a field override capability
 * 2022-03-14 - Nathan Franklin - uplifted to version 52
 * 2022-08-25 - Mahesh Parvathaneni - Added method selectByName
 * 2022-08-30 - Nathan Franklin - Added field overrides Map<>
 * 2023-01-27 - Naveen Rajanna - Updated api version and added method selectUsersEligibleForDeactivationQueryLocator
 * 2023-02-01 - Noel Lim - added method selectActiveUserById 
 * 2023-03-01 - Nathan Franklin - add search conditions, new fields, and field overrides to related Profile selector
 * 2023-07-14 - Nathan Franklin - add search params and param validation
 * 2023-08-08 - Mahesh Parvathaneni - added method getAuthenticationSObjectFieldList for user authentication fields
*/
public virtual inherited sharing class UsersSelector extends ApplicationSelector {

	public enum Options {
		WITH_ROLE, WITH_PROFILE, WITH_CONTACT, FILTER_EXTERNAL_USERS, WITH_COMMUNITY_ACCOUNT
	}

	public static final String MERCHANT_PORTAL_PROFILE_NAME = 'Merchant Portal Community User';

	public static UsersSelector newInstance() {
		return (UsersSelector)Application.Selectors.newInstance(UsersSelector.class);
	}
	public static UsersSelector newInstance(Integer recordLimit) {
		return (UsersSelector)Application.Selectors.newInstance(UsersSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static UsersSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		UsersSelector selector = (UsersSelector)Application.Selectors.newInstance(UsersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static UsersSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		UsersSelector selector = (UsersSelector)Application.Selectors.newInstance(UsersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}


	public override SObjectType getSObjectType() {
		return User.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				User.Id,User.Name, User.Username, User.FirstName, User.LastName, User.Email, User.FederationIdentifier, User.ProfileId, User.UserRoleId, User.UserPermissionsLiveAgentUser,
				User.OID_ID__c, User.UserType, User.Current_Owner_Role__c, User.LocaleSidKey, User.LanguageLocaleKey, User.TimeZoneSidKey, User.TimeZoneSidKey, User.Alias, User.IsActive,
				User.ContactId, User.APCN__c, User.EmployeeNumber, User.IsPortalEnabled
		};
	}

	public static Set<SObjectField> getAuthenticationSObjectFieldList() {
		return new Set<SObjectField> {
			User.Id, User.Name, User.Username, User.FirstName, User.LastName, User.Email, User.FederationIdentifier, User.ProfileId, User.LocaleSidKey, User.LanguageLocaleKey, User.TimeZoneSidKey, 
			User.Alias, User.IsActive, User.ContactId, User.IsPortalEnabled
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, User> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, User> selectById(Set<Id> ids, Set<Object> selectorOptions) {
				QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.Id + ' in :ids')).endConditions();
		return new Map<Id, User>((List<User>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on usernames
	 */
	public Map<Id, User> selectByUsername(Set<String> usernames) {
		return selectByUsername(usernames, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get active users based on Id's
	 */
	public Map<Id, User> selectActiveUserById(Set<Id> ids) {
	QueryBuilder qb = newQueryBuilder(new Set<Object>())
				.addConditions()
				.add(new QueryBuilder.CompareCondition(User.IsActive).eq(true))
				.add(new QueryBuilder.SimpleCondition(User.Id + ' in :ids'))
				.setConditionOrder('1 AND 2')
				.endConditions();
		return new Map<Id, User>((List<User>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get active users based on Id, profile Name
	 */
	public Map<Id, User> selectActiveUserByProfileName(Set<Id> contactIds, String profileName, Set<Object> selectorOptions) {
		return new Map<Id, User>(search(new Map<String, Object>{
				'contactIds' => contactIds, 'profileNames' => profileName, 'isActive' => true
		}, selectorOptions, true));
	}

	/**
	 * @description Run a simple query to get users based on contact Id, profile Name
	 */
	public Map<Id, User> selectUserByContactIdAndProfileName(Set<Id> contactIds, String profileName, Set<Object> selectorOptions) {
		return new Map<Id, User>(search(new Map<String, Object>{
				'contactIds' => contactIds, 'profileNames' => profileName
		}, selectorOptions, true));
	}

	/**
	 * @description Run a simple query to get records based on usernames
	 */
	public Map<Id, User> selectByUsername(Set<String> usernames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.Username + ' in :usernames')).endConditions();
		return new Map<Id, User>((List<User>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on names
	 */
	public Map<Id, User> selectByName(Set<String> names) {
		return selectByName(names, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on names
	 */
	public Map<Id, User> selectByName(Set<String> names, Set<Object> selectorOptions) {
				QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.Name + ' in :names')).endConditions();
		return new Map<Id, User>((List<User>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on Username.ContactId
	 */
	public Map<Id, User> selectByContactId(Set<Id> contactIds) {
		return selectByContactId(contactIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Username.ContactId
	 */
	public Map<Id, User> selectByContactId(Set<Id> contactIds, Set<Object> selectorOptions) {
				QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.ContactId + ' in :contactIds')).endConditions();
		return new Map<Id, User>((List<User>)Database.query(qb.toSoqlString()));
	}

 	/**
	 * To retrieve users who have been inactive and based on few more filters
	 * @param userTypeSet userType to be filtered
	 * @param lastLoginDays number of days of inactivity after which a user should be deactivated
	 * @param lastCreatedDays number of days to wait for deactivation after a user has been invited but has not yet logged in
	 * @param excludeProfileSet profile names to be excluded
	 * @param selectorOptions 
	 * @return	`Database.QueryLocator`
	 */	
	public Database.QueryLocator selectUsersEligibleForDeactivationQueryLocator(
		Set<String> userTypeSet,
		Integer lastLoginDays,
		Integer lastCreatedDays,
		Set<String> excludeProfileSet,
		Set<Object> selectorOptions
	) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions
			.add(new QueryBuilder.CompareCondition(User.IsActive).eq(true))
			.add(new QueryBuilder.CompareCondition(User.IsExcludedFromAutoDeactivation__c).eq(false))
			.add(new QueryBuilder.SimpleCondition(User.UserType + ' IN :userTypeSet'))
			.add(new QueryBuilder.SimpleCondition('Profile.Name NOT IN :excludeProfileSet'))
			.add(new QueryBuilder.SimpleCondition(User.Last_Login_Date_Test__c + ' < LAST_N_DAYS:' + lastLoginDays))
			.add(new QueryBuilder.NullCondition(User.LastLoginDate).isNull())
			.add(new QueryBuilder.SimpleCondition(User.CreatedDate + ' < LAST_N_DAYS:' + lastCreatedDays));
		String conditionString = '1 AND 2 AND 3 AND 4 AND (5 OR (6 AND 7))';
		conditions.setConditionOrder(conditionString).endConditions();	
		qb.addOrderAsc(User.LastLoginDate);
		return Database.getQueryLocator(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 federationIds: maps to FederationIdentifier (Set<String>/String)
	 *						 contactIds: maps to Contact (Set<Id>/Id)
	 *						 profileIds: maps to Profile (Set<Id>/Id)
	 *						 roleIds: maps to UserRole (Set<Id>/Id)
	 *						 profileNames: maps to Profile (Set<String>/String)
	 *						 usernames: maps to Username (Set<String>/String)
	 *						 userTypes: maps to UserType (Set<String>/String)
	 *						 contactStatuses: maps to Contact.Status__c (Set<String>/String)
	 *						 contactCNumbers: maps to Contact.OID_ID__c (Set<String>/String)
	 *						 networkIds: Users with NetworkMember records (Set<Id>/Id)
	 *						 isCommunityUser: maps to IsPortalEnabled (true/false)
	 *						 isPersonAccount: maps to Contact.IsPersonAccount (true/false) - Assumes user would have to be a community user
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<User> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 federationIds: maps to FederationIdentifier (Set<String>/String)
	 *						 contactIds: maps to Contact (Set<Id>/Id)
	 *						 profileIds: maps to Profile (Set<Id>/Id)
	 *						 roleIds: maps to UserRole (Set<Id>/Id)
	 *						 profileNames: maps to Profile (Set<String>/String)
	 *						 usernames: maps to Username (Set<String>/String)
	 *						 userTypes: maps to UserType (Set<String>/String)
	 *						 contactStatuses: maps to Contact.Status__c (Set<String>/String)
	 *						 contactCNumbers: maps to Contact.OID_ID__c (Set<String>/String)
	 *						 networkIds: Users with NetworkMember records (Set<Id>/Id)
	 *						 federationField: This is the field to use when comparing federationIds is supplied. This will default to User.FederationIdentifier if no SObjectField is passed in
	 *						 isCommunityUser: maps to IsPortalEnabled (true/false)
	 *						 isPersonAccount: maps to Contact.IsPersonAccount (true/false) - Assumes user would have to be a community user
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<User> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		Set<Id> profileIds = (Set<Id>)(searchParams.get('profileIds') == null ? new Set<Id>() : (searchParams.get('profileIds') instanceof Set<Id> ? searchParams.get('profileIds') : new Set<Id>{(Id)searchParams.get('profileIds')}));
		Set<Id> contactIds = (Set<Id>)(searchParams.get('contactIds') == null ? new Set<Id>() : (searchParams.get('contactIds') instanceof Set<Id> ? searchParams.get('contactIds') : new Set<Id>{(Id)searchParams.get('contactIds')}));
		Set<Id> roleIds = (Set<Id>)(searchParams.get('roleIds') == null ? new Set<Id>() : (searchParams.get('roleIds') instanceof Set<Id> ? searchParams.get('roleIds') : new Set<Id>{(Id)searchParams.get('roleIds')}));
		Set<String> federationIds = (Set<String>)(searchParams.get('federationIds') == null ? new Set<String>() : (searchParams.get('federationIds') instanceof Set<String> ? searchParams.get('federationIds') : new Set<String>{String.valueOf(searchParams.get('federationIds'))}));
		Set<String> profileNames = (Set<String>)(searchParams.get('profileNames') == null ? new Set<String>() : (searchParams.get('profileNames') instanceof Set<String> ? searchParams.get('profileNames') : new Set<String>{String.valueOf(searchParams.get('profileNames'))}));
		Set<String> usernames = (Set<String>)(searchParams.get('usernames') == null ? new Set<String>() : (searchParams.get('usernames') instanceof Set<String> ? searchParams.get('usernames') : new Set<String>{String.valueOf(searchParams.get('usernames'))}));
		Set<String> userTypes = (Set<String>)(searchParams.get('userTypes') == null ? new Set<String>() : (searchParams.get('userTypes') instanceof Set<String> ? searchParams.get('userTypes') : new Set<String>{String.valueOf(searchParams.get('userTypes'))}));
		Set<String> contactStatuses = (Set<String>)(searchParams.get('contactStatuses') == null ? new Set<String>() : (searchParams.get('contactStatuses') instanceof Set<String> ? searchParams.get('contactStatuses') : new Set<String>{String.valueOf(searchParams.get('contactStatuses'))}));
		Set<String> contactCNumbers = (Set<String>)(searchParams.get('contactCNumbers') == null ? new Set<String>() : (searchParams.get('contactCNumbers') instanceof Set<String> ? searchParams.get('contactCNumbers') : new Set<String>{String.valueOf(searchParams.get('contactCNumbers'))}));
		Boolean activeOrMerchantPortalProfile = (searchParams.get('activeOrMerchantPortalProfile') != null ? (Boolean)searchParams.get('activeOrMerchantPortalProfile') : false);
		Boolean isActive = (searchParams.get('isActive') != null ? (Boolean)searchParams.get('isActive') : false);
		Boolean isCommunityUser = (searchParams.get('isCommunityUser') != null ? (Boolean)searchParams.get('isCommunityUser') : false);
		Boolean isPersonAccount = (searchParams.get('isPersonAccount') != null ? (Boolean)searchParams.get('isPersonAccount') : false);

		return (List<User>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'profileIds', 'contactIds', 'roleIds', 'networkIds', 'federationField', 
																	'federationIds', 'profileNames', 'usernames', 'isActive' , 'isCommunityUser', 
																	'isPersonAccount', 'contactStatuses', 'contactCNumbers', 'userTypes',
																	'activeOrMerchantPortalProfile'});

		Set<Id> networkIds = (Set<Id>)(searchParams.get('networkIds') == null ? new Set<Id>() : (searchParams.get('networkIds') instanceof Set<Id> ? searchParams.get('networkIds') : new Set<Id>{(Id)searchParams.get('networkIds')}));
		SObjectField federationField = (searchParams.get('federationField') != null ? (SObjectField)searchParams.get('federationField') : User.FederationIdentifier);

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('profileIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.ProfileId + ' in :profileIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('contactIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.ContactId + ' in :contactIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('roleIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.UserRoleId + ' in :roleIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('networkIds')) {
			QueryBuilder qbInner = new QueryBuilder(NetworkMember.SObjectType);
			qbInner.addFields(new List<SObjectField>{NetworkMember.MemberId});
			qbInner.addConditions().add(new QueryBuilder.InCondition(NetworkMember.NetworkId).inCollection(networkIds)).endConditions();

			conditions.add(new QueryBuilder.InCondition(User.Id).inCollection(qbInner));
			conditionCount++;
		}
		if(searchParams.containsKey('federationIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(federationField + ' in :federationIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('profileNames')) {
			conditions.add(new QueryBuilder.SimpleCondition('Profile.' + Profile.Name + ' in :profileNames'));
			conditionCount++;
		}
		if(searchParams.containsKey('usernames')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.Username + ' in :usernames'));
			conditionCount++;
		}
		if(searchParams.containsKey('contactCNumbers')) {
			conditions.add(new QueryBuilder.SimpleCondition('Contact.' + Contact.OID_ID__c + ' in :contactCNumbers'));
			conditionCount++;
		}
		if(searchParams.containsKey('contactStatuses')) {
			conditions.add(new QueryBuilder.SimpleCondition('Contact.' + Contact.Status__c + ' in :contactStatuses'));
			conditionCount++;
		}
		if(searchParams.containsKey('userTypes')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.UserType + ' in :userTypes'));
			conditionCount++;
		}
		if(searchParams.containsKey('isActive')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.IsActive + ' = :isActive'));
			conditionCount++;
		}
		if(searchParams.containsKey('isCommunityUser')) {
			conditions.add(new QueryBuilder.SimpleCondition(User.IsPortalEnabled + ' = :isCommunityUser'));
			conditionCount++;
		}
		if(searchParams.containsKey('isPersonAccount')) {
			conditions.add(new QueryBuilder.SimpleCondition('Contact.IsPersonAccount = :isPersonAccount'));
			conditionCount++;
		}
		if(searchParams.containsKey('activeOrMerchantPortalProfile')) {
			conditions.add(new QueryBuilder.SimpleCondition('(Profile.Name = :MERCHANT_PORTAL_PROFILE_NAME OR IsActive = true)'));
			conditionCount++;
		}

		// build our condition string which would end up being something liek the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		return conditions.endConditions().toSoqlString();
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Contact');
		}

		if(selectorOptions.contains(Options.WITH_ROLE)) {
			builder.addRelatedFields(UserRolesSelector.newInstance().newQueryBuilder(), 'UserRole');
		}

		if(selectorOptions.contains(Options.WITH_PROFILE)) {
			builder.addRelatedFields(ProfilesSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Profile');
		}

		if(selectorOptions.contains(Options.FILTER_EXTERNAL_USERS)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(User.IsPortalEnabled).eq(true)).endConditions();
		}

		if(selectorOptions.contains(Options.WITH_COMMUNITY_ACCOUNT)) {
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Contact.Account');
		}

		return builder;
	}



}