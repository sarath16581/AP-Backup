/***
 * @description Test class for PUDJobDispatchEventHandler.
 * @author Ranjeewa Silva
 * @date 2021-08-26
 * @group Tests
 * @domain PUD
 * @changelog
 * 2021-08-26 - Ranjeewa Silva - Created.
 * 2021-10-11 - Ranjeewa Silva - Updated test case to cover receiving "Accepted" job action out of order.
 * 2021-11-11 - Ranjeewa Silva - Added more test to verify population of cancellation confirmation timestamp.
 * 2022-01-18 - Ranjeewa Silva - Updated tests to verify population of dispatch event timestamps on Job record.
 * 2022-03-21 - Seth Heang - Updated tests to verify Photo GUID populated on "Failed" Job record.
 */

@IsTest
private class PUDJobDispatchEventHandler_Test {

	/**
	 * Tests the outcome of receiving all the different Job Action events from dispatch system with container payload.
	 * Testing scenarios for containers:
	 * 1. Updates to existing containers with Actual Quantity
	 * 2. Inserts of new containers received from dispatch system.
	 * 3. Inserts of unique containers in case duplicate containers are passed as a Containers Payload for a same event.
	 */
	@IsTest
	static void testProcessJobActionEventsFromDispatchSystemForContainerTypes() {
		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(3, null, PUDConstants.PUD_JOB_STATUS_NEW, true);
		//jobs[0] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		//jobs[1] has previously been updated by job action events from dispatch system.
		jobs[1].Status__c = PUDConstants.PUD_JOB_STATUS_ACCEPTED;
		jobs[1].Schedule_Confirmed_Timestamp__c = System.now().addHours(-1);

		jobs[2].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		

		PUD_Container__c c1 = PUDTestDataFactory.getPUDJobContainers(1, pudBookingList[0].Id, jobs[1].Id, 'Pallets', 'Empty', true )[0];
		c1.Expected_Quantity__c = 10;
		PUD_Container__c c2 = PUDTestDataFactory.getPUDJobContainers(1, pudBookingList[0].Id, jobs[1].Id, 'Aircan', 'Empty', true )[0];
		c2.Expected_Quantity__c = 30;


		List<PUD_Job_Dispatch_Event__e> events = new List<PUD_Job_Dispatch_Event__e>();
		//'Accepted' event for jobs[0]. Confirming the job has been accepted by the driver.
		//Setting blank container payload
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[0].Id, Status__c='Accepted', Event_Timestamp__c = System.now().addHours(-2), 
		Containers_Payload__c ='[]'));
		
		//'Completed' event for jobs[1]. Confirming the job has been completed by the driver.
		//Setting container payload with existing and new container types.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Completed', Event_Timestamp__c = System.now().addHours(-1), 
		Containers_Payload__c = '[{"Name":"Aircan","Quantity":30,"ActualQuantity":52,"Condition":"Empty"},{"Name":"Colby","Quantity":3,"ActualQuantity":2,"Condition":"Full"}, {"Name":"Pallets","Quantity":10,"ActualQuantity":12,"Condition":"Empty"}]'));
		
		//'Completed' event for jobs[2]. Confirming the job has been completed by the driver.
		//Setting duplicate container payload from MobileStar
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Completed', Event_Timestamp__c = System.now().addHours(-1),
		Containers_Payload__c ='[{"Name":"Aircan","Quantity":30,"ActualQuantity":52,"Condition":"Empty"}, {"Name":"Aircan","Quantity":30,"ActualQuantity":52,"Condition":"Empty"}]'));
		
		//associating containers with jobs.
		// Two containers are set as childs to a job.
		jobs[1] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[1], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{c1, c2}});

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(jobs);
		
		//ApplicationDatabase does not have a class to return MOCK answer() for DML Upsert.
		//This is a temporary mock Answer for DML Upsert.
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>)fflib_Match.anyObject(), (SObjectField)fflib_Match.anyObject())).thenAnswer(new AnswerContainerDMLUpserted());

		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());


		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDJobDispatchEventHandler.getInstance().processJobActionEvents(events);

		Test.stopTest();

		fflib_ArgumentCaptor updatableJobsCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Job__c>.class);

		//define insert containers Captor
		fflib_ArgumentCaptor upsertableContainersCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Container__c>.class);

		//verify that PUDUtility is called once with expected list of jobs
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<PUD_Job__c>) updatableJobsCaptor.capture());

		//verify that PUDUtility is called once with expected list of containers
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpsert((List<PUD_Container__c>) upsertableContainersCaptor.capture(), (SObjectField) fflib_Match.eq(PUD_Container__c.Id));

		Map<Id, PUD_Container__c> upsertedContainers = new Map<Id, PUD_Container__c>((List<PUD_Container__c>) upsertableContainersCaptor.getValue());
		
		//assert actual quantities are updated against a already existing containers.
		System.assertEquals(4, upsertedContainers.size(), 'Expected to upsert 4 container for a job. 2 Updates and 2 inserts.');
		system.assertEquals(12, upsertedContainers.get(c1.Id).Actual_Quantity__c, 'Expected to update Actual Quantity for container');
		system.assertEquals(52, upsertedContainers.get(c2.Id).Actual_Quantity__c, 'Expected to update Actual Quantity for container');
		system.assertNotEquals(null, upsertedContainers.get(c1.Id).Actual_Quantity__c, 'Expected to update Actual Quantity for container');
		

		Map<Id, PUD_Job__c> updatableJobs = new Map<Id, PUD_Job__c>((List<PUD_Job__c>) updatableJobsCaptor.getValue());
		System.assertEquals(3, updatableJobs.size(), 'Expected to update 3 job records from Dispatch System Job Action events.');

	}


	/**
	 * Tests the outcome of receiving all the different Job Action events from dispatch system.
	 */
	@IsTest
	static void testProcessJobActionEventsFromDispatchSystem() {
		// =====================================
		// Data Preparation
		// =====================================
		
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, null, PUDConstants.PUD_JOB_STATUS_NEW, true);
		//jobs[0] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		//jobs[1] has previously been updated by job action events from dispatch system.
		jobs[1].Status__c = PUDConstants.PUD_JOB_STATUS_ACCEPTED;
		jobs[1].Schedule_Confirmed_Timestamp__c = System.now().addHours(-1);

		//jobs[2] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[2].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		//jobs[3] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[3].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		//jobs[4] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[4].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		//jobs[5] is in status 'Cancel'. Job Cancellation request has been pushed to dispatch system but awaiting confirmation.
		jobs[5].Status__c = PUDConstants.PUD_JOB_STATUS_CANCEL;

	


		List<PUD_Job_Dispatch_Event__e> events = new List<PUD_Job_Dispatch_Event__e>();
		//'Accepted' event for jobs[0]. Confirming the job has been accepted by the driver.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[0].Id, Status__c='Accepted', Event_Timestamp__c = System.now().addHours(-2)));
		//'Completed' event for jobs[1]. Confirming the job has been completed by the driver.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Completed', Event_Timestamp__c = System.now().addHours(-1)));
		//'Completed' event for jobs[2]. Confirming the job has been completed by the driver.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Completed', Event_Timestamp__c = System.now().addHours(-1)));
		//exception scenario - invalid status in event.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[3].Id, Status__c='invalid', Event_Timestamp__c = System.now().addHours(-1)));
		//exception scenario - invalid parent id in event.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='invalid', Status__c='Accepted', Event_Timestamp__c = System.now().addHours(-1)));
		//'Failed' event for jobs[4]. Confirming the driver was not able to complete the job and PhotoGUID is supplied
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[4].Id, Status__c='Failed', Reason__c='No Access', Comments__c='driver comments', Photo_GUID__c='777123456', Event_Timestamp__c = System.now().addHours(-1)));
		//'Cancelled' event for jobs[5]. Confirming the job has been cancelled in dispatch system.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[5].Id, Status__c='Cancelled', Event_Timestamp__c = System.now().addHours(-1)));


		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(jobs);
		
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());


		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDJobDispatchEventHandler.getInstance().processJobActionEvents(events);

		Test.stopTest();

		fflib_ArgumentCaptor updatableJobsCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Job__c>.class);

		//verify that PUDUtility is called once with expected list of jobs
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<PUD_Job__c>) updatableJobsCaptor.capture());

		

		Map<Id, PUD_Job__c> updatableJobs = new Map<Id, PUD_Job__c>((List<PUD_Job__c>) updatableJobsCaptor.getValue());
		System.assertEquals(5, updatableJobs.size(), 'Expected to update 5 job records from Dispatch System Job Action events.');

		//jobs[0] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[0].Id), 'Job status not updated on receiving \'Accepted\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_ACCEPTED, updatableJobs.get(jobs[0].Id).Status__c, 'Job status not updated on receiving \'Accepted\' action');
		System.assertEquals(events[0].Event_Timestamp__c, updatableJobs.get(jobs[0].Id).Accepted_Timestamp__c, 'Accepted timestamp not updated on receiving \'Accepted\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[0].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving \'Accepted\' action');

		//jobs[1] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[1].Id), 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[1].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(events[1].Event_Timestamp__c, updatableJobs.get(jobs[1].Id).Completed_Timestamp__c, 'Completed timestamp not updated on receiving \'Completed\' action');
		System.assertEquals(jobs[1].Schedule_Confirmed_Timestamp__c, updatableJobs.get(jobs[1].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' should not be updated on already confirmed job');

		//jobs[2] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[2].Id), 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[2].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(events[2].Event_Timestamp__c, updatableJobs.get(jobs[2].Id).Completed_Timestamp__c, 'Completed timestamp not updated on receiving \'Completed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[2].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving \'Completed\' action');

		//jobs[4] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[4].Id), 'Job status not updated on receiving \'Failed\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_FAILED, updatableJobs.get(jobs[4].Id).Status__c, 'Job status not updated on receiving \'Failed\' action');
		System.assertEquals(events[5].Event_Timestamp__c, updatableJobs.get(jobs[4].Id).Failed_Timestamp__c, 'Failed timestamp not updated on receiving \'Failed\' action');
		//Assert that Photo GUID is populated on PUD Job from Platform event for Failed status
		System.assertEquals('777123456', updatableJobs.get(jobs[4].Id).Photo_GUID__c, 'Photo GUID is updated with the value received in \'Failed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[4].Id).Failure_Reason__c, 'Failure Reason not updated with the value received in \'Failed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[4].Id).Driver_Comments__c, 'Driver Comments not updated with the value received in \'Failed\' action');

		//jobs[5] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[5].Id), 'Job status not updated on receiving \'Cancelled\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_CANCELLED, updatableJobs.get(jobs[5].Id).Status__c, 'Job status not updated on receiving \'Cancelled\' action');
		System.assertEquals(events[6].Event_Timestamp__c, updatableJobs.get(jobs[5].Id).Cancelled_Timestamp__c, 'Cancelled timestamp not updated on receiving \'Cancelled\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[5].Id).Cancellation_Confirmed_Timestamp__c, '\'Cancellation Confirmed Timestamp\' should be updated on receiving \'Cancelled\' action');

	}

	/**
	 * Tests the scenario when Job Actions are received out of order from dispatch system.
	 * For example, we may receive 'Completed' before getting the 'Accepted' action. In this case subsequent 'Accepted' action should be ignored.
	 */
	@IsTest
	static void testProcessJobActionEventsReceivedOutOfOrderFromDispatchSystem() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(3, null, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//jobs[0] is in status 'Completed'. Job has been pushed to dispatch system. Salesforce has already received "Completed" job action from dispatch system.
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_COMPLETED;

		//jobs[1] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[1].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		//jobs[2] is in status 'Schedule'. Job has been pushed to dispatch system but awaiting confirmation.
		jobs[2].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		List<PUD_Job_Dispatch_Event__e> events = new List<PUD_Job_Dispatch_Event__e>();
		// exception scenario - receiving 'Accepted' event out of order for for jobs[0].
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[0].Id, Status__c='Accepted'));
		// receive both 'Accepted' and 'Completed' events in the same batch for jobs[1].
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Accepted', Event_Timestamp__c=System.now().addHours(-3)));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Completed', Event_Timestamp__c=System.now().addHours(-1)));
		// receive both 'Accepted' and 'Completed' events in the same batch for jobs[2]. Job Actions are received out of order (i.e. 'Completed' before 'Accepted')
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Completed', Event_Timestamp__c=System.now().addMinutes(-25)));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Accepted', Event_Timestamp__c=System.now().addMinutes(-28)));

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(jobs);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDJobDispatchEventHandler.getInstance().processJobActionEvents(events);

		Test.stopTest();

		fflib_ArgumentCaptor updatableJobsCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Job__c>.class);

		//verify that PUDUtility is called once with expected list of jobs
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<PUD_Job__c>) updatableJobsCaptor.capture());

		Map<Id, PUD_Job__c> updatableJobs = new Map<Id, PUD_Job__c>((List<PUD_Job__c>) updatableJobsCaptor.getValue());
		System.assertEquals(3, updatableJobs.size(), 'Expected to update 3 job records from Dispatch System Job Action events.');

		//jobs[1] is expected to be updated.
		System.assert(updatableJobs.containsKey(jobs[1].Id), 'Job status not updated on receiving both \'Accepted\' and \'Completed\' actions in same batch');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[1].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(events[1].Event_Timestamp__c, updatableJobs.get(jobs[1].Id).Accepted_Timestamp__c, 'Accepted timestamp not updated on receiving \'Accepted\' action');
		System.assertEquals(events[2].Event_Timestamp__c, updatableJobs.get(jobs[1].Id).Completed_Timestamp__c, 'Completed timestamp not updated on receiving \'Completed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[1].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving both \'Accepted\' and \'Completed\' actions in same batch');

		//jobs[2] is expected to be updated. 'Accepted' event received Out of order should still populate the accepted timestamp.
		System.assert(updatableJobs.containsKey(jobs[2].Id), 'Job status not updated on receiving both \'Accepted\' and \'Completed\' actions out of order in same batch');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[2].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(events[3].Event_Timestamp__c, updatableJobs.get(jobs[2].Id).Completed_Timestamp__c, 'Completed timestamp not updated on receiving \'Completed\' action');
		System.assertEquals(events[4].Event_Timestamp__c, updatableJobs.get(jobs[2].Id).Accepted_Timestamp__c, 'Accepted timestamp not updated on receiving \'Accepted\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[2].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving both \'Accepted\' and \'Completed\' actions out of order in same batch');
	}


	/**
	 * A simple Answer class to set an Id on the record to simulate a DML upsert operation
	 */
	public class AnswerContainerDMLUpserted implements fflib_Answer {
		List<SObject> mockDMLUpsertedRecords = new List<SObject>();

		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> upsertResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				
				//only in case of insert, set record id.
				//This allows us to check if records are updated in case of updates.
				if(record.Id == null){
					record.Id = fflib_IDGenerator.generate(record.getSObjectType());
				}

				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				upsertResults.add(result);
			}

			// store a list of the records that were updated when this answer is invoked.
			mockDMLUpsertedRecords.addAll(records);

			List<Database.UpsertResult> result = (List<Database.UpsertResult>)JSON.deserialize(JSON.serialize(upsertResults), List<Database.UpsertResult>.class);
			return result;
		}
	}
}