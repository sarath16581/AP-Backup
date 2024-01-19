/* @author Seth Heang
 * @date 2022-06-28
 * @group Tests
 * @tag Product2
 * @domain Core
 * @description A very simple selector class that sits in the core domain
 * @changelog
 * 2022-06-28 - Seth Heang - Created
 * 2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
 * 2023-04-25 - Yatika Bansal - Added APT_Product_Lines__c field
 * 2023-04-21 - Pratyush Chalasani - Added selectByIdOrderByName
 */
public with sharing class ProductsSelector extends ApplicationSelector{
	public enum Options {
	}
	public static ProductsSelector newInstance() {
		return (ProductsSelector)Application.Selectors.newInstance(ProductsSelector.class);
	}

	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*						  This approach removes data consistency and prevents possible caching of results
	*/
	public static ProductsSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		ProductsSelector selector = (ProductsSelector)Application.Selectors.newInstance(ProductsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Product2.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Product2.Id, Product2.Name, Product2.SAP_Rating_Model__c, Product2.SAP_Rating_Group__c, Product2.SAP_Product_Code__c, Product2.APT_Lodgement_Zone_Code__c, Product2.APT_Apttus_Product_Classification__c,
				Product2.APT_Product_Lines__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Product2> selectByIdOrderByName(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Product2.Id + ' in :ids')).endConditions();

		qb.addOrderAsc(Product2.Product_Level_4__c);
		qb.addOrderAsc(Product2.Name);

		return (List<Product2>)Database.query(qb.toSoqlString());
	}
}