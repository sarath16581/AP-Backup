/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Case
 * @domain Core
 * @description Test Class covering CasesSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectbyId Method.
 * 2020-08-24 - Disha Kariya - Added tests for with Network and with Article
 * 2020-10-18 - Nathan Franklin - Added tests for selectByCaseNumber
 * 2021-03-02 - Ranjeewa Silva - Added tests for selectOpenCasesByCaseNumberOrReferenceId
 * 2021-08-09 - Seth Heang - Added selectByReferenceIdOrderByCreatedDate test coverage
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2021-11-26 - Ashapriya Gadi - Added test coverage for enum WITH_SINGLE_EMAIL_MESSAGE_ASC_ORDER
 * 2022-02-17 - Nathan Franklin - Refactored WITH_SINGLE_EMAIL_MESSAGE_ASC_ORDER
 * 2022-01-23 - Dattaraj Deshmukh - Added tests for 'CaseInvestigations__r' child records query.
 * 2022-02-13 - Dattaraj Deshmukh - Added test for StarTrack cases and case investigations in testSelectorIntegration method.
 * 2022-02-28 - Dattaraj Deshmukh - Added test for WITH_NETWORK_RESPONSE in 'testEnsureQueryBuilderProducesCorrectStringWithRelatedFields' method.
 * 2023-05-22 - Mahesh Parvathaneni - SF-961 - Added filter for the network lookup field
 * 2023-06-08 - Mahesh Parvathaneni - Added tests for WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER
 * 2023-12-04 - SteveL - Added tests for: getClosedCasesByAccountIdsNMonths, and getOpenCasesByAccountIds
 * 2024-04-25 - Vasu Gorakati - Added test method for selectCasesByReferenceId
 * 2024-08-12 - Ranjeewa Silva - Updated tests to verify selector options WITH_CONTACT_REQUESTS, WITH_IMPACTED_ARTICLES
 * 2024-10-08 - George Nguyen - added searchByReferenceIdPartial(...). This allows for partial matching of the Case.ReferenceId__c allowing And using search params
 */
@IsTest
public with sharing class CasesSelector_Test {

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		CasesSelector selector = CasesSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(CasesSelector.class, qa); 
		selector.selectByIdsAndRecordTypeIds(cases.keySet(), new Set<Id>(), new Set<Object>());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + Case.Id + ' IN :ids AND ' + Case.RecordTypeId + ' IN :recordTypeIds\\b').matcher(queryString).find(), 'Filters by ids and record type ids in query');
		
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

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

		CasesSelector selector = CasesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select from Case');

		qb = selector.newQueryBuilder(new Set<Object>{ CasesSelector.Options.WITH_RECORDTYPE });
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bRecordType\\b').matcher(soql).find(), 'Resulting query does not select from RecordType');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		CasesSelector selector = CasesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_CONTACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Contact\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Contact fields');

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE, CasesSelector.Options.WITH_CONTACT, CasesSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');
		System.assertEquals(true, Pattern.compile('(?is)Contact\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Contact fields');

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_SINGLE_EMAIL_MESSAGES_ASC_ORDER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Select.*?\\(Select.*?\\bfrom EmailMessages\\b.*?\\bLIMIT 1\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select single EmailMessage record');

		//Testing field override
		CasesSelector selectorNew = CasesSelector.newInstance(0, new Set<SObjectField>{Case.IssuePreviouslyReported__c});
		qb = selectorNew.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)IssuePreviouslyReported__c.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select IssuePreviouslyReported__c field: ' + soql);

		CasesSelector selectorNew2 = CasesSelector.newInstance(new Set<SObjectField>{Case.IssuePreviouslyReported__c});
		qb = selectorNew2.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)IssuePreviouslyReported__c.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select IssuePreviouslyReported__c field: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_ARTICLE, CasesSelector.Options.WITH_NETWORK});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)ArticleTest__r\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Article fields'+soql);
		System.assertEquals(true, Pattern.compile('(?is)Network__r\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Network fields'+soql);

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_CHILD_INVESTIGATIONS});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom CaseInvestigations__r\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(),
			'Resulting query does not select Case Investigation child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_NETWORK_RESPONSE});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Network_Responses1__r\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(),
			'Resulting query does not select Network Response child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Select.*?\\(Select.*?\\bfrom EmailMessages\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Incoming EmailMessage records');



		Map<SObjectType, Set<SObjectField>> overrideFields = new Map<SObjectType, Set<SObjectField>>();
		Set<SObjectField> caseFields = new Set<SObjectField>{Case.Id, Case.Call_Purpose__c};
		Set<SObjectField> billingAccountFields = new Set<SObjectField>{Billing_Account__c.BSC_Calc_Transfer_Queue__c};
		Set<SObjectField> accountFields = new Set<SObjectField>{Account.StarTrack_Customer_Stream__c};
		overrideFields.put(Case.SObjectType, caseFields);
		overrideFields.put(Billing_Account__c.SObjectType, billingAccountFields);
		overrideFields.put(Account.SObjectType, accountFields);
		CasesSelector selectorNew3 = CasesSelector.newInstance(0, overrideFields);		
		qb = selectorNew3.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_BILLINGACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Related_Billing_Account__r\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Billing Account fields'+soql);
		
		qb = selectorNew3.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Account\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Account fields'+soql);

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_CONTACT_REQUESTS});
		soql = qb.toSoqlString();
		Assert.isTrue(Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom ContactRequests\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select ContactRequest child records: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_IMPACTED_ARTICLES});
		soql = qb.toSoqlString();
		Assert.isTrue(Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom ImpactedArticles__r\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select ImpactedArticle child records: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test to ensure that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {

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

		Map<String, Object> searchParams;
		Set<Object> selectorOptions = new Set<Object>();

		CasesSelector selector = CasesSelector.newInstance(1);

		searchParams = new Map<String, Object>{
				'caseIds' => new Set<Id>{'500000000000000'},
				'recordTypeIds' => new Set<Id>{'012Bm000005SlxBIAS', '012900000015ftpAAA'},
				'relatedArticleIds' => new Set<Id>{'a1h000000000000000'},
				'isClosed' => false,
				'recordTypeDeveloperNames' => new Set<String> {SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME}
		};

		QueryBuilder builder = selector.newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditionsManager = builder.addConditions();

		String soql = selector.getSearchSoql(conditionsManager, searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bRecordTypeId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter RecordType.');
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter Case Id.');
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bArticleTest__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter article id : ' + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bRecordType.DeveloperName\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter record type developer name id : ' + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bIsClosed\\s*=\\s').matcher(soql).find(), 'Resulting query does not filter case IsClosed : ' + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
				'caseIds' => new Set<Id>{'500000000000000'}
		};

		builder = selector.newQueryBuilder(selectorOptions);
		conditionsManager = builder.addConditions();
		soql = selector.getSearchSoql(conditionsManager, searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter Case Id.');
		Assert.isFalse(Pattern.compile('(?ism)\\s+from Case\\s+where\\b.*?\\bRecordTypeId\\s+In\\b').matcher(soql).find(), 'Resulting query filter RecordType, but it should not.');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		// make sure an exception is thrown for invalid search parameters
		searchParams = new Map<String, Object>{
				'invalidParam' => new Set<String>{'somevalue'},
				'caseIds' => new Set<Id>{'500000000000000'}
		};

		try {
			builder = selector.newQueryBuilder(selectorOptions);
			conditionsManager = builder.addConditions();
			soql = selector.getSearchSoql(conditionsManager, searchParams, new Set<Object>(), false);
		} catch (Exception e) {
			// ensure correct type of exception thrown
			Assert.isInstanceOfType(e, ApplicationSelector.SelectorException.class);
		}

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		RecordType rt = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0];

		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		Article__c article = new Article__c();
		insert new List<SObject>{ contact, article };

		List<Case> cases = ApplicationTestDataFactory.getCases(5, new List<Id>{contact.Id, contact.Id, contact.Id, contact.Id, contact.Id}, false);
		cases[0].RecordTypeId = rt.Id;
		cases[0].Type = 'General Enquiry';
		cases[0].ArticleTest__c = article.Id;
		cases[1].RecordTypeId = rt.Id;
		cases[1].Type = 'General Enquiry';
		cases[1].ReferenceID__c = '5555000';
		//assigning ST case record type ID.
		cases[2].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId();

		cases[3].ReferenceID__c = 'TEST1234000001';
		cases[3].Type = 'Investigation';
		cases[3].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME).getRecordTypeId();

		cases[4].ReferenceID__c = 'TEST1234';
		cases[4].Type = 'Investigation';
		cases[4].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.CASE_RT_SSSW_DELIVERY).getRecordTypeId();

		insert cases;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Contact_Facility__c = 'MyNetwork';
		networks[0].Org_ID__c = '1234';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;
		insert networks;

		//insert CaseInvestigations
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases[2].Id, null, networks[0].Id, false);
		caseInvestigations[0].ReferenceID__c = '12314';
		caseInvestigations[1].ReferenceID__c = '54345';
		
		insert caseInvestigations;

		cases[0] = [Select Id, CaseNumber From Case Where Id = :cases[0].Id];

		Set<Id> caseIds = new Set<Id>{cases[0].Id, cases[1].Id};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

	   	CasesSelector selector = CasesSelector.newInstance(2);
		Map<Id, Case> results = selector.selectById(caseIds);
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByCaseNumber(new Set<String>{cases[0].CaseNumber});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(cases[0].Id, results.values()[0].Id);

		results = selector.selectById(caseIds, new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE, CasesSelector.Options.WITH_OWNER, CasesSelector.Options.WITH_CONTACT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');
		System.assertNotEquals(null, results.values()[0].RecordType, 'Results did not include RecordType object');
		System.assertNotEquals(null, results.values()[0].Contact, 'Results did not include Contact object');

		//https://success.salesforce.com/issues_view?id=a1p30000000SwHDAA0
		// Owner field is empty in this scenario
		// The owner fields are included in the query as per above tests, it's just the integration test does not produce the actual values
		// This problem is localised to only test classes
		// The above URL documents that only custom objects are affected... It appears the same is true for Case.... oddly, this works when selecting from Account
		//System.assertNotEquals(null, results.values()[0].Owner);

		results = selector.selectOpenCasesByCaseNumberOrReferenceId(new Set<String>{cases[0].CaseNumber}, new Set<Id>{rt.Id}, new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertNotEquals(null, results.values()[0].RecordType, 'Results did not include RecordType object');

		results = selector.selectByReferenceIdOrderByCreatedDate(new Set<String>{cases[1].ReferenceID__c});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		System.assertNotEquals(null, selector.getClosedCasesByAccountIds(new Set<Id>{account.Id}, new Set<Object>()), 'Invalid query locator');
		System.assertNotEquals(null, selector.getOpenCasesByAccountIds(new Set<Id>{account.Id}, new Set<Object>()), 'Invalid query locator');
		
		List<Case> listResults = selector.selectCasesByReferenceId(new Set<String>{cases[1].ReferenceID__c}, new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE});
		System.assertEquals(1, listResults.size(), 'Expected result size of 1');

		listResults = selector.selectByArticleId(new Set<Id>{ article.Id }, 'SSSWGeneralEnquiry', new Set<Object>());
		System.assertEquals(1, listResults.size(), 'Expected result size of 1');

		String referenceId = 'TEST1234';
		Map<String, Object> searchParams = new Map<String, Object>{
			'recordTypeDeveloperNames' => new Set<String> {SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME, SSSWConstants.CASE_RT_SSSW_DELIVERY}
		};
		Set<Object> selectorOptions = new Set<Object>();
		listResults = selector.searchByReferenceIdPartial(referenceId, searchParams, selectorOptions, true);
		System.assertEquals(2, listResults.size(), 'Expected result size of 2');

		Test.stopTest();

	}

	@IsTest
	static void testSelectByContactIdCaseHistoryQB() {
		CasesSelector selector = CasesSelector.newInstance();
		Set<Id> contactIds = new Set<Id> { fflib_IDGenerator.generate(Contact.getSObjectType()) };
		Set<Object> selectorOptions = new Set<Object>();
		QueryBuilder qb = selector.selectByContactIdCaseHistoryQB(contactIds, selectorOptions);
		String soql = qb.toSoqlString();

		Assert.isTrue(Pattern.compile('(?is)\\bWHERE ContactId IN :contactIds').matcher(soql).find(),  'Did not include the ContactId filter');
		Assert.isTrue(Pattern.compile('(?is)\\bORDER BY IsClosed ASC, LastModifiedDate DESC').matcher(soql).find(),  'Did not include the correct ORDER BY');
	}

	@IsTest
	static void testSelectByConsignmentTrackingNumberCaseHistoryQB() {
		CasesSelector selector = CasesSelector.newInstance();
		Set<String> contconsignmentTrackingNumbersactIds = new Set<String> { '123456' };
		Set<Object> selectorOptions = new Set<Object>();
		QueryBuilder qb = selector.selectByConsignmentTrackingNumberCaseHistoryQB(contconsignmentTrackingNumbersactIds, selectorOptions);
		String soql = qb.toSoqlString();

		Assert.isTrue(Pattern.compile('(?is)\\bWHERE ArticleTest__r.ArticleId__c IN :consignmentTrackingNumbers').matcher(soql).find(),  'Did not include the ArticleId__c filter');
		Assert.isTrue(Pattern.compile('(?is)\\bOR ArticleTest__r.ConsignmentTrackingNumber__c IN :consignmentTrackingNumbers').matcher(soql).find(),  'Did not include the ConsignmentTrackingNumber__c filter');
		Assert.isTrue(Pattern.compile('(?is)\\bORDER BY IsClosed ASC, LastModifiedDate DESC').matcher(soql).find(),  'Did not include the correct ORDER BY');
	}
	
}