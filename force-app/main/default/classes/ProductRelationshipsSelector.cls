/* @author Ken McGuire
 * @date 2023-05-29
 * @test ProductRelationshipsSelector_Test
 * @description simple selector class for product relationships
 * @changelog
 *  2023-05-29 - Ken McGuire - Created
 */
public virtual inherited sharing class ProductRelationshipsSelector extends ApplicationSelector {
	public enum Options {
		WITH_PRODUCT_RELATIONSHIP
	}

	public static ProductRelationshipsSelector newInstance() {
		return (ProductRelationshipsSelector) Application.Selectors.newInstance(ProductRelationshipsSelector.class);
	}

	public static ProductRelationshipsSelector newInstance(Integer recordLimit) {
		return (ProductRelationshipsSelector) Application.Selectors.newInstance(ProductRelationshipsSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return ProductRelationship__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
		ProductRelationship__c.ParentProduct__c, ProductRelationship__c.RelatedProduct__c
		// add more fields as needed
		};
	}

	public List<ProductRelationship__c> selectByRelatedAndParent(Set<Id> relatedProductsToInclude, Set<Id> parentProductsToInclude) {
		return selectByRelatedAndParent(relatedProductsToInclude, parentProductsToInclude, new Set<Object>());
	}

	public List<ProductRelationship__c> selectByRelatedAndParent(Set<Id> relatedProductsToInclude, Set<Id> parentProductsToInclude, Set<Object> selectorOptions) {
		Date todaysDate = Date.today();
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition('RelatedProduct__c in :relatedProductsToInclude'))
		.add(new QueryBuilder.SimpleCondition('ParentProduct__c in :parentProductsToInclude'))
		.add(new QueryBuilder.SimpleCondition('Relationship__c = \'Replaces\''))
		.add(new QueryBuilder.SimpleCondition('(EndDate__c = NULL OR EndDate__c > :todaysDate)'))
		.endConditions();
		return (List<ProductRelationship__c>) Database.query(qb.toSoqlString());
	}
    
  	public List<ProductRelationship__c> selectByParent(Set<Id> parentProductsToInclude) {
		return selectByParent(parentProductsToInclude, new Set<Object>());
	}

	public List<ProductRelationship__c> selectByParent(Set<Id> parentProductsToInclude, Set<Object> selectorOptions) {
		Date todaysDate = Date.today();
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition('ParentProduct__c in :parentProductsToInclude'))
		.add(new QueryBuilder.SimpleCondition('Relationship__c = \'Replaces\''))
		.add(new QueryBuilder.SimpleCondition('(EndDate__c = NULL OR EndDate__c > :todaysDate)'))
		.endConditions();
		return (List<ProductRelationship__c>) Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_PRODUCT_RELATIONSHIP)) {
			builder.addRelatedFields(ProductsSelector.newInstance().newQueryBuilder(), 'ProductRelationship__c');
		}

		return builder;
	}
}