/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Selector
 * @tag Selector
 * @tag ICPS Articles
 * @domain ICPS
 * @description Selector class to provide a query interface to the ICPSArticle__c SObject.
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
public inherited sharing class ICPSArticlesSelector extends ApplicationSelector {

	public static ICPSArticlesSelector newInstance() {
		return (ICPSArticlesSelector)Application.Selectors.newInstance(ICPSArticlesSelector.class);
	}

	public static ICPSArticlesSelector newInstance(Integer recordLimit) {
		return (ICPSArticlesSelector)Application.Selectors.newInstance(ICPSArticlesSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static ICPSArticlesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ICPSArticlesSelector selector = (ICPSArticlesSelector)Application.Selectors.newInstance(ICPSArticlesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static ICPSArticlesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ICPSArticlesSelector selector = (ICPSArticlesSelector)Application.Selectors.newInstance(ICPSArticlesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static ICPSArticlesSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return (ICPSArticlesSelector)Application.Selectors.newInstance(ICPSArticlesSelector.class).setFieldOverrides(fieldOverrides);
	}

	protected override SObjectType getSObjectType() {
		return ICPSArticle__c.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				ICPSArticle__c.Id, ICPSArticle__c.Name, ICPSArticle__c.ConsignmentReference__c, ICPSArticle__c.DeclaredValue__c,
				ICPSArticle__c.Weight__c, ICPSArticle__c.PostageInsurance__c, ICPSArticle__c.ICPS__c
		};
	}
}