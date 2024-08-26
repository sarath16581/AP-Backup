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
public virtual inherited sharing class KnowledgeDataCategorySelectionsSelector extends ApplicationSelector {
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static KnowledgeDataCategorySelectionsSelector newInstance(Set<SObjectField> fieldOverrides) {
		KnowledgeDataCategorySelectionsSelector selector = (KnowledgeDataCategorySelectionsSelector)Application.Selectors.newInstance(KnowledgeDataCategorySelectionsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	public static KnowledgeDataCategorySelectionsSelector newInstance() {
		KnowledgeDataCategorySelectionsSelector selector = (KnowledgeDataCategorySelectionsSelector)Application.Selectors.newInstance(KnowledgeDataCategorySelectionsSelector.class);
		return selector;
	}
	
	protected override SObjectType getSObjectType() {
		return Knowledge__DataCategorySelection.SObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Knowledge__DataCategorySelection.DataCategoryGroupName, Knowledge__DataCategorySelection.DataCategoryName, Knowledge__DataCategorySelection.ParentId, Knowledge__DataCategorySelection.Id
		};
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams Map of params that are used in the query where clause
	 */
	public List<Knowledge__DataCategorySelection> search(Map<String, Object> searchParams) {
		return search(searchParams, new Set<Object>());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams Map of params that are used in the query where clause
	 * @param selectorOptions Selector Options
	 */
	public List<Knowledge__DataCategorySelection> search(Map<String, Object> searchParams, Set<Object> selectorOptions) {
		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		List<Knowledge__DataCategorySelection> dataCategories = new List<Knowledge__DataCategorySelection>();

		if (searchParams != null) {
			super.validateSearchParams(searchParams.keySet(), new Set<String>{ 'parentIds' });
			dataCategories = selectDataCategorySelections(searchParams, selectorOptions);
		}

		return dataCategories;
	}

	/**
	* @description This methods uses querybuilder framework to build and runs a simple query based on the given params.
	* @param searchParams Map of params that are used in the query where clause.
	* @return List of Knowledge__kav in the form List<Sobject> we have to typecast to List<Knowledge__kav>
	*/
	@testVisible
	private List<Knowledge__DataCategorySelection> selectDataCategorySelections(Map<String, Object> searchParams, Set<Object> selectorOptions) {
		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.conditionsManager;
		
		//Where clause
		if(searchParams.containsKey('parentIds')){
			Set<Id> parentIds = (Set<Id>)(searchParams.get('parentIds') == null ? new Set<Id>() : (searchParams.get('parentIds') instanceof Set<Id> ? searchParams.get('parentIds') : new Set<Id>{(Id)searchParams.get('parentIds')}));
			conditions.add(new QueryBuilder.SimpleCondition(Knowledge__DataCategorySelection.parentId + ' IN :parentIds'));
		}

		conditions.endConditions();
		List<Knowledge__DataCategorySelection> queryResults = Database.query(builder.toSoqlString());
		return queryResults;
	}
}