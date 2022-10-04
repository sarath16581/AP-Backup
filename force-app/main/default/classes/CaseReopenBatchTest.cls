/**
* @author Alex Volkov
* @date 02/12/2021
* @group Tests
* @description Test class for CaseReopenBatch job
* @changelog
* 02/12/2021 - Alex Volkov - Initial creation
* 28/09/2022 - Mahesh Parvathaneni - DDS-12732 - Included the exception checker logic
*/

@IsTest
private with sharing class CaseReopenBatchTest {

	/**
	 * @description Test the execute() method of the batch.
	 * This method runs and validates main logic of the batch job: updating queue allocation flag
	 * and resetting the reopen date to null, thus prompting case routing.
	 * The test makes sure that all cases passed to execute() method will get updated.
	 * Correctness of the cases list passed to the execute() method is ensured by SSSWCasesSelector_Test.
	 */
	@IsTest
	private static void testReopen() {
		//Case records
		List<Case> vCases = ApplicationTestDataFactory.getCases(200, true);
		for (Case c: vCases) {
			c.Case_Reopen_Date__c = System.now();
		}
		//Mocks
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		//Test
		Test.startTest();
		CaseReopenBatch vBatch = new CaseReopenBatch();
		vBatch.execute(null, vCases);
		Test.stopTest();
		// fflib_ArgumentCaptor vArgCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		// //update called on cases and case comments
		// ((ApplicationDatabase) MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<Case>)vArgCaptor.capture(), fflib_Match.eqBoolean(false));
		// Map<Id, Case> vRecords = new Map<Id, Case>((List<Case>) vArgCaptor.getValue());
		// System.assertEquals(200, vRecords.size(), 'Records were not updated');

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor vArgCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		//update called on cases and case comments
		((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)vArgCaptor.capture(), fflib_Match.eqBoolean(false));
		Map<Id, SObject> vRecords = new Map<Id, Case>((List<SObject>) vArgCaptor.getValue());
		System.assertEquals(200, vRecords.size(), 'Records were not updated');
	}

	/**
 	* @description Test the full run of the batch.
 	* This method runs and validates the entire batch job to cover methods other than execute().
 	* The test makes sure that the batch job completes normally.
 	*/
	@IsTest
	private static void testBatchRun(){
		//Mocks
		SSSWCasesSelector vSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(vSelector.selectCasesEligibleForReopenByOwnerAndDate((Set<String>)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(Database.getQueryLocator([SELECT Id FROM Case LIMIT 1]));
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		//Test
		Test.startTest();
		CaseReopenBatch vBatch = new CaseReopenBatch();
		vBatch.execute(null);
		Test.stopTest();
		List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob];
		System.assertEquals(1, vJob.size(), 'Batch failed to run');
		System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');
	}
}