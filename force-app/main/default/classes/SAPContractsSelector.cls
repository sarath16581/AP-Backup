/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Selector
 * @domain Core
 * @description Selector class to provide a query interface to the SAP Contract SObject.
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public inherited sharing class SAPContractsSelector extends ApplicationSelector{

	public enum Options {
		WITH_ORGANISATION
	}

	public static SAPContractsSelector newInstance() {
		return (SAPContractsSelector)Application.Selectors.newInstance(SAPContractsSelector.class);
	}

	public static SAPContractsSelector newInstance(Integer recordLimit) {
		return (SAPContractsSelector)Application.Selectors.newInstance(SAPContractsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static SAPContractsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SAPContractsSelector selector = (SAPContractsSelector)Application.Selectors.newInstance(SAPContractsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static SAPContractsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		SAPContractsSelector selector = (SAPContractsSelector)Application.Selectors.newInstance(SAPContractsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static SAPContractsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SAPContractsSelector selector = (SAPContractsSelector)Application.Selectors.newInstance(SAPContractsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return APT_SAP_Contracts__c.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				APT_SAP_Contracts__c.APT_Contracted_Revenue__c, APT_SAP_Contracts__c.APT_Contract_End_Date__c, APT_SAP_Contracts__c.APT_Contract_Extension_Date__c,
				APT_SAP_Contracts__c.APT_Contract_Sold_To_Billing_Account__c, APT_SAP_Contracts__c.APT_Contract_Sold_To_ID__c, APT_SAP_Contracts__c.APT_Contract_Sold_To_Name__c,
				APT_SAP_Contracts__c.APT_Contract_Start_Date__c, APT_SAP_Contracts__c.APT_Contract_Type_Code__c
		};
	}

	/**
	* This method is used to get query builder of SAP Contract records where organisaion not null
	* @return query locator of SAP Contract records
	*/
	public Database.QueryLocator selectByAccountRelationshipQueryLocator(Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(APT_SAP_Contracts__c.Organisation__c + ' != null'))
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
		if (selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Organisation__r');
		}
		return builder;
	}
}