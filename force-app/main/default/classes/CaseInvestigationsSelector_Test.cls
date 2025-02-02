/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering CaseInvestigationsSelector
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Updated test method 'testSelectorIntegration' and added test for 'selectOpenCaseInvestigationsByCaseArticleNetworkId'.
 * 									Replaced Status__c value from 'Open' to 'New'.
 * 2023-01-31 - Mahesh Parvathaneni - Updated tests for selectNetworkMilestoneViolatedOpenCaseInvestigations
 * 2023-02-22 - Dattaraj Deshmukh	- Updated methods by passing 'stCaseInvestigationRecordTypeId' to selector methods.
 * 2023-02-21 - Mahesh Parvathaneni - Added recordtype filter for selector selectOpenCaseInvestigationsByCaseArticleNetworkId
 * 2023-02-28 - Dattaraj Deshmukh 	- Added tests for 'WITH_FEEDS' options.
 * 2023-03-10 - Dattaraj Deshmukh   - Added tests for 'selectOpenCaseInvestigationsByNetworkIdOwnerId' and 'selectOpenCaseInvestigationsByNetworkIdAndCaseSLA'.
 * 2023-03-16 - Dattaraj Deshmukh   - Added tests for 'selectOpenCaseInvestigationsByNetworkIdAndClosedCases'.
 * 2023-05-22 - Mahesh Parvathaneni - SF-961 - Added filter for the network lookup field
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

		// Testing field overrides passing in field overrides for CaseInvestigation__c with record limit
		selector = CaseInvestigationsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
			User.getSObjectType() => new Set<SObjectField>{User.Name}
		});
		qb = selector.newQueryBuilder(new Set<Object>{CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS});
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom CaseInvestigation__c\\b').matcher(soql).find(), 'Resulting query does not select User fields');

		// Testing field overrides passing in field overrides for CaseInvestigation__c without record limit
		selector = CaseInvestigationsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
			User.getSObjectType() => new Set<SObjectField>{User.Name}
		});
		qb = selector.newQueryBuilder(new Set<Object>{CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS, CaseInvestigationsSelector.Options.WITH_FEEDS});
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom CaseInvestigation__c\\b').matcher(soql).find(), 'Resulting query does not select User fields');
		System.assertEquals(true, 
		Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Feeds\\b.*?\\).*?\\bfrom CaseInvestigation__c\\b').matcher(soql).find(),
			'Resulting query does not select FeedItem records: ' + soql);


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

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName()
		.get('StarTrack_MyNetwork').getRecordTypeId();

		//create test data
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		account.ServiceSLA__c = 'Enterprise';
		insert account;

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;

		List<Case> cases = ApplicationTestDataFactory.getCases(2, false);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		cases[0].AccountId = account.Id;
		cases[1].ArticleTest__c = articles[0].Id;
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		cases[1].AccountId = account.Id;
		cases[1].ResolutionCode__c = 'sample resolution';
		insert cases;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';
		networks[0].Contact_Facility__c = 'MyNetwork';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;
		insert networks;

		List<Facility_User__c> networkUsers = ApplicationTestDataFactory.getNetworkUsers(1, networks[0].Id, UserInfo.getUserId(), false);
		insert networkUsers;
		

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		caseInvestigations[0].Status__c = 'New';
		caseInvestigations[0].RecordTypeId = stCaseInvestigationRecordTypeId;

		List<CaseInvestigation__c> caseInvestigationsWithClosedCase = ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[0], networks[0].Id, false);
		caseInvestigationsWithClosedCase[0].Status__c = 'New';
		caseInvestigationsWithClosedCase[0].Case__c = cases[1].Id;
		caseInvestigationsWithClosedCase[0].RecordTypeId = stCaseInvestigationRecordTypeId;

		insert (new List<CaseInvestigation__c>{caseInvestigations[0], caseInvestigationsWithClosedCase[0]});

		//update NetworkMilestoneNextViolationDatetime__c
		caseInvestigations[0].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addMinutes(-10);
		update caseInvestigations;

		
		//perfoming an update on Case, as IsClosed field is NOT set to true when a Case is created with 'Closed' status.
		update (new Case(Id = cases[1].Id, Status='Closed'));//All CI records against closed case should marked as UPDATED ON PORTAL(ONLY).

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
		Map<Id, CaseInvestigation__c> resultsOpenCaseInvestion = selectorOpenCaseInvestion.selectOpenCaseInvestigationsByCaseArticleNetworkId(new Set<Id> {cases[0].Id}, new Set<String> {articles[0].Name}, new Set<Id> {networks[0].Id}, new Set<Id>{stCaseInvestigationRecordTypeId});
		System.assertEquals(1, resultsOpenCaseInvestion.size(), 'Expected result size of 1');

		//passing options to select CI records with Articles, Networks and Case details
		Map<Id, CaseInvestigation__c> resultsInvestigationsByCases = selectorOpenCaseInvestion.selectOpenCaseInvestigationsByCaseIds(new Set<Id> {cases[0].Id}, 
																				new Set<Id>{stCaseInvestigationRecordTypeId}, 
																				new Set<Object> {CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																									CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																									CaseInvestigationsSelector.Options.WITH_NETWORKS});
		System.assertEquals(1, resultsInvestigationsByCases.size(), 'Expected result size of 1');

		Map<Id, CaseInvestigation__c> resultsInvestigationsByNetworks = selector.selectOpenCaseInvestigationsByNetworkId(new Set<Id> {networks[0].Id}, 
																				new Set<Id>{stCaseInvestigationRecordTypeId}, 
																				new Set<Object> {CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																									CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																									CaseInvestigationsSelector.Options.WITH_NETWORKS});
		System.assertEquals(2, resultsInvestigationsByNetworks.size(), 'Expected result size of 2');
 

		CaseInvestigationsSelector selectorQueryLocator = CaseInvestigationsSelector.newInstance();
		Database.QueryLocator ciQueryLocator = selectorQueryLocator.selectNetworkMilestoneViolatedOpenCaseInvestigations(Datetime.now(), new Set<Id>{stCaseInvestigationRecordTypeId}, new Set<Object>());
		System.assertNotEquals(null, ciQueryLocator, 'Expected a valid query locator but got null');


		Map<Id, CaseInvestigation__c> resultsInvestigationsByNetworksAndOwner = selector.selectOpenCaseInvestigationsByNetworkIdOwnerId(new Set<Id> {networks[0].Id}, 
																				new Set<Id>{stCaseInvestigationRecordTypeId}, new Set<Id>{UserInfo.getUserId()},
																				new Set<Object> {CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																									CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																									CaseInvestigationsSelector.Options.WITH_NETWORKS});
		System.assertEquals(2, resultsInvestigationsByNetworksAndOwner.size(), 'Expected result size of 2');

		Map<Id, CaseInvestigation__c> resultsInvestigationsByNetworksAndSLA = selector.selectOpenCaseInvestigationsByNetworkIdAndCaseSLA(new Set<Id> {networks[0].Id}, 
																				new Set<Id>{stCaseInvestigationRecordTypeId}, 'Enterprise',
																				new Set<Object> {CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																									CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																									CaseInvestigationsSelector.Options.WITH_NETWORKS});
		System.assertEquals(2, resultsInvestigationsByNetworksAndSLA.size(), 'Expected result size of 2');

		Map<Id, CaseInvestigation__c> resultsInvestigationsByNetworksAndClosedCase = selector.selectOpenCaseInvestigationsByNetworkIdAndClosedCases(new Set<Id> {networks[0].Id}, 
																				new Set<Id>{stCaseInvestigationRecordTypeId}, 
																				new Set<Object> {CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																									CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																									CaseInvestigationsSelector.Options.WITH_NETWORKS});
		System.assertEquals(1, resultsInvestigationsByNetworksAndClosedCase.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}