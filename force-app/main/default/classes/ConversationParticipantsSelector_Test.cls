/***
 * @author SteveL
 * @description Test class for ConversationParticipantsSelector
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

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{ConversationParticipant.Id, ConversationParticipant.ParticipantDisplayName};
		ConversationParticipantsSelector selector2 = ConversationParticipantsSelector.newInstance(1,fieldOverrides);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Id.*?\\bfrom ConversationParticipant\\b').matcher(soql).find(), 'Resulting query does not select ConversationParticipant field: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)ParticipantDisplayName.*?\\bfrom ConversationParticipant\\b').matcher(soql2).find(), 'Resulting query does not select ConversationParticipant fields: ' + soql2);
		System.assertEquals(false, Pattern.compile('(?ism)CreatedDate.*?\\bfrom ConversationParticipant\\b').matcher(soql2).find(), 'Resulting selects ConversationParticipant but it shouldn\'t: ' + soql2);
		Test.stopTest();
	}
}