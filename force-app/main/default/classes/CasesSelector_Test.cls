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
 * 2023-12-04 - SteveL - Added test for getClosedCasesByAccountIdsNMonths
 * 2023-12-04 - SteveL - Added test for getOpenCasesByAccountIds
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
		insert contact;

		List<Case> cases = ApplicationTestDataFactory.getCases(3, new List<Id>{contact.Id, contact.Id, contact.Id}, false);
		cases[0].RecordTypeId = rt.Id;
		cases[0].Type = 'General Enquiry';
		cases[1].RecordTypeId = rt.Id;
		cases[1].Type = 'General Enquiry';
		cases[1].ReferenceID__c = '5555000';
		//assigning ST case record type ID.
		cases[2].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId();
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

		Test.stopTest();

	}
}