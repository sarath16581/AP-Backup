/**
 * A very simple selector class for GenesysAgentStatusMapping
 *
 * @author 		Paul Perry
 * @date 		15-08-2024
 * @group 		Selector
 * @tag			Selector
 */
public virtual inherited sharing class GenesysAgentStatusMappingsSelector extends ApplicationSelector {
	public enum Options { }

	public static GenesysAgentStatusMappingsSelector newInstance() {
		return (GenesysAgentStatusMappingsSelector)Application.Selectors.newInstance(GenesysAgentStatusMappingsSelector.class);
	}

	public static GenesysAgentStatusMappingsSelector newInstance(Integer recordLimit) {
		return (GenesysAgentStatusMappingsSelector)Application.Selectors.newInstance(GenesysAgentStatusMappingsSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return GenesysAgentStatusMapping__mdt.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			GenesysAgentStatusMapping__mdt.Id,
			GenesysAgentStatusMapping__mdt.DeveloperName,
			GenesysAgentStatusMapping__mdt.MappingData__c,
			GenesysAgentStatusMapping__mdt.MappingType__c
		};
	}

	/**
	 * Run a simple query to get records based on parent product Id's
	 */
	public Map<String,GenesysAgentStatusMapping__mdt> selectBydeveloperName(Set<String> developerNames) {
		return selectBydeveloperName(
			developerNames,
			new Set<Object>{ ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER }
		);
	}

	/**
	 * Run a simple query to get records based on matching DeveloperName
	 */
	public Map<String,GenesysAgentStatusMapping__mdt> selectBydeveloperName(Set<String> developerNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(GenesysAgentStatusMapping__mdt.DeveloperName + ' IN :developerNames'))
			.endConditions();

		GenesysAgentStatusMapping__mdt[] mappingList = (GenesysAgentStatusMapping__mdt[])
			Database.query(qb.toSoqlString());

		Map<String,GenesysAgentStatusMapping__mdt> result = new Map<String,GenesysAgentStatusMapping__mdt>();

		for (GenesysAgentStatusMapping__mdt mapping :mappingList) {
			result.put(mapping.DeveloperName, mapping);
		}

		return result;
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}