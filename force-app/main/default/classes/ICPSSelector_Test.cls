/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Tests
 * @tag Selector
 * @tag ICPS Object
 * @domain ICPS
 * @description Test class for ICPSSelector
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
@IsTest
public with sharing class ICPSSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		ICPSSelector selector = ICPSSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPS__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		selector = ICPSSelector.newInstance(1);
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPS__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		ICPSSelector selector = ICPSSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPS__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		selector = ICPSSelector.newInstance(1, new Set<SObjectField>{
				ICPS__c.Id, ICPS__c.ABFAuthoriser__c
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPS__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		selector = ICPSSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				ICPS__c.SObjectType => new Set<SObjectField>{ICPS__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPS__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');

		selector = ICPSSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				ICPS__c.SObjectType => new Set<SObjectField>{ICPS__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ICPS__C\\b').matcher(soql).find(), 'Resulting query does not select from ICPS__C');
		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual search criteria
	 */
	@IsTest
	public static void testSearch() {
		// =====================================
		// Data Preparation
		// =====================================
		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(2, false);
		insert icpsList;

		List<ICPSArticle__c> icpsArticles = new List<ICPSArticle__c>();
		for (ICPS__c icps : icpsList) {
			icpsArticles.addAll(ICPSTestDataFactory.getICPSArticles(icps.Id, 2, false));
		}

		insert icpsArticles;

		List<ICPS__c> toUpdateICPS = new List<ICPS__c>();
		for (ICPS__c icps : icpsList) {
			icps.ABFReason__c = 'Released for Delivery';
			icps.ABFInstructionDate__c = Date.newInstance(2022, 2, 22);
			icps.ABFAuthoriser__c = 'Test ABF';
			toUpdateICPS.add(icps);
		}
		update toUpdateICPS;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> searchParams = new Map<String, Object>();

		// Search Scenario 1
		searchParams.put('reference', '8888');
		searchParams.put('recipient_name', 'recipient name');
		searchParams.put('article_number', '8888');
		searchParams.put('stored_location', 'Large');
		searchParams.put('status', 'delivered');
		searchParams.put('from_first_notice_date', '2022-02-22');
		searchParams.put('to_first_notice_date', '2022-02-22');
		searchParams.put('from_final_notice_date', '2022-02-22');
		searchParams.put('to_final_notice_date', '2022-02-22');
		List<ICPS__c> searchResults = ICPSSelector.newInstance().search(searchParams, true);
		System.assertEquals(0, searchResults.size(), 'Expected 0 results');

		// Search Scenario 2
		searchParams.clear();
		searchParams.put('stored_location', 'Bulk I');
		searchParams.put('from_holding_date', String.valueOf(Date.today().addDays(40)));
		searchParams.put('to_holding_date',  String.valueOf(Date.today().addDays(40)));
		searchParams.put('from_release_date', '2022-02-22');
		searchParams.put('to_release_date', '2022-02-22');
		searchResults = ICPSSelector.newInstance().search(searchParams, true);
		System.assertEquals(2, searchResults.size(), 'Expected 2 results');
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
		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(1, false);
		insert icpsList;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPS__c searchResult = ICPSSelector.newInstance().selectById(new Set<Id>{
				icpsList[0].Id
		})[0];
		System.assertEquals(icpsList[0].Id, searchResult.Id, 'Expected Id not matched');
		Test.stopTest();
	}
}