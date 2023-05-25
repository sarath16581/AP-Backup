/**
 * @description
 * A very simple selector class that sits in the base domain
 * @author Mahesh Parvathaneni
 * @date 2023-05-09
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

public virtual inherited sharing class PostcodeMappingsSelector extends ApplicationSelector {

	public enum Options {
		WITH_NETWORK
	}
	
	public static PostcodeMappingsSelector newInstance() {
		return (PostcodeMappingsSelector)Application.Selectors.newInstance(PostcodeMappingsSelector.class);
	}
	public static PostcodeMappingsSelector newInstance(Integer recordLimit) {
		return (PostcodeMappingsSelector)Application.Selectors.newInstance(PostcodeMappingsSelector.class).setLimit(recordLimit);
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PostcodeMappingsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PostcodeMappingsSelector selector = (PostcodeMappingsSelector)Application.Selectors.newInstance(PostcodeMappingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PostcodeMappingsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PostcodeMappingsSelector selector = (PostcodeMappingsSelector) Application.Selectors.newInstance(PostcodeMappingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	
	public override SObjectType getSObjectType() {
		return PostcodeMapping__c.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			PostcodeMapping__c.Id, PostcodeMapping__c.Postcode__c, PostcodeMapping__c.Network__c
		};
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<PostcodeMapping__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<PostcodeMapping__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PostcodeMapping__c.Id + ' in :ids')).endConditions();
		return (List<PostcodeMapping__c>)Database.query(qb.toSoqlString());
	}
	
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_NETWORK)) {
			// backwards compatability
			Set<Object> networkOptions = selectorOptions.clone();
			networkOptions.add(NetworksSelector.Options.WITH_RECORDTYPE);
			builder.addRelatedFields(NetworksSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(networkOptions), 'Network__r');
		}
	
		return builder;
	}
}