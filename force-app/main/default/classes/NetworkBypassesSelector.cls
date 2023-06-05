/**
 * @description
 * A very simple selector class that sits in the base domain
 * @author Mahesh Parvathaneni
 * @date 2023-05-17
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

public virtual inherited sharing class NetworkBypassesSelector extends ApplicationSelector {

	public static NetworkBypassesSelector newInstance() {
		return (NetworkBypassesSelector)Application.Selectors.newInstance(NetworkBypassesSelector.class);
	}
	public static NetworkBypassesSelector newInstance(Integer recordLimit) {
		return (NetworkBypassesSelector)Application.Selectors.newInstance(NetworkBypassesSelector.class).setLimit(recordLimit);
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworkBypassesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		NetworkBypassesSelector selector = (NetworkBypassesSelector)Application.Selectors.newInstance(NetworkBypassesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	public override SObjectType getSObjectType() {
		return FacilityByPass__c.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			FacilityByPass__c.Id, FacilityByPass__c.Name, FacilityByPass__c.Comment__c, FacilityByPass__c.Facility_By_Pass_From__c, FacilityByPass__c.Facility_By_Pass_From_Name__c,
			FacilityByPass__c.Facility_By_Pass_To__c, FacilityByPass__c.Facility_By_Pass_To_Name__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<FacilityByPass__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<FacilityByPass__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(FacilityByPass__c.Id + ' in :ids')).endConditions();
		return (List<FacilityByPass__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 bypassFromIds: maps to Facility_By_Pass_From__c (Set<Id>/Id)
	 *						 bypassToIds: maps to Facility_By_Pass_To__c (Set<Id>/Id)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<FacilityByPass__c> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 bypassFromIds: maps to Facility_By_Pass_From__c (Set<Id>/Id)
	 *						 bypassToIds: maps to Facility_By_Pass_To__c (Set<Id>/Id)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<FacilityByPass__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{'bypassFromIds', 'bypassToIds'});

		Set<Id> bypassFromIds = (Set<Id>)(searchParams.get('bypassFromIds') == null ? new Set<Id>() : (searchParams.get('bypassFromIds') instanceof Set<Id> ? searchParams.get('bypassFromIds') : new Set<Id>{(Id)searchParams.get('bypassFromIds')}));
		Set<Id> bypassToIds = (Set<Id>)(searchParams.get('bypassToIds') == null ? new Set<Id>() : (searchParams.get('bypassToIds') instanceof Set<Id> ? searchParams.get('bypassToIds') : new Set<Id>{(String)searchParams.get('bypassToIds')}));

		return (List<FacilityByPass__c>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		
		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('bypassFromIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(FacilityByPass__c.Facility_By_Pass_From__c + ' in :bypassFromIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('bypassToIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(FacilityByPass__c.Facility_By_Pass_To__c + ' in :bypassToIds'));
			conditionCount++;
		}

		// build our condition string which would end up being something like the following:
		// 1 AND 2
		// 1 OR 2
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		return conditions.endConditions().toSoqlString();
	}
	
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
	
		return builder;
	}
}