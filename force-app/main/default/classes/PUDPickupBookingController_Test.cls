/***
 * @description Test cases for PUDPickupBookingController
 * @author Ranjeewa Silva
 * @date 2021-08-17
 * @group Tests
 * @domain PUD
 * @changelog
 * 2021-08-17 - Ranjeewa Silva - Created.
 * 2022-03-23 - Ranjeewa Silva - Added new test methods to test bulk edit functionality.
 * 2022-04-04 - Seth Heang - Added new test method to test update dispatch job integration flag on network
 * 2022-04-21 - Ranjeewa Silva - Added test methods for retrieving dispatch photo from Digital Repository.
 * 2022-08-24 - Dattaraj Deshmukh - Updated test method 'testEnsureCancelJobActionNotAllowedForFutureJobs' to allow cancellation for today and tomorrow.
 * 								  - Renamed test method 'testEnsureTriggerDispatchSystemSyncOnlyForCurrentDayJobs' with 'testEnsureTriggerDispatchSystemSyncOnlyForJobsWithInDispatchWindow'
 */

@IsTest
private class PUDPickupBookingController_Test {

	@IsTest
	static void testEnsureTriggerDispatchSystemSyncOnlyForJobsWithInDispatchWindow() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(3, null, PUDConstants.PUD_JOB_STATUS_NEW, true);
		//jobs[0] & jobs[1] are set for today and as per PUDUtility.JOB_DISPATCH_TO_DATE respectively.
		//PUDUtility.JOB_DISPATCH_TO_DATE returns Date.today()+number configured for offset. 
		//If 'Pickup_Booking_Settings__c & Pickup_Booking_Settings__c.Job_Dispatch_Offset_Days__c' is null then it will return date = 'Date.today.addDays(1)'.
		//In this scenario since we are not creating instance of Pickup_Booking_Settings__c, it will return 'Date.today.addDays(1)'
		jobs[0].Date__c = Date.today();
		jobs[1].Date__c = PUDUtility.JOB_DISPATCH_TO_DATE;
		
		//setting jobs[2] date after 2 days.
		jobs[2].Date__c = Date.today().addDays(2);


		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(jobs);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDPickupBookingController.PickupBookingActionResult job_0_result = PUDPickupBookingController.triggerDispatchSystemSync(jobs[0].Id);
		PUDPickupBookingController.PickupBookingActionResult job_1_result = PUDPickupBookingController.triggerDispatchSystemSync(jobs[1].Id);
		PUDPickupBookingController.PickupBookingActionResult job_2_result = PUDPickupBookingController.triggerDispatchSystemSync(jobs[2].Id);

		Test.stopTest();

		//asserting job[0] is sent to dispatch
		System.assertNotEquals(null, job_0_result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.SUCCESSFUL.name(), job_0_result.status, 'Expected status not returned');

		//asserting job[1] is sent to dispatch
		System.assertNotEquals(null, job_1_result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.SUCCESSFUL.name(), job_1_result.status, 'Expected status not returned');

		//asserting job[2] throws error
		System.assertNotEquals(null, job_2_result, 'Expected a valid response, but received null');
		System.assertEquals(PUDPickupBookingController.Status.ERROR.name(), job_2_result.status, 'Expected error status not returned');
		System.assert(String.isNotBlank(job_2_result.errorMessage), 'Expected a valid error message; but was blank');
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

		//setting job after 2 days. 
		//This job should not be allowed to be cancelled. 
		//Job cancellation is only allowed within date range specified in 'Pickup_Booking_Settings__c' config.
		//Since we are not creating an instance of 'Pickup_Booking_Settings__c', 
		//default date range specified in PUDUtility.JOB_DISPATCH_FROM_DATE  & PUDUtility.JOB_DISPATCH_TO_DATE will be used.
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

	// ensure no exception is thrown when home depot cannot be found
	@IsTest
	static void testEnsureGetHomeDepotDoNotErrorWhenHomeDepotCannotBeFound() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Group> currentUserGroups = ApplicationTestDataFactory.getGroups(1, true);
		List<GroupMember> currentUserGroupMemberships = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{currentUserGroups[0].Id}, new List<Id>{(Id)UserInfo.getUserId()}, true);
		ApplicationTestDataFactory.setUnwritableFields(currentUserGroupMemberships[0], new Map<String, Object>{'Group' => currentUserGroups[0]});


		// =====================================
		// Stubbing
		// =====================================
		GroupMembersSelector mockGroupMemberSelector = (GroupMembersSelector) MockUtility.mockSelector(GroupMembersSelector.class);
		PUDNetworksSelector mockNetworkSelector = (PUDNetworksSelector) MockUtility.mockSelector(PUDNetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockGroupMemberSelector.selectByMyGroups((List<String>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, GroupMember>(currentUserGroupMemberships));
		// no matching network records returned by networks selector
		MockUtility.Mocks.when(mockNetworkSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(new List<Network__c>());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Id depotId = PUDPickupBookingController.getHomeDepotForCurrentUser();

		Test.stopTest();

		System.assertEquals(null, depotId, 'Expected null as the home depot id when current user\'s home depot cannot be found.');
	}

	// ensure id of the matching Network record is returned when current user's home depot is configured via public group.
	@IsTest
	static void testEnsureGetHomeDepotIdReturnsConfiguredDepotId() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Group> currentUserGroups = ApplicationTestDataFactory.getGroups(1, true);
		List<GroupMember> currentUserGroupMemberships = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{currentUserGroups[0].Id}, new List<Id>{(Id)UserInfo.getUserId()}, true);
		currentUserGroupMemberships[0] = (GroupMember) ApplicationTestDataFactory.setUnwritableFields(currentUserGroupMemberships[0], new Map<String, Object>{'Group' => currentUserGroups[0]});
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);


		// =====================================
		// Stubbing
		// =====================================
		GroupMembersSelector mockGroupMemberSelector = (GroupMembersSelector) MockUtility.mockSelector(GroupMembersSelector.class);
		PUDNetworksSelector mockNetworkSelector = (PUDNetworksSelector) MockUtility.mockSelector(PUDNetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockGroupMemberSelector.selectByMyGroups((List<String>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, GroupMember>(currentUserGroupMemberships));
		// matching network record returned by networks selector
		MockUtility.Mocks.when(mockNetworkSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(networks);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Id depotId = PUDPickupBookingController.getHomeDepotForCurrentUser();

		Test.stopTest();

		System.assertEquals(networks[0].Id, depotId, 'Expected valid network record id when current user\'s home depot is configured.');
	}

	// ensure bulk edit configuration values are returned.
	@IsTest
	private static void testBulkEditConfig() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> config = PUDPickupBookingController.loadBulkEditConfig();

		Test.stopTest();

		System.assertNotEquals(null, config, 'Expected valid configuration to be returned, but received null value');
		System.assert(config.containsKey('homeDepotId'), 'Expected home depot id to be returned in configuration, but not returned');
	}

	// ensure Network record for corresponding depot id is returned.
	@IsTest
	static void testGetDepotDetails() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);

		// =====================================
		// Stubbing
		// =====================================
		PUDNetworksSelector mockNetworkSelector = (PUDNetworksSelector) MockUtility.mockSelector(PUDNetworksSelector.class);


		// set up our responses
		MockUtility.Mocks.startStubbing();
		// matching network record returned by networks selector
		MockUtility.Mocks.when(mockNetworkSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Network__c>(networks));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Network__c depot = PUDPickupBookingController.getDepot(networks[0].Id);

		Test.stopTest();

		System.assertNotEquals(null, depot, 'Expected a valid depot record, but received null value');
		System.assertEquals(networks[0].Id, depot.Id, 'Expected network record not returned');
	}

	// ensure route details are returned with all active child bookings.
	@IsTest
	static void testEnsureGetRoutesReturnParentRoutesWithActiveChildBookings() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c depot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<Account> customers = ApplicationTestDataFactory.getAccounts(1, true);
		List<PUD_Booking_Location__c> bookingLocations = PUDTestDataFactory.getPUDCustomerBookingLocations(2, customers[0].Id, true);

		List<PUD_Route__c> routes = PUDTestDataFactory.getPUDRoutes(2, depot.Id, true);
		PUD_Booking__c permanentBooking_Location1 = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, bookingLocations[0].Id, depot.Id, Date.today().addDays(-7), null, null, true)[0];
		PUD_Booking__c adhocBooking_Location1 = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(1, bookingLocations[0].Id, depot.Id, Date.today().addDays(-7), null, null, true)[0];
		// set start times and dwell times on bookings
		// both bookings for location1 has valid start times and dwell times.
		permanentBooking_Location1.Start_Time__c = Time.newInstance(10, 0, 0, 0);
		permanentBooking_Location1.Dwell_Time_Planned__c = 15;
		adhocBooking_Location1.Start_Time__c = Time.newInstance(10, 30, 0, 0);
		adhocBooking_Location1.Dwell_Time_Planned__c = 5;

		PUD_Booking__c permanentBooking_Location2 = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, bookingLocations[1].Id, depot.Id, Date.today().addDays(-7), null, null, true)[0];
		PUD_Booking__c adhocBooking_Location2 = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(1, bookingLocations[1].Id, depot.Id, Date.today().addDays(-7), null, null, true)[0];
		// set start times and dwell times on bookings
		// only one booking for location 2 has a start time populated.
		permanentBooking_Location2.Start_Time__c = Time.newInstance(15, 0, 0, 0);
		permanentBooking_Location2.Dwell_Time_Planned__c = 5;

		// assign bookings to routes
		routes[0] = (PUD_Route__c) ApplicationTestDataFactory.setChildRelationships(routes[0], new Map<String, List<SObject>>{'Bookings__r' => new List<SObject>{permanentBooking_Location1, adhocBooking_Location1}});
		routes[1] = (PUD_Route__c) ApplicationTestDataFactory.setChildRelationships(routes[1], new Map<String, List<SObject>>{'Bookings__r' => new List<SObject>{permanentBooking_Location2, adhocBooking_Location2}});

		// =====================================
		// Stubbing
		// =====================================
		PUDRoutesSelector mockRoutesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRoutesSelector.selectByIdWithActiveBookings((Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(routes);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<PUDPickupBookingController.PUDRoute> pudRoutes = PUDPickupBookingController.getRoutes(new List<Id>{routes[0].Id, routes[1].Id}, new List<Id>());

		Test.stopTest();

		System.assertNotEquals(null, pudRoutes, 'Expected a list of routes, but received null');
		System.assertEquals(2, pudRoutes.size(), 'Expected number of routes not returned.');

		for (PUDPickupBookingController.PUDRoute pudRoute: pudRoutes) {
			System.assertNotEquals(null, pudRoute.route, 'Route details not populated on the returned PUDRoute instance.');
			if (pudRoute.route.Id == routes[0].Id) {
				// assert route[0]
				System.assertNotEquals(null, pudRoute.bookings, 'Active child bookings not returned with PUDRoute instance [' + pudRoute.route.Name + ']');
				System.assertEquals(2, pudRoute.bookings.size(), 'Active child bookings not returned with PUDRoute instance [' + pudRoute.route.Name + ']');
				// assert that the start / end times returned in pudRoute is based on the 2 bookings. both bookings on this route has start time and dwell time populated.
				System.assertEquals(permanentBooking_Location1.Start_Time__c, pudRoute.startTime, 'Incorrect start time returned with PUDRoute instance [' + pudRoute.route.Name + ']');
				Time expectedEndTime = adhocBooking_Location1.Start_Time__c.addMinutes(Integer.valueOf(adhocBooking_Location1.Dwell_Time_Planned__c));
				System.assertEquals(expectedEndTime, pudRoute.endTime, 'Incorrect start time returned with PUDRoute instance [' + pudRoute.route.Name + ']');
			} else if (pudRoute.route.Id == routes[1].Id) {
				// assert route[1]
				System.assertNotEquals(null, pudRoute.bookings, 'Active child bookings not returned with PUDRoute instance [' + pudRoute.route.Name + ']');
				System.assertEquals(2, pudRoute.bookings.size(), 'Active child bookings not returned with PUDRoute instance [' + pudRoute.route.Name + ']');
				// assert that the start / end times returned in pudRoute is based on the booking on which the start time and dwell time is populated.
				// 'adhocBooking_Location2' is assigned to this route - but doesn't have a valid start time for the booking. so this is ignored in determining
				// the start time of the route.
				System.assertEquals(permanentBooking_Location2.Start_Time__c, pudRoute.startTime, 'Incorrect start time returned with PUDRoute instance [' + pudRoute.route.Name + ']');
				Time expectedEndTime = permanentBooking_Location2.Start_Time__c.addMinutes(Integer.valueOf(permanentBooking_Location2.Dwell_Time_Planned__c));
				System.assertEquals(expectedEndTime, pudRoute.endTime, 'Incorrect start time returned with PUDRoute instance [' + pudRoute.route.Name + ']');
			}
		}
	}

	@IsTest
	static void testGetRoutesThrowAnExceptionOnUnexpectedError() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c depot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Route__c> routes = PUDTestDataFactory.getPUDRoutes(2, depot.Id, true);

		// =====================================
		// Stubbing
		// =====================================
		PUDRoutesSelector mockRoutesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRoutesSelector.selectByIdWithActiveBookings((Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try {
			List<PUDPickupBookingController.PUDRoute> pudRoutes = PUDPickupBookingController.getRoutes(new List<Id>{routes[0].Id, routes[1].Id}, new List<Id>());
			System.assert(false, 'Expected exception not thrown.');
		} catch (Exception ex) {
			// expected
		}
		Test.stopTest();
	}

	// ensure route details are returned with all active child bookings.
	@IsTest
	static void testEnsureUpdateBookingsSaveBookingDetails() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c depot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Booking_Location__c> bookingLocations = PUDTestDataFactory.getPUDNetworkBookingLocations(10, depot.Id, true);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(10, bookingLocations[0].Id, depot.Id, Date.today().addDays(-7), null, null, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.eqList(bookings))).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			PUDPickupBookingController.updateBookings(bookings);
		} catch (Exception ex) {
			// unexpected exception thrown - fail the test
			System.assert(false, 'Unexpected exception thrown : ' + ex.getMessage());
		}

		Test.stopTest();
	}

	// ensure route details are returned with all active child bookings.
	@IsTest
	static void testUpdateBookingsDMLException() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c depot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Booking_Location__c> bookingLocations = PUDTestDataFactory.getPUDNetworkBookingLocations(10, depot.Id, true);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(10, bookingLocations[0].Id, depot.Id, Date.today().addDays(-7), null, null, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.eqList(bookings))).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			PUDPickupBookingController.updateBookings(bookings);
			System.assert(false, 'Expected to throw an Exception on any errors. but not thrown.');
		} catch (Exception ex) {
			// expected
		}

		Test.stopTest();
	}

	// ensure the update on job dispatch integration flag on network in System mode is successful
	@IsTest
	static void testUpdateNetworkInWithoutSharingMode() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c depot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		depot.recordtypeid  = PUDTestDataFactory.businessHubNetworkRecordType;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.eq(depot))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			// enable job dispatch flag and call void method in without sharing context
			depot.Integrated_Job_Dispatch_Enabled__c = true;
			PUDPickupBookingController.updateDispatchJobIntegration(depot);
		} catch (Exception ex) {
			// unexpected exception thrown - fail the test
			System.assert(false, 'Unexpected exception thrown : ' + ex.getMessage());
		}
		Test.stopTest();
		// verify that dmlUpdate has been made 
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
	}

	// ensure retrieving dispatch photos from digital repository is delegated to DigitalRepositoryService
	@IsTest
	private static void testGetDispatchPhoto() {

		// =====================================
		// Data Preparation
		// =====================================
		Pickup_Booking_Settings__c settings = new Pickup_Booking_Settings__c();
		settings.Dispatch_Photo_Bucket_Name__c = 'testbucket';
		insert(settings);

		// =====================================
		// Stubbing
		// =====================================
		DigitalRepositoryService mockDigitalRepositoryService = (DigitalRepositoryService) MockUtility.mockUtility(DigitalRepositoryService.class);

		HttpResponse mockHttpResponse = new HttpResponse();
		mockHttpResponse.setStatusCode(200);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDigitalRepositoryService.getContinuation(fflib_Match.anyString(), (String) fflib_Match.anyObject())).thenReturn(new Continuation(60));
		DigitalRepositoryService.DocumentApiResponse mockResponse = new DigitalRepositoryService.DocumentApiResponse();
		MockUtility.Mocks.when(mockDigitalRepositoryService.parseResponse((HttpResponse)fflib_Match.eq(mockHttpResponse))).thenReturn(mockResponse);
		MockUtility.Mocks.stopStubbing();

		Test.setContinuationResponse('reqlabel', mockHttpResponse);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		Continuation cont = (Continuation)PUDPickupBookingController.getDispatchPhoto('TEST');
		DigitalRepositoryService.DocumentApiResponse response = (DigitalRepositoryService.DocumentApiResponse) PUDPickupBookingController.dispatchPhotoCallback(new List<String>{'reqlabel'}, null);

		Test.stopTest();

		System.assertNotEquals(null, cont, 'Expected a valid continuation instance, but received null.');
		System.assertEquals(mockResponse, response, 'Expected to return parsed response from DigitalRepositoryService, but got something different.');
	}

	private class MockException extends Exception {}
}