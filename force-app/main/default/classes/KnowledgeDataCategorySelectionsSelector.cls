/**
* @author Raghav Ravipati
* @date 2024-04-24
* @group Selector
* @tag Selector
* @domain Core
* @description A Selector Class for Knowledge__DataCategorySelection object
* @changelog
* 2024-04-24 - Raghav Ravipati - Created
*/
public virtual inherited sharing class KnowledgeDataCategorySelectionsSelector extends ApplicationSelector{
	
	public enum Options {WITH_PARENT}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static KnowledgeDataCategorySelectionsSelector newInstance(Set<SObjectField> fieldOverrides) {
		KnowledgeDataCategorySelectionsSelector selector = (KnowledgeDataCategorySelectionsSelector)Application.Selectors.newInstance(KnowledgeDataCategorySelectionsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static KnowledgeDataCategorySelectionsSelector newInstance(Map<SobjectType, Set<SObjectField>> fieldOverrides) {
		KnowledgeDataCategorySelectionsSelector selector = (KnowledgeDataCategorySelectionsSelector)Application.Selectors.newInstance(KnowledgeDataCategorySelectionsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return Knowledge__DataCategorySelection.SObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Knowledge__DataCategorySelection.DataCategoryGroupName, Knowledge__DataCategorySelection.DataCategoryName,  Knowledge__DataCategorySelection.ParentId		 
		};
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams Map of params that are used in the query where clause
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Knowledge__DataCategorySelection> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams Map of params that are used in the query where clause
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Knowledge__DataCategorySelection> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		List<Knowledge__DataCategorySelection> dataCats = new List<Knowledge__DataCategorySelection>();
		if(searchParams != null){
			super.validateSearchParams(searchParams.keySet(), new Set<String>{'recordTypeNames', 'parentIds'});
			
			dataCats = selectDataCategorySelections(searchParams,selectorOptions,matchAll);    
		}
		
		return dataCats;
	}

	/**
	* @description This methods uses querybuilder framework to build and runs a simple query based on the given params.
	* @param searchParams Map of params that are used in the query where clause.
	* @param matchAll If true will search based on AND, else search based on OR
	* @return List of Knowledge__kav in the form List<Sobject> we have to typecast to List<Knowledge__kav>
	*/
	@testVisible
	private List<Knowledge__DataCategorySelection> selectDataCategorySelections(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll)
	{	
		QueryBuilder qb = newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_PARENT)){

			qb.addRelatedFields(KnowledgeArticleVersionsSelector.newInstance(fieldOverrides).newQueryBuilder(), 'Parent');
			qb.addField('parent.RecordType.DeveloperName');
		}
		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		Integer conditionCount = 0;
		//Where clause

		if(searchParams.containsKey('recordTypeNames')){
			Set<String> recordTypeNames = (Set<String>)(searchParams.get('recordTypeNames') == null ? new Set<String>() : (searchParams.get('recordTypeNames') instanceof Set<String> ? searchParams.get('recordTypeNames') : new Set<String>{(String)searchParams.get('recordTypeNames')}));
			cm.add(new QueryBuilder.InCondition('Parent.RecordType.DeveloperName').inCollection(recordTypeNames));
			conditionCount++;
		}
		if(searchParams.containsKey('parentIds')){
			Set<Id> parentIds = (Set<Id>)(searchParams.get('parentIds') == null ? new Set<Id>() : (searchParams.get('parentIds') instanceof Set<Id> ? searchParams.get('parentIds') : new Set<Id>{(Id)searchParams.get('parentIds')}));
			cm.add(new QueryBuilder.InCondition('parentId').inCollection(parentIds));
			conditionCount++;
		}

		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		cm.setConditionOrder(conditionOrder);

		cm.endConditions();
		List<Knowledge__DataCategorySelection> queryResults = Database.query((qb.toSoqlString()));
		return queryResults;
	}
}