/**
 * @description Test class for MyNetworkCaseUserResponseController
 * @author Dattaraj Deshmukh
 * @date 2022-12-07
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
 * 2023-02-15 - Dattaraj Deshmukh - Added testUpdateCase method.
 * 2023-03-16 - Mahesh Parvathaneni - Updated testUpdateCase method. 
*/
@IsTest
private class MyNetworkCaseUserResponseController_Test {
	/**
	 * @desc: test if method creates chatter feed record for a case investigation record.
	 * When Portal user updates response on case investgiation record, chatter feed is created
	 * Expected: Case status is updated to 'Network Responded'.
	 */
	@IsTest
	public static void testPostCaseInvestigationChatterFeed() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, null, null, true);
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();
		String result = MyNetworkCaseUserResponseController.postCaseInvestigationChatterFeed('Sample Feed Comments', caseInvestigations[0].Id, cases[0].Id);
		Test.stopTest();

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<FeedItem>) fflib_Match.eqList(new List<FeedItem>{ new FeedItem(ParentId = caseInvestigations[0].Id, Body = 'Sample Feed Comments')}));
		
		System.assertEquals('success', result);
	}	

	/**
	 * @desc: test if method update case record.
	 * When Portal user updates response on case investgiation record then related case record has to be updated.
	 */
	@IsTest
	public static void testUpdateCase() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();
		String result = MyNetworkCaseUserResponseController.updateCase(cases[0]);
		Test.stopTest();

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) fflib_Match.eqList(new List<Case>{ cases[0] }));

		System.assertEquals('success', result, 'Expected case record to be updated.');
	}

	/**
	 * @desc: test if method update case record throw an exception.
	 */
	@IsTest
	public static void testUpdateCaseException() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.eqList(cases))).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		try {
			String result = MyNetworkCaseUserResponseController.updateCase(cases[0]);
			System.assert(false, 'Expected to throw an Exception on any errors. but not thrown.');
		} catch (Exception ex) {
			// expected
			System.assertNotEquals(null, ex.getMessage(), 'Expected exception to be thrown');
		}
		Test.stopTest();
	}

	private class MockException extends Exception {
	}
}