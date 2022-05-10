/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Tests
 * @tag Selector
 * @tag ICPS Article Object
 * @domain ICPS
 * @description Test class for ICPSArticlesSelector
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
@IsTest
public with sharing class ICPSArticlesSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		ICPSArticlesSelector selector = ICPSArticlesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPSArticle__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		selector = ICPSArticlesSelector.newInstance(1);
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPSArticle__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		ICPSArticlesSelector selector = ICPSArticlesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPSArticle__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPSArticle__C');

		selector = ICPSArticlesSelector.newInstance(1, new Set<SObjectField>{
				ICPSArticle__c.Id, ICPSArticle__c.ICPS__c
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPSArticle__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPSArticle__C');

		selector = ICPSArticlesSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				ICPSArticle__c.SObjectType => new Set<SObjectField>{ICPSArticle__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPSArticle__c\\b').matcher(soql).find(), 'Resulting query does not select from ICPSArticle__c');

		selector = ICPSArticlesSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				ICPSArticle__c.SObjectType => new Set<SObjectField>{ICPSArticle__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPSArticle__c\\b').matcher(soql).find(), 'Resulting query does not select from ICPSArticle__c');
		Test.stopTest();
	}
}