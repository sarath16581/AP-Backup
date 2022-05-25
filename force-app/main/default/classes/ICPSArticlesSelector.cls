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
				ICPSArticle__c.Weight__c, ICPSArticle__c.PostageInsurance__c, ICPSArticle__c.ICPS__c, ICPSArticle__c.ReceiverName__c,
				ICPSArticle__c.ReceiverEmail__c, ICPSArticle__c.ReceiverMobile__c, ICPSArticle__c.ReceiverStreetLine1__c,
				ICPSArticle__c.ReceiverStreetLine2__c, ICPSArticle__c.ReceiverCity__c, ICPSArticle__c.ReceiverPostalCode__c,
				ICPSArticle__c.ReceiverState__c,ICPSArticle__c.SenderName__c, ICPSArticle__c.SenderStreetLine1__c, ICPSArticle__c.SenderStreetLine2__c,
				ICPSArticle__c.SenderCity__c, ICPSArticle__c.SenderPostalCode__c, ICPSArticle__c.SenderState__c, ICPSArticle__c.SenderCountry__c,
				ICPSArticle__c.Contents__c
		};
	}

	/**
	* @description Return ICPS Article List by ICPS Id set
	*/
	public List<ICPSArticle__c> selectByICPSId(Set<Id> icpsIds) {
		QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(ICPSArticle__c.ICPS__c + ' IN :icpsIds')).endConditions();
		return (List<ICPSArticle__c>) Database.query(qb.toSoqlString());
	}
}