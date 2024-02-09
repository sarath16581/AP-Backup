/**
 * @description Selector case to get ContentVersion records
 * @author Nathan Franklin
 * @date 2020-10-04
 * @group Selector
 * @domain Core
 * @changelog
*/
public virtual inherited sharing class ContentVersionsSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE,
		IS_LATEST_VERSION
	}

	public static String sortOrder ='Desc';
	public static String sortfieldAPIName = 'Id'; 

	public static ContentVersionsSelector newInstance() {
		return (ContentVersionsSelector)Application.Selectors.newInstance(ContentVersionsSelector.class);
	}

	public static ContentVersionsSelector newInstance(String sortField, String order){
        if(!String.isEmpty(sortField))
            sortfieldAPIName = sortField;
        if(!String.isEmpty(order))
            sortOrder = order;
		return (ContentVersionsSelector)Application.Selectors.newInstance(ContentVersionsSelector.class);
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static ContentVersionsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return (ContentVersionsSelector)Application.Selectors.newInstance(ContentVersionsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
	}

	public override SObjectType getSObjectType() {
		return ContentVersion.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				ContentVersion.Checksum, ContentVersion.ContentBodyId, ContentVersion.ContentDocumentId, ContentVersion.ContentLocation,
				ContentVersion.ContentModifiedById, ContentVersion.ContentModifiedDate, ContentVersion.ContentSize, ContentVersion.ContentUrl,
				ContentVersion.CreatedById, ContentVersion.CreatedDate, ContentVersion.Document_Date__c, ContentVersion.Document_Interval__c,
				ContentVersion.Document_Type__c, ContentVersion.FileExtension, ContentVersion.FileType, ContentVersion.Id, ContentVersion.IsLatest,
				ContentVersion.LastModifiedById, ContentVersion.LastModifiedDate, ContentVersion.NetworkId, ContentVersion.Origin,
				ContentVersion.OwnerId, ContentVersion.PathOnClient, ContentVersion.PublishStatus, ContentVersion.RecordTypeId,
				ContentVersion.SharingOption, ContentVersion.SharingPrivacy, ContentVersion.Title, ContentVersion.VersionNumber
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, ContentVersion> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, ContentVersion> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ContentVersion.Id + ' in :ids')).endConditions();
		return new Map<Id, ContentVersion>((List<ContentVersion>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on Content Document Id's
	 */
	public virtual Map<Id, ContentVersion> selectByContentDocumentId(Set<Id> ids) {
		return selectByContentDocumentId(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Content Document Id's
	 */
	public virtual Map<Id, ContentVersion> selectByContentDocumentId(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ContentVersion.ContentDocumentId + ' in :ids')).endConditions();
		return new Map<Id, ContentVersion>((List<ContentVersion>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'RecordType');
		}

		if(selectorOptions.contains(Options.IS_LATEST_VERSION)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(ContentVersion.IsLatest+ ' = true'));
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