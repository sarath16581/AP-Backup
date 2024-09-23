/*
* @author 		Paul Perry
* @date 		15-08-2024
* @group 		Selector
* @tag			Selector
*
* @description 	A very simple selector class for ServicePreseneStatus
*/
public virtual inherited sharing class ServicePresenceStatusSelector extends ApplicationSelector {
	public enum Options { }

	public static ServicePresenceStatusSelector newInstance() {
		return (ServicePresenceStatusSelector)Application.Selectors.newInstance(ServicePresenceStatusSelector.class);
	}

	public static ServicePresenceStatusSelector newInstance(Integer recordLimit) {
		return (ServicePresenceStatusSelector)Application.Selectors.newInstance(ServicePresenceStatusSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return ServicePresenceStatus.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			ServicePresenceStatus.Id,
			ServicePresenceStatus.MasterLabel,
			ServicePresenceStatus.DeveloperName
		};
	}

	/**
	 * Run a simple query to get records based on parent product Id's
	 */
	public List<ServicePresenceStatus> selectActiveStatuses() {
		return selectActiveStatuses(new Set<Object>{ ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER });
	}

	/**
	 * Run a simple query to get records based on parent product Id's
	 */
	public List<ServicePresenceStatus> selectActiveStatuses(Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ServicePresenceStatus.IsDeleted + ' = false'))
			.endConditions();
		return (List<ServicePresenceStatus>)Database.query(qb.toSoqlString());
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}