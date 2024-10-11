/**
 * @author Disha Kariya
 * @date 2020-08-21
 * @group Selector
 * @tag Selector
 * @tag Event Messages
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-21 - Disha kariya - Created
 * 2020-10-06 - Disha Kariya - Added Filter with Safe drop guid
 * 2021-06-15 - Ranjeewa Silva - Added Selector option to filter with Attachment GUID (FILTER_ATTACHMENT_GUID) and renamed
 * 								selector option 'FILTER_NOT_BLANK_GUID' to 'FILTER_SAFE_DROP_GUID'.
 * 2021-10-01 - Nathan Franklin - Added selectByArticleNumber and uplifted to version 52 and also the WITH_SIGNATURE_FIELD option
 * 2021-10-03 - Nathan Franklin - Updated to pass selectorOptions into all related object selectors
 * 2022-11-23 - Mahesh Parvathaneni - Added newInstance method with sort field and order and also added the selector FILTER_AP_NETWORK_NOT_NULL
 * 2023-03-06 - Mahesh Parvathaneni - Added field ActualDateTime_Timestamp__c
 * 2023-03-08 - Mahesh Parvathaneni - Added options FILTER_GEO_LOCATION
 * 2023-03-10 - Mahesh Parvathaneni - Removed the option FILTER_AP_NETWORK_NOT_NULL
 * 2024-09-23 - Seth Heang - added selectByCaseIdAndEventType()
 */
public virtual inherited sharing class EventMessagesSelector extends ApplicationSelector {

	public static String sortOrder ='Asc';
	public static String sortfieldAPIName = 'ActualDateTime__c';

	/**
	 * NOTE: WITH_SIGNATURE_FIELD allows us to conditionally add the signature long text field only when it's needed
	 */
	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_ARTICLE, WITH_ATTACHMENT, WITH_SIGNATURE_FIELD, FILTER_SAFE_DROP_GUID, FILTER_ATTACHMENT_GUID, FILTER_GEO_LOCATION
	}

	public static EventMessagesSelector newInstance() {
		return (EventMessagesSelector)Application.Selectors.newInstance(EventMessagesSelector.class);
	}
	public static EventMessagesSelector newInstance(Integer recordLimit) {
		return (EventMessagesSelector)Application.Selectors.newInstance(EventMessagesSelector.class).setLimit(recordLimit);
	}

	public static EventMessagesSelector newInstance(String sortField, String order){
		if(!String.isEmpty(sortField)) {
			sortfieldAPIName = sortField;
		}
		if(!String.isEmpty(order)) {
			sortOrder = order;
		}
		return (EventMessagesSelector)Application.Selectors.newInstance(EventMessagesSelector.class);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static EventMessagesSelector newInstance(Set<SObjectField> fieldOverrides) {
		EventMessagesSelector selector = (EventMessagesSelector)Application.Selectors.newInstance(EventMessagesSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static EventMessagesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		EventMessagesSelector selector = (EventMessagesSelector)Application.Selectors.newInstance(EventMessagesSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						 This approach removes data consistency and prevents possible caching of results
	 */
	public static EventMessagesSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		EventMessagesSelector selector = (EventMessagesSelector)Application.Selectors.newInstance(EventMessagesSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return EventMessage__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		//NOTE: It's generally not a good practice to add LONG TEXT fields in the generic field list
		// In this case, when the signature is required, I've created an option WITH_SIGNATURE_FIELD to add the field in
		return new Set<SObjectField> {
			EventMessage__c.Id, EventMessage__c.DriverContract__c, EventMessage__c.RoundNo__c, EventMessage__c.UserName__c, EventMessage__c.SignatoryName__c, EventMessage__c.Safe_Drop_GUID__c, 
			EventMessage__c.Article__c, EventMessage__c.EventGeoLocation__Latitude__s, EventMessage__c.EventGeoLocation__Longitude__s, EventMessage__c.EventType__c, EventMessage__c.AttachmentGUID__c,
			EventMessage__c.AttachmentType__c, EventMessage__c.EventDescription__c, EventMessage__c.ActualDateTime__c, EventMessage__c.TrackingID__c, EventMessage__c.FacilityOrganisationID__c,
			EventMessage__c.ActualDateTime_Timestamp__c, EventMessage__c.Post_Office_Code__c, EventMessage__c.Case__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, EventMessage__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, EventMessage__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(EventMessage__c.Id + ' in :ids')).endConditions();
		return new Map<Id, EventMessage__c>((List<EventMessage__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get event messages based on Case Id AND Event Type
	 * @param caseIds set of case Ids
	 * @param eventTypes set of event type string
	 * @return List<EventMessage__c>
	 */
	public virtual List<EventMessage__c> selectByArticleIdAndEventType(Set<Id> articleIds, Set<String> eventTypes) {
		return selectByArticleIdAndEventType(articleIds, eventTypes, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get event messages based on Case Id AND Event Type
	 * @param caseIds set of case Ids
	 * @param eventTypes set of event type string
	 * @param selectorOptions options for retrieving related objects or additional filter
	 * @return List<EventMessage__c>
	 */
	public virtual List<EventMessage__c> selectByArticleIdAndEventType(Set<Id> articleIds, Set<String> eventTypes, Set<Object> selectorOptions) {
		// Avoid running query without any criteria
		articleIds.remove(null);
		eventTypes.remove(null);
		eventTypes.remove('');
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(EventMessage__c.Article__c + ' in :articleIds'))
				.add(new QueryBuilder.SimpleCondition(EventMessage__c.EventType__c + ' in :eventTypes'))
				.endConditions();
		return (List<EventMessage__c>) Database.query(qb.toSoqlString());
	}
	
	/**
	 * @description Run a query to get records based on Article Id's and event types
	 */
	public virtual Map<Id, EventMessage__c> selectByArticleId(Set<Id> ids) {
		return selectByArticleId(ids, new Set<String>(),new Set<Object>());
	}

	/**
	 * @description Run a query to get records based on Article Id's and event types
	 */
	public virtual Map<Id, EventMessage__c> selectByArticleId(Set<Id> ids, Set<String> eventTypes) {
		return selectByArticleId(ids, eventTypes, new Set<Object>());
	}

	/**
	 * @description Run a query to get records based on Article Id's and event types
	 */
	public virtual Map<Id, EventMessage__c> selectByArticleId(Set<Id> ids, Set<Object> selectorOptions) {
		return selectByArticleId(ids, new Set<String>(), selectorOptions);
	}

	/**
	 * @description Run a query to get records based on Article Id's and event types
	 */
	public virtual Map<Id, EventMessage__c> selectByArticleId(Set<Id> ids, Set<String> eventTypes, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(EventMessage__c.Article__c + ' in :ids')).endConditions();
		if(eventTypes.size() > 0) {
			qb.addConditions().add(new QueryBuilder.SimpleCondition(EventMessage__c.EventType__c + ' in :eventTypes')).endConditions();
		}
		//qb.addOrder(new QueryBuilder.Order('ActualDateTime__c', 'Asc'));
		return new Map<Id, EventMessage__c>((List<EventMessage__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a query to get records based on Article Id's and event types
	 */
	public virtual List<EventMessage__c> selectByArticleNumber(Set<String> articleIds) {
		return selectByArticleNumber(articleIds, new Set<Object>());
	}

	/**
	 * @description Run a query to get records based on Article Id's and event types
	 */
	public virtual List<EventMessage__c> selectByArticleNumber(Set<String> articleIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition('Article__r.ArticleID__c in :articleIds')).endConditions();
		return (List<EventMessage__c>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		// Only add long fields if necessary
		if(selectorOptions.contains(Options.WITH_SIGNATURE_FIELD)) {
			builder.addField(EventMessage__c.SignatureXString__c);
		}

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(selectorOptions), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(selectorOptions), 'Owner');
		}
		
		if(selectorOptions.contains(Options.WITH_ARTICLE)) {

			// backwards compatability
			Set<Object> articleOptions = selectorOptions.clone();
			articleOptions.add(ArticlesSelector.Options.WITH_RECORDTYPE);

			builder.addRelatedFields(ArticlesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(articleOptions), 'Article__r');
		}
		
		if(selectorOptions.contains(Options.WITH_ATTACHMENT)) {
			builder.addSubQuery(AttachmentsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Attachments');
		}

		if(selectorOptions.contains(Options.FILTER_SAFE_DROP_GUID)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(EventMessage__c.Safe_Drop_GUID__c).ne('')).endConditions();
			builder.addConditions().add(new QueryBuilder.NullCondition(EventMessage__c.Safe_Drop_GUID__c).notNull()).endConditions();
		}

		if (selectorOptions.contains(Options.FILTER_ATTACHMENT_GUID)) {
			builder.addConditions().add(new QueryBuilder.NullCondition(EventMessage__c.AttachmentGUID__c).notNull()).endConditions();
		}

		if (selectorOptions.contains(Options.FILTER_GEO_LOCATION)) {
			builder.addConditions().add(new QueryBuilder.NullCondition(EventMessage__c.EventGeoLocation__Latitude__s).notNull()).endConditions();
			builder.addConditions().add(new QueryBuilder.NullCondition(EventMessage__c.EventGeoLocation__Longitude__s).notNull()).endConditions();
		}

		return builder;
	}

	/**
	 * This should only be changed with caution!
	 */
	public override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order(sortfieldAPIName, sortOrder)};
	}

}