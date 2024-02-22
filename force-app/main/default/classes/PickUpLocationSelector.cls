/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag Pick Up Location Selector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 * 2023-10-10 - paul.perry5@auspost.com.au - Added options for selecting related tasks and filtering status pending information
 * 2024-02-19 - SteveL - Added selectByParentId
 */
public with sharing class PickUpLocationSelector extends ApplicationSelector{
	public enum Options {
		FILTER_PRIMARY_PICKUP_LOCATION,
		FILTER_STATUS_PENDING_INFORMATION,
		WITH_PENDING_TASKS
	}
	public static PickUpLocationSelector newInstance() {
		return (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class);
	}
	public static PickUpLocationSelector newInstance(Integer recordLimit) {
		return (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class).setLimit(recordLimit);
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */ 
	public static PickUpLocationSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PickUpLocationSelector selector = (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */ 
	public static PickUpLocationSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PickUpLocationSelector selector = (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}	
	public virtual override SObjectType getSObjectType() {
		return Pick_Up_Location__c.getSObjectType();
	}	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Pick_Up_Location__c.Id,Pick_Up_Location__c.Primary_Pick_Up_Location__c,Pick_Up_Location__c.Address__c, Pick_Up_Location__c.State__c, Pick_Up_Location__c.Postcode__c, Pick_Up_Location__c.Suburb__c,
			Pick_Up_Location__c.Pick_up_Location_Status__c
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Pick_Up_Location__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */

	public virtual Map<Id, Pick_Up_Location__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Pick_Up_Location__c.Id + ' in :ids')).endConditions();
		System.debug('Pickup Location query>>>>>>>>>>>'+qb.toSoqlString());
		return new Map<Id, Pick_Up_Location__c>((List<Pick_Up_Location__c>)Database.query(qb.toSoqlString()));
	}
	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on CSQ Id's
	 */
	public virtual List<Pick_Up_Location__c> selectByParentId(Set<Id> parentIds, Set<Object> selectorOptions) {
		QueryBuilder.ConditionsManager cm = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(Pick_Up_Location__c.CSQ__c + ' in :parentIds'));

		QueryBuilder qb = cm.endConditions();
		return (List<Pick_Up_Location__c>) Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		builder.addField('CSQ__r.Name');

		if(selectorOptions.contains(Options.FILTER_PRIMARY_PICKUP_LOCATION)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(Pick_Up_Location__c.Primary_Pick_Up_Location__c + '= true'));
		}
		if(selectorOptions.contains(Options.FILTER_STATUS_PENDING_INFORMATION)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(Pick_Up_Location__c.Pick_up_Location_Status__c + '= \'Pending Information\''));
		}
		builder.conditionsManager.endConditions();

		if(selectorOptions.contains(Options.WITH_PENDING_TASKS)) {
			builder.addField(String.join(new String[] {
				'(',
				'	SELECT Id, Subject, Status',
				'	FROM Tasks',
				'	WHERE Status != \'Completed\'',
				')'
			}, '\r\n'));
		}
		
	   return builder;
	}
}