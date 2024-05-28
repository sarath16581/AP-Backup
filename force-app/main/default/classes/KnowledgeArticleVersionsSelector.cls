/**
* @author Victor Cheng
* @date 2021-04-28
* @group Selector
* @tag Selector
* @tag Custom Settings
* @domain Core
* @description A polymorphic Selector Class for custom settings
* @changelog
* 2021-04-28 - Victor Cheng - Created
* 2024-04-12 - Raghav Ravipati - 	Introduced the Lightning knowledge object Knowledge__Kav to the class and
									We will be using this as a selector class for Knowledge__Kav.
*/
public virtual inherited sharing class KnowledgeArticleVersionsSelector extends ApplicationSelector {

	public enum Options { WITH_RECORDTYPE }

	public static KnowledgeArticleVersionsSelector newInstance() {
		KnowledgeArticleVersionsSelector selector = (KnowledgeArticleVersionsSelector)Application.Selectors.newInstance(KnowledgeArticleVersionsSelector.class);
		return selector;
	} 

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static KnowledgeArticleVersionsSelector newInstance(Set<SObjectField> fieldOverrides) {
		KnowledgeArticleVersionsSelector selector = (KnowledgeArticleVersionsSelector)Application.Selectors.newInstance(KnowledgeArticleVersionsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static KnowledgeArticleVersionsSelector newInstance(Integer recordLimit, Set<SObjectField> fields) {
		KnowledgeArticleVersionsSelector selector = (KnowledgeArticleVersionsSelector)Application.Selectors.newInstance(KnowledgeArticleVersionsSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fields);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static KnowledgeArticleVersionsSelector newInstance(Map<SobjectType, Set<SObjectField>> fieldOverrides) {
		KnowledgeArticleVersionsSelector selector = (KnowledgeArticleVersionsSelector)Application.Selectors.newInstance(KnowledgeArticleVersionsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return Knowledge__kav.SObjectType;
	}
	
	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Knowledge__kav.Action__c, Knowledge__kav.Addvalue__c, Knowledge__kav.Answer__c, Knowledge__kav.AP_Website_URL__c, Knowledge__kav.Approvingstakeholders__c, 
			Knowledge__kav.Author__c, Knowledge__kav.Categoryselections__c, Knowledge__kav.Description__c, Knowledge__kav.Details__c, Knowledge__kav.Features__c, 
			Knowledge__kav.HowTo__c, Knowledge__kav.LegacyId__c, Knowledge__kav.Message__c, Knowledge__kav.NeedToKnow__c, Knowledge__kav.NeedsReview__c, Knowledge__kav.NetworkOrgId__c, 
			Knowledge__kav.Notes__c, Knowledge__kav.Overview__c, Knowledge__kav.Pricing__c, Knowledge__kav.PublishStatus, Knowledge__kav.Supportinformation__c, 
			Knowledge__kav.TimeToRemind__c, Knowledge__kav.Title, Knowledge__kav.Type__c, Knowledge__kav.UrlName, Knowledge__kav.Websiteinformation__c, 
			Knowledge__kav.WhatDoITellCustomers__c, Knowledge__kav.Whathappened__c, Knowledge__kav.WhenToAction__c, Knowledge__kav.WhoToActionFor__c		
		};
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams Map of params that are used in the query where clause
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Knowledge__kav> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}
	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams Map of params that are used in the query where clause
	 * @param selectorOptions Selector Options
	 * @param orderByField object field that is used to order by
	 * @param sortOrder ASC or DESC
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Knowledge__kav> search(Map<String, Object> searchParams, Boolean matchAll, Schema.SobjectField orderByField, String sortOrder) {
		return search(searchParams, new Set<Object>(), matchAll, orderByField, sortOrder );
	}

	public List<Knowledge__kav> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{'statuses', 'languages', 'recordTypeNames', 'types', 'IsLatestVersion'});

		return (List<Knowledge__kav>)selectByStatusLanguageType(searchParams, selectorOptions, matchAll, null, '');
	}

	private List<Knowledge__kav> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll, Schema.SobjectField orderByField, String sortOrder) {
		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{'statuses', 'languages', 'recordTypeNames', 'types', 'IsLatestVersion'});

		return (List<Knowledge__kav>)selectByStatusLanguageType(searchParams, selectorOptions, matchAll, orderByField, sortOrder);
	}

	/**
	 * @description Run a simple query to get records based on Id's
	* @param knowledgeIds Knowledge Article Ids
	* @param selectorOptions options that help to build the query
	* @return List of Knowledge__kav in the form List<Sobject> we have to typecast to List<Knowledge__kav>
	 */
	public List<Knowledge__kav> selectById(Set<Id> knowledgeIds, Set<Object> selectorOptions) {

		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		//Where clause
		cm.add(new QueryBuilder.SimpleCondition(Knowledge__kav.Id + ' in :knowledgeIds'));
		cm.endConditions();

		return (List<Knowledge__kav>) Database.query(qb.toSoqlString());
	}

	/**
	* @description This methods uses querybuilder framework to build and runs a simple query based on the given params.
	* @param searchParams Map of params that are used in the query where clause.
	* @param orderByField object field that is used to order by
	* @param sortOrder ASC or DESC
	* @param matchAll If true will search based on AND, else search based on OR
	* @return List of Knowledge__kav in the form List<Sobject> we have to typecast to List<Knowledge__kav>
	*/
	@testVisible
	private List<SObject> selectByStatusLanguageType(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll, Schema.SobjectField orderByField, String sortOrder ) {		
		QueryBuilder qb = newQueryBuilder(selectorOptions);		
		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		Integer conditionCount = 0;

		//Where clause
		if (searchParams.containsKey('statuses')) {
			Set<String> statuses = (Set<String>)(searchParams.get('statuses') == null ? new Set<String>() : (searchParams.get('statuses') instanceof Set<String> ? searchParams.get('statuses') : new Set<String>{String.valueOf(searchParams.get('statuses'))}));
			cm.add(new QueryBuilder.SimpleCondition(Knowledge__kav.PublishStatus + ' in :statuses'));
			conditionCount++;
		}
		
		if (searchParams.containsKey('languages')) {
			Set<String> languages = (Set<String>)(searchParams.get('languages') == null ? new Set<String>() : (searchParams.get('languages') instanceof Set<String> ? searchParams.get('languages') : new Set<String>{String.valueOf(searchParams.get('languages'))}));
			cm.add(new QueryBuilder.SimpleCondition(Knowledge__kav.Language + ' in :languages'));
			conditionCount++;
		}
		
		if (searchParams.containsKey('recordTypeNames')) {
			Set<String> recordTypeNames = (Set<String>)(searchParams.get('recordTypeNames') == null ? new Set<String>() : (searchParams.get('recordTypeNames') instanceof Set<String> ? searchParams.get('recordTypeNames') : new Set<String>{(String)searchParams.get('recordTypeNames')}));
			Set<Id> recorTypeIds = (RecordTypesSelector.newInstance().selectByDeveloperName('Knowledge__kav', recordTypeNames)).Keyset();
			cm.add(new QueryBuilder.SimpleCondition(Knowledge__kav.RecordTypeId + ' in :recorTypeIds'));
			conditionCount++;
		}
		
		if (searchParams.containsKey('types')) {
			Set<String> types = (Set<String>)(searchParams.get('types') == null ? new Set<String>() : (searchParams.get('types') instanceof Set<String> ? searchParams.get('types') : new Set<String>{(String)searchParams.get('types')}));
			cm.add(new QueryBuilder.SimpleCondition(Knowledge__kav.Type__c + ' in :types'));
			conditionCount++;
		}
		
		if(searchParams.containsKey('isLatestVersion')){
			Boolean isLatestVersion = (Boolean)(searchParams.get('isLatestVersion') == null ? null : (searchParams.get('isLatestVersion') instanceof Boolean ? searchParams.get('isLatestVersion') : true));
			
			if(isLatestVersion != null){
				cm.add(new QueryBuilder.CompareCondition('IsLatestVersion').eq(isLatestVersion));
			}
			conditionCount++;
		}

		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		cm.setConditionOrder(conditionOrder);

		cm.endConditions();
		//Order by clause
		if(String.isNotBlank(sortOrder)){

			if(sortOrder.equalsIgnoreCase('DESC') && orderByField != null){
				qb.addOrderDesc(orderByField);
			}
			else if(sortOrder.equalsIgnoreCase('ASC') && orderByField != null){
				qb.addOrderAsc(orderByField);
			}
		}
		List<SObject> queryResults = Database.query((qb.toSoqlString()));
		
		return queryResults;
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addField('RecordType.DeveloperName');
		}
		return builder;
	}
	
	/**
	* @description SOSL to return knowledge articles based on Keywork
	* @param searchKeyWord Map of params that are used in the query where clause.
	* @return List of Knowledge__kav in the form List<Sobject> we have to typecast to List<Knowledge__kav>
	*/

	public List<SObject> searchArticles(String searchKeyWord, List<String> allowedArticles)	{	
		List<SObject> sobjLst = new List<SObject>();
		List<List<SObject>> listOfSobjLst = [FIND: searchKeyword IN ALL FIELDS RETURNING  Knowledge__kav (UrlName,Answer__c,Summary,ArticleNumber,KnowledgeArticleId,id, Title, recordType.DeveloperName WHERE PublishStatus = 'Online' AND Language = 'en_US' AND RecordType.DeveloperName IN: allowedArticles)];
		
		if(!listOfSobjLst.isEmpty()){
			sobjLst = listOfSobjLst[0];	
		}
		return sobjLst;
	}

}