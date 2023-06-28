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
*/
public virtual inherited sharing class AtRiskBusinessSelector extends ApplicationSelector {
	public enum Options {
	}
	public static AtRiskBusinessSelector newInstance() {
		return (AtRiskBusinessSelector)Application.Selectors.newInstance(AtRiskBusinessSelector.class);
	}

	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*						  This approach removes data consistency and prevents possible caching of results
	*/
	public static AtRiskBusinessSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		AtRiskBusinessSelector selector = (AtRiskBusinessSelector)Application.Selectors.newInstance(AtRiskBusinessSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	public virtual override SObjectType getSObjectType() {
		return At_Risk_Business__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			At_Risk_Business__c.Id, At_Risk_Business__c.Name, At_Risk_Business__c.Legal_Entity_Name__c, At_Risk_Business__c.Scale__c, At_Risk_Business__c.Product_IDs__c, At_Risk_Business__c.Date_of_Revenue_Calculation__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<At_Risk_Business__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(At_Risk_Business__c.Id + ' in :ids')).endConditions();
		return (List<At_Risk_Business__c>)Database.query(qb.toSoqlString());
	}
}