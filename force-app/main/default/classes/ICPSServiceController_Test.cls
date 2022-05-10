/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Tests
 * @tag Controller
 * @tag ICPS Service
 * @domain ICPS
 * @description Test class for ICPSServiceController
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
@IsTest
private class ICPSServiceController_Test {
	/**
	* Test:
	*  Ensures that 'getICPSCases' returns based on the search parameters passed in.
	*/
	@IsTest
	public static void testGetICPSCases() {
		// =====================================
		// Data Preparation
		// =====================================
		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(2, true);

		// =====================================
		// Stubbing
		// =====================================
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.search((Map<String, String>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(icpsList);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Map<String, String> searchParams = new Map<String, String>();
		searchParams.put('reference', '8888');
		searchParams.put('recipient_name', 'recipient name');

		Test.startTest();
		List<ICPS__c> icps = ICPSServiceController.getICPSCases(searchParams, true);
		System.assertEquals(2, icps.size(), 'Expected 2 found');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that cloned record is returned on successful clone.
	*/
	@IsTest
	public static void testCloneICPS() {
		// =====================================
		// Data Preparation
		// =====================================
		ICPS__c icps = ICPSTestDataFactory.getICPS(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ICPS__c>{icps});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// Test normal clone
		ICPS__c clonedICPS = ICPSServiceController.cloneICPS(icps.Id);

		Test.stopTest();

		System.assert(clonedICPS != null, 'Expected ICPS cloned');
		System.assertNotEquals(icps.Id, clonedICPS.Id, 'Expected ids to be different');
	}

	/**
	* Test:
	*  Ensures that an exception is thrown on dml error inserting cloned record.
	*/
	@IsTest
	public static void testCloneICPSOnDMLError() {
		// =====================================
		// Data Preparation
		// =====================================
		ICPS__c icps = ICPSTestDataFactory.getICPS(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ICPSSelector mockSelector = (ICPSSelector) MockUtility.mockSelector(ICPSSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ICPS__c>{icps});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			ICPS__c clonedICPS = ICPSServiceController.cloneICPS(icps.Id);
			System.assert(false, 'Expected an exception to be thrown - but was not thrown.');
		} catch (Exception ex) {
			//expected
		}
		Test.stopTest();
	}

	private class MockException extends Exception {}
}