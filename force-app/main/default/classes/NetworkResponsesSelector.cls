/**
* @author Disha Kariya
* @date 2020-08-21
* @group Selector
* @tag Selector
* @tag Network responses
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-08-21 - Disha kariya - Created
*/
public virtual inherited sharing class NetworkResponsesSelector extends ApplicationSelector {

	public enum Options {
		WITH_OWNER
	}

	public static NetworkResponsesSelector newInstance() {
		return (NetworkResponsesSelector)Application.Selectors.newInstance(NetworkResponsesSelector.class);
	}
	public static NetworkResponsesSelector newInstance(Integer recordLimit) {
		return (NetworkResponsesSelector)Application.Selectors.newInstance(NetworkResponsesSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworkResponsesSelector newInstance(Set<SObjectField> fieldOverrides) {
		NetworkResponsesSelector selector = (NetworkResponsesSelector)Application.Selectors.newInstance(NetworkResponsesSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworkResponsesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		NetworkResponsesSelector selector = (NetworkResponsesSelector)Application.Selectors.newInstance(NetworkResponsesSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}
    
    /**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworkResponsesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		NetworkResponsesSelector selector = (NetworkResponsesSelector)Application.Selectors.newInstance(NetworkResponsesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Network_Response__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Network_Response__c.Id, Network_Response__c.Name, Network_Response__c.OwnerId, Network_Response__c.to_Reassign_Network__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Network_Response__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Network_Response__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Network_Response__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Network_Response__c>((List<Network_Response__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		return builder;
	}

}