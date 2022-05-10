/***
 * @description Selector class for SSOAttributeMapping__mdt custom emtadata type
 *              NOTE: Currently, since no long text area fields are used, SOQL queries here do not count toward governor limits
 * @author Nathan Franklin
 * @date 2022-05-10
 * @changelog
*/
public virtual inherited sharing class SSOAttributeMappingsSelector extends ApplicationSelector {
	public enum Options { }

	public static SSOAttributeMappingsSelector newInstance() {
		return newInstance(0, new Set<SObjectField>());
	}
	public static SSOAttributeMappingsSelector newInstance(Integer recordLimit) {
		return newInstance(recordLimit, new Set<SObjectField>());
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SSOAttributeMappingsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return newInstance(recordLimit, new Map<SObjectType, Set<SObjectField>>{SSOAttributeMapping__mdt.SObjectType => fieldOverrides});
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static SSOAttributeMappingsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SSOAttributeMappingsSelector selector = (SSOAttributeMappingsSelector)Application.Selectors.newInstance(SSOAttributeMappingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return SSOAttributeMapping__mdt.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			SSOAttributeMapping__mdt.Id, SSOAttributeMapping__mdt.FederationField__c, SSOAttributeMapping__mdt.SubjectAttribute__c, SSOAttributeMapping__mdt.NetworkId__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Names
	 */
	public List<SSOAttributeMapping__mdt> selectByName(Set<String> recordNames) {
		return selectByName(recordNames, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Names
	 */
	public List<SSOAttributeMapping__mdt> selectByName(Set<String> recordNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(SSOAttributeMapping__mdt.DeveloperName + ' in :recordNames')).endConditions();
		return (List<SSOAttributeMapping__mdt>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on Network Ids
	 * Note that networkIds is String since the corresponding field on the object is also a String
	 */
	public List<SSOAttributeMapping__mdt> selectByNetworkIds(Set<String> networkIds) {
		return selectByNetworkIds(networkIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Network Ids
	 * Note that networkIds is String since the corresponding field on the object is also a String
	 */
	public List<SSOAttributeMapping__mdt> selectByNetworkIds(Set<String> networkIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(SSOAttributeMapping__mdt.NetworkId__c + ' in :networkIds')).endConditions();
		return (List<SSOAttributeMapping__mdt>)Database.query(qb.toSoqlString());
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('DeveloperName', 'Asc')};
	}

}