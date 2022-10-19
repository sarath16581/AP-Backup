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
		ExceptionCheckerService exceptionService = (ExceptionCheckerService)MockUtility.mockUtility(ExceptionCheckerService.class);

		MockUtility.Mocks.startStubbing();
		((ExceptionCheckerService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), exceptionService)).assignCasesToAgentQueue((List<Case>)fflib_Match.eq(vCases));
		MockUtility.Mocks.stopStubbing();
		//Test
		Test.startTest();
		CaseReopenBatch vBatch = new CaseReopenBatch();
		vBatch.execute(null, vCases);
		vBatch.execute(null);
		Test.stopTest();

		List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob];
		System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');

		// should have called ExceptionCheckerService methods
        ((ExceptionCheckerService)MockUtility.Mocks.verify(exceptionService, MockUtility.Mocks.times(1))).assignCasesToAgentQueue((List<Case>)fflib_Match.eq(vCases));
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


	/**
	 * @description Test the exception checker logic to assign the cases to agent queue and close the cases
	 */
	@IsTest
	private static void testExceptionCheckerCasesReopen() {

		// =====================================
        // Data Preparation
        // =====================================
		List<Case> vCases = ApplicationTestDataFactory.getCases(100, true);
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(4, null, true);
		Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
		List<EventMessage__c> articleOneEventMessages = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true);
		articleOneEventMessages[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
		articleOneEventMessages[0].ActualDateTime__c = System.now();
		articleOneEventMessages[0].TrackingID__c = '1234ABC';
		List<EventMessage__c> articleTwoEventMessages = ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true);
		articleTwoEventMessages[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
		articleTwoEventMessages[0].ActualDateTime__c = System.now();
		articleTwoEventMessages[0].TrackingID__c = '5678DEF';
		List<EventMessage__c> articleThreeEventMessages = ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true);
		articleThreeEventMessages[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
		articleThreeEventMessages[0].ActualDateTime__c = System.now();
		articleThreeEventMessages[0].TrackingID__c = 'ABC123';
		List<EventMessage__c> articleFourEventMessages = ApplicationTestDataFactory.getEventMessages(1, articles[3].Id, true);
		articleFourEventMessages[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
		articleFourEventMessages[0].ActualDateTime__c = System.now();
		articleFourEventMessages[0].TrackingID__c = 'DEF456';
		for (Integer i = 0; i < 100 ; i++) {
			vCases[i].Case_Reopen_Date__c = System.now();
			if (i < 25) {
				vCases[i].ArticleTest__c = articles[0].Id;
			} else if (i < 50) {
				vCases[i].ArticleTest__c = articles[1].Id;
			} else if (i < 75) {
				vCases[i].ArticleTest__c = articles[2].Id;
			} else if (i < 85) {
				vCases[i].ArticleTest__c = articles[2].Id;
				vCases[i].CaseOriginator__c = 'Sender';
			} else {
				vCases[i].ArticleTest__c = articles[3].Id;
			}
		}

		List<ExceptionCheckerService.ExceptionResultDTO> exceptionResult = new List<ExceptionCheckerService.ExceptionResultDTO>();
		ExceptionCheckerService.ExceptionResultDTO ex1 = new ExceptionCheckerService.ExceptionResultDTO();
		ex1.isException = true;
		ex1.CaseToCheck = vCases[0];
		ExceptionCheckerService.ExceptionResultDTO ex2 = new ExceptionCheckerService.ExceptionResultDTO();
		ex2.isException = true;
		ex2.CaseToCheck = vCases[1];
		ExceptionCheckerService.ExceptionResultDTO ex3 = new ExceptionCheckerService.ExceptionResultDTO();
		ex3.isException = false;
		ex3.CaseToCheck = vCases[2];
		ExceptionCheckerService.ExceptionResultDTO ex4 = new ExceptionCheckerService.ExceptionResultDTO();
		ex4.isException = true;
		ex4.CaseToCheck = vCases[3];

		exceptionResult.add(ex1);
		exceptionResult.add(ex2);
		exceptionResult.add(ex3);
		exceptionResult.add(ex4);

		// =====================================
        // Stubbing
        // =====================================
        EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);
		ExceptionCheckerService exceptionService = (ExceptionCheckerService)MockUtility.mockUtility(ExceptionCheckerService.class);

		MockUtility.Mocks.startStubbing();
		List<EventMessage__c> eventMessages = new List<EventMessage__c>(articleOneEventMessages);
        eventMessages.addAll(articleTwoEventMessages);
		eventMessages.addAll(articleThreeEventMessages);
		eventMessages.addAll(articleFourEventMessages);
        MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>(eventMessages));
		MockUtility.Mocks.when(exceptionService.isExceptionApplies((List<ExceptionCheckerService.ExceptionCheckDTO>)fflib_Match.anyObject())).thenReturn(exceptionResult);
		((ExceptionCheckerService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), exceptionService)).assignCasesToAgentQueue((List<Case>)fflib_Match.anyObject());
		((ExceptionCheckerService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), exceptionService)).closeCases((List<Case>)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();
		//Test
		Test.startTest();
		CaseReopenBatch vBatch = new CaseReopenBatch();
		vBatch.execute(null, vCases);
		vBatch.execute(null);
		Test.stopTest();

		List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob];
		System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');

		// should have called ExceptionCheckerService methods
        ((ExceptionCheckerService)MockUtility.Mocks.verify(exceptionService, MockUtility.Mocks.times(1))).assignCasesToAgentQueue((List<Case>)fflib_Match.anyObject());
		((ExceptionCheckerService)MockUtility.Mocks.verify(exceptionService, MockUtility.Mocks.times(1))).closeCases((List<Case>)fflib_Match.anyObject());
	}
}