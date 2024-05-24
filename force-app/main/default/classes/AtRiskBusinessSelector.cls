/**
* @author Pratyush Chalasani
* @date 2023-04-21
* @group Selector
* @tag Selector
* @tag Profile SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2023-04-21 - Pratyush Chalasani - Created
* 2024-05-21 - Harry Wang - Added new option WITH_RELATED_ORGANISATION and fieldOverrides
*/
public virtual inherited sharing class AtRiskBusinessSelector extends ApplicationSelector {
	public enum Options {
		WITH_RELATED_ORGANISATION
	}

	public static AtRiskBusinessSelector newInstance() {
		return (AtRiskBusinessSelector)Application.Selectors.newInstance(AtRiskBusinessSelector.class);
	}

	public static AtRiskBusinessSelector newInstance(Set<SObjectField> fieldOverrides) {
		AtRiskBusinessSelector selector = (AtRiskBusinessSelector)Application.Selectors.newInstance(AtRiskBusinessSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	public static AtRiskBusinessSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return (AtRiskBusinessSelector) Application.Selectors.newInstance(AtRiskBusinessSelector.class)
				.setFieldOverrides(fieldOverrides);
	}

	public virtual override SObjectType getSObjectType() {
		return At_Risk_Business__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			At_Risk_Business__c.Id, At_Risk_Business__c.Name, At_Risk_Business__c.Legal_Entity_Name__c, At_Risk_Business__c.Scale__c, At_Risk_Business__c.Products_IDs__c, At_Risk_Business__c.Date_of_Revenue_Calculation__c, At_Risk_Business__c.Recalculate_Revenue__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<At_Risk_Business__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<At_Risk_Business__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(At_Risk_Business__c.Id + ' in :ids')).endConditions();
		return (List<At_Risk_Business__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_RELATED_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'Related_Organisation__r');
		}
		return builder;
	}
}