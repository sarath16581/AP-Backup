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
}