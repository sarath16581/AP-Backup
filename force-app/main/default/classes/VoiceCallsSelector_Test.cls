/**
* @author SteveL
* @date 2024-09-10
* @group Tests
* @tag Selector
* @description A very simple selector test class
* @changelog
* 2024-09-10 - SteveL - Created
* */

@IsTest
private class VoiceCallsSelector_Test {
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

		VoiceCallsSelector selector = VoiceCallsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom VoiceCall\\b').matcher(soql).find(), 'Resulting query does not select from VoiceCall');

		VoiceCallsSelector selector1 = VoiceCallsSelector.newInstance(1);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{VoiceCall.Id, VoiceCall.CallAcceptDateTime};
		VoiceCallsSelector selector2 = VoiceCallsSelector.newInstance(1,fieldOverrides);
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

		VoiceCallsSelector selector = VoiceCallsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{VoiceCallsSelector.Options.WITH_RECIPIENT});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Recipient\\..*?\\bfrom VoiceCall\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{VoiceCallsSelector.Options.WITH_CALLER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Caller\\..*?\\bfrom VoiceCall\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, false)[0];
		Case aCase = ApplicationTestDataFactoryCase.getCases(1, new Set<Id>{ct.Id}, false)[0];
		VoiceCall voiceCall = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{aCase.Id}, false)[0];
		voiceCall.CallType = 'Inbound';
		voiceCall.VendorType = 'ContactCenter';
		voiceCall.CallStartDateTime = System.now();
		voiceCall.CallEndDateTime = System.now().addMinutes(5);
		voiceCall.FromPhoneNumber = '+61 432 077 455';
		voiceCall.ToPhoneNumber = 'CS_Test';
		insert voiceCall;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		VoiceCallsSelector selector = VoiceCallsSelector.newInstance(2);
		List<VoiceCall> results = selector.selectByIds(new Set<Object>(), new Set<Id>{voiceCall.Id});
		System.assertEquals(1, results.size(), 'Expected result size of 2');

		Test.stopTest();
	}
}