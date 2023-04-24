/**
 * @description
 * A very simple selector class that sits in the base domain
 *
 * @author Mahesh Parvathaneni
 * @date 2023-01-26
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

public virtual inherited sharing class EntitlementRulesSelector extends ApplicationSelector {

	public enum Options {
		WITH_ESCALATION_HIERARCHY
	}

	public static EntitlementRulesSelector newInstance() {
		return (EntitlementRulesSelector)Application.Selectors.newInstance(EntitlementRulesSelector.class);
	}

	public static EntitlementRulesSelector newInstance(Integer recordLimit) {
		return (EntitlementRulesSelector)Application.Selectors.newInstance(EntitlementRulesSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return Entitlement_Rule__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Entitlement_Rule__c.Id, Entitlement_Rule__c.Active__c, Entitlement_Rule__c.Escalation_Hierarchy__c,
			Entitlement_Rule__c.Rule__c, Entitlement_Rule__c.RecordTypeId, Entitlement_Rule__c.Entitlement_Rule_Name__c
		};
	}

	/**
	 * @description Run a simple query to get active entitlement records by record type dev names
	 */
	public virtual Map<Id, Entitlement_Rule__c> selectActiveRulesByRecordTypeDevNames(Set<String> recordTypeDevNames) {
		return selectActiveRulesByRecordTypeDevNames(recordTypeDevNames, new Set<Object>());
	}

    /**
	 * @description Run a simple query to get active entitlement records by record type dev names
	 */
	public virtual Map<Id, Entitlement_Rule__c> selectActiveRulesByRecordTypeDevNames(Set<String> recordTypeDevNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add((new QueryBuilder.InCondition('RecordType.DeveloperName')).inCollection(recordTypeDevNames))
				.endConditions();			
		return new Map<Id, Entitlement_Rule__c>((List<Entitlement_Rule__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_ESCALATION_HIERARCHY)) {
			builder.addRelatedFields(EscalationHierarchiesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Escalation_Hierarchy__r');
		}

		return builder;
	}
}