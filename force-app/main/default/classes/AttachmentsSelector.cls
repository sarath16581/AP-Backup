/**
 * @author Disha Kariya
 * @date 2020-08-21
 * @group Selector
 * @tag Selector
 * @tag Attachments
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-21 - Disha kariya - Created
 * 2021-10-01 -  Nathan Franklin - Added WITH_BODY option + uplift to v52
 * 2023-07-15 -  Hasantha Liyanage added selectByParentId method
 */
public virtual inherited sharing class AttachmentsSelector extends ApplicationSelector {

	/**
	 * WITH_BODY is a special option to include the Body field. This field shouldn't be selected out unless its absolutely needed :)
	 */
	public enum Options {
		WITH_OWNER, WITH_BODY
	}

	public static AttachmentsSelector newInstance() {
		return (AttachmentsSelector)Application.Selectors.newInstance(AttachmentsSelector.class);
	}
	public static AttachmentsSelector newInstance(Integer recordLimit) {
		return (AttachmentsSelector)Application.Selectors.newInstance(AttachmentsSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static AttachmentsSelector newInstance(Set<SObjectField> fieldOverrides) {
		AttachmentsSelector selector = (AttachmentsSelector)Application.Selectors.newInstance(AttachmentsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static AttachmentsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		AttachmentsSelector selector = (AttachmentsSelector)Application.Selectors.newInstance(AttachmentsSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static AttachmentsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		AttachmentsSelector selector = (AttachmentsSelector)Application.Selectors.newInstance(AttachmentsSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static AttachmentsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		AttachmentsSelector selector = (AttachmentsSelector)Application.Selectors.newInstance(AttachmentsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Attachment.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		//NOTE: Do not add Body to this, see note about WITH_BODY selector option
		return new Set<SObjectField> {
			Attachment.Id, Attachment.Name, Attachment.ParentId, Attachment.CreatedDate, Attachment.ContentType, Attachment.BodyLength
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Attachment> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Attachment> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Attachment.Id + ' in :ids')).endConditions();
		return new Map<Id, Attachment>((List<Attachment>)Database.query(qb.toSoqlString()));
	}

	public virtual List<Attachment> selectByParentId(Set<Id> ids) {
		return selectByParentId(ids, new Set<Object>());
	}

	public virtual List<Attachment> selectByParentId(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Attachment.ParentId + ' in :ids')).endConditions();
		return (List<Attachment>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		// the Body shouldn't be selected out unless it's absolutely needed
		// hence why it's a selector option and not included in the field list
		if(selectorOptions.contains(Options.WITH_BODY)) {
			builder.addField(Attachment.Body);
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(selectorOptions), 'Owner');
		}

		return builder;
	}
	
	public override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('CreatedDate', 'Desc')};
	}

}