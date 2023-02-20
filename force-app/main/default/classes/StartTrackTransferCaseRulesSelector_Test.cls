/**
 * @author Thang Nguyen
 * @date 2023-01-19
 * @group Tests
 * @description Test class for the StartTrackTransferCaseRulesSelector
 * @changelog
 * 2023-01-19 - Thang Nguyen - Created
 */
@IsTest
public with sharing class StartTrackTransferCaseRulesSelector_Test {

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

		StartTrackTransferCaseRulesSelector selector = StartTrackTransferCaseRulesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(
			true,
			Pattern.compile('(?ism)\\bfrom StarTrack_Transfer_Case_Rule__c\\b').matcher(soql).find(),
			'Resulting query does not select from StarTrack_Transfer_Case_Rule__c'
		);

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			StarTrack_Transfer_Case_Rule__c.Id, StarTrack_Transfer_Case_Rule__c.Name
		};
		StartTrackTransferCaseRulesSelector selector1 = StartTrackTransferCaseRulesSelector.newInstance(fieldOverrides);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();

		System.debug('qb1: ' + qb1.toSoqlString());

		System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b').matcher(soql1).find(), 'Resulting query does not have Name field');

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

		List<StarTrack_Transfer_Case_Rule__c> transferCaseRules = new List<StarTrack_Transfer_Case_Rule__c>();
		transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'StarTrack Next Flight Queue', Product_Group__c = 'Next Flight', Order__c = 1, Business_Solutions_Customer__c = true));
		transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.TRANSFER_QUEUE, Business_Solutions_Customer__c = true, Order__c = 2));
		transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.ETA_QUEUE, Case_RecordType__c = 'Pickup Booking Enquiry', Case_Purpose__c = 'Pickup ETA', Order__c = 4));
		Database.insert(transferCaseRules);


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StartTrackTransferCaseRulesSelector selector = StartTrackTransferCaseRulesSelector.newInstance();
		List<StarTrack_Transfer_Case_Rule__c> results = selector.selectAll(new Set<Object>{
																				StartTrackTransferCaseRulesSelector.Options.ORDER_BY_ORDERFIELD
																			});
		System.assertEquals(3, results.size(), 'Result count was wrong');

		Test.stopTest();
	}
}