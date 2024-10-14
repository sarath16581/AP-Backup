/**
* @description Impacted Articles Selector
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
* 2024-08-31 - Ranjeewa Silva - Added new search method with search parameter validation.
* 2024-09-06 - Seth Heang - added selectById() and added newInstance(fieldOverrides)
* 2024-10-09 - Seth Heang - added selectByCaseId()
**/
public virtual inherited sharing class ImpactedArticlesSelector extends ApplicationSelector {

	public enum Options {
		WITH_CASE, WITH_ARTICLE
	}
	
	public static ImpactedArticlesSelector newInstance() {
		return (ImpactedArticlesSelector)Application.Selectors.newInstance(ImpactedArticlesSelector.class);
	}
	
	
	public static ImpactedArticlesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ImpactedArticlesSelector selector = (ImpactedArticlesSelector)Application.Selectors.newInstance(ImpactedArticlesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * Instantiate the ImpactedArticlesSelector and passed in fieldOverrides
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						 This approach removes data consistency and prevents possible caching of results
	 * @return new instance of ImpactedArticlesSelector with setFieldOverrides
	 */
	public static ImpactedArticlesSelector newInstance(Map<SObjectType,Set<SObjectField>> fieldOverrides) {
		return (ImpactedArticlesSelector) Application.Selectors.newInstance(ImpactedArticlesSelector.class)
				.setFieldOverrides(fieldOverrides);
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
	 * Retrieve Impacted Articles with matching case ids
	 * @param caseIds list of case ids
	 *
	 * @return List<ImpactedArticle__c>
	*/
	public virtual List<ImpactedArticle__c> selectByCaseId(Set<Id> caseIds) {
		return selectByCaseId(caseIds, new Set<Object>());
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

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 articleIds: maps to Article__c (Set<Id>/Id)
	 *						 caseRecordTypeIds: maps to Case__r.RecordTypeId (Set<Id>/Id)
	 *						 caseEnquirySubTypes: maps to Case__r.EnquirySubType__c (Set<String>/String)
	 *						 isCaseOpen: maps to !(Case__r.IsClosed) (Boolean)
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of ImpactedArticle__c records
	 */
	public List<ImpactedArticle__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		Set<Id> articleIds = (Set<Id>)(searchParams.get('articleIds') == null ? new Set<Id>() : (searchParams.get('articleIds') instanceof Set<Id> ? searchParams.get('articleIds') : new Set<Id>{(Id)searchParams.get('articleIds')}));
		Set<Id> caseRecordTypeIds = (Set<Id>)(searchParams.get('caseRecordTypeIds') == null ? new Set<Id>() : (searchParams.get('caseRecordTypeIds') instanceof Set<Id> ? searchParams.get('caseRecordTypeIds') : new Set<Id>{(Id)searchParams.get('caseRecordTypeIds')}));
		Set<String> caseEnquirySubTypes = (Set<String>)(searchParams.get('caseEnquirySubTypes') == null ? new Set<String>() : (searchParams.get('caseEnquirySubTypes') instanceof Set<String> ? searchParams.get('caseEnquirySubTypes') : new Set<String>{(String)searchParams.get('caseEnquirySubTypes')}));
		Boolean isCaseOpen = searchParams.get('isCaseOpen') instanceof Boolean ? (Boolean)searchParams.get('isCaseOpen') : true;
		return (List<ImpactedArticle__c>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'articleIds', 'caseRecordTypeIds', 'isCaseOpen', 'caseEnquirySubTypes'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if (searchParams.containsKey('articleIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(ImpactedArticle__c.Article__c + ' in :articleIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('caseRecordTypeIds')) {
			conditions.add(new QueryBuilder.SimpleCondition('Case__r.' + Case.RecordTypeId + ' in :caseRecordTypeIds'));
			conditionCount++;
		}
		if (searchParams.containsKey('caseEnquirySubTypes')) {
			conditions.add(new QueryBuilder.SimpleCondition('Case__r.' + Case.EnquirySubType__c + ' in :caseEnquirySubTypes'));
			conditionCount++;
		}
		if (searchParams.containsKey('isCaseOpen')) {
			conditions.add(new QueryBuilder.SimpleCondition('Case__r.' + Case.IsClosed + ' != :isCaseOpen'));
			conditionCount++;
		}

		// build our condition string which would end up being something liek the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for (Integer i=0; i<conditionCount; i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		return conditions.endConditions().toSoqlString();
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_ARTICLE)) {
			builder.addRelatedFields(ArticlesSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Article__r');
		}

		if(selectorOptions.contains(Options.WITH_CASE)) {
			builder.addRelatedFields(CasesSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Case__r');
		}

		return builder;
	}
}