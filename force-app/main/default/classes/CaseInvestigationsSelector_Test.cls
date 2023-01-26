/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering CaseInvestigationsSelector
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Updated test method 'testSelectorIntegration' and added test for 'selectOpenCaseInvestigationsByCaseArticleNetworkId'.
 */

 @IsTest
 public with sharing class CaseInvestigationsSelector_Test {
	 
	 /**
	  * Test:
	  * Ensures that the selectors QueryBuilder is generating the correct output
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

		CaseInvestigationsSelector selector = CaseInvestigationsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom CaseInvestigation__c\\b').matcher(soql).find(), 'Resulting query does not select from CaseInvestigation__c');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(CaseInvestigation__c.Article__c) + '\\b').matcher(soql).find(), 'Article__c field does not exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(CaseInvestigation__c.Case__c) + '\\b').matcher(soql).find(), 'Case__c field does not exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(CaseInvestigation__c.Case__c) + '\\b').matcher(soql).find(), 'ReferenceID__c field does not exists in query');

		Test.stopTest();
 
	 }
 
	 /**
	  * Test:
	  * Executes a query to ensure it returns expected results
	  */
	 @IsTest
	 private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		//create test data
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;

		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		insert cases;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';
		insert networks;

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		caseInvestigations[0].Status__c = 'Open';
		insert caseInvestigations;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseInvestigationsSelector selector = CaseInvestigationsSelector.newInstance();
		Map<Id, CaseInvestigation__c> results = selector.selectById(new Set<Id> {caseInvestigations[0].Id});
		System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

		CaseInvestigationsSelector selectorLimit = CaseInvestigationsSelector.newInstance(1);
		Map<Id, CaseInvestigation__c> resultsLimit = selectorLimit.selectById(new Set<Id> {caseInvestigations[0].Id});
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

		CaseInvestigationsSelector selectorOpenCaseInvestion = CaseInvestigationsSelector.newInstance();
		Map<Id, CaseInvestigation__c> resultsOpenCaseInvestion = selectorOpenCaseInvestion.selectOpenCaseInvestigationsByCaseArticleNetworkId(new Set<Id> {cases[0].Id}, new Set<String> {articles[0].Name}, new Set<Id> {networks[0].Id});
		System.assertEquals(1, resultsOpenCaseInvestion.size(), 'Expected result size of 1');

		//passing options to select CI records with Articles, Networks and Case details
		Map<Id, CaseInvestigation__c> resultsInvestigationsByCases = selectorOpenCaseInvestion.selectOpenCaseInvestigationsByCaseIds(new Set<Id> {cases[0].Id}, 
																				new Set<Object> {CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																									CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																									CaseInvestigationsSelector.Options.WITH_NETWORKS});
		System.assertEquals(1, resultsInvestigationsByCases.size(), 'Expected result size of 1');
 
		Test.stopTest();
	 }
 }