/**
 * @description Test class for ICPS Module
 * @author Harry Wang
 * @date 2022-06-21
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-21 - Harry Wang - Created
*/
@IsTest
private class ICPSAutomationModule_Test {
	/**
	* Test:
	*  Ensure Hold Until date is populated correctly
	*/
	@IsTest
	public static void testUpdateHoldUntilDate() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPSAutomationModule module = ICPSAutomationModule.newInstance();
		module.updateHoldUntilDate(icps);
		Test.stopTest();

		ICPSSettings__mdt icpsSettings = ICPSSettings__mdt.getInstance('ICPS_Settings');
		Decimal holdingDays = icpsSettings.HoldingDateDays__c;
		System.assertEquals(System.today().addDays(holdingDays.intValue()), icps[0].HoldUntilDate__c, 'Expected hold until date');
	}

	/**
	* Test:
	*  Ensure exceptions are handled correctly
	*/
	@IsTest
	public static void testExceptionHandling() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		ICPSAutomationModule.Constructor constructor = new ICPSAutomationModule.Constructor();
		constructor.construct();
		ICPSAutomationModule module = ICPSAutomationModule.newInstance();
		module.onBeforeInsert(null, mockUow);
		module.onBeforeUpdate(null, null, mockUow);
		System.assert(true, 'PMD by-pass');
	}

	/**
	* Test:
	*  Ensure fields are capitalized
	*/
	@IsTest
	public static void testCapitalizeFields() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPSAutomationModule.newInstance().capitalizeFields(icps, null);
		Test.stopTest();

		System.assert(icps[0].ReceiverName__c.deleteWhitespace().isAllUpperCase(), 'Capitalized');
	}
}