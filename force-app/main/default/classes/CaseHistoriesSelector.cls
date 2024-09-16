/**
* @author SteveL
* @date 2024-09-10
* @group Selector
* @tag Selector
* @tag Case History SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2024-09-10 - SteveL - Created
*/

public virtual inherited sharing class CaseHistoriesSelector extends ApplicationSelector{
	public enum Options {
		WITH_CASE
	}

	public static CaseHistoriesSelector newInstance() {
		return (CaseHistoriesSelector)Application.Selectors.newInstance(CaseHistoriesSelector.class);
	}

	public static CaseHistoriesSelector newInstance(Integer recordLimit) {
		return (CaseHistoriesSelector)Application.Selectors.newInstance(CaseHistoriesSelector.class).setLimit(recordLimit);
	}

	public static CaseHistoriesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CaseHistoriesSelector selector = (CaseHistoriesSelector)Application.Selectors.newInstance(CaseHistoriesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return CaseHistory.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				CaseHistory.CaseId, CaseHistory.NewValue, CaseHistory.OldValue
		};
	}

	/**
	 * @param selectorOptions Set<Object>
	 * @param caseIds Set<Id>
	 * @param caseType String
	 * @description Run a simple query to get Case History based on CaseId
	 *
	 * @return Map<Id, CaseHistory>
	 */
	public Map<Id, CaseHistory> selectCaseHistoriesByTypeAndCaseIds(Set<Object> selectorOptions, Set<Id> caseIds, String caseType) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
				.add(new QueryBuilder.InCondition(CaseHistory.CaseId).inCollection(caseIds))
				.add(new QueryBuilder.CompareCondition('CaseHistory.Case.Type').eq(caseType))
				.endConditions();
		qb.addOrderDesc('CreatedDate');
		return new Map<Id, CaseHistory>((List<CaseHistory>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CASE)) {
			builder.addRelatedFields(CasesSelector.newInstance().newQueryBuilder(), 'Case');
		}

		return builder;
	}
}