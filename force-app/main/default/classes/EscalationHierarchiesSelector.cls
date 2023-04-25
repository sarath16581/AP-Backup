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

public virtual inherited sharing class EscalationHierarchiesSelector extends ApplicationSelector {
    
	public static EscalationHierarchiesSelector newInstance() {
		return (EscalationHierarchiesSelector)Application.Selectors.newInstance(EscalationHierarchiesSelector.class);
	}

	public static EscalationHierarchiesSelector newInstance(Integer recordLimit) {
		return (EscalationHierarchiesSelector)Application.Selectors.newInstance(EscalationHierarchiesSelector.class).setLimit(recordLimit);
	}

	public static EscalationHierarchiesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		EscalationHierarchiesSelector selector = (EscalationHierarchiesSelector)Application.Selectors.newInstance(EscalationHierarchiesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Escalation_Hierarchy__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Escalation_Hierarchy__c.Id, Escalation_Hierarchy__c.Name, Escalation_Hierarchy__c.Charter__c,
			Escalation_Hierarchy__c.Customer_Tier_1__c, Escalation_Hierarchy__c.Customer_Tier_2__c, Escalation_Hierarchy__c.Customer_Tier_3__c,
			Escalation_Hierarchy__c.Internal_Tier_1__c, Escalation_Hierarchy__c.Internal_Tier_2__c, Escalation_Hierarchy__c.Internal_Tier_3__c,
			Escalation_Hierarchy__c.Facility_Tier_1__c, Escalation_Hierarchy__c.Facility_Tier_2__c, Escalation_Hierarchy__c.Facility_Tier_3__c,
			Escalation_Hierarchy__c.Facility_Tier_4__c, Escalation_Hierarchy__c.Facility_Tier_5__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Escalation_Hierarchy__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Escalation_Hierarchy__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Escalation_Hierarchy__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Escalation_Hierarchy__c>((List<Escalation_Hierarchy__c>)Database.query(qb.toSoqlString()));
	}
}