/***
 * @description Selector class for EmailToCaseMapping__mdt custom metadata type
 * @author Mahesh Parvathaneni
 * @date 2023-05-26
 * @changelog
 * 05/04/2024 - Thang Nguyen - add the new ProductType__c field
*/

public virtual inherited sharing class EmailToCaseMappingsSelector extends ApplicationSelector {

	public enum Options {
		FILTER_ACTIVE
	}

	public static EmailToCaseMappingsSelector newInstance() {
		return newInstance(0, new Set<SObjectField>());
	}
	public static EmailToCaseMappingsSelector newInstance(Integer recordLimit) {
		return newInstance(recordLimit, new Set<SObjectField>());
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static EmailToCaseMappingsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return newInstance(recordLimit, new Map<SObjectType, Set<SObjectField>>{EmailToCaseMapping__mdt.SObjectType => fieldOverrides});
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static EmailToCaseMappingsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		EmailToCaseMappingsSelector selector = (EmailToCaseMappingsSelector)Application.Selectors.newInstance(EmailToCaseMappingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return EmailToCaseMapping__mdt.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			EmailToCaseMapping__mdt.Id, EmailToCaseMapping__mdt.AssignNetworkWCIS__c, EmailToCaseMapping__mdt.EmailToCaseAddress__c, 
			EmailToCaseMapping__mdt.IsActive__c, EmailToCaseMapping__mdt.CasePurpose__c, EmailToCaseMapping__mdt.ProductType__c
		};
	}

	/**
	 * @description Run a simple query to get all records
	 */
	public List<EmailToCaseMapping__mdt> selectAll() {
		return selectAll(new Set<Object>());
	}

	/**
	 * @description Run a simple query to get all records
	 */
	public List<EmailToCaseMapping__mdt> selectAll(Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		return (List<EmailToCaseMapping__mdt>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on email to case address
	 */
	public List<EmailToCaseMapping__mdt> selectByEmailToCaseAddress(Set<String> emailAddress) {
		return selectByEmailToCaseAddress(emailAddress, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on email to case address
	 */
	public List<EmailToCaseMapping__mdt> selectByEmailToCaseAddress(Set<String> emailAddress, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(EmailToCaseMapping__mdt.EmailToCaseAddress__c + ' in :emailAddress')).endConditions();
		return (List<EmailToCaseMapping__mdt>)Database.query(qb.toSoqlString());
	}

	/**
	 * overridden method to generate QueryBuilder instance
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.FILTER_ACTIVE)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(EmailToCaseMapping__mdt.IsActive__c).eq(true)).endConditions();
		}

		return builder;
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('DeveloperName', 'Asc')};
	}
}