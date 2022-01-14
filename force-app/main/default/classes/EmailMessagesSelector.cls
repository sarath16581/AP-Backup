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
*/

public virtual inherited sharing class EmailMessagesSelector extends ApplicationSelector {
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
				EmailMessage.Id, EmailMessage.ToAddress
		};
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
	
	/**
	 * Forces an order to be applied to any query built with QueryBuilder. This can be overridden if needed
	 */
	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order(String.valueOf(sortField), sortOrder)};
	}
}