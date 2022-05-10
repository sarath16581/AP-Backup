/**
 * @author Ashapriya Gadi
 * @date 2021-11-17
 * @group Selector
 * @tag Selector
 * @tag Entitlement
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-11-17 - Ashapriya Gadi - Created
 * 2022-02-17 - Nathan Franklin - Changed method name and small refactor
 */
public virtual inherited sharing class EntitlementsSelector extends ApplicationSelector {
	
	public static EntitlementsSelector newInstance() {
		return (EntitlementsSelector)Application.Selectors.newInstance(EntitlementsSelector.class);
	}
	
	public virtual override SObjectType getSObjectType() {
		return Entitlement.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Entitlement.Id, Entitlement.Name, Entitlement.BusinessHoursId
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<Entitlement> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<Entitlement> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Entitlement.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());
	}
	/**
	 * @description Run a simple query to get entitlements based on Name that are tied to specific accounts
	 */
	public virtual List<Entitlement> selectByNameAndAccountName(Set<String> entitlementNames, Set<String> accountNames) {
		return selectByNameAndAccountName(entitlementNames, accountNames, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get entitlements based on Name that are tied to specific accounts
	 */
	public virtual List<Entitlement> selectByNameAndAccountName(Set<String> entitlementNames, Set<String> accountNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
					.add(new QueryBuilder.SimpleCondition(Entitlement.Name + ' in :entitlementNames'))
					.add(new QueryBuilder.SimpleCondition('Account.Name in :accountNames'))
				.endConditions();
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