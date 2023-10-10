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
*/
@isTest
public with sharing class AtRiskBusinessSelector_Test {
    @isTest
	static void testSelectById() {
		// =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		At_Risk_Business__c arb = ApplicationTestDataFactory.getAtRiskBusiness(1, testAcc.Id, false)[0];

		insert arb;

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

		AtRiskBusinessSelector selector = AtRiskBusinessSelector.newInstance();
		List<At_Risk_Business__c> results = selector.selectById(new Set<Id>{arb.Id});
        
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}