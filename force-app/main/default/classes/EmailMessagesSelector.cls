/**
 * @author Ashapriya Gadi
 * @date 2021-11-17
 * @group Selector
 * @tag Selector
 * @tag EmailMessage
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-11-17 - Ashapriya Gadi - Created
 * 2022-02-04 Ashapriya Gadi - Added  EmailMessage.CcAddress, EmailMessage.BccAddress
 * 2022-02-16 - Nathan Franklin - Added option to filter email by INCOMING/OUTGOING only
 * 2022-02-22 - Naveen Rajanna - REQ2723199 Added method selectByIdsWithParentStarTrackCase, new WITH_CASE enum and fields to getSObjectFieldList
 * 2023-05-26 - Mahesh Parvathaneni - Added method selectByIdsAndParentRecordTypeId
 * 2023-11-06 - hasantha.liyanage@auspost.com.au - Modified: added selectByParentIds
 */
public virtual inherited sharing class EmailMessagesSelector extends ApplicationSelector {

	public enum Options {
		FILTER_INCOMING, FILTER_OUTGOING, WITH_CASE
	}

	protected String sortOrder ='Desc';
	protected SObjectField sortField = EmailMessage.Id;
	
	public static EmailMessagesSelector newInstance() {
		return (EmailMessagesSelector)Application.Selectors.newInstance(EmailMessagesSelector.class);
	}

	public static EmailMessagesSelector newInstance(SObjectField sortField, String orderBy, Integer recordLimit){
		EmailMessagesSelector selector = (EmailMessagesSelector)Application.Selectors.newInstance(EmailMessagesSelector.class).setLimit(recordLimit);
		selector.sortField = sortField;
		selector.sortOrder = orderBy;
		return selector;
	}

	public override SObjectType getSObjectType() {
		return EmailMessage.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			EmailMessage.Id, EmailMessage.ToAddress, EmailMessage.CcAddress, EmailMessage.BccAddress, EmailMessage.Incoming, EmailMessage.Status, EmailMessage.Subject, EmailMessage.CreatedDate, EmailMessage.FromAddress, 
			EmailMessage.Headers, EmailMessage.ParentId
		};
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static EmailMessagesSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		EmailMessagesSelector selector = (EmailMessagesSelector)Application.Selectors.newInstance(EmailMessagesSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<EmailMessage> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<EmailMessage> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(EmailMessage.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.FILTER_INCOMING)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(EmailMessage.Incoming).eq(true)).endConditions();
		}
		if(selectorOptions.contains(Options.FILTER_OUTGOING)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(EmailMessage.Incoming).eq(false)).endConditions();
		}
		if(selectorOptions.contains(Options.WITH_CASE)) {
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_CASE);
			builder.addRelatedFields(CasesSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(clonedOptions), 'Parent');
		}
		return builder;
	}
	
	/**
	 * Forces an order to be applied to any query built with QueryBuilder. This can be overridden if needed
	 */
	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order(String.valueOf(sortField), sortOrder)};
	}

	public virtual List<EmailMessage> selectByIdsWithParentStarTrackCase(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(EmailMessage.Id + ' in :ids'))
			.add(new QueryBuilder.CompareCondition('Parent.StarTrack_RecordType__c').eq(true))
			.endConditions();
		return Database.query(qb.toSoqlString());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's and parent record type ids
	 */
	public virtual List<EmailMessage> selectByIdsAndParentRecordTypeId(Set<Id> ids, Set<Id> recordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(EmailMessage.Id + ' in :ids'))
			.add(new QueryBuilder.SimpleCondition('Parent.RecordTypeId in :recordTypeIds'))
			.endConditions();
		return Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on parent Id
	 * @return List<EmailMessage>
	 */
	public virtual List<EmailMessage> selectByParentIds(Set<Id> ids,Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(EmailMessage.ParentId + ' in :ids'))
				.endConditions();
		return Database.query(qb.toSoqlString());
	}

	public virtual Integer getDuplicateEmailMessagesCount(Id emailMessageId, String fromAddress, String subject, Datetime customDateTime) {
		String query = 'SELECT COUNT() FROM EmailMessage WHERE Id!=:emailMessageId AND FromAddress=:fromAddress AND Subject=:subject AND CreatedDate>:customDateTime';
		return Database.countQuery(query);
	}
}