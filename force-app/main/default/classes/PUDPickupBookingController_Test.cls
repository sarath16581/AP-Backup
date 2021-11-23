/***
 * @description Test cases for PUDPickupBookingController
 * @author Ranjeewa Silva
 * @date 2021-08-17
 * @group Tests
 * @domain PUD
 * @changelog
 * 2021-08-17 - Ranjeewa Silva - Created.
 */

@IsTest
private class PUDPickupBookingController_Test {

	@IsTest
	static void testEnsureTriggerDispatchSystemSyncOnlyForCurrentDayJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];
		job.Date__c = Date.today().addDays(2);


		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.triggerDispatchSystemSync(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected error status not returned');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');
	}

	@IsTest
	static void testEnsureTriggerDispatchSystemSyncNotAllowedForStopCreditBookings() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];
		job.Stop_Credit__c = true;


		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.triggerDispatchSystemSync(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected error status not returned');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');

	}

	@IsTest
	static void testEnsureTriggerDispatchSystemSyncNotAllowedForDepotsNotInPilot() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});
		// return an empty list to simulate an ineligible job
		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.listContains(job))).thenReturn(new List<PUD_Job__c>());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.triggerDispatchSystemSync(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected error status not returned');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');

	}

	@IsTest
	static void testEnsureTriggerDispatchSystemSyncReturnsErrorOnUnexpectedException() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});
		// throw an exception to simulate an unexpected error
		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.listContains(job))).thenThrow(new MockException());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			PUDPickupBookingController.triggerDispatchSystemSync(job.Id);
			System.assert(false, 'Expected exception not thrown');
		} catch (AuraHandledException ex) {
			// expected
		} catch (Exception e) {
			System.assert(false, 'Expected type of exception not thrown');
		}

		Test.stopTest();
	}

	@IsTest
	static void testEnsureTriggerDispatchSystemSync() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});
		// return an empty list to simulate an ineligible job
		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.listContains(job))).thenReturn(new List<PUD_Job__c>{job});
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.triggerDispatchSystemSync(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.SUCCESSFUL.name(), result.status, 'Expected status not returned');

		// should have updated the job
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{job});
	}

	// ensure cancellations not allowed for jobs in the past
	@IsTest
	static void testEnsureCancelJobActionNotAllowedForPastJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_SCHEDULE, true)[0];
		job.Date__c = Date.today().addDays(-1);

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.cancel(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected error status not returned');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');
	}

	// ensure cancelling future jobs not allowed via cancel action. this should be done via the booking.
	@IsTest
	static void testEnsureCancelJobActionNotAllowedForFutureJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];
		job.Date__c = Date.today().addDays(1);

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.cancel(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected to return error attempting to cancel future jobs via \'cancel\' action.');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');
	}

	// ensure cancelling jobs in 'New' status is not allowed via cancel action. this should be done via the booking.
	@IsTest
	static void testEnsureCancelJobActionNotAllowedForNewJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.cancel(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected to return error attempting to cancel jobs in New status via \'cancel\' action.');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');
	}

	// ensure cancelling already dispatched jobs are not allowed.
	@IsTest
	static void testEnsureCancelJobActionNotAllowedForDispatchedJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_COMPLETED, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.cancel(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), result.status, 'Expected to return error attempting to cancel jobs already dispatched.');
		System.assert(String.isNotBlank(result.errorMessage), 'Expected a valid error message; but was blank');
	}

	// ensure cancelling already dispatched jobs are not allowed.
	@IsTest
	static void testEnsureCancelJobActionAllowedForCurrentDayJobsNotDispatchedYet() {
		// =====================================
		// Data Preparation
		// =====================================
		PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_SCHEDULE, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{job});
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult result = PUDPickupBookingController.cancel(job.Id);

		Test.stopTest();

		System.assertNotEquals(null, result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.SUCCESSFUL.name(), result.status, 'Expected to return status success.');

		// should have updated the job
		fflib_ArgumentCaptor updatableJobsCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Job__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<PUD_Job__c>) updatableJobsCaptor.capture());

		List<PUD_Job__c> updatableJobs = (List<PUD_Job__c>) updatableJobsCaptor.getValue();
		System.assertEquals(1, updatableJobs.size(), 'Expected to update only one job.');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_CANCEL, updatableJobs[0].Status__c, 'Expected to update job status to ' + PUDConstants.PUD_JOB_STATUS_CANCEL);

	}

	private class MockException extends Exception {}
}