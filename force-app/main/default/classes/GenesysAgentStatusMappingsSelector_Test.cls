/**
 * Test class for GenesysAgentStatusMapping
 *
 * @author 		Paul Perry
 * @date 		15-08-2024
 * @group 		Selector
 * @tag			Selector
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

		GenesysAgentStatusMappingsSelector.newInstance(1);
		GenesysAgentStatusMappingsSelector selector = GenesysAgentStatusMappingsSelector.newInstance(1);

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

		Set<String> developerNames = new Set<String>{ 'genesysStatusChange', 'salesforceStatusChange' };
		// Query Agreement Lodgement Point based on Apttus Contract Id
		Map<String,GenesysAgentStatusMapping__mdt> result =
			GenesysAgentStatusMappingsSelector.newInstance().selectByDeveloperName(developerNames);

		for (String name :developerNames) {
			System.assert(
				result.containsKey(name),
				'Missing result. Missing Custom metadata for ' + name + '?'
			);
		}

		Test.stopTest();
	}
}