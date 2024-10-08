/* @author Seth Heang
 * @date 2020-12-18
 * @group Selector
 * @tag Selector
 * @tag SSSWRouting__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2024-07-09 - Ranjeewa Silva - Added search method with search parameter validation.
 */
public virtual inherited sharing class SSSWRoutingSelector extends ApplicationSelector {
	public enum Options {
		WITH_RECORDTYPE
	}

	public static SSSWRoutingSelector newInstance() {
		return (SSSWRoutingSelector)Application.Selectors.newInstance(SSSWRoutingSelector.class);
	}
	public static SSSWRoutingSelector newInstance(Integer recordLimit) {
		return (SSSWRoutingSelector)Application.Selectors.newInstance(SSSWRoutingSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return SSSWRouting__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				SSSWRouting__c.Id,SSSWRouting__c.RecordTypeId, SSSWRouting__c.Credit_Person_Code__c, SSSWRouting__c.DSR_Queue_Name__c ,
				SSSWRouting__c.Credit_Representative_Email__c, SSSWRouting__c.Credit_DSR_Routing__c
		};
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('Sequence__c', 'ASC')};
	}

	/**
	 * Run a SOQL based on the search parameters passed in.
	 *
	 * @param searchParams A map containing searchable values:
	 *						 recordtypeDeveloperNames: maps to RecordType.DeveloperName (Set<String>/String)
	 *						 isActive: maps to IsActive__c (Boolean)
	 *						 matchRulesOn: maps to Match_Rules_On__c (Set<String>/String)
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of SSSWRouting__c records based on the parameters passed in
	 */
	public List<SSSWRouting__c> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in.
	 *
	 * @param searchParams A map containing searchable values:
	 *						 recordtypeDeveloperNames: maps to RecordType.DeveloperName (Set<String>/String)
	 *						 isActive: maps to IsActive__c (Boolean)
	 *						 matchRulesOn: maps to Match_Rules_On__c (Set<String>/String)
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of SSSWRouting__c records based on the parameters passed in
	 */
	public List<SSSWRouting__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		// setup variables for search parameters, so that they can be used as parameters and bind variables in the
		// generated SOQL.
		Set<String> recordtypeDeveloperNames = (Set<String>)(searchParams.get('recordtypeDeveloperNames') == null ? new Set<String>() : (searchParams.get('recordtypeDeveloperNames') instanceof Set<String> ? searchParams.get('recordtypeDeveloperNames') : new Set<String>{(String)searchParams.get('recordtypeDeveloperNames')}));
		Boolean isActive = (Boolean)searchParams.get('isActive');
		Set<String> matchRulesOn = (Set<String>)(searchParams.get('matchRulesOn') == null ? new Set<String>() : (searchParams.get('matchRulesOn') instanceof Set<String> ? searchParams.get('matchRulesOn') : new Set<String>{(String)searchParams.get('matchRulesOn')}));

		return (List<SSSWRouting__c>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * @description Run a simple query to get records based on opportunity Id's
	 */
	public virtual Map<Id, SSSWRouting__c> selectByRecordTypeId(Set<Id> ids) {
		return selectByRecordTypeId(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on record type Id's
	 */
	public virtual Map<Id, SSSWRouting__c> selectByRecordTypeId(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
				.add(new QueryBuilder.SimpleCondition(SSSWRouting__c.RecordTypeId + ' = :ids'))
				.endConditions();
		return new Map<Id, SSSWRouting__c>((List<SSSWRouting__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 *
	 * @param searchParams A map containing search parameters. See documentation on search method.
	 * @param selectorOptions Additional selector options
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return SOQL generated based on the parameters passed in.
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'recordtypeDeveloperNames', 'isActive', 'matchRulesOn'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if (searchParams.containsKey('recordtypeDeveloperNames')) {
			conditions.add((new QueryBuilder.InCondition('RecordType.DeveloperName')).inCollection((Set<String>)searchParams.get('recordtypeDeveloperNames'))).endConditions();
			conditionCount++;
		}
		if (searchParams.containsKey('isActive')) {
			conditions.add(new QueryBuilder.SimpleCondition(SSSWRouting__c.IsActive__c + ' = :isActive'));
			conditionCount++;
		}
		if (searchParams.containsKey('matchRulesOn')) {
			conditions.add(new QueryBuilder.SimpleCondition(SSSWRouting__c.Match_Rules_On__c + ' in :matchRulesOn'));
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

	public override virtual QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(selectorOptions), 'RecordType');
		}

		return builder;
	}
}