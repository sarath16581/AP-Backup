/**
 * @author Ranjeewa Silva
 * @group Selector
 * @tag Selector
 * @tag Sharing
 * @domain Core
 * @description Generic selector class for accessing Share objects of all custom objects and standard objects that support
 *              the model specified in:
 *              https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_associated_objects_share.htm
 *
 *              IMPORTANT: As per the above document below objects are not following the standard model and not supported by
 *              this selector. Please create specific selector classes for accessing these share types.
 *                  - AccountShare
 *                  - AssetShare
 *                  - CampaignShare
 *                  - CaseShare
 *                  - ContactShare
 *                  - IndividualShare
 *                  - LeadShare
 *                  - OpportunityShare
 *                  - UserShare
 *
 * @changelog
 * 2022-12-02 - Ranjeewa Silva - Created
 */
public virtual inherited sharing class SObjectSharesSelector extends ApplicationSelector {

	// share sobject supported by this selector instance
	protected SObjectType shareSObjectType = null;
	// list of fields for the share sobject type supported by this selector instance
	protected Set<SObjectField> shareSObjectFields = new Set<SObjectField>();

	public static SObjectSharesSelector newInstance(SobjectType shareSObjectType) {
		return (((SObjectSharesSelector)Application.Selectors.newInstance(SObjectSharesSelector.class)).setShareSobjectType(shareSObjectType));
	}

	public static SObjectSharesSelector newInstance(SobjectType shareSObjectType, Integer recordLimit) {
		return (((SObjectSharesSelector)Application.Selectors.newInstance(SObjectSharesSelector.class).setLimit(recordLimit)).setShareSobjectType(shareSObjectType));
	}

	public static SObjectSharesSelector newInstance(SobjectType shareSObjectType, Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SObjectSharesSelector selector = ((SObjectSharesSelector) Application.Selectors.newInstance(SObjectSharesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides)).setShareSobjectType(shareSObjectType);
		return selector;
	}

	public SObjectSharesSelector setShareSobjectType(SObjectType shareSObjectType) {
		this.shareSObjectType = shareSObjectType;
		this.shareSObjectFields = new Set<SObjectField>(shareSObjectType.getDescribe().fields.getMap().values());
		return this;
	}

	/**
	 * Query share records based on parentIds and rowCause
	 * @param parentIds set of parent id's for filtering
	 * @param rowCauses row causes for filtering
	 *
	 * @return list of share records.
	 */
	public virtual List<SObject> selectByParentIdAndRowCause(Set<Id> parentIds, Set<String> rowCauses) {
		return selectByParentIdAndRowCause(parentIds, rowCauses, new Set<Object>());
	}

	/**
	 * Query share records based on parentIds and rowCause
	 * @param parentIds set of parent id's for filtering
	 * @param rowCauses row causes for filtering
	 * @param selectorOptions selector options
	 *
	 * @return
	 */
	public virtual List<SObject> selectByParentIdAndRowCause(Set<Id> parentIds, Set<String> rowCauses, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(getSObjectType() + '.ParentId in :parentIds'))
				.add(new QueryBuilder.SimpleCondition(getSObjectType() + '.RowCause in :rowCauses'))
				.endConditions();
		return Database.query(qb.toSoqlString());
	}

	protected override SObjectType getSObjectType() {
		return this.shareSObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return shareSObjectFields;
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		// Application selector default ordering is by 'CreatedDate', which doesn't exist for Share objects.
		// order by LastModifiedDate instead
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('LastModifiedDate', 'Desc')};
	}
}