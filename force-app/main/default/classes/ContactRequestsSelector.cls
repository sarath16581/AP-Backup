/**
 * @author Ranjeewa Silva
 * @date 2024-07-15
 * @description A very simple selector class
 * @test ContactRequestsSelector_Test
 * @changelog
 * 2024-09-24 - George Nguyen - Included Case__c field as default. It qualifies to be as it will be commonly used. Included method .selectByIds(...) to be used by UnifiedInteractionService
 */
public virtual inherited sharing class ContactRequestsSelector extends ApplicationSelector {

	public static ContactRequestsSelector newInstance() {
		return (ContactRequestsSelector)Application.Selectors.newInstance(ContactRequestsSelector.class);
	}
	public static ContactRequestsSelector newInstance(Integer recordLimit) {
		return (ContactRequestsSelector)Application.Selectors.newInstance(ContactRequestsSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ContactRequestsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ContactRequestsSelector selector = (ContactRequestsSelector)Application.Selectors.newInstance(ContactRequestsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ContactRequestsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ContactRequestsSelector selector = (ContactRequestsSelector)Application.Selectors.newInstance(ContactRequestsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return ContactRequest.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				ContactRequest.Id, ContactRequest.OwnerId, ContactRequest.WhatId, ContactRequest.WhoId, ContactRequest.Status, ContactRequest.Case__c
		};
	}

	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param ids Set<Id>
	 * @description returns a list of records base on their Id
	 *
	 * @return List<ContactRequest>
	 */
	public List<ContactRequest> selectByIds(Set<Object> selectorOptions, Set<Id> ids) {		
		QueryBuilder qb = newQueryBuilder(selectorOptions);  
	   QueryBuilder.ConditionsManager conditions = qb.addConditions();
	   conditions.add(new QueryBuilder.SimpleCondition(ContactRequest.Id + ' IN :ids'));
	   conditions.endConditions();
	   return (List<ContactRequest>)Database.query(qb.toSoqlString());
   }

	/**
	 * Run a SOQL based on the search parameters passed in
	 * @param searchParams A map containing searchable values:
	 *						 whatIds: maps to WhatId (Set<Id>/Id)
	 *						 status: maps to Status (Set<String>/String)
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of ContactRequest records
	 */
	public List<ContactRequest> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 whatIds: maps to WhatId (Set<Id>/Id)
	 *						 status: maps to Status (Set<String>/String)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of ContactRequest records
	 */
	public List<ContactRequest> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		Set<Id> whatIds = (Set<Id>)(searchParams.get('whatIds') == null ? new Set<Id>() : (searchParams.get('whatIds') instanceof Set<Id> ? searchParams.get('whatIds') : new Set<Id>{(Id)searchParams.get('whatIds')}));
		Set<String> status = (Set<String>)(searchParams.get('status') == null ? new Set<String>() : (searchParams.get('status') instanceof Set<String> ? searchParams.get('status') : new Set<String>{(String)searchParams.get('status')}));
		return (List<ContactRequest>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'whatIds', 'status'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if (searchParams.containsKey('whatIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(ContactRequest.WhatId + ' in :whatIds'));
			conditionCount++;
		}
		if (searchParams.containsKey('status')) {
			conditions.add(new QueryBuilder.SimpleCondition(ContactRequest.Status + ' in :status'));
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
}