/*
* @author 		Paul Perry
* @date 		15-08-2024
* @group 		Selector
* @tag			Selector
*
* @description 	A very simple selector class for GenesysAgentStatusIdMapping
*/
public virtual inherited sharing class GenesysAgentStatusIdMappingsSelector extends ApplicationSelector {
	public enum Options { }

	public static GenesysAgentStatusIdMappingsSelector newInstance() {
		return (GenesysAgentStatusIdMappingsSelector)Application.Selectors.newInstance(GenesysAgentStatusIdMappingsSelector.class);
	}

	public static GenesysAgentStatusIdMappingsSelector newInstance(Integer recordLimit) {
		return (GenesysAgentStatusIdMappingsSelector)Application.Selectors.newInstance(GenesysAgentStatusIdMappingsSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return GenesysAgentStatusIdMapping__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			GenesysAgentStatusIdMapping__c.Id,
			GenesysAgentStatusIdMapping__c.Name,
			GenesysAgentStatusIdMapping__c.StatusId__c,
			GenesysAgentStatusIdMapping__c.Source__c
		};
	}

	/**
	 * Run a simple query to get records based on parent product Id's
	 */
	public List<GenesysAgentStatusIdMapping__c> selectBySource(String source) {
		return selectBySource(source, new Set<Object>{ ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER });
	}

	/**
	 * Run a simple query to get records based on matching source
	 */
	public List<GenesysAgentStatusIdMapping__c> selectBySource(String source, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(GenesysAgentStatusIdMapping__c.Source__c + ' = :source'))
			.endConditions();
		return (List<GenesysAgentStatusIdMapping__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}