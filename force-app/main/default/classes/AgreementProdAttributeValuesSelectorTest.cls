/**
* @author Seth Heang
* @date 2021-08-15
* @group Tests
* @tag Selector
* @tag Apttus_CMConfig__AgreementProductAttributeValue__c SObject
* @domain Apttus
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-08-15 - Seth Heang - Created
*/
@IsTest
private with sharing class AgreementProdAttributeValuesSelectorTest {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
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

		AgreementProductAttributeValuesSelector selector = AgreementProductAttributeValuesSelector.newInstance();
		AgreementProductAttributeValuesSelector.newInstance(1, new Map<Schema.SObjectType,Set<Schema.SObjectField>>{
			Apttus_CMConfig__AgreementProductAttributeValue__c.SObjectType => new Set<SObjectField>{Apttus_CMConfig__AgreementProductAttributeValue__c.Name
			}});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_CMConfig__AgreementProductAttributeValue__c\\b').matcher(soql).find(), 'Resulting query does not select from agreement product attribute value object');

		Test.stopTest();

	}
}