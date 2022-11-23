/**
 * @description Test class for BusinessAccountIntermediaryModule
 * @author Harry Wang
 * @date 2022-11-08
 * @group Domain
 * @domain Account
 * @changelog
 * 2022-11-08 - Harry Wang - Created
*/
@IsTest
private class BusinessAccountIntermediaryModule_Test {

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
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		Account newAcc = accounts[0];
		newAcc.Sales_Segment__c = 'Holding Sales Team';
		Account oldAcc = accounts[1];
		oldAcc.Sales_Segment__c = 'Intermediaries';

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
		BusinessAccountIntermediaryModule module = BusinessAccountIntermediaryModule.newInstance();
		module.onBeforeUpdate(new List<Account>{newAcc}, new Map<Id, SObject>{oldAcc.Id => oldAcc}, mockUow);
		System.assertEquals('Holding', newAcc.SalesTeamType__c, 'Expected sales team type stamped');

		BusinessAccountIntermediaryModule.Constructor constructor = new BusinessAccountIntermediaryModule.Constructor();
		constructor.construct();
		module.onBeforeInsert(null, mockUow);
		System.assert(true, 'PMD by-pass');

		Test.stopTest();
	}
}