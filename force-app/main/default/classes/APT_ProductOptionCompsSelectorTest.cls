/**
* @author Seth Heang
* @date 2022-09-19
* @group Tests
* @tag Selector
* @tag Apttus_Config2__ProductOptionComponent__c SObject
* @domain Apttus
* @description A very simple selector class for Apttus_Config2__ProductOptionComponent__c
* @changelog
* 2022-09-19 - Seth Heang - Created
*/
@IsTest
private with sharing class APT_ProductOptionCompsSelectorTest {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedList() {

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

		APT_ProductOptionCompsSelector selector = APT_ProductOptionCompsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Config2__ProductOptionComponent__c\\b').matcher(soql).find(), 'Resulting query does not select from product option component object');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is querying the correct output including related fields
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Product2 parentProduct = ApplicationTestDataFactory.getPSRProducts(1, false)[0];
		insert parentProduct;

		Product2 optionProduct = ApplicationTestDataFactory.getPSRProducts(1, false)[0];
		insert optionProduct;

		Apttus_Config2__ProductOptionComponent__c productOptComp = APT_TestDataFactory.getAPTProductOptionComponentRecord(1, parentProduct.Id, optionProduct.Id, false)[0];
		insert productOptComp;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Query Agreement Lodgement Point based on Apttus Contract Id
		List<Apttus_Config2__ProductOptionComponent__c> results = new List<Apttus_Config2__ProductOptionComponent__c>(
			APT_ProductOptionCompsSelector.newInstance(1).selectByParentProductId(
			new Set<id>{parentProduct.Id}));
			
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		Test.stopTest();
	}
}