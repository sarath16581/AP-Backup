/**
 * @description Selector case to get ContentVersion records
 * @author Nathan Franklin
 * @date 2020-10-04
 * @group Selector
 * @domain Core
 * @changelog
 * -----------------------------------------------------------------------------------
 * 12-10-2020  Jansi added newInstance method with recordLimit, offsetLimit params
 * 13-10-2020 added sortOrder, sortfieldAPIName class variables
 * 21-07-2023 hasantha.liyanage@auspost.com.au Added with with contentDocument option
*/
public virtual inherited sharing class ContentDocumentLinksSelector extends ApplicationSelector {

	public enum Options {
		WITH_CONTENTVERSION,
		WITH_CONTENTDOCUMENT
	}

	public String sortOrder ='Desc';
	public String sortfieldAPIName = 'Id';  

	public static ContentDocumentLinksSelector newInstance() {
		return (ContentDocumentLinksSelector)Application.Selectors.newInstance(ContentDocumentLinksSelector.class);
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static ContentDocumentLinksSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return (ContentDocumentLinksSelector)Application.Selectors.newInstance(ContentDocumentLinksSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
	}

	public  ContentDocumentLinksSelector newInstance(Integer recordLimit, Integer offsetLimit) {
		return (ContentDocumentLinksSelector)Application.Selectors.newInstance(ContentDocumentLinksSelector.class).setLimit(recordLimit).setOffset(offsetLimit);
	}

	public override SObjectType getSObjectType() {
		return ContentDocumentLink.getSObjectType();
	}
    
    public ContentDocumentLinksSelector newInstance(String sortOrder, String sortfieldAPIName) {
        if(!String.isEmpty(sortfieldAPIName))
            sortfieldAPIName = sortfieldAPIName;
        if(!String.isEmpty(sortOrder))
            sortOrder = sortOrder;
		return (ContentDocumentLinksSelector)Application.Selectors.newInstance(ContentDocumentLinksSelector.class);
    }

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				ContentDocumentLink.ContentDocumentId, ContentDocumentLink.Id, ContentDocumentLink.LinkedEntityId, ContentDocumentLink.ShareType, ContentDocumentLink.Visibility
		};
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *                          entityId / entityIds: maps to LinkedEntityId
	 *                          documentId / documentIds: maps to ContentDocumentId
	 *                          title / titles: maps to ContentDocument.Title
	 *                          contentVersionDocumentDate / contentVersionDocumentDates: maps to ContentDocument.LatestPublishedVersion.Document_Date__c
	 *                          contentVersionDocumentType / contentVersionDocumentTypes: maps to ContentDocument.LatestPublishedVersion.Document_Type__c
	 *                          contentVersionDocumentInterval / contentVersionDocumentIntervals: maps to ContentDocument.LatestPublishedVersion.Document_Interval__c
	 *                          contentVersionRecordTypeId: maps to ContentDocument.LatestPublishedVersion.Title
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, ContentDocumentLink>
	 */
	public Map<Id, ContentDocumentLink> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>{}, matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 * NOTE: entityIds OR documentIds MUST be passed to avoid a runtime error
	 *
	 * @param searchParams A map containing searchable values:
	 *                          entityIds: maps to LinkedEntityId
	 *                          documentIds: maps to ContentDocumentId
	 *                          titles: maps to ContentDocument.Title
	 *                          contentVersionDocumentDates: maps to ContentDocument.LatestPublishedVersion.Document_Date__c
	 *                          contentVersionDocumentTypes: maps to ContentDocument.LatestPublishedVersion.Document_Type__c
	 *                          contentVersionDocumentIntervals: maps to ContentDocument.LatestPublishedVersion.Document_Interval__c
	 *                          contentVersionRecordTypeId: maps to ContentDocument.LatestPublishedVersion.Title
	 *                          forcedParameters: a list of parameters that should be included even if the passed in values are empty
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, ContentDocumentLink>
	 */
	public Map<Id, ContentDocumentLink> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		QueryBuilder builder = newQueryBuilder(selectorOptions);

		// add our tracking query
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Set<Id> entityIds = (Set<Id>)(searchParams.get('entityIds') == null ? new Set<Id>() : (searchParams.get('entityIds') instanceof Set<Id> ? searchParams.get('entityIds') : new Set<Id>{(Id)searchParams.get('entityIds')}));
		Set<Id> documentIds = (Set<Id>)(searchParams.get('documentIds') == null ? new Set<Id>() : (searchParams.get('documentIds') instanceof Set<Id> ? searchParams.get('documentIds') : new Set<Id>{(Id)searchParams.get('documentIds')}));
		Set<String> titles = (Set<String>)(searchParams.get('titles') == null ? new Set<String>() : (searchParams.get('titles') instanceof Set<String> ? searchParams.get('titles') : new Set<String>{String.valueOf(searchParams.get('titles'))}));
		Set<Date> documentDates = (Set<Date>)(searchParams.get('contentVersionDocumentDates') == null ? new Set<Date>() : (searchParams.get('contentVersionDocumentDates') instanceof Set<Date> ? searchParams.get('contentVersionDocumentDates') : new Set<Date>{(Date)searchParams.get('contentVersionDocumentDates')}));
		Set<String> documentTypes = (Set<String>)(searchParams.get('contentVersionDocumentTypes') == null ? new Set<String>() : (searchParams.get('contentVersionDocumentTypes') instanceof Set<String> ? searchParams.get('contentVersionDocumentTypes') : new Set<String>{String.valueOf(searchParams.get('contentVersionDocumentTypes'))}));
		Set<String> documentIntervals = (Set<String>)(searchParams.get('contentVersionDocumentIntervals') == null ? new Set<String>() : (searchParams.get('contentVersionDocumentIntervals') instanceof Set<String> ? searchParams.get('contentVersionDocumentIntervals') : new Set<String>{String.valueOf(searchParams.get('contentVersionDocumentIntervals'))}));
		Date documentFromDate = searchParams.get('contentVersionDocumentFromDate') == null ? null : Date.valueOf(searchParams.get('contentVersionDocumentFromDate'));
		Date documentToDate = searchParams.get('contentVersionDocumentToDate') == null ? null : Date.valueOf(searchParams.get('contentVersionDocumentToDate'));
		Id recordTypeId = (searchParams.get('contentVersionRecordTypeId') == null ? null : Id.valueOf(String.valueOf(searchParams.get('contentVersionRecordTypeId'))));

		Integer conditionCount = 0;
		if(!entityIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(ContentDocumentLink.LinkedEntityId + ' IN :entityIds'));
			conditionCount++;
		}
		if(!documentIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(ContentDocumentLink.ContentDocumentId + ' IN :documentIds'));
			conditionCount++;
		}
		if(!titles.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.' + ContentDocument.Title + ' IN :titles'));
			conditionCount++;
		}
		if(!documentDates.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.LatestPublishedVersion.' + ContentVersion.Document_Date__c + ' IN :documentDates'));
			conditionCount++;
		}
		if(!documentTypes.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.LatestPublishedVersion.' + ContentVersion.Document_Type__c + ' IN :documentTypes'));
			conditionCount++;
		}
		if(!documentIntervals.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.LatestPublishedVersion.' + ContentVersion.Document_Interval__c + ' IN :documentIntervals'));
			conditionCount++;
		}
		if(recordTypeId != null) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.LatestPublishedVersion.' + ContentVersion.RecordTypeId + ' = :recordTypeId'));
			conditionCount++;
		}
		if(documentFromDate != null) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.LatestPublishedVersion.' + ContentVersion.Document_Date__c + ' >= :documentFromDate'));
			conditionCount++;
		}
		if(documentToDate != null) {
			conditions.add(new QueryBuilder.SimpleCondition('ContentDocument.LatestPublishedVersion.' + ContentVersion.Document_Date__c + ' <= :documentToDate'));
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

		return new Map<Id, ContentDocumentLink>((List<ContentDocumentLink>)Database.query(soql));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		system.debug(selectorOptions);
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CONTENTVERSION)) {
			builder.addRelatedFields(ContentVersionsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'ContentDocument.LatestPublishedVersion');
		}

		if(selectorOptions.contains(Options.WITH_CONTENTDOCUMENT)) {
			builder.addRelatedFields(ContentDocumentsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'ContentDocument');
		}

		return builder;
	}

	/**
	 * Forces an order to be applied to any query built with QueryBuilder. This can be overridden if needed
	 */
	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order(sortfieldAPIName, sortOrder)};
	}

}