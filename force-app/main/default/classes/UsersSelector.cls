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
*/
public virtual inherited sharing class UsersSelector extends ApplicationSelector {

	public enum Options {
		WITH_ROLE, WITH_PROFILE, WITH_CONTACT, FILTER_EXTERNAL_USERS
	}

	public static UsersSelector newInstance() {
		return (UsersSelector)Application.Selectors.newInstance(UsersSelector.class);
	}
	public static UsersSelector newInstance(Integer recordLimit) {
		return (UsersSelector)Application.Selectors.newInstance(UsersSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return User.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				User.Id, User.Username, User.FirstName, User.LastName, User.Email, User.FederationIdentifier, User.ProfileId, User.UserRoleId, User.UserPermissionsLiveAgentUser,
				User.OID_ID__c, User.UserType, User.Current_Owner_Role__c, User.LocaleSidKey, User.LanguageLocaleKey, User.TimeZoneSidKey, User.TimeZoneSidKey, User.Alias, User.IsActive,
				User.ContactId, User.APCN__c, User.EmployeeNumber
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
	 * @description Run a simple query to get active users based on Id, profile Name
	 */
	public Map<Id, User> selectActiveuserByProfileName(Set<Id> contactIds, String profileName, Set<Object> selectorOptions ) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(
			new QueryBuilder.SimpleCondition('ContactId in :contactIds')).add(
			new QueryBuilder.SimpleCondition('Profile.Name = :profileName')).add(
			new QueryBuilder.SimpleCondition('IsActive = true')).endConditions();
		return new Map<Id, User>((List<User>)Database.query(qb.toSoqlString()));
	}
	
	/**
	 * @description Run a simple query to get records based on usernames
	 */
	public Map<Id, User> selectByUsername(Set<String> usernames, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.Username + ' in :usernames')).endConditions();
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

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'Contact');
		}

		if(selectorOptions.contains(Options.WITH_ROLE)) {
			builder.addRelatedFields(UserRolesSelector.newInstance().newQueryBuilder(), 'UserRole');
		}

		if(selectorOptions.contains(Options.WITH_PROFILE)) {
			builder.addRelatedFields(ProfilesSelector.newInstance().newQueryBuilder(), 'Profile');
		}

		if(selectorOptions.contains(Options.FILTER_EXTERNAL_USERS)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(User.IsPortalEnabled).eq(true)).endConditions();
		}

		return builder;
	}



}