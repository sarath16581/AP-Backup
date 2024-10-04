/**
 * @description Test class for GenesysAgentStatusMappingsSelector
 * @author 		Paul Perry
 * @date 		15-08-2024
 * @changelog
 */
@IsTest
private with sharing class GenesysAgentStatusMappingsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		GenesysAgentStatusMappingsSelector selector = GenesysAgentStatusMappingsSelector.newInstance();

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assert(
			soql.contains('FROM GenesysAgentStatusMapping__mdt'),
			'Resulting query does not select from GenesysAgentStatusMapping__mdt object'
		);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is querying the correct output including related fields
	 * 	Ensures that required Custom Metadata is present in the system
	 */
	@IsTest
	private static void testEnsureSelectorOutput() {
		Test.startTest();

		// Query Agreement Lodgement Point based on Apttus Contract Id
		GenesysAgentStatusMapping__mdt resultBySfStatus = GenesysAgentStatusMappingsSelector.newInstance(1)
			.selectBySalesforcePresenceStatus('Training', null);

		System.assertEquals('Training', resultBySfStatus?.SalesforcePresenceStatus__c, 'Invalid record returned');

		GenesysAgentStatusMapping__mdt resultByGenStatusId = GenesysAgentStatusMappingsSelector.newInstance()
			.selectByGenesysStatusId(resultBySfStatus.GenesysStatusId__c, null);

		System.assertEquals('Training', resultByGenStatusId?.SalesforcePresenceStatus__c, 'Invalid record returned');
		System.assertEquals(resultBySfStatus.Id, resultByGenStatusId.Id, 'Records should be matching to the same instance');

		Test.stopTest();
	}
}