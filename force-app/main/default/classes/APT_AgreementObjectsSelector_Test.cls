/**
* @author Sri Harsha
* @date 2022-04-22
* @group Tests
* @tag Selector
* @tag Apttus__APTS_Agreement__c SObject
* @domain Apttus
* @description APT_AgreementObjectsSelector to validate contract.
* changelog:
* 2022-08-11 - Seth Heang - Fix test classes failure due to Product attribute value's Price Structure picklist API name change
* 2023-07-31 - Yatika Bansal - Fixed Test Class
*/
@IsTest
private with sharing class APT_AgreementObjectsSelector_Test {

	/**
	 * Test:Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		APT_AgreementObjectsSelector selector = APT_AgreementObjectsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		Test.stopTest();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Agreement');
	}


	/**
	 * Test: Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c agg = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];

		Test.startTest();

		List<Apttus__APTS_Agreement__c> aggs = APT_AgreementObjectsSelector.newInstance(1)
			   .selectByConfigId(new Set<Id>{agg.Id});
		Test.stopTest();

		System.assertEquals(0, aggs.size(), 'Result count was correct');
	}
}