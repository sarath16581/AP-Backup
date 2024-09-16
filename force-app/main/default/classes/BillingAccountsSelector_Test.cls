/**
 * @author Nathan Franklin
 * @date 2020-07-10
 * @group Tests
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-10-18 - Nathan Franklin - Added tests for selectByAccountNumber.
 * 2021-08-09 - Seth Heang - Added selectByLikedNameOrderByName test coverage
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2022-06-01 - Seth Heang - Added selectByOrgId and WITH_PAYER_ACCOUNT_ID related list test coverage
 * 2023-07-10 - Mahesh Parvathaneni - Added tests for options FILTER_TYPE_NOT_IN_SBBA_CASH, FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT
 * 2023-10-27 - Harry Wang - Added tests for selectByLeaderAccountId and option FILTER_TYPE_FOLLOWER\
 * 2024-08-08 - Harry Wang - Added tests for selectByOrganisationABN and option FILTER_SOURCE_SYSTEM_SAP_ERP
 */
@IsTest
private class BillingAccountsSelector_Test {

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

		BillingAccountsSelector selector = BillingAccountsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom billing_account__c\\b').matcher(soql).find(), 'Resulting query does not select from Billing Account');

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

		BillingAccountsSelector selector = BillingAccountsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION,BillingAccountsSelector.Options.WITH_PAYER_ACCOUNT_ID});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Organisation__r\\..*?\\bfrom billing_account__c\\b').matcher(soql).find(), 'Resulting query does not select Organisation fields');
		System.assertEquals(true, Pattern.compile('(?ism)PAYER_ACCOUNT_ID__r\\..*?\\bfrom billing_account__c\\b').matcher(soql).find(), 'Resulting query does not select Payer Account Id fields');

		selector = BillingAccountsSelector.newInstance(BillingAccountsSelector.sortfieldAPIName, BillingAccountsSelector.sortOrder, new Set<SObjectField>());
		qb = selector.newQueryBuilder(new Set<Object>{BillingAccountsSelector.Options.FILTER_TYPE_NOT_IN_SBBA_CASH, BillingAccountsSelector.Options.FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom billing_account__c\\b.*Source_System__c\\s*!=\\s*\'PeopleSoft\'').matcher(soql).find(), 'Resulting query does not limit source system of PeopleSoft');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom billing_account__c\\b.*Type__c\\s*NOT IN\\s*').matcher(soql).find(), 'Resulting query does not limit Type__c field');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

		BillingAccountsSelector selector = BillingAccountsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Billing_Account__c.SObjectType => new Set<SObjectField>{Billing_Account__c.Name, Billing_Account__c.Source_System__c},
				Account.SObjectType => new Set<SObjectField>{Account.NumberOfEmployees}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION, AccountsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Organisation__r\\.RecordType\\..*?\\bfrom Billing_Account__c\\b').matcher(soql).find(), 'Resulting query does not select Organisation__r.RecordType fields: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Organisation__r\\.NumberOfEmployees.*?\\bfrom Billing_Account__c\\b').matcher(soql).find(), 'Resulting query does not select Organisation__r fields: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Organisation__r\\.Name.*?\\bfrom Billing_Account__c\\b').matcher(soql).find(), 'Resulting selects Organisation__r.Name but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Source_System__c.*?\\bfrom Billing_Account__c\\b').matcher(soql).find(), 'Resulting query does not select Source_System__c field: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom Billing_Account__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

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

		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountRecord.LEGACY_ID__c = '60000000';
		accountRecord.ABN__c = '1234567890';
		insert accountRecord;

		Account account2 =  ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account2;

		Billing_Account__c leaderBillingAccount = ApplicationTestDataFactory.getBillingAccounts(1, account2.Id, 'TEAM', false)[0];
		leaderBillingAccount.LEGACY_ID__c = '70000000';
		insert leaderBillingAccount;

		List<Billing_Account__c> billingAccounts = ApplicationTestDataFactory.getBillingAccounts(2, accountRecord.Id, 'SAP ERP', false);
		billingAccounts[0].Name = 'MYER Account';
		billingAccounts[1].Name = 'MYER Account';
		insert billingAccounts;

		Billing_Account__c billingAccount2 = ApplicationTestDataFactory.getBillingAccounts(1, account2.Id, 'TEAM', false)[0];
		billingAccount2.Name = 'Test Account';
		billingAccount2.LeaderAccount__c = leaderBillingAccount.Id;
		billingAccount2.Source_System__c = 'TEAM';
		billingAccount2.SAP_marked_for_deletion__c = false;
		billingAccount2.LEGACY_ID__c = '80000000';
		insert billingAccount2;

		Set<String> parentLegacyIdSet = new Set<String>();
		for(Billing_Account__c bill : billingAccounts){
			parentLegacyIdSet.add(bill.LEGACY_ID__c);
		}

		Map<Id, Billing_Account__c> mappedBillingAccounts = new Map<Id, Billing_Account__c>(billingAccounts);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BillingAccountsSelector selector = BillingAccountsSelector.newInstance(1, new Set<SObjectField>());
		Map<Id, Billing_Account__c> results = selector.selectById(mappedBillingAccounts.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectById(mappedBillingAccounts.keySet(), new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION});
		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results.values()[0].Organisation__r, 'Expected Organisation__r object');

		selector = BillingAccountsSelector.newInstance(2, new Set<SObjectField>());
		results = selector.selectByAccountNumber(new Set<String>{billingAccounts[0].LEGACY_ID__c});
		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertEquals(billingAccounts[0].Id, results.values()[0].Id, 'Result count was wrong');

		results = selector.selectByLikedNameOrderByName(billingAccounts[0].Name);
		System.assertEquals(2, results.size(), 'Result count was wrong');

		Map<Id, Billing_Account__c> resultsforBillingAccountwithNumbers = selector.selectByIdorAccountNumber(billingAccounts,parentLegacyIdSet);
		System.assertEquals(2, resultsforBillingAccountwithNumbers.size(), 'Result count was wrong');

		Map<Id, Billing_Account__c> selectByOrgIdResult = selector.selectByOrgId(new Set<Id>{accountRecord.Id});
		System.assertEquals(2, selectByOrgIdResult.size(), 'Result count was wrong');

		selectByOrgIdResult =  selector.selectByOrgId(new Set<Id>{accountRecord.Id}, new Set<Object>{BillingAccountsSelector.Options.FILTER_TYPE_NOT_IN_SBBA_CASH, BillingAccountsSelector.Options.FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT});
		System.assertEquals(2, selectByOrgIdResult.size(), 'Result count was wrong');

		List<Billing_Account__c> resultList = selector.selectByLeaderAccountId(new set<Id>{leaderBillingAccount.Id}, new Set<Object>{BillingAccountsSelector.Options.FILTER_TYPE_FOLLOWER, BillingAccountsSelector.Options.FILTER_ACTIVE});
		System.assertEquals(1, resultList.size(), 'Expecting one result');
		System.assertEquals('Test Account', resultList[0].Name, 'Name not matched');

		resultList = selector.selectByOrganisationABN(new Set<String>{'1234567890'}, new Set<Object>{BillingAccountsSelector.Options.FILTER_SOURCE_SYSTEM_SAP_ERP});
		System.assertEquals(2, resultList.size(), 'Expecting one result');
		System.assertEquals('MYER Account', resultList[0].Name, 'Name was wrong');
		Test.stopTest();
	}
}