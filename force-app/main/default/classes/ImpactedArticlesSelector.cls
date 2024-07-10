/**
* @description Impacted Articles Selector
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
**/
public virtual inherited sharing class ImpactedArticlesSelector extends ApplicationSelector {
    
    public static ImpactedArticlesSelector newInstance() {
        return (ImpactedArticlesSelector)Application.Selectors.newInstance(ImpactedArticlesSelector.class);
    }
    
    
    public static ImpactedArticlesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        ImpactedArticlesSelector selector = (ImpactedArticlesSelector)Application.Selectors.newInstance(ImpactedArticlesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    
	public virtual override SObjectType getSObjectType() {
		return ImpactedArticle__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				ImpactedArticle__c.Article__c, ImpactedArticle__c.ArticleId__c, ImpactedArticle__c.Case__c
		};
	}
    
   	/*
	* this method returns records with matching case ids
	 * @param caseIds list of case ids
	 * @param selectorOptions selector options to augment result set
	 *
	 * @return Case List
	*/
 	public virtual List<ImpactedArticle__c> selectByCaseId(Set<Id> caseIds, Set<Object> selectorOptions) {        
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ImpactedArticle__c.Case__c + ' in :caseIds')).endConditions();
		return (List<ImpactedArticle__c>)Database.query(qb.toSoqlString());        
	}
}