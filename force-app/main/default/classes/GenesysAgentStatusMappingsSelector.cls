/**
 * @description A very simple selector class for GenesysAgentStatusMapping
 * @author 		Paul Perry
 * @date 		15-08-2024
 * @changelog
 */
public virtual inherited sharing class GenesysAgentStatusMappingsSelector extends ApplicationSelector {
	public enum Options { }

	/**
	 * Create a new instance for the GenesysAgentStatusMappingsSelector
	 * @return GenesysAgentStatusMappingsSelector instance
	 */
	public static GenesysAgentStatusMappingsSelector newInstance() {
		return (GenesysAgentStatusMappingsSelector)Application.Selectors.newInstance(GenesysAgentStatusMappingsSelector.class);
	}

	/**
	 * Create a new instance for the GenesysAgentStatusMappingsSelector with provided record limit
	 * @param recordLimit the record limit
	 * @return GenesysAgentStatusMappingsSelector instance
	 */
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
			GenesysAgentStatusMapping__mdt.GenesysStatusId__c,
			GenesysAgentStatusMapping__mdt.GenesysStatusLabel__c,
			GenesysAgentStatusMapping__mdt.SalesforcePresenceStatus__c
		};
	}

	/**
	 * Run a simple query to get matching record based on genesysStatusId
	 * @param genesysStatusId the Genesys Cloud Status Id
	 * @param selectorOptions set of selectorOptions
	 * @return GenesysAgentStatusMapping__mdt record or null if not found
	 */
	public GenesysAgentStatusMapping__mdt selectByGenesysStatusId(String genesysStatusId, Set<Object> selectorOptions) {
		Set<String> syncDirection = new Set<String>{
			'Any', 'Gen => SF'
		};

		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(GenesysAgentStatusMapping__mdt.GenesysStatusId__c + ' = :genesysStatusId'))
			.add(new QueryBuilder.SimpleCondition(GenesysAgentStatusMapping__mdt.SyncDirection__c + ' IN :syncDirection'))
			.endConditions();

		List<SObject> records = Database.query(qb.toSoqlString());
		return records.isEmpty() ? null : (GenesysAgentStatusMapping__mdt)records[0];
	}

	/**
	 * Run a simple query to get matching record based on (SalesforcePresenceStatus__c_ ServicePresence developerName
	 * @param developerName the Salesforce Presence DeveloperName
	 * @param selectorOptions set of selectorOptions
	 * @return GenesysAgentStatusMapping__mdt record or null if not found
	 */
	public GenesysAgentStatusMapping__mdt selectBySalesforcePresenceStatus(String developerName, Set<Object> selectorOptions) {
		Set<String> syncDirection = new Set<String>{
			'Any', 'SF => Gen'
		};
		
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(GenesysAgentStatusMapping__mdt.SalesforcePresenceStatus__c + ' = :developerName'))
			.add(new QueryBuilder.SimpleCondition(GenesysAgentStatusMapping__mdt.SyncDirection__c + ' IN :syncDirection'))
			.endConditions();

		List<SObject> records = Database.query(qb.toSoqlString());
		return records.isEmpty() ? null : (GenesysAgentStatusMapping__mdt)records[0];
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 * @param selectorOptions set of selectorOptions
	 * @return QueryBuilder instance created with provided selector options
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		if (selectorOptions == null || selectorOptions.isEmpty()) {
			selectorOptions = new Set<Object>{ ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER };
		}

		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}