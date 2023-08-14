/**
 * @author Steve L.
 * @date 2023-07-13
 * @group Selector
 * @tag Selector
 * @tag Event SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2023-07-13 - Steve L- Created
 * 2023-08-11 - SteveL - added selectByWhatIdAllRows
 */
public virtual inherited sharing class EventsSelector extends ApplicationSelector {
	public enum Options {
		WITH_OWNER, WITH_CONTACT
	}

	protected String sortField = 'CreatedDate';
	protected String sortOrder ='DESC';

	public static EventsSelector newInstance() {
		return (EventsSelector)Application.Selectors.newInstance(EventsSelector.class);
	}

	public static EventsSelector newInstance(Integer offsetLimit) {
		return (EventsSelector)Application.Selectors.newInstance(EventsSelector.class).setOffset(offsetLimit);
	}

	public static EventsSelector newInstance(Integer recordLimit,Integer offsetLimit, Set<SObjectField> fieldOverrides) {
		return (EventsSelector)Application.Selectors.newInstance(EventsSelector.class).setLimit(recordLimit).setOffset(offsetLimit).setFieldOverrides(fieldOverrides);
	}

	public override SObjectType getSObjectType() {
		return Event.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Event.Id, Event.Subject, Event.Description, Event.ActivityDate, Event.OwnerId, Event.WhatId,
				Event.WhoId,Event.Category__c, Event.Type, Event.OwnerId, Event.Status__c,
				Event.StartDateTime, Event.EndDate, Event.EndDateTime, Event.CreatedDate
		};
	}

	/**
	 * @description Run a simple query to get records based on Ids
	 */
	public Map<Id, Event> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Ids
	 */
	public Map<Id, Event> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Event.Id + ' in :ids')).endConditions();
		return new Map<Id, Event>((List<Event>)Database.query(qb.toSoqlString()));
	}

	/**
	  * @description Run a simple query to get records based on what Ids | PBRP
	  */
	public Map<Id, Event> selectByWhatId(Set<Id> whatIds) {
		return selectByWhatId(whatIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on what Ids | PBRP
	 */
	public Map<Id, Event> selectByWhatId(Set<Id> whatIds, Set<Object> selectorOptions) {
		return selectByWhatId(whatIds, selectorOptions, false);
	}

	/**
	 * @description Run a simple query to get records based on what Ids with ALL ROWS
	 */
	public Map<Id, Event> selectByWhatId(Set<Id> whatIds, Set<Object> selectorOptions, Boolean allRows) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Event.WhatId + ' in :whatIds')).endConditions();
		String qString = allRows ? qb.toSoqlString() + ' ALL ROWS' : qb.toSoqlString();
		return new Map<Id, Event>((List<Event>)Database.query(qString));
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