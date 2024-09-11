/***
 * @description Test class for ConversationParticipantsSelector
 * @author SteveL
 * @date 2024-09-11
 * @changelog
 * 11/9/2024 created - SteveL
 */
@IsTest
private class ConversationParticipantsSelector_Test {
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

		ConversationParticipantsSelector selector = ConversationParticipantsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ConversationParticipant\\b').matcher(soql).find(), 'Resulting query does not select from ConversationParticipant');

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{Contact.Id, Contact.AccountId};
		ConversationParticipantsSelector selector2 = ConversationParticipantsSelector.newInstance(1,fieldOverrides);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bid\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');

		Test.stopTest();
	}
}