/**
* @author Ken McGuire
* @date 2023-05-29
* @group Tests
* @tag Selector
* @description Test class for ProductRelationshipSelector
* @changelog :
*/
@IsTest
private class ProductRelationshipsSelector_Test {
/**
	 * Test:
	 *Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ProductRelationshipsSelector selector = ProductRelationshipsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ProductRelationship__c\\b').matcher(soql).find(), 'Resulting query does not select from agreement lodgement point object');

		Test.stopTest();

	}

	/**
	 * Test:
	 *Ensures that the selectors QueryBuilder is querying the correct output including related fields
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<Product2> productList = new List<Product2>();
		Product2 parentProduct = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('International Bundle', TRUE);
		productList.add(parentProduct);

		Product2 replacementProduct = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Road Express - STE', TRUE);
		productList.add(replacementProduct);

		insert productList;

		Set<Id> productIdSet = new Set<Id> {parentProduct.id,replacementProduct.id};

		ProductRelationship__c relationship = new ProductRelationship__c(
		ParentProduct__c = parentProduct.id, 
		RelatedProduct__c = replacementProduct.id,
		Relationship__c = 'Replaces');
		insert relationship;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<ProductRelationship__c> results = ProductRelationshipsSelector.newInstance(1).selectByRelatedAndParent(productIdSet,productIdSet);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		List<ProductRelationship__c> results2 = ProductRelationshipsSelector.newInstance(1).selectByParent(productIdSet);
		System.assertEquals(1, results2.size(), 'Expected result size of 1');
		Test.stopTest();
	}
}