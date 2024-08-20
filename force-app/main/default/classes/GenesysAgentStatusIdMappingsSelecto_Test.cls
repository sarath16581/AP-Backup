/**
* @author Paul Perry
* @date 15/08/2024
* @group Tests
* @tag Selector
* @tag GenesysAgentStatusIdMapping__c SObject
* @description
*	A very simple selector class for GenesysAgentStatusIdMapping__c
*/
@IsTest
private with sharing class GenesysAgentStatusIdMappingsSelecto_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilder() {
		Test.startTest();

		GenesysAgentStatusIdMappingsSelector selector = GenesysAgentStatusIdMappingsSelector.newInstance(1);
		String soql = selector.newQueryBuilder().toSoqlString();

		System.assertEquals(true, soql.contains('FROM GenesysAgentStatusIdMapping__c'), 'Resulting query does not select from GenesysAgentStatusIdMapping__c object');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is querying the correct output including related fields
	 */
	@IsTest
	private static void testEnsureSelectorOutput() {
		final String systemSource = 'Genesys';

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		GenesysAgentStatusIdMapping__c statusIdMapping = new GenesysAgentStatusIdMapping__c(
			Name = 'TEST',
			Source__c = systemSource,
			StatusId__c = 'genesys-status-id'
		);

		insert statusIdMapping;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Query Agreement Lodgement Point based on Apttus Contract Id
		List<GenesysAgentStatusIdMapping__c> results = GenesysAgentStatusIdMappingsSelector.newInstance().selectBySource(systemSource);

		System.assertEquals(1, results.size(), 'Expected result size of 1');
		Test.stopTest();
	}
}