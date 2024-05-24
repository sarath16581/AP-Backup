/**
* @author Pratyush Chalasani
* @date 2023-04-21
* @group Selector
* @tag Selector
* @tag Profile SObject
* @domain Core
* @description Test class for AtRiskBusinessSelector
* @changelog
* 2023-04-21 - Pratyush Chalasani - Created
* 2024-05-21 - Harry Wang - Added tests for new option WITH_RELATED_ORGANISATION and fieldOverrides
*/
@isTest
public with sharing class AtRiskBusinessSelector_Test {
	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		AtRiskBusinessSelector selector = AtRiskBusinessSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom At_Risk_Business__c\\b').matcher(soql).find(), 'Resulting query does not select from At_Risk_Business__c');

		selector = AtRiskBusinessSelector.newInstance(new Set<SObjectField>{
				At_Risk_Business__c.Id, At_Risk_Business__c.Legal_Entity_Name__c
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom At_Risk_Business__c\\b').matcher(soql).find(), 'Resulting query does not select from At_Risk_Business__c');

		selector = AtRiskBusinessSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				At_Risk_Business__c.SObjectType => new Set<SObjectField>{At_Risk_Business__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom At_Risk_Business__c\\b').matcher(soql).find(), 'Resulting query does not select from At_Risk_Business__c');
	}

	/**
	* Test:
	*  Ensures that the testSelectById method return expected matching result
	*/
	@IsTest
	static void testSelectById() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');
		Account testAcc1 = new Account(Name = 'test1');

		insert new List<Account>{testAcc, testAcc1};

		At_Risk_Business__c arb = ApplicationTestDataFactory.getAtRiskBusiness(1, testAcc.Id, false)[0];
		arb.Related_Organisation__c = testAcc1.Id;

		insert arb;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessSelector selector = AtRiskBusinessSelector.newInstance();

		List<At_Risk_Business__c> results = selector.selectById(new Set<Id>{arb.Id});
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		results = selector.selectById(new Set<Id>{arb.Id}, new Set<Object>{AtRiskBusinessSelector.Options.WITH_RELATED_ORGANISATION});
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areEqual('test1', results[0].Related_Organisation__r.Name, 'Expected related organisation name');

		Test.stopTest();
	}
}