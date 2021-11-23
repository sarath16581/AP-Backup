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
 */

@IsTest
private class PUDJobDispatchEventHandler_Test {

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
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[0].Id, Status__c='Accepted'));
		//'Completed' event for jobs[1]. Confirming the job has been completed by the driver.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Completed'));
		//'Completed' event for jobs[2]. Confirming the job has been completed by the driver.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Completed'));
		//exception scenario - invalid status in event.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[3].Id, Status__c='invalid'));
		//exception scenario - invalid parent id in event.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c='invalid', Status__c='Accepted'));
		//'Failed' event for jobs[4]. Confirming the driver was not able to complete the job.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[4].Id, Status__c='Failed', Reason__c='No Access', Comments__c='driver comments'));
		//'Cancelled' event for jobs[5]. Confirming the job has been cancelled in dispatch system.
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[5].Id, Status__c='Cancelled'));

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(jobs);
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
		System.assertNotEquals(null, updatableJobs.get(jobs[0].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving \'Accepted\' action');

		//jobs[1] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[1].Id), 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[1].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(jobs[1].Schedule_Confirmed_Timestamp__c, updatableJobs.get(jobs[1].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' should not be updated on already confirmed job');

		//jobs[2] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[2].Id), 'Job status not updated on receiving \'Completed\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[2].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[2].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving \'Completed\' action');

		//jobs[4] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[4].Id), 'Job status not updated on receiving \'Failed\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_FAILED, updatableJobs.get(jobs[4].Id).Status__c, 'Job status not updated on receiving \'Failed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[4].Id).Failure_Reason__c, 'Failure Reason not updated with the value received in \'Failed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[4].Id).Driver_Comments__c, 'Driver Comments not updated with the value received in \'Failed\' action');

		//jobs[5] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[5].Id), 'Job status not updated on receiving \'Cancelled\' action');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_CANCELLED, updatableJobs.get(jobs[5].Id).Status__c, 'Job status not updated on receiving \'Cancelled\' action');
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
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Accepted'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[1].Id, Status__c='Completed'));
		// receive both 'Accepted' and 'Completed' events in the same batch for jobs[2]. Job Actions are received out of order (i.e. 'Completed' before 'Accepted')
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Completed'));
		events.add(new PUD_Job_Dispatch_Event__e(Source_System__c='MOBILESTAR', Type__c='Job_Action', Parent_Id__c=jobs[2].Id, Status__c='Accepted'));

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(jobs);
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
		System.assertEquals(2, updatableJobs.size(), 'Expected to update 2 job records from Dispatch System Job Action events.');

		//jobs[1] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[1].Id), 'Job status not updated on receiving both \'Accepted\' and \'Completed\' actions in same batch');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[1].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[1].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving both \'Accepted\' and \'Completed\' actions in same batch');

		//jobs[2] is expected to be updated
		System.assert(updatableJobs.containsKey(jobs[2].Id), 'Job status not updated on receiving both \'Accepted\' and \'Completed\' actions out of order in same batch');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_COMPLETED, updatableJobs.get(jobs[2].Id).Status__c, 'Job status not updated on receiving \'Completed\' action');
		System.assertNotEquals(null, updatableJobs.get(jobs[2].Id).Schedule_Confirmed_Timestamp__c, '\'Schedule Confirmed Timestamp\' not updated on receiving both \'Accepted\' and \'Completed\' actions out of order in same batch');
	}
}