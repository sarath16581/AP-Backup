/**
 * @author Madhusudhan
 * @date 2021-06-21
 * @group Selector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-03-05	Naveen Rajanna	REQ2723199 Added enum and selectByCaseAndMilestoneNames method
 */
public virtual inherited sharing class CaseMilestonesSelector extends ApplicationSelector {
	
	public enum Options {
		FILTER_VIOLATED,
		FILTER_NOT_VIOLATED,
		FILTER_COMPLETED,
		FILTER_NOT_COMPLETED
	}
	
	public static CaseMilestonesSelector newInstance() {
		return (CaseMilestonesSelector) Application.Selectors.newInstance(CaseMilestonesSelector.class);
	}

	public virtual override SObjectType getSObjectType() {
		return CaseMilestone.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			CaseMilestone.CaseId,
			CaseMilestone.CompletionDate,
			CaseMilestone.StartDate,
			CaseMilestone.TargetDate,
			CaseMilestone.MilestoneTypeId,
			CaseMilestone.ElapsedTimeInMins,
			CaseMilestone.TargetResponseInMins
		};
	}

	/**
	 * @description Run a simple query to get records based on caseIds
	 */
	public virtual Map<Id, CaseMilestone> selectByCase(Set<Id> caseIds) {
		return selectByCase(caseIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on caseIds
	 */
	public virtual Map<Id, CaseMilestone> selectByCase(Set<Id> caseIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(CaseMilestone.CaseId + ' in :caseIds'))
			.endConditions();
		return new Map<Id, CaseMilestone>((List<CaseMilestone>) Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		// Violated or Not Violated
		if(selectorOptions.contains(Options.FILTER_VIOLATED)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(CaseMilestone.IsViolated).eq(true)).endConditions();
		} else if(selectorOptions.contains(Options.FILTER_NOT_VIOLATED)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(CaseMilestone.IsViolated).eq(false)).endConditions();
		}

		// Completed or Not Completed
		if(selectorOptions.contains(Options.FILTER_COMPLETED)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(CaseMilestone.IsCompleted).eq(true)).endConditions();
		} else if(selectorOptions.contains(Options.FILTER_NOT_COMPLETED)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(CaseMilestone.IsCompleted).eq(false)).endConditions();
		}

		return builder;
	}

	/**
	 * @description Run a simple query to get records based on caseIds and milestoneNames
	 */
	public virtual List<CaseMilestone> selectByCaseAndMilestoneNames(Set<Id> caseIds, Set<String> mileStoneNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(CaseMilestone.CaseId + ' in :caseIds'))
			.add(new QueryBuilder.SimpleCondition('MilestoneType.Name in :mileStoneNames'))
			.endConditions();
		return Database.query(qb.toSoqlString());
	}
}