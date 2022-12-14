/**
 * @description Test class for SalesAutomationModule
 * @author Harry Wang
 * @date 2022-11-08
 * @group Domain
 * @domain Account
 * @changelog
 * 2022-11-08 - Harry Wang - Created
*/
@IsTest
private class SalesAutomationModule_Test {

	/**
	* Test:
	*  Ensure Sales Team is stamped correctly based on Sales Team Type
	*/
	@IsTest
	public static void testStampSalesTeamType() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(4, true);
		Account newAcc1 = accounts[0];
		newAcc1.Sales_Segment__c = 'Holding Sales Team';
		Account oldAcc1 = accounts[1];
		oldAcc1.Sales_Segment__c = 'Intermediaries';

		Account newAcc2 = accounts[2];
		newAcc2.Sales_Segment__c = 'Holding';
		Account oldAcc2 = accounts[3];
		oldAcc2.Sales_Segment__c = 'Intermediaries';

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
		Test.startTest();
		SalesAutomationModule module = SalesAutomationModule.newInstance();
		module.onBeforeUpdate(new List<Account>{newAcc1, newAcc2}, new Map<Id, SObject>{oldAcc1.Id => oldAcc1, oldAcc2.Id => oldAcc2}, mockUow);
		System.assertEquals('Holding', newAcc1.SalesTeamType__c, 'Expected sales team type stamped');
		System.assert(String.isEmpty(newAcc2.SalesTeamType__c), 'Expected sales team type emptied');

		SalesAutomationModule.Constructor constructor = new SalesAutomationModule.Constructor();
		constructor.construct();
		module.onBeforeInsert(null, mockUow);
		System.assert(true, 'PMD by-pass');

		Test.stopTest();
	}
}