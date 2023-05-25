/**
 * @description
 * A very simple selector class that sits in the base domain
 * @author Mahesh Parvathaneni
 * @date 2023-05-09
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

 public virtual inherited sharing class PostcodesSelector extends ApplicationSelector {

	public enum Options {
		WITH_POSTCODE_MAPPING
	}
	
	public static PostcodesSelector newInstance() {
		return (PostcodesSelector)Application.Selectors.newInstance(PostcodesSelector.class);
	}
	public static PostcodesSelector newInstance(Integer recordLimit) {
		return (PostcodesSelector)Application.Selectors.newInstance(PostcodesSelector.class).setLimit(recordLimit);
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PostcodesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PostcodesSelector selector = (PostcodesSelector)Application.Selectors.newInstance(PostcodesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	public override SObjectType getSObjectType() {
		return Postcode__c.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Postcode__c.Id, Postcode__c.Name, Postcode__c.Suburb__c, Postcode__c.Locality_Postcode_ID__c
		};
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Postcode__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Postcode__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Postcode__c.Id + ' in :ids')).endConditions();
		return (List<Postcode__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 postcodes: maps to Name (Set<String>/String)
	 *						 suburbs: maps to Suburb__c (Set<String>/String)
	 *						 localityIds: maps to Locality_Postcode_ID__c (Set<String>/String)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Postcode__c> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 postcodes: maps to Name (Set<String>/String)
	 *						 suburbs: maps to Suburb__c (Set<String>/String)
	 *						 localityIds: maps to Locality_Postcode_ID__c (Set<String>/String)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<Postcode__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{'postcodes', 'suburbs', 'localityIds'});

		Set<String> postcodes = (Set<String>)(searchParams.get('postcodes') == null ? new Set<String>() : (searchParams.get('postcodes') instanceof Set<String> ? searchParams.get('postcodes') : new Set<String>{(String)searchParams.get('postcodes')}));
		Set<String> suburbs = (Set<String>)(searchParams.get('suburbs') == null ? new Set<String>() : (searchParams.get('suburbs') instanceof Set<String> ? searchParams.get('suburbs') : new Set<String>{(String)searchParams.get('suburbs')}));
		Set<String> localityIds = (Set<String>)(searchParams.get('localityIds') == null ? new Set<String>() : (searchParams.get('localityIds') instanceof Set<String> ? searchParams.get('localityIds') : new Set<String>{(String)searchParams.get('localityIds')}));

		return (List<Postcode__c>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		
		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('postcodes')) {
			conditions.add(new QueryBuilder.SimpleCondition(Postcode__c.Name + ' in :postcodes'));
			conditionCount++;
		}
		if(searchParams.containsKey('suburbs')) {
			conditions.add(new QueryBuilder.SimpleCondition(Postcode__c.Suburb__c + ' in :suburbs'));
			conditionCount++;
		}
		if(searchParams.containsKey('localityIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(Postcode__c.Locality_Postcode_ID__c + ' in :localityIds'));
			conditionCount++;
		}

		// build our condition string which would end up being something like the following:
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

		if(selectorOptions.contains(Options.WITH_POSTCODE_MAPPING)) {
			builder.addSubQuery(PostcodeMappingsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Postcode_Mappings__r');
		}
	
		return builder;
	}
}