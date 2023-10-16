/**
* @author Dish Kariya
* @date 2020-05-12
* @group Selector
* @tag Selector
* @tag Asset SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-05-12 - Disha Kariya - Created
* 2023-08-24 - Mahesh Parvathaneni - Added search method
*/
public virtual inherited sharing class AssetsSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE
	}

	public static AssetsSelector newInstance() {
		return (AssetsSelector)Application.Selectors.newInstance(AssetsSelector.class);
	}
	public static AssetsSelector newInstance(Integer recordLimit) {
		return (AssetsSelector)Application.Selectors.newInstance(AssetsSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static AssetsSelector newInstance(Set<SObjectField> fieldOverrides) {
		AssetsSelector selector = (AssetsSelector)Application.Selectors.newInstance(AssetsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Asset.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Asset.Id, Asset.Name, Asset.Status, Asset.Product2Id, Asset.AccountId
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Asset> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Asset> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Asset.Id + ' in :ids')).endConditions();
		return new Map<Id, Asset>((List<Asset>)Database.query(qb.toSoqlString()));
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 contactIds: maps to ContactId (Set<Id>/Id)
	 *						 assetNames: maps to Name (Set<String>/String)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Asset> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 contactIds: maps to ContactId (Set<Id>/Id)
	 *						 assetNames: maps to Name (Set<String>/String)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Asset> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		Set<Id> contactIds = (Set<Id>)(searchParams.get('contactIds') == null ? new Set<Id>() : (searchParams.get('contactIds') instanceof Set<Id> ? searchParams.get('contactIds') : new Set<Id>{(Id)searchParams.get('contactIds')}));
		Set<String> assetNames = (Set<String>)(searchParams.get('assetNames') == null ? new Set<String>() : (searchParams.get('assetNames') instanceof Set<String> ? searchParams.get('assetNames') : new Set<String>{String.valueOf(searchParams.get('assetNames'))}));

		return (List<Asset>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'contactIds', 'assetNames'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('contactIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(Asset.ContactId + ' in :contactIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('assetNames')) {
			conditions.add(new QueryBuilder.SimpleCondition(Asset.Name + ' in :assetNames'));
			conditionCount++;
		}
		
		// build our condition string which would end up being something liek the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		return conditions.endConditions().toSoqlString();
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}
		return builder;
	}
}