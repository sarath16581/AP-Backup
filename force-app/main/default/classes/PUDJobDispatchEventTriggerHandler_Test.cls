/***
 * @description Test class for PUDJobDispatchEventTriggerHandler.
 * @author Ranjeewa Silva
 * @date 2021-08-26
 * @group Tests
 * @domain PUD
 * @changelog
 * 2021-08-26 - Ranjeewa Silva - Created.
 * 2022-08-15 - Dattaraj Deshmukh - updated test class to include UnitOfWork.
 */

@IsTest
private class PUDJobDispatchEventTriggerHandler_Test {
	@IsTest
	static void testEnsureEventsProcessedOnPublish() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job_Dispatch_Event__e> events = new List<PUD_Job_Dispatch_Event__e>();
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='1', Status__c='Stop_Accept'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='2', Status__c='Stop_Success'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='3', Status__c='Stop_Success'));

		// =====================================
		// Stubbing
		// =====================================
		PUDJobDispatchEventHandler mockEventHandler = (PUDJobDispatchEventHandler)MockUtility.mockUtility(PUDJobDispatchEventHandler.class);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDJobDispatchEventTriggerHandler.getUnitOfWorkSObjectTypes());


		// set up our responses
		MockUtility.Mocks.startStubbing();

		((PUDJobDispatchEventHandler)MockUtility.Mocks.doAnswer(new DoNothingAnswer(), mockEventHandler)).processJobActionEvents((List<PUD_Job_Dispatch_Event__e>)fflib_Match.eqList(events), (ApplicationUnitOfWork)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();


		EventBus.publish(events);

		Test.stopTest();

		// get event bus subscriber information for the trigger
		List<EventBusSubscriber> eventBusSubscribers = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Name='PUDJobDispatchEventTrigger' AND Type='ApexTrigger' AND Topic='PUD_Job_Dispatch_Event__e'];
		System.assertEquals(1, eventBusSubscribers.size(), 'Only one apex trigger is expected to subscribe to PUD_Job_Dispatch_Event__e platform event.');
		System.assertEquals(3, eventBusSubscribers[0].Position, 'Expected to successfully process all published events');
		System.assertEquals(0, eventBusSubscribers[0].Retries, 'No retries expected when event handler has processed events as normal');
	}

	@IsTest
	static void testEnsureEventsRetriedOnProcessingException() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job_Dispatch_Event__e> events = new List<PUD_Job_Dispatch_Event__e>();
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='1', Status__c='Stop_Accept'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='2', Status__c='Stop_Success'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='3', Status__c='Stop_Success'));

		// =====================================
		// Stubbing
		// =====================================
		PUDJobDispatchEventHandler mockEventHandler = (PUDJobDispatchEventHandler)MockUtility.mockUtility(PUDJobDispatchEventHandler.class);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDJobDispatchEventTriggerHandler.getUnitOfWorkSObjectTypes());

		// set up our responses
		MockUtility.Mocks.startStubbing();
		((PUDJobDispatchEventHandler) MockUtility.Mocks.doThrowWhen(new MockException('test'),  mockEventHandler)).processJobActionEvents((List<PUD_Job_Dispatch_Event__e>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventBus.publish(events);

		Test.stopTest();

		// get event bus subscriber information for the trigger
		List<EventBusSubscriber> eventBusSubscribers = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Name='PUDJobDispatchEventTrigger' AND Type='ApexTrigger' AND Topic='PUD_Job_Dispatch_Event__e'];
		System.assertEquals(1, eventBusSubscribers.size(), 'Only one apex trigger is expected to subscribe to PUD_Job_Dispatch_Event__e platform event.');
		System.assertEquals(0, eventBusSubscribers[0].Position, 'Expected none of the events to be processed successfully due to the handler exception.');
		System.assertEquals(1, eventBusSubscribers[0].Retries, 'Expected to retry events when the handler throws exception');
	}

	@IsTest
	static void testEnsureExceptionLoggedAfterExceedingRetryAttempts() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job_Dispatch_Event__e> events = new List<PUD_Job_Dispatch_Event__e>();
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='1', Status__c='Stop_Accept'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='2', Status__c='Stop_Success'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='3', Status__c='Stop_Success'));

		// =====================================
		// Stubbing
		// =====================================
		PUDJobDispatchEventHandler mockEventHandler = (PUDJobDispatchEventHandler)MockUtility.mockUtility(PUDJobDispatchEventHandler.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		((PUDJobDispatchEventHandler) MockUtility.Mocks.doThrowWhen(new MockException('test'),  mockEventHandler)).processJobActionEvents((List<PUD_Job_Dispatch_Event__e>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventBus.publish(events);

		// deliver published events to trigger - expected to throw EventBus.RetryableException
		Test.getEventBus().deliver();

		// again deliver published events to trigger - expected to throw EventBus.RetryableException
		Test.getEventBus().deliver();

		// again deliver published events to trigger. trigger has already reached allowed retry attempts.
		// expected to generate an exception log and discard the events
		Test.getEventBus().deliver();

		Test.stopTest();

		// get event bus subscriber information for the trigger
		List<EventBusSubscriber> eventBusSubscribers = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Name='PUDJobDispatchEventTrigger' AND Type='ApexTrigger' AND Topic='PUD_Job_Dispatch_Event__e'];
		System.assertEquals(1, eventBusSubscribers.size(), 'Only one apex trigger is expected to subscribe to PUD_Job_Dispatch_Event__e platform event.');
		System.assertEquals(3, eventBusSubscribers[0].Position, 'Expected unprocessed events to be discarded after retrying for 3 times (as configured).');
	}

	private class DoNothingAnswer implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			return null;
		}
	}

	private class MockException extends Exception {}
}