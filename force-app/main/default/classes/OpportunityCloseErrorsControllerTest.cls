/* @author 
 * @date 2020-04-10
 * @group Tests
 * @domain Core
 * @description test class for OpportunityCloseErrosController
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 * 2023-08-17 - Ranjeewa Silva - Updated tests after refactoring controller class.
 */
@IsTest
private class OpportunityCloseErrorsControllerTest {

	/**
	 * Test to ensure all validation errors encountered are returned by the controller
	 */
	@IsTest
	private static void testGetValidationResultsReturnAllErrors() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// stub the database so we don't need to insert new records
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		System.Savepoint mockSavePoint = Database.setSavepoint();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(mockSavePoint);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		OpportunityCloseErrorsController.ValidationResults results = OpportunityCloseErrorsController.getValidationResults(opportunity);
		Test.stopTest();

		System.assert(results != null, 'Expected validation results but got null');
		System.assertEquals(opportunity.Id, results.recordId, 'Returned validation results should have record id populated');
		System.assert(results.errorMessage == null, 'Error message should not be set when validation results are returned');
		System.assertEquals(1, results.validationMessages.size(), 'Expected one validation message but got ' + results.validationMessages.size());

		// verify update transactions are rolled back twice.
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlRollback((System.Savepoint)fflib_Match.anyObject());
	}

	/**
	* Ensure validation results contain no error messages when no DML errors encountered
	*/
	@IsTest
	private static void testValidationResultsWhenNoDMLErrorsEncountered() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// stub the database so we don't need to insert new records
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		System.Savepoint mockSavePoint = Database.setSavepoint();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(mockSavePoint);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		OpportunityCloseErrorsController.ValidationResults results = OpportunityCloseErrorsController.getValidationResults(opportunity);
		Test.stopTest();

		System.assert(results != null, 'Expected validation results but got null');
		System.assertEquals(opportunity.Id, results.recordId, 'Returned validation results should have record id populated');
		System.assert(results.errorMessage == null, 'Error message should not be set when validation results are returned');
		System.assertEquals(0, results.validationMessages.size(), 'Expected no validation message but got ' + results.validationMessages.size());

		// verify update transactions are rolled back.
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlRollback((System.Savepoint)fflib_Match.anyObject());
	}

	/**
	* Ensure validation results contain exception messages when an unexpected exception encountered
	*/
	@IsTest
	private static void testValidationResultsContainExceptionErrorMessage() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// stub the database so we don't need to insert new records
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		System.Savepoint mockSavePoint = Database.setSavepoint();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(mockSavePoint);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenThrow(new MockException('mock exception'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		OpportunityCloseErrorsController.ValidationResults results = OpportunityCloseErrorsController.getValidationResults(opportunity);
		Test.stopTest();

		System.assert(results != null, 'Expected validation results but got null');
		System.assertEquals(opportunity.Id, results.recordId, 'Returned validation results should have record id populated');
		System.assert(results.errorMessage != null, 'Error message should be set when an exception is encountered');

		// verify update transactions are rolled back.
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlRollback((System.Savepoint)fflib_Match.anyObject());
	}

	/**
	* Ensure LWC configuration is returned by the controller
	*/
	@IsTest
	private static void testLWCLoadConfig() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> config = OpportunityCloseErrorsController.loadConfig();
		Test.stopTest();
		System.assert(config != null, 'Expected valid configuration, but got null');
		System.assert(config.containsKey('lightningHostname'), 'Configuration does not contain lightning host name.');
		System.assert(config.containsKey('visualforceHostname'), 'Configuration does not contain visualforce host name.');
	}

	/**
	* Ensure properties accessed by visualforce page is initialised
	*/
	@IsTest
	private static void testVisualforceControllerExtension() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ApexPages.StandardController opportunityStandardController = new ApexPages.StandardController(opportunity);
		OpportunityCloseErrorsController controllerExt = new OpportunityCloseErrorsController(opportunityStandardController);
		Test.stopTest();

		System.assertEquals(opportunity.Id, controllerExt.recordId, 'Record Id must be set from the standard controller instance');
		System.assert(controllerExt.lightningExperienceBaseURL != null, 'Lightning Experience base URL must be set');
	}

	private static Database.SaveResult getMockSaveResult(List<Database.Error> errors) {
		return (Database.SaveResult)JSON.deserialize(JSON.serialize(
				new Map<String, Object>{
						'success' => errors.isEmpty(),
						'errors' => errors
				}), Database.SaveResult.class);
	}

	private class MockException extends Exception {}
}