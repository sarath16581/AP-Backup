/**
* @author Ashapriya Gadi
* @date 2021-11-17
* @group Selector
* @tag Selector
* @tag BusinessHours
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-11-17 - Ashapriya Gadi - Created
*/

public virtual inherited sharing class BusinessHoursSelector extends ApplicationSelector {
	public static BusinessHoursSelector newInstance() {
		return (BusinessHoursSelector)Application.Selectors.newInstance(BusinessHoursSelector.class);
	}
	
	public virtual override SObjectType getSObjectType() {
		return  Schema.BusinessHours.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				BusinessHours.Id, BusinessHours.Name
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<BusinessHours> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<BusinessHours> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(BusinessHours.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());
	}
	/**
	 * @description Run a simple query to get entitlements based on Name
	 */
	public virtual List<BusinessHours> selectByName(Set<String> BusinessHoursNames) {
		return selectByName(BusinessHoursNames, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get entitlements based on Name
	 */
	public virtual List<BusinessHours> selectByName(Set<String> BusinessHoursNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(BusinessHours.Name + ' in :BusinessHoursNames')).endConditions();
		return Database.query(qb.toSoqlString());
	}
	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}
	
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}
}