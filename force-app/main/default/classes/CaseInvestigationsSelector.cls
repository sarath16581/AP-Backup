/**
 * @description
 * A very simple selector class that sits in the base domain
 *
 * @author Mahesh Parvathaneni
 * @date 2022-11-25
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

public virtual inherited sharing class CaseInvestigationsSelector extends ApplicationSelector {
    
    public static CaseInvestigationsSelector newInstance() {
		return (CaseInvestigationsSelector)Application.Selectors.newInstance(CaseInvestigationsSelector.class);
	}

    public static CaseInvestigationsSelector newInstance(Integer recordLimit) {
		return (CaseInvestigationsSelector)Application.Selectors.newInstance(CaseInvestigationsSelector.class).setLimit(recordLimit);
	}

    public virtual override SObjectType getSObjectType() {
		return CaseInvestigation__c.getSObjectType();
	}

    public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
            CaseInvestigation__c.Id, CaseInvestigation__c.Article__c, CaseInvestigation__c.Case__c,
            CaseInvestigation__c.Network__c, CaseInvestigation__c.Status__c
		};
	}

    /**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, CaseInvestigation__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, CaseInvestigation__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Id + ' in :ids')).endConditions();
		return new Map<Id, CaseInvestigation__c>((List<CaseInvestigation__c>)Database.query(qb.toSoqlString()));
	}

    /**
     * Select case investigation records that are not closed and related to AP Network based on case Id, article id and network id
     */
    public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByCaseArticleNetworkId(Set<Id> caseIds, Set<Id> articleIds, Set<Id> networkIds) {
        return selectOpenCaseInvestigationsByCaseArticleNetworkId(caseIds, articleIds, networkIds, new Set<Object>());
    }

    /**
     * Select case investigation records that are not closed and related to AP Network based on case Id, article id and network id
     */
    public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByCaseArticleNetworkId(Set<Id> caseIds, Set<Id> articleIds, Set<Id> networkIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
                .add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Case__c + ' in :caseIds'))
                .add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Article__c + ' in :articleIds'))
                .add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Network__c + ' in :networkIds'))
                .add(new QueryBuilder.CompareCondition(CaseInvestigation__c.Status__c).ne('Closed'))
				.endConditions();
		return new Map<Id, CaseInvestigation__c>((List<CaseInvestigation__c>)Database.query(qb.toSoqlString()));
    }
}
