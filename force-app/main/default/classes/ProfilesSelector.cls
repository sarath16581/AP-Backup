/**
* @author Nathan Franklin
* @date 2020-04-10
* @group Selector
* @tag Selector
* @tag Profile SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - Nathan Franklin - Created
* 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId,selectbyName and selectbyType Methods
*/
public virtual inherited sharing class ProfilesSelector extends ApplicationSelector {

	public static ProfilesSelector newInstance() {
		return (ProfilesSelector)Application.Selectors.newInstance(ProfilesSelector.class);
	}
	public static ProfilesSelector newInstance(Integer recordLimit) {
		return (ProfilesSelector)Application.Selectors.newInstance(ProfilesSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return Profile.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Profile.Description, Profile.Id, Profile.Name, Profile.UserLicenseId, Profile.UserType
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Profile> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Profile> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Profile.Id + ' in :ids')).endConditions();
		return new Map<Id, Profile>((List<Profile>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on profile name
	 */
	public Map<Id, Profile> selectByName(Set<String> names) {
		return selectByName(names, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on profile name
	 */
	public Map<Id, Profile> selectByName(Set<String> names, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Profile.Name + ' in :names')).endConditions();
		return new Map<Id, Profile>((List<Profile>)Database.query(qb.toSoqlString()));
	}

	public Map<Id, Profile> selectByType(Set<String> types) {
		return selectByType(types, new Set<Object>());
	}

	public Map<Id, Profile> selectByType(Set<String> types, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Profile.UserType + ' in :types')).endConditions();
		return new Map<Id, Profile>((List<Profile>)Database.query(qb.toSoqlString()));        
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}



}