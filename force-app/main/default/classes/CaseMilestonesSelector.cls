/**
 * @author Madhusudhan
 * @date 2021-06-21
 * @group Selector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 */
public virtual inherited sharing class CaseMilestonesSelector extends ApplicationSelector {
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
			CaseMilestone.MilestoneTypeId
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
		return builder;
	}
}