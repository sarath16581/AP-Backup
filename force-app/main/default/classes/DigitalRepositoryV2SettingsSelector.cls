/**
 * @author Raghav Ravipati
 * @date 2024-07-01
 * @group Selector
 * @tag Selector
 * @tag DigitalRepositoryV2Settings__mdt SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domaia and returns the configuration for digital repository API
 */
public virtual inherited sharing class DigitalRepositoryV2SettingsSelector extends ApplicationSelector {
	public static DigitalRepositoryV2SettingsSelector newInstance() {
		DigitalRepositoryV2SettingsSelector selector = (DigitalRepositoryV2SettingsSelector) Application.Selectors.newInstance(DigitalRepositoryV2SettingsSelector.class);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static DigitalRepositoryV2SettingsSelector newInstance(Set<SObjectField> fieldOverrides) {
		DigitalRepositoryV2SettingsSelector selector = (DigitalRepositoryV2SettingsSelector) Application.Selectors.newInstance(DigitalRepositoryV2SettingsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return DigitalRepositoryV2Settings__mdt.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			DigitalRepositoryV2Settings__mdt.AttachmentType__c,
			DigitalRepositoryV2Settings__mdt.FileExtensionType__c,
			DigitalRepositoryV2Settings__mdt.BlurImage__c,
			DigitalRepositoryV2Settings__mdt.BucketName__c,
			DigitalRepositoryV2Settings__mdt.Default__c,
			DigitalRepositoryV2Settings__mdt.ResizePercentage__c,
			DigitalRepositoryV2Settings__mdt.ResizeThreshold__c,
			DigitalRepositoryV2Settings__mdt.DeveloperName
		};
	}

	/**
	 * @description This methods uses querybuilder framework to build and runs a simple query based on the given params.
	 * @param attachmentTypes returns a list of records that matches with the given attachmentTypes.
	 * @return list of DigitalRepositoryV2Settings__mdt records
	 */
	public List<DigitalRepositoryV2Settings__mdt> getAPIConfigurationsByAttachmentType(Set<String> attachmentTypes) {
		QueryBuilder querybuilder = newQueryBuilder();
		QueryBuilder.ConditionsManager conditionsManager = querybuilder.conditionsManager;
		conditionsManager.add(new QueryBuilder.SimpleCondition(DigitalRepositoryV2Settings__mdt.AttachmentType__c + ' in :attachmentTypes'));
		conditionsManager.add(new QueryBuilder.CompareCondition('Default__c').eq(false));
		conditionsManager.endConditions();
		querybuilder.setOrder(new QueryBuilder.Order(DigitalRepositoryV2Settings__mdt.Id));
		List<DigitalRepositoryV2Settings__mdt> queryResults = Database.query((querybuilder.toSoqlString()));

		return queryResults;
	}

	/**
	 * @description return default api configuration settings
	 * @param attachmentTypes returns a list of records that matches with the given attachmentTypes.
	 * @return list of DigitalRepositoryV2Settings__mdt records
	 */
	public List<DigitalRepositoryV2Settings__mdt> getDefaultAPIConfiguration() {
		QueryBuilder querybuilder = newQueryBuilder();
		QueryBuilder.ConditionsManager conditionsManager = querybuilder.conditionsManager;
		//Retrieving default settings
		conditionsManager.add(new QueryBuilder.CompareCondition('Default__c').eq(true));
		conditionsManager.endConditions();
		querybuilder.setOrder(new QueryBuilder.Order(DigitalRepositoryV2Settings__mdt.Id));
		List<DigitalRepositoryV2Settings__mdt> queryResults = Database.query((querybuilder.toSoqlString()));

		return queryResults;
	}
}