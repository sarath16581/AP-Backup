/* @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Accounts
 * @domain Core
 * @description Test Class covering OpportunitiesSelector
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 * 2023-05-17 - Ranjeewa Silva - Updated tests to cover new selector option 'WITH_OVERLAY_SPLITS'
 * 2023-08-18 - Ranjeewa Silva - Updated tests to cover new selector options to include competitor, dsr and apttus contracts
 * 2023-10-26 - Mahesh Parvathaneni - Updated tests to cover selector option WITH_OPPORTUNITY_LINE_ITEMS
 * 2024-06-20 - Harry Wang - Added test for selectByAccountId with WITH_KEY_CONTACT option
 */

@IsTest
public with sharing class OpportunitiesSelector_Test {
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

		OpportunitiesSelector selector = OpportunitiesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select from opportunity');

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

		OpportunitiesSelector selector = OpportunitiesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
				OpportunitiesSelector.Options.WITH_RECORDTYPE,
				OpportunitiesSelector.Options.WITH_OWNER,
				OpportunitiesSelector.Options.WITH_OVERLAY_SPLITS,
				OpportunitiesSelector.Options.WITH_COMPETITORS,
				OpportunitiesSelector.Options.WITH_DEAL_SUPPORT_REQUESTS,
				OpportunitiesSelector.Options.WITH_APTTUS_CONTRACTS,
				OpportunitiesSelector.Options.WITH_OPPORTUNITY_LINE_ITEMS
		});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom opportunity\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom opportunitysplits\\b.*?\\).*?\\bfrom opportunity\\b').matcher(soql).find(),
				'Resulting query does not select OpportunitySplit child records: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom competitors__r\\b.*?\\).*?\\bfrom opportunity\\b').matcher(soql).find(),
				'Resulting query does not select Competitor__c child records: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom deal_support_request__r\\b.*?\\).*?\\bfrom opportunity\\b').matcher(soql).find(),
				'Resulting query does not select Deal_Support_Request__c child records: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Apttus__R00N50000001Xl0FEAS__r\\b.*?\\).*?\\bfrom opportunity\\b').matcher(soql).find(),
				'Resulting query does not select Apttus Contract (Apttus__APTS_Agreement__c) child records: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom OpportunityLineItems\\b.*?\\).*?\\bfrom opportunity\\b').matcher(soql).find(),
				'Resulting query does not select OpportunityLineItem child records: ' + soql);

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

		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert contact;

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		opportunityRecord.KeyContact__c = contact.Id;
		insert opportunityRecord;

		Set<Id> oppIds = new Set<Id>{
				opportunityRecord.Id
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		OpportunitiesSelector selector = OpportunitiesSelector.newInstance(1);
		Map<Id, opportunity> results = selector.selectById(oppIds);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		results = selector.selectById(oppIds, new Set<Object>{
				OpportunitiesSelector.Options.WITH_RECORDTYPE, OpportunitiesSelector.Options.WITH_OWNER
		});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertNotEquals(null, results.values()[0].RecordType, 'Results did not include RecordType object');

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{Opportunity.Id, Opportunity.Name, Opportunity.AccountId, Opportunity.KeyContact__c};
		selector = OpportunitiesSelector.newInstance(1, fieldOverrides);
		List<Opportunity> opportunities = selector.selectByAccountId(new Set<Id>{account.Id}, new Set<Object>{OpportunitiesSelector.Options.WITH_KEY_CONTACT});
		System.assertEquals(account.Id, opportunities[0].AccountId, 'Parent account Id not matched');
		System.assertEquals(contact.Id, opportunities[0].KeyContact__c, 'Key contact Id not matched');

		Test.stopTest();

	}
}