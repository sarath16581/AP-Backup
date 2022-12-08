/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Selector
 * @domain Core
 * @description Selector class to provide a query interface to the APR__c SObject.
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public inherited sharing class APRsSelector extends ApplicationSelector{

	public enum Options {
		WITH_LEGAL_ENTITY
	}

	public static APRsSelector newInstance() {
		return (APRsSelector)Application.Selectors.newInstance(APRsSelector.class);
	}

	public static APRsSelector newInstance(Integer recordLimit) {
		return (APRsSelector)Application.Selectors.newInstance(APRsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static APRsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		APRsSelector selector = (APRsSelector)Application.Selectors.newInstance(APRsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static APRsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		APRsSelector selector = (APRsSelector)Application.Selectors.newInstance(APRsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static APRsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		APRsSelector selector = (APRsSelector)Application.Selectors.newInstance(APRsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return APR__c.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				APR__c.Billing_Account_Name__c, APR__c.Billing_Account_Revenue__c, APR__c.Billing_Account_Revenue_3PL__c,APR__c.Billing_Account_Revenue_COU__c,
				APR__c.Billing_Account_Revenue_EXP__c, APR__C.Billing_Account_Revenue_PRM__c, APR__c.Communicated_to_customer__c,
				APR__c.Communicated_to_customer_Date__c, APR__c.Conclusion_Date__c, APR__c.Confirmed_Rate__c, APR__c.Customer_Correspondence_Method__c,
				APR__c.Customer_Number__c, APR__c.Customer_Revenue__c, APR__c.Delegation_Allowance__c, APR__c.Confirmed_Date__c,
				APR__c.Entity_Phone__c, APR__c.Legal_Entity_Name_LookUp__c, APR__c.MHS_Cohort__c, APR__c.MHS_Comments__c, APR__c.MHS_Confirmed_Rate__c,
				APR__c.MHS_Published_Rate__c, APR__c.MHS_Status__c, APR__c.Penalty__c, APR__c.PriceTargetExcluded__c, APR__c.Sales_Team__c,
				APR__c.Sales_Team_Owner__c, APR__c.Special_Treatment__c, APR__c.Status__c, APR__c.Sub_Status__c, APR__c.Type__c,
				APR__c.Unresolved_Expected_Outcome_Date__c, APR__c.Walk_in_Rate__c, APR__c.Walk_out_Rate__c, APR__c.Year__c
		};
	}

	/**
	* This method is used to get query builder of APR__c records where legal entity not null
	* @return query locator of APR__c records
	*/
	public Database.QueryLocator selectByAccountRelationshipQueryLocator(Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(APR__c.Legal_Entity_Name_LookUp__c + ' != null'))
				.endConditions();
		return Database.getQueryLocator(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	/**
	 * Grabs a new QueryBuilder based on the selector options passed in
	 *
	 * @param selectorOptions set of additional selector options to augment the result set
	 * @return new QueryBuilder instance
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_LEGAL_ENTITY)) {
			builder.addRelatedFields(AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Legal_Entity_Name_LookUp__r');
		}
		return builder;
	}
}