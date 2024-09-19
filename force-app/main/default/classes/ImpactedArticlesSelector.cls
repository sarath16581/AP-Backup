/**
* @description Impacted Articles Selector
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
* 2024-09-06 - Seth Heang - added selectById() and added newInstance(fieldOverrides)
**/
public virtual inherited sharing class ImpactedArticlesSelector extends ApplicationSelector {

	public enum Options {
		WITH_CASE, WITH_ARTICLE
	}

	public static ImpactedArticlesSelector newInstance() {
		return (ImpactedArticlesSelector)Application.Selectors.newInstance(ImpactedArticlesSelector.class);
	}

	/**
	 * Instantiate the CaseTeamMembersSelector and passed in fieldOverrides
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						This approach removes data consistency and prevents possible caching of results
	 * @return new instance of CaseTeamMembersSelector with setFieldOverrides
	 */
	public static ImpactedArticlesSelector newInstance(Map<SObjectType,Set<SObjectField>> fieldOverrides) {
		return (ImpactedArticlesSelector) Application.Selectors.newInstance(ImpactedArticlesSelector.class)
				.setFieldOverrides(fieldOverrides);
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

	/**
	 * @description Run a simple query to get records by Id
	 * @param ids
	 * @return List<ImpactedArticle__c>
	 */
	public virtual List<ImpactedArticle__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records by Id
	 * @param ids
	 * @param selectorOptions
	 * @return List<ImpactedArticle__c>
	 */
	public virtual List<ImpactedArticle__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ImpactedArticle__c.Id + ' in :ids')).endConditions();
		return (List<ImpactedArticle__c>)Database.query(qb.toSoqlString());
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

	/**
	 * @description QueryBuilder for adding related objects into the query
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_CASE)) {
			builder.addRelatedFields(CasesSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Case__r');
		}
		if (selectorOptions.contains(Options.WITH_ARTICLE)) {
			builder.addRelatedFields(ArticlesSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Article__r');
		}
		return builder;
	}
}