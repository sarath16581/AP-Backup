/* @author Seth Heang
 * @date 2022-06-28
 * @group Tests
 * @tag Product2
 * @domain Core
 * @description A very simple selector class that sits in the core domain
 * @changelog
 * 2022-06-28 - Seth Heang - Created
 * 2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
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
			Product2.Id, Product2.Name, Product2.SAP_Rating_Model__c, Product2.SAP_Rating_Group__c, Product2.SAP_Product_Code__c, Product2.APT_Lodgement_Zone_Code__c, Product2.APT_Apttus_Product_Classification__c 
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

	@AuraEnabled
	public static List<Product2> getAllProducts() {
		try {
			List<Product2> products = [SELECT Id, Name, ProductCode, APT_Product_Type__c, Product_Level_1__c, Product_Level_2__c, Product_Level_3__c, Product_Level_4__c FROM Product2 WHERE Product_Level_4__c != null AND IsActive = true ORDER BY Product_Level_4__c, Name];

			return products;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}