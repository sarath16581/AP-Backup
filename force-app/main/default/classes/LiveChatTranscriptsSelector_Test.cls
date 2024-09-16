/**
	* @description Test class for LiveChatTranscriptsSelector
	* @author Rejeesh Raghavan
	* @group Tests
	* @tag Selector
	* @tag LiveChatTranscript SObject
	* @domain Core
	* @changelog
	* 2024-09-16 - Rejeesh Raghavan - Created
 */
@IsTest
public with sharing class LiveChatTranscriptsSelector_Test {
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

		LiveChatTranscriptsSelector selector = LiveChatTranscriptsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom liveChatTranscript\\b').matcher(soql).find(), 'Resulting query does not select from LiveChatTranscript');

		LiveChatTranscriptsSelector selector1 = LiveChatTranscriptsSelector.newInstance(1);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{LiveChatTranscript.Id, LiveChatTranscript.CreatedById, LiveChatTranscript.OwnerId};
		LiveChatTranscriptsSelector selector2 = LiveChatTranscriptsSelector.newInstance(1,fieldOverrides);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bid\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		LiveChatTranscriptsSelector selector = LiveChatTranscriptsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{LiveChatTranscriptsSelector.Options.WITH_OWNER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom liveChatTranscript\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		Test.stopTest();
	}

	/**
	 * Test selectorById method
	 */
	@IsTest
	private static void testSelectorById() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		Database.SaveResult visitorSaveResult = Database.insert(new LiveChatVisitor());

		Database.SaveResult transcriptSaveResult = Database.insert(
			new LiveChatTranscript(
				LiveChatVisitorId=visitorSaveResult.getId()
			));
		Set<Id> setRecordIds = new Set<Id>{transcriptSaveResult.getId()};
		Set<Object> selectorOptions = new Set<Object>();
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		LiveChatTranscriptsSelector selector = LiveChatTranscriptsSelector.newInstance();
		List<LiveChatTranscript> results = selector.selectByIds(selectorOptions, setRecordIds);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}