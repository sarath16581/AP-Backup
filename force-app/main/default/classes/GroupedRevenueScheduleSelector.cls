/**
 * @author KenM.
 * @date 2023-03-03
 * @group Selector
 * @tag Selector
 * @tag GroupedRevenueSchedule__c SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2023-03-03 - KenM.
 */
public virtual inherited sharing class GroupedRevenueScheduleSelector extends ApplicationSelector {
	public enum Options {
		WITH_PRODUCT,
		WITH_REVENUE
	}

	public static GroupedRevenueScheduleSelector newInstance() {
		return (GroupedRevenueScheduleSelector )Application.Selectors.newInstance(GroupedRevenueScheduleSelector .class);
	}
	public static GroupedRevenueScheduleSelector newInstance(Integer recordLimit) {
		return (GroupedRevenueScheduleSelector )Application.Selectors.newInstance(GroupedRevenueScheduleSelector .class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return GroupedRevenueSchedule__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				GroupedRevenueSchedule__c.Id,
				GroupedRevenueSchedule__c.GroupedAccountProductRevenue__c,
				GroupedRevenueSchedule__c.OpportunityProduct__c,
				GroupedRevenueSchedule__c.Opportunity__c,
				GroupedRevenueSchedule__c.For1__c,
				GroupedRevenueSchedule__c.For2__c,
				GroupedRevenueSchedule__c.For3__c,
				GroupedRevenueSchedule__c.For4__c,
				GroupedRevenueSchedule__c.For5__c,
				GroupedRevenueSchedule__c.For6__c,
				GroupedRevenueSchedule__c.For7__c,
				GroupedRevenueSchedule__c.For8__c,
				GroupedRevenueSchedule__c.For9__c,
				GroupedRevenueSchedule__c.For10__c,
				GroupedRevenueSchedule__c.For11__c,
				GroupedRevenueSchedule__c.For12__c,
				GroupedRevenueSchedule__c.Year__c
		};
	}

	public Map<Id, GroupedRevenueSchedule__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public Map<Id, GroupedRevenueSchedule__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(GroupedRevenueSchedule__c.Id + ' in :ids')).endConditions();
		return new Map<Id, GroupedRevenueSchedule__c>((List<GroupedRevenueSchedule__c>)Database.query(qb.toSoqlString()));
	}

	public virtual List<GroupedRevenueSchedule__c> selectByOpportunityProductIds(Set<String> opportunityProductIds, Set<Object> selectorOptions) {
		Set<Object> options = (selectorOptions != null ? selectorOptions : new Set<Object>());
		options.add(GroupedRevenueScheduleSelector.Options.WITH_REVENUE);
		QueryBuilder qb = newQueryBuilder(options).addConditions().add(new QueryBuilder.SimpleCondition(GroupedRevenueSchedule__c.OpportunityProduct__c + ' in :opportunityProductIds')).endConditions();
		return Database.query(qb.toSoqlString());
	}


	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_PRODUCT)) {
			builder.addRelatedFields(ProductsSelector.newInstance().newQueryBuilder(), 'OpportunityProduct__r');
		}

		if(selectorOptions.contains(Options.WITH_REVENUE)) {
			builder.addRelatedFields(GroupedAccountProductRevenueSelector.newInstance().newQueryBuilder(), 'GroupedAccountProductRevenue__r');
		}
		return builder;
	}

}