/**
 * @author Steve W.
 * @date 2021-03-03
 * @group Selector
 * @tag Selector
 * @tag Task SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2010-03-03 - Steve W - Created
 * 2021-06-24 - Raman Saxena(Salesforce) - Added Priority field in getSObjectFieldList method and created a new method selectByWhatId - PBRP
 * 2021-12-22 - Ashapriya Gadi - Added method selectList to retrieve tasks based on WhatIds and ownerIds
 * 2022-02-02 - Nathan Franklin - Update search method and fixed injection attack vector
 * 2023-08-11 - SteveL - added selectByWhatIdAllRows
 * 2024-05-28 - Ranjeewa Silva - Fixed a bug in search method by defining bind variables for 'subjects' and 'ownerIds' search parameters
 */
public virtual inherited sharing class TasksSelector extends ApplicationSelector {

	public enum Options {
		WITH_OWNER, WITH_CONTACT
	}

	protected String sortField = 'ActivityDate';
	protected String sortOrder ='Desc NULLS First';

	public static TasksSelector newInstance() {
		return (TasksSelector)Application.Selectors.newInstance(TasksSelector.class);
	}

	public static TasksSelector newInstance(Integer offsetLimit) {
		return (TasksSelector)Application.Selectors.newInstance(TasksSelector.class).setOffset(offsetLimit);
	}

	public static TasksSelector newInstance(Integer recordLimit, Integer offsetLimit, String sortField, String sortOrder, Set<SObjectField> fieldOverrides) {
		TasksSelector selector = (TasksSelector)Application.Selectors.newInstance(TasksSelector.class).setLimit(recordLimit).setOffset(offsetLimit).setFieldOverrides(fieldOverrides);
		selector.sortField = sortField;
		selector.sortOrder = sortOrder;
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Task.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Task.Id, Task.Subject, Task.Description, Task.ActivityDate, Task.OwnerId, Task.WhatId,
				Task.WhoId, Task.Status, Task.Category__c, Task.Type, Task.TaskSubtype, Task.IsClosed,
				Task.Priority, Task.OwnerId, Task.Operations_Outcome_Comment__c, Task.CreatedDate
		};
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 whatIds: maps to WhatId (Set<Id>/Id)
	 *						 ownerIds: maps to OwnerId (Set<Id>/Id)
	 *						 subjects: maps to Subject (Set<String>/String)
	 *						 fromActivityDate: maps to ActivityDate and is the oldest activity date to select (Datetime)
	 *						 isClosed: maps to IsClosed (Boolean)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, Task>
	 */
	public Map<Id, Task> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		QueryBuilder builder = newQueryBuilder(selectorOptions);

		// add our tracking query
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Set<Id> whatIds = (Set<Id>)(searchParams.get('whatIds') == null ? new Set<Id>() : (searchParams.get('whatIds') instanceof Set<Id> ? searchParams.get('whatIds') : new Set<Id>{(Id)searchParams.get('whatIds')}));
		Date fromActivityDate = searchParams.get('fromActivityDate') == null ? null : Date.valueOf(String.valueOf(searchParams.get('fromActivityDate')));
		Boolean isClosed = (Boolean) searchParams.get('isClosed');
		Set<String> subjects = (Set<String>)(searchParams.get('subjects') == null ? new Set<String>() : (searchParams.get('subjects') instanceof Set<String> ? searchParams.get('subjects') : new Set<String>{String.valueOf(searchParams.get('subjects'))}));
		Set<Id> ownerIds = (Set<Id>)(searchParams.get('ownerIds') == null ? new Set<Id>() : (searchParams.get('ownerIds') instanceof Set<Id> ? searchParams.get('ownerIds') : new Set<Id>{(Id)searchParams.get('ownerIds')}));

		// these are for backwards compatibility ONLY. This parameters should not be used anymore and are @deprecated
		if(searchParams.get('WhatId') != null) {
			whatIds.add((Id)searchParams.get('WhatId'));
		}
		if(searchParams.get('IsClosed') != null) {
			isClosed = (Boolean)searchParams.get('IsClosed');
		}
		if(searchParams.get('ActivityDate') != null) {
			fromActivityDate = Date.valueOf(String.valueOf(searchParams.get('ActivityDate')));
		}
		
		Integer conditionCount = 0;
		if(searchParams.containsKey('ActivityDate') || searchParams.containsKey('fromActivityDate')) {
			conditions.add(new QueryBuilder.SimpleCondition('ActivityDate >= :fromActivityDate'));
			conditionCount++;
		}
		if(searchParams.containsKey('WhatId') || searchParams.containsKey('whatIds')) {
			conditions.add(new QueryBuilder.SimpleCondition('WhatId in :whatIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('IsClosed') || searchParams.containsKey('isClosed')) {
			conditions.add(new QueryBuilder.SimpleCondition('IsClosed = :isClosed'));
			conditionCount++;
		}
		if(searchParams.containsKey('subjects')) {
			conditions.add(new QueryBuilder.SimpleCondition('Subject in :subjects'));
			conditionCount++;
		}

		if(searchParams.containsKey('ownerIds')) {
			conditions.add(new QueryBuilder.SimpleCondition('OwnerId in :ownerIds'));
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
		String soql = conditions.endConditions().toSoqlString();

		return new Map<Id, Task>((List<Task>)Database.query(soql));
	}

	/**
	 * @description Run a simple query to get records based on Ids
	 */
	public Map<Id, Task> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Ids
	 */
	public Map<Id, Task> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Task.Id + ' in :ids')).endConditions();
		return new Map<Id, Task>((List<Task>)Database.query(qb.toSoqlString()));
	}
   
   /**
	 * @description Run a simple query to get records based on what Ids | PBRP
	 */
	public Map<Id, Task> selectByWhatId(Set<Id> whatIds) {
		return selectByWhatId(whatIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on what Ids | PBRP
	 */
	public Map<Id, Task> selectByWhatId(Set<Id> whatIds, Set<Object> selectorOptions) {
		return selectByWhatId(whatIds, selectorOptions, false);
	}

	/**
	 * @description Run a simple query to get records based on what Ids with ALL ROWS
	 */
	public Map<Id, Task> selectByWhatId(Set<Id> whatIds, Set<Object> selectorOptions, Boolean allRows) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Task.WhatId + ' in :whatIds')).endConditions();
		String qString = allRows ? qb.toSoqlString() + ' ALL ROWS' : qb.toSoqlString();
		return new Map<Id, Task>((List<Task>)Database.query(qString));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(RelatedTosSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Who');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Owner');
		}

		return builder;
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order(sortField, sortOrder)};
	}
}