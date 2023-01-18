/* @author Ranjeewa Silva
 * @group Selector
 * @tag Selector
 * @tag Account
 * @domain Sales
 * @test SalesAccountsSelector_Test
 * @description Selector class that sits in Sales domain for accessing accounts.
 * @changelog
 * 2022-12-18 - Ranjeewa Silva - Created.
 */
public virtual inherited sharing class SalesAccountsSelector extends AccountsSelector {

	public enum Options {
		FILTER_BUSINESS_ACCOUNTS_ONLY
	}

	public static SalesAccountsSelector newInstance() {
		return (SalesAccountsSelector) Application.Selectors.newInstance(SalesAccountsSelector.class);
	}
	public static SalesAccountsSelector newInstance(Integer recordLimit) {
		return (SalesAccountsSelector) Application.Selectors.newInstance(SalesAccountsSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static SalesAccountsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SalesAccountsSelector selector = (SalesAccountsSelector) Application.Selectors.newInstance(SalesAccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * Query accounts by specified ids. Also retrieve related records of the specified sobject types using the
	 * child relationship names passed in and include with the query results returned.
	 *
	 * Intended to be used when caller needs to retrieve child records of Accounts of particular sobject types dynamically
	 * at run time and child relationship names are already known (e.g. configuration specific to caller). Caller is
	 * responsible for passing in valid child relationships.
	 *
	 * @param ids account ids to retrieve
	 * @param childRelationships child relationships to be included in results as related records
	 *
	 * @return list of Accounts
	 */
	public List<Account> selectByIdWithChildRecords(Set<Id> ids, Map<SObjectType, String> childRelationships) {
		return selectByIdWithChildRecords(ids, childRelationships, new Set<Object>());
	}

	/**
	 * Query accounts by specified ids. Also retrieve related records of the specified sobject types using the
	 * child relationship names passed in and include with the query results returned.
	 *
	 * Intended to be used when caller needs to retrieve child records of Accounts of particular sobject types dynamically
	 * at run time and child relationship names are already known (e.g. configuration specific to caller). Caller is
	 * responsible for passing in valid child relationships.
	 *
	 * @param ids account ids to retrieve
	 * @param childRelationships  child relationships to be included in results as related records
	 * @param selectorOptions selector options
	 *
	 * @return list of Accounts
	 */
	public List<Account> selectByIdWithChildRecords(Set<Id> ids, Map<SObjectType, String> childRelationships, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Account.Id + ' in :ids')).endConditions();
		for (SObjectType relatedObject: childRelationships.keySet()) {
			QueryBuilder relatedObjectQueryBuilder = new QueryBuilder();
			// always retrieve child record id from the related object
			relatedObjectQueryBuilder.addField('Id');
			if (fieldOverrides.containsKey(relatedObject)) {
				relatedObjectQueryBuilder.addFields(fieldOverrides.get(relatedObject));
			}
			qb.addSubQuery(relatedObjectQueryBuilder, childRelationships.get(relatedObject));
		}
		return (List<Account>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.FILTER_BUSINESS_ACCOUNTS_ONLY)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Account.IsPersonAccount).eq(false)).endConditions();
		}
		return builder;
	}
}