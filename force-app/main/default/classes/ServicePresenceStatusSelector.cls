/*
* @description 	A very simple selector class for ServicePreseneStatus
*
* @author 		Paul Perry
* @date 		15-08-2024
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
	 * Run a simple query to get records based on DeveloperName
	 */
	public ServicePresenceStatus selectByDeveloperName(String developerName, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ServicePresenceStatus.DeveloperName + ' = :developerName'))
			.endConditions();

		List<ServicePresenceStatus> result = (List<ServicePresenceStatus>)Database.query(qb.toSoqlString());
		return result.isEmpty() ? null : result.get(0);
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		if (selectorOptions == null || selectorOptions.isEmpty()) {
			// ServicePresenceStatus object doesn't have a CreatedDate field
			selectorOptions = new Set<Object>{ ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER };
		}

		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}