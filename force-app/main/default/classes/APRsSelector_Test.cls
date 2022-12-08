/**
 * @author Harry Wang
 * @group Tests
 * @tag Selector
 * @domain Sales
 * @description Test class for APRsSelector
 * @changelog
 * 2022-12-01 - Harry Wang - Created
 */
@IsTest
public with sharing class APRsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		APRsSelector selector = APRsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');

		selector = APRsSelector.newInstance(1);
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__c\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		APRsSelector selector = APRsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__C');

		selector = APRsSelector.newInstance(1, new Set<SObjectField>{
				APR__c.Id, APR__c.Legal_Entity_Name_LookUp__c
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');

		selector = APRsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				APR__c.SObjectType => new Set<SObjectField>{APR__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');

		selector = APRsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				APR__c.SObjectType => new Set<SObjectField>{APR__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');
		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the selector methods return expected matching result
	*/
	@IsTest
	public static void testSelectorIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Database.QueryLocator queryLocator = APRsSelector.newInstance().selectByAccountRelationshipQueryLocator(new Set<Object>{APRsSelector.Options.WITH_LEGAL_ENTITY});
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(queryLocator.getQuery()).find(), 'Resulting query does not select from APR__C');
		Test.stopTest();
	}
}