/***
 * @group Selector
 * @tag Selector
 * @tag CreditSuspect
 * @domain Core
 * @description Selector class for CreditSuspect
 * @testclass CreditSuspectSelector_Test
 */
public virtual inherited sharing class CreditSuspectSelector extends ApplicationSelector {
	public enum Options { }

	public static CreditSuspectSelector newInstance() {
		return (CreditSuspectSelector) Application.Selectors.newInstance(CreditSuspectSelector.class);
	}
	public static CreditSuspectSelector newInstance(Integer recordLimit) {
		return (CreditSuspectSelector) Application.Selectors.newInstance(CreditSuspectSelector.class).setLimit(recordLimit);
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CreditSuspectSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		CreditSuspectSelector selector = (CreditSuspectSelector) Application.Selectors.newInstance(CreditSuspectSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static CreditSuspectSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CreditSuspectSelector selector = (CreditSuspectSelector) Application.Selectors.newInstance(CreditSuspectSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return CreditSuspect__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			CreditSuspect__c.Id, CreditSuspect__c.Name, CreditSuspect__c.FirstName__c, CreditSuspect__c.LastName__c, CreditSuspect__c.Phone__c,
			CreditSuspect__c.Email__c, CreditSuspect__c.Birthdate__c, CreditSuspect__c.StreetAddress__c, CreditSuspect__c.Suburb__c,
			CreditSuspect__c.PostCode__c, CreditSuspect__c.State__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, CreditSuspect__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, CreditSuspect__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(CreditSuspect__c.Id + ' IN :ids')).endConditions();
		return new Map<Id, CreditSuspect__c>((List<CreditSuspect__c>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}
}