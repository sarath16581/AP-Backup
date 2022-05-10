/**
 * @author Ranjeewa Silva
 * @date 2022-03-18
 * @group Selector
 * @tag Selector
 * @tag Networks
 * @domain PUD
 * @description A very simple selector class that sits in PUD domain
 * @changelog
 * 2022-03-18 - Ranjeewa Silva - Created
 */

public virtual inherited sharing class PUDNetworksSelector extends NetworksSelector {

	public enum Options {
		WITH_ROUTES
	}

	public static PUDNetworksSelector newInstance() {
		return (PUDNetworksSelector)Application.Selectors.newInstance(PUDNetworksSelector.class);
	}
	public static PUDNetworksSelector newInstance(Integer recordLimit) {
		return (PUDNetworksSelector)Application.Selectors.newInstance(PUDNetworksSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDNetworksSelector newInstance(Set<SObjectField> fieldOverrides) {
		PUDNetworksSelector selector = (PUDNetworksSelector)Application.Selectors.newInstance(PUDNetworksSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDNetworksSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PUDNetworksSelector selector = (PUDNetworksSelector)Application.Selectors.newInstance(PUDNetworksSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDNetworksSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDNetworksSelector selector = (PUDNetworksSelector)Application.Selectors.newInstance(PUDNetworksSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDNetworksSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDNetworksSelector selector = (PUDNetworksSelector)Application.Selectors.newInstance(PUDNetworksSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Network__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Network__c.Id, Network__c.Name, Network__c.OwnerId, Network__c.RecordTypeId, Network__c.Org_ID__c,
				Network__c.Integrated_Job_Dispatch_Enabled__c
		};
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_ROUTES)) {
			builder.addSubQuery(PUDRoutesSelector.newInstance(fieldOverrides).newQueryBuilder(), 'Routes__r');
		}

		return builder;
	}
}