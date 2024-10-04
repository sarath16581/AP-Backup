/**
 * @description A selector class for the `ConversationContextEntry` SObject.
 * @changelog
 * 2024-09-02 - Marcel HK - Created
 */
public virtual inherited sharing class ConversationContextEntrySelector extends ApplicationSelector {
	public static ConversationContextEntrySelector newInstance() {
		return (ConversationContextEntrySelector) Application.Selectors.newInstance(ConversationContextEntrySelector.class);
	}

	public static ConversationContextEntrySelector newInstance(Integer recordLimit) {
		return (ConversationContextEntrySelector) Application.Selectors.newInstance(ConversationContextEntrySelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ConversationContextEntrySelector newInstance(Set<SObjectField> fieldOverrides) {
		ConversationContextEntrySelector selector = (ConversationContextEntrySelector) Application.Selectors.newInstance(ConversationContextEntrySelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @description Returns the SObject type for this selector.
	 *
	 * @return the `ConversationContextEntry` SObjectType.
	 */
	public override SObjectType getSObjectType() {
		return ConversationContextEntry.getSObjectType();
	}

	/**
	 * @description Returns a list of fields to include the the query by default.
	 *
	 * @return a list of fields.
	 */
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			ConversationContextEntry.Id,
			ConversationContextEntry.ParentId,
			ConversationContextEntry.CustomDetailContextKey,
			ConversationContextEntry.CustomDetailContextValue
		};
	}

	/**
	 * @description Get all records for a specified ParentId (e.g. `LiveChatTranscript`).
	 *
	 * @param parentId - The Parent Id to get records for.
	 * @return a Map of `ConversationContextEntry` objects.
	 */
	public Map<Id, ConversationContextEntry> selectByParentId(Id parentId) {
		return selectByParentId(parentId, new Set<Object>());
	}

	/**
	 * @description Get all records for a specified ParentId (e.g. `LiveChatTranscript`).
	 *
	 * @param parentId - The Parent Id to get records for.
	 * @param selectorOptions - Specify any selector options for the query.
	 * @return a Map of `ConversationContextEntry` objects.
	 */
	public Map<Id, ConversationContextEntry> selectByParentId(Id parentId, Set<Object> selectorOptions) {
		QueryBuilder qb = getSelectByParentIdQuery(parentId, selectorOptions);
		return new Map<Id, ConversationContextEntry>((List<ConversationContextEntry>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Create a new instance of the `QueryBuilder` class and configure selector options.
	 *
	 * @param selectorOptions - Specify any selector options for the query.
	 * @return an instance of the `QueryBuilder` class.
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}

	/**
	 * @description Create the `QueryBuilder` for the `selectByParentId` method.
	 *
	 * @param parentId - The Parent Id to get records for.
	 * @param selectorOptions - Specify any selector options for the query.
	 * @return an instance of the `QueryBuilder` that is ready to be executed.
	 */
	@TestVisible
	private QueryBuilder getSelectByParentIdQuery(Id parentId, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.CompareCondition(ConversationContextEntry.ParentId).eq(parentId)).endConditions();

		return qb;
	}
}