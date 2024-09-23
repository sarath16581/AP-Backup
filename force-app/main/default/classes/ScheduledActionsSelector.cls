/**
 * @author Seth Heang
 * @date 2024-07-18
 * @group Selector
 * @tag Selector
 * @domain Core
 * @description A Selector Class for ScheduledAction__c object
 * @changelog
 * 2024-07-18 - Seth Heang - Created
 */
public virtual inherited sharing class ScheduledActionsSelector extends ApplicationSelector {
	public enum Options {
		WITH_CASE
	}

	public static ScheduledActionsSelector newInstance() {
		ScheduledActionsSelector selector = (ScheduledActionsSelector) Application.Selectors.newInstance(ScheduledActionsSelector.class);
		return selector;
	}

	/**
	 * Instantiate the ScheduledActionsSelector and passed in fieldOverrides
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 * @return new instance of ScheduledActionsSelector with setFieldOverrides
	 */
	public static ScheduledActionsSelector newInstance(Set<SObjectField> fieldOverrides) {
		ScheduledActionsSelector selector = (ScheduledActionsSelector)Application.Selectors.newInstance(ScheduledActionsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return ScheduledAction__c.SObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{ ScheduledAction__c.Id, ScheduledAction__c.Case__c, ScheduledAction__c.ActionType__c };
	}

	/**
	 * @description Run a simple query to get records based on Parent Case Id
	 */
	public virtual List<ScheduledAction__c> selectByCaseId(Set<Id> caseIds) {
		return selectByCaseId(caseIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Parent Case Id
	 */
	public virtual List<ScheduledAction__c> selectByCaseId(Set<Id> caseIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder();
		qb.addConditions().add(new QueryBuilder.SimpleCondition(ScheduledAction__c.Case__c + ' in :caseIds')).endConditions();
		return (List<ScheduledAction__c>) Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on Parent Case Id and Action Type
	 */
	public virtual List<ScheduledAction__c> selectByCaseIdAndActionType(Set<Id> caseIds, Set<String> actionNames) {
		return selectByCaseIdAndActionType(caseIds, actionNames, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Parent Case Id and Action Type
	 */
	public virtual List<ScheduledAction__c> selectByCaseIdAndActionType(Set<Id> caseIds, Set<String> actionNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
		.add(new QueryBuilder.SimpleCondition(ScheduledAction__c.Case__c + ' in :caseIds'))
		.add(new QueryBuilder.SimpleCondition(ScheduledAction__c.ActionType__c + ' in :actionNames'))
		.endConditions();
		return (List<ScheduledAction__c>) Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records by Id
	 */
	public virtual List<ScheduledAction__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records by Id
	 */
	public virtual List<ScheduledAction__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions().add(new QueryBuilder.SimpleCondition(ScheduledAction__c.Id + ' in :ids')).endConditions();
		return (List<ScheduledAction__c>) Database.query(qb.toSoqlString());
	}

	/**
	 * @description QueryBuilder for adding related objects into the query
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_CASE)) {
			builder.addRelatedFields(CasesSelector.newInstance().newQueryBuilder(), 'Case__r');
		}
		return builder;
	}
}