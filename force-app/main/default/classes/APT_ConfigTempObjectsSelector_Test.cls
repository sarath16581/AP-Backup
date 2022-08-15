/**
* @author Seth Heang
* @date 2022-04-08
* @group Tests
* @tag Selector
* @tag Apttus_Config2__TempObject__c SObject
* @domain Apttus
* @description A very simple selector class that sits in the Apttus domain
* @changelog
* 2022-04-08 - Seth Heang - Created
*/
@IsTest
private with sharing class APT_ConfigTempObjectsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
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

		APT_ConfigTempObjectsSelector selector = APT_ConfigTempObjectsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Config2__TempObject__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus Config Temp Object record');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors method is returning the correct query result
	 */
	@IsTest
	private static void testEnsureSelectorMethodsReturnCorrectResult() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, false)[0];
		insert prodConfig;

		Apttus_Config2__TempObject__c configTempObj = APT_TestDataFactory.getAPTConfigTempObj(1, prodConfig.Id, false)[0];
		insert configTempObj;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		APT_ConfigTempObjectsSelector selector = APT_ConfigTempObjectsSelector.newInstance(1);
		List<Apttus_Config2__TempObject__c> results = selector.selectByConfigId(new Set<id>{prodConfig.Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();

	}

}