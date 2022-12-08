/**
 * @author Harry Wang
 * @group Tests
 * @tag Selector
 * @domain Sales
 * @description Test class for SAPContractsSelector
 * @changelog
 * 2022-12-01 - Harry Wang - Created
 */
@IsTest
public with sharing class SAPContractsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		SAPContractsSelector selector = SAPContractsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(soql).find(), 'Resulting query does not select from APT_SAP_Contracts__c');

		selector = SAPContractsSelector.newInstance(1);
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(soql).find(), 'Resulting query does not select from APT_SAP_Contracts__c');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		SAPContractsSelector selector = SAPContractsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(soql).find(), 'Resulting query does not select from APT_SAP_Contracts__c');

		selector = SAPContractsSelector.newInstance(1, new Set<SObjectField>{
				APT_SAP_Contracts__c.Id
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(soql).find(), 'Resulting query does not select from APT_SAP_Contracts__c');

		selector = SAPContractsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				APT_SAP_Contracts__c.SObjectType => new Set<SObjectField>{APT_SAP_Contracts__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(soql).find(), 'Resulting query does not select from APT_SAP_Contracts__c');

		selector = SAPContractsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				APT_SAP_Contracts__c.SObjectType => new Set<SObjectField>{APT_SAP_Contracts__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(soql).find(), 'Resulting query does not select from APT_SAP_Contracts__c');
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
		Database.QueryLocator queryLocator = SAPContractsSelector.newInstance().selectByAccountRelationshipQueryLocator(new Set<Object>{SAPContractsSelector.Options.WITH_ORGANISATION});
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_SAP_Contracts__c\\b').matcher(queryLocator.getQuery()).find(), 'Resulting query does not select from APT_SAP_Contracts__c');
		Test.stopTest();
	}
}