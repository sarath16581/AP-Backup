/**
 * @description
 * A very simple selector class that sits in the base domain
 *
 * @author Dattaraj Deshmukh
 * @date 2023-02-06
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog	
 */
public virtual inherited sharing class NetworkUsersSelector extends ApplicationSelector {
	public static NetworkUsersSelector newInstance() {
		return (NetworkUsersSelector)Application.Selectors.newInstance(NetworkUsersSelector.class);
	}
	public static NetworkUsersSelector newInstance(Integer recordLimit) {
		return (NetworkUsersSelector)Application.Selectors.newInstance(NetworkUsersSelector.class).setLimit(recordLimit);
	}
	public virtual override SObjectType getSObjectType() {
		return Facility_User__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Facility_User__c.Id, Facility_User__c.Network__c, Facility_User__c.Is_MyNetwork_User__c,
			Facility_User__c.User__c, Facility_User__c.User_Role__c
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Facility_User__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Facility_User__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Facility_User__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Facility_User__c>((List<Facility_User__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Facility_User__c> selectByUserId(Set<Id> userIds) {
		return selectByUserId(userIds, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Facility_User__c> selectByUserId(Set<Id> userIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Facility_User__c.User__c + ' in :userIds')).endConditions();
		return new Map<Id, Facility_User__c>((List<Facility_User__c>)Database.query(qb.toSoqlString()));
	}
}