/**
 * @description
 * A very simple selector class that sits in the base domain
 *
 * @author Mahesh Parvathaneni
 * @date 2022-08-01
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

public virtual inherited sharing class AssignmentRulesSelector extends ApplicationSelector {
    
    public static AssignmentRulesSelector newInstance() {
		return (AssignmentRulesSelector)Application.Selectors.newInstance(AssignmentRulesSelector.class);
	}

    public static AssignmentRulesSelector newInstance(Integer recordLimit) {
		return (AssignmentRulesSelector)Application.Selectors.newInstance(AssignmentRulesSelector.class).setLimit(recordLimit);
	}

    public virtual override SObjectType getSObjectType() {
		return AssignmentRule.getSObjectType();
	}

    public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
                AssignmentRule.Id, AssignmentRule.SobjectType, AssignmentRule.Active
		};
	}

    /**
	 * @description Run a simple query to get records based on sobjectType
	 */
	public virtual Map<Id, AssignmentRule> selectActiveRulesBySObjectType(String sobjectType) {
		return selectActiveRulesBySObjectType(sobjectType, new Set<Object>());
	}

    /**
	 * @description Run a simple query to get records based on sobjectType
	 */
	public virtual Map<Id, AssignmentRule> selectActiveRulesBySObjectType(String sobjectType, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
                            .addConditions()
                            .add(new QueryBuilder.SimpleCondition(AssignmentRule.SobjectType + ' = :sobjectType'))
                            .add(new QueryBuilder.SimpleCondition(AssignmentRule.Active + ' =  true'))
                            .endConditions();
		return new Map<Id, AssignmentRule>((List<AssignmentRule>)Database.query(qb.toSoqlString()));
	}

}