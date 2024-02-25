/**
 * @author Harry Wang
 * @group Tests
 * @tag Selector
 * @domain Sales
 * @description Test class for APRsSelector
 * @changelog
 * 2022-12-01 - Harry Wang - Created
 */
@IsTest
public with sharing class APRsSelector_Test {
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

		APRsSelector selector = APRsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		APRsSelector selector = APRsSelector.newInstance(1, new Set<SObjectField>{
				APR__c.Id, APR__c.Legal_Entity_Name_LookUp__c
		});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');
		System.assertEquals(false, Pattern.compile('(?ism)RecordTypeId\\b.*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting selects RecordTypeId but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Legal_Entity_Name_LookUp__c\\b.*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select Legal_Entity_Name_LookUp__c field: ' + soql);

		selector = APRsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				APR__c.SObjectType => new Set<SObjectField>{APR__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');
		System.assertEquals(false, Pattern.compile('(?ism)Legal_Entity_Name_LookUp__c\\b.*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting selects Legal_Entity_Name_LookUp__c but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Id\\b.*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select Id field: ' + soql);

		selector = APRsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				APR__c.SObjectType => new Set<SObjectField>{APR__c.Id, APR__c.Legal_Entity_Name_LookUp__c}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select from APR__c');
		System.assertEquals(false, Pattern.compile('(?ism)RecordTypeId\\b.*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting selects RecordTypeId but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Legal_Entity_Name_LookUp__c\\b.*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select Legal_Entity_Name_LookUp__c field: ' + soql);

		Test.stopTest();
	}

	/**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output with related fields
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

		APRsSelector selector = APRsSelector.newInstance(0);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{APRsSelector.Options.WITH_ORGANISATION});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Legal_Entity_Name_LookUp__r\\..*?\\bfrom APR__C\\b').matcher(soql).find(), 'Resulting query does not select Organisation fields');

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
		MockUtility.disableTriggerExecution();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, false);
		parentAccounts[0].LEGACY_ID__c = '60000000';
		parentAccounts[1].LEGACY_ID__c = '60000001';
		insert(parentAccounts);

		List<Billing_Account__c> billingAccounts = new List<Billing_Account__c>();
		for (Account parentAccount: parentAccounts) {
			billingAccounts.add(ApplicationTestDataFactory.getBillingAccounts(1, parentAccount.Id, 'SAP ERP', false)[0]);
		}
		insert billingAccounts;

		List<APR__c> aprs = new List<APR__c>();
		for (Billing_Account__c billingAccount: billingAccounts) {
			APR__c apr = ApplicationTestDataFactory.getAPRs(1, billingAccount.Id, null, false)[0];
			apr.Legal_Entity_Name_LookUp__c = billingAccount.Organisation__c;
			aprs.add(apr);
		}
		insert(aprs);

		// =====================================
		// Stubbing
		// =====================================
		//None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Set<Id> accountIds = new Set<Id>{parentAccounts[0].Id};
		Database.QueryLocator queryLocator = APRsSelector.newInstance().selectByAccountOrderByAccountIdQueryLocator(accountIds, new Set<Object>{
				APRsSelector.Options.WITH_ORGANISATION
		});

		List<APR__c> queryResults = (List<APR__c>)Database.query(queryLocator.getQuery());

		System.assertEquals(1, queryResults.size(), 'Expected to return only the APRs related to the supplied account');
		System.assertEquals(aprs[0].Id, queryResults[0].Id, 'Expected to return only the APRs related to the supplied account');


		queryLocator = APRsSelector.newInstance().selectByAccountOrderByAccountIdQueryLocator(new Set<Id>(), new Set<Object>{
				APRsSelector.Options.WITH_ORGANISATION
		});
		queryResults = (List<APR__c>)Database.query(queryLocator.getQuery());
		System.assertEquals(2, queryResults.size(), 'Expected to return APRs related to any account when account id is not specified');
		Test.stopTest();
	}
}