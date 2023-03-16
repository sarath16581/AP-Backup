/**
 * @description Test class for SalesAutomationModule
 * @author Harry Wang
 * @date 2022-11-08
 * @group Domain
 * @domain Sales
 * @changelog
 * 2022-11-08 - Harry Wang - Created
 * 2023-01-08 - Ranjeewa Silva - Refactored the tests and added more tests to cover insert scenario
*/
@IsTest
private class SalesAutomationModule_Test {

	/**
	*  Ensure Sales Team Type is populated based on Sales Team (Sales_Segment__c) on insert
	*/
	@IsTest
	public static void testEnsureSalesTeamTypePopulatedOnBeforeInsert() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].Sales_Segment__c = 'Holding Sales Team';
		accounts[1].Sales_Segment__c = 'InvalidSalesTeam';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAutomationModule.newInstance().onBeforeInsert(accounts, mockUow);

		Test.stopTest();

		System.assertEquals('Holding', accounts[0].SalesTeamType__c, 'Expected sales team type not populated');
		System.assertEquals(null, accounts[1].SalesTeamType__c, 'SalesTeamType__c should be set to null when Sales Team (Sales_Segment__c) value is unknown');

		// verify excluded records are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

	}

	/**
	*  Ensure Sales Team Type is populated based on Sales Team (Sales_Segment__c) on update
	*/
	@IsTest
	public static void testEnsureSalesTeamTypePopulatedOnBeforeUpdate() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].Sales_Segment__c = 'Intermediaries';
		accounts[1].Sales_Segment__c = 'Intermediaries';

		List<Account> updatedAccounts = accounts.deepClone(true);
		updatedAccounts[0].Sales_Segment__c = 'InvalidSalesTeam';
		updatedAccounts[1].Sales_Segment__c = 'Holding Sales Team';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAutomationModule.newInstance().onBeforeUpdate(updatedAccounts, new Map<Id, SObject>(accounts), mockUow);

		Test.stopTest();

		System.assertEquals(null, updatedAccounts[0].SalesTeamType__c, 'SalesTeamType__c should be set to null when Sales Team (Sales_Segment__c) value is unknown');
		System.assertEquals('Holding', updatedAccounts[1].SalesTeamType__c, 'Expected sales team type not populated');

		// verify excluded records are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}
}