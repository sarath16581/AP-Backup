/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Case SObject
 * @domain Core
 * @description Test Class covering SSSWCasesSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-08-24 - Disha Kariya - Updated with test for field override
 * 2022-02-10 - Alex Volkov - Added test for selectCasesEligibleForReopenByOwnerAndDate method
 * 2023-05-30 - StephenL - Added test for getCasesByCreatedByUserOrAPCN
 * 2024-06-25 - Mona Raghav - REQ3564142 - Test coverage for selectCasesByCreatedByUserAndCaseOrigin method, for case origin logic
 * 2024-06-28 - Mona Raghav - Method name updated from selectCasesByCreatedByUserAndCaseOrigin to selectCasesByCreatedByUserOrAPCNAndCaseOrigin
 */
@IsTest
public with sharing class SSSWCasesSelector_Test {

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

		SSSWCasesSelector selector = SSSWCasesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		// make sure there is RecordType.DeveloperName condition
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom case\\b.*?RecordType\\.DeveloperName in').matcher(soql).find(), 'Resulting query does not contain RecordType.DeveloperName filter');

		//Test for field override
		selector = SSSWCasesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Case.SObjectType => new Set<SObjectField>{Case.IssuePreviouslyReported__c, Case.Id},
				Network__c.SObjectType => new Set<SObjectField>{Network__c.Fax_Number__c, Network__c.Id}
		});
		qb = selector.newQueryBuilder(new Set<Object>{CasesSelector.Options.WITH_NETWORK});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)IssuePreviouslyReported__c.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select IssuePreviouslyReported__c field: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Network__r\\.Fax_Number__c.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select Network__r fields: ' + soql);

		selector = SSSWCasesSelector.newInstance(0, new Set<SObjectField>{Case.IssuePreviouslyReported__c, Case.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)IssuePreviouslyReported__c.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select IssuePreviouslyReported__c field: ' + soql);

		selector = SSSWCasesSelector.newInstance(new Set<SObjectField>{Case.IssuePreviouslyReported__c, Case.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)IssuePreviouslyReported__c.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select IssuePreviouslyReported__c field: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{SSSWCasesSelector.Options.WITH_NETWORK_RESPONSE, SSSWCasesSelector.Options.WITH_ARTICLE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom network_responses1__r\\b.*?\\).*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Network_Responses1__r child records: '+soql);
		System.assertEquals(true, Pattern.compile('(?ism)ArticleTest__r\\.RecordTypeId.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query does not select ArticleTest__r fields: ' + soql);

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
		Id vHoldQueueId = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{SSSWConstants.QUEUE_NAME_REOPEN_Q}).values()[0].Id;

		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert contact;

		List<Case> cases = ApplicationTestDataFactory.getCases(3, new List<Id>{contact.Id, contact.Id, contact.Id}, false);
		cases[0].ReferenceID__c = '12345';
		cases[0].RecordTypeId = rt.Id;
		cases[0].Type = 'General Enquiry';
		cases[1].ReferenceID__c = '123456';
		cases[1].RecordTypeId = rt.Id;
		cases[1].Type = 'General Enquiry';
		cases[2].Type = 'General Enquiry';
		cases[2].Case_Reopen_Date__c = System.now();
		cases[2].OwnerId = vHoldQueueId;
		cases[2].RecordTypeId = rt.Id;
		cases[2].Origin = 'Direct Email';
		insert cases;
		cases[1].ParentId = cases[0].Id;
		update cases[1];

//		Set<Id> caseIds = new Set<Id>{cases[0].Id, cases[1].Id};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SSSWCasesSelector selector = SSSWCasesSelector.newInstance();
		Map<Id, Case> results = selector.selectByReferenceIdPartial('1234');
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		selector = SSSWCasesSelector.newInstance(1);
		results = selector.selectOpenCasesByReferenceId(new Set<String>{'123456'});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = SSSWCasesSelector.newInstance();
		Integer recordCount = selector.countOpenCasesByReferenceId(new Set<String>{'12345'});
		System.assertEquals(1, recordCount, 'Expected result size of 1');

		selector = SSSWCasesSelector.newInstance();
		results = selector.selectChildCasesByParent(new Set<Id>{cases[0].Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = SSSWCasesSelector.newInstance();
		Date vReopenUpToDate = System.today().addDays(1);
		//Test record returning mode
		results = (Map<Id, Case>)selector.selectCasesEligibleForReopenByOwnerAndDate(new Set<String>{vHoldQueueId}, Datetime.newInstance(vReopenUpToDate.year(), vReopenUpToDate.month(), vReopenUpToDate.day()), new Set<Object>());
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		//Test query locator mode
		selector = SSSWCasesSelector.newInstance();
		System.assertNotEquals(null, (Database.QueryLocator)selector.selectCasesEligibleForReopenByOwnerAndDate(new Set<String>{vHoldQueueId}, Datetime.newInstance(vReopenUpToDate.year(), vReopenUpToDate.month(), vReopenUpToDate.day()), new Set<Object>{SSSWCasesSelector.Options.RETURN_QUERY_LOCATOR}), 'Invalid query locator');

		selector = SSSWCasesSelector.newInstance();
		results = (Map<Id, Case>)selector.selectCasesByCreatedByUserOrAPCNAndCaseOrigin(UserInfo.getUserId(),null, new Set<Object>{SSSWCasesSelector.Options.WITH_CONTACT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		Test.stopTest();
	}
}