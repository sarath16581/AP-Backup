/**
 * @description
 * Test class for PUDJobDispatchSystemSyncModule
 * @author Ranjeewa Silva
 * @date 2021-08-17
 * @group Tests
 * @domain PUD
 * @changelog
 * 2021-08-17 - Ranjeewa Silva - Created
 * 2022-02-10 - Seth Heang - Updated test method to detect Revenue Check flag change which triggers the job update to the dispatch system where job status is schedule or accepted
 * 2022-03-08 - Seth Heang - Updated test method to detect Container Payload change which triggers the job update to the dispatch system where job status is schedule or accepted
 * 2022-08-09 - Dattaraj Deshmukh - Update ContainerPayload to use Container Object.
 */

@IsTest
private class PUDJobDispatchSystemSyncModule_Test {

	@IsTest
	static void testEnsureBeforeInsertTriggerDispatchSystemSyncForEligibleJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(5, null, PUDConstants.PUD_JOB_STATUS_NEW, false);

		// set the date on jobs
		jobs[0].Date__c = Date.today();
		jobs[1].Date__c = Date.today();
		jobs[2].Date__c = Date.today().addDays(1);
		jobs[3].Date__c = Date.today().addDays(2);
		jobs[4].Date__c = Date.today().addDays(3);

		// set Job status to something other than 'New'
		jobs[1].Status__c = null;

		// =====================================
		// Stubbing
		// =====================================
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.listContains(jobs[0]))).thenReturn(new List<PUD_Job__c>{jobs[0]});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDJobTriggerHandler.getUnitOfWorkSObjectTypes());
		PUDJobDispatchSystemSyncModule module = PUDJobDispatchSystemSyncModule.newInstance();

		module.onBeforeInsert(jobs, uow);

		Test.stopTest();

		fflib_ArgumentCaptor jobsCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Job__c>.class);

		//verify that PUDUtility is called once with expected list of jobs
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>) jobsCaptor.capture());

		List<PUD_Job__c> jobsForDispatch = (List<PUD_Job__c>) jobsCaptor.getValue();
		System.assertNotEquals(null, jobsForDispatch, 'Expected a list of pud jobs to be passed in for dispatch; but passed null.');
		System.assertEquals(1, jobsForDispatch.size(), 'Expected only one pud job to be passed in for dispatch');
		System.assertEquals(Date.today(), jobsForDispatch[0].Date__c, 'Expected only current day jobs to be dispatched');
	}

	@IsTest
	static void testEnsureBeforeUpdateTriggerDispatchSystemSyncForEligibleJobs() {
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(9, null, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//jobs[0] is a current day job in status 'New'
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_NEW;
		jobs[0].Job_Instructions__c = 'test1';

		//jobs[1] is a current day job in status 'Cancelled'
		jobs[1].Status__c = PUDConstants.PUD_JOB_STATUS_CANCELLED;
		jobs[1].Job_Instructions__c = 'test1';

		//jobs[2] is a current day job in 'Schedule' status
		jobs[2].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		jobs[2].Job_Instructions__c = 'test1';

		//jobs[3] is a current day job in status 'New'
		jobs[3].Status__c = PUDConstants.PUD_JOB_STATUS_NEW;
		jobs[3].Job_Instructions__c = 'test1';

		//jobs[4] is a future job in status 'New'
		jobs[4].Date__c = Date.today().addDays(1);
		jobs[4].Status__c = PUDConstants.PUD_JOB_STATUS_NEW;
		jobs[4].Job_Instructions__c = 'test1';

		//jobs[5] is a future job in status 'New'
		jobs[5].Date__c = Date.today().addDays(1);
		jobs[5].Status__c = PUDConstants.PUD_JOB_STATUS_NEW;
		jobs[5].Job_Instructions__c = 'test1';

		//jobs[6] is a current job in status 'Accepted'
		jobs[6].Status__c = PUDConstants.PUD_JOB_STATUS_ACCEPTED;
		jobs[6].Revenue_Check__c = false;

		//jobs[7] is a current job in status 'Schedule'
		jobs[7].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		jobs[7].Revenue_Check__c = false;

		// construct a sample json structure for container payload
		jobs[8].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		jobs[8].Containers_Payload__c = JSON.serialize(new List<PUDUtility.ContainerPayload>{
			new PUDUtility.ContainerPayload(new PUD_Container__c(Type__c='Aircan', Expected_Quantity__c=5, Condition__c ='Empty')),
			new PUDUtility.ContainerPayload(new PUD_Container__c(Type__c='Trailer', Expected_Quantity__c=6, Condition__c ='Full'))

		});

		// clone the jobs - this is used as the old versions
		List<PUD_Job__c> oldJobs = new List<PUD_Job__c>{jobs[0].clone(true), jobs[1].clone(true), jobs[2].clone(true), jobs[3].clone(true), jobs[4].clone(true), jobs[5].clone(true), jobs[6].clone(true), jobs[7].clone(true), jobs[8].clone(true)};

		// now update field values on jobs to test the scenario
		jobs[0].Job_Instructions__c = 'test2';
		jobs[1].Job_Instructions__c = 'test2';
		jobs[2].Job_Instructions__c = 'test2';
		jobs[3].Status__c = PUDConstants.PUD_JOB_STATUS_CANCEL;
		jobs[4].Job_Instructions__c = 'test2';
		jobs[5].Status__c = PUDConstants.PUD_JOB_STATUS_CANCEL;

		// Update Revenue Check flag to True
		jobs[6].Revenue_Check__c = true;
		jobs[7].Revenue_Check__c = true;
		// Update Containers Payload
		jobs[8].Containers_Payload__c = JSON.serialize(new List<PUDUtility.ContainerPayload>{
			new PUDUtility.ContainerPayload(new PUD_Container__c(Type__c='Aircan', Expected_Quantity__c=10, Condition__c ='Empty')),
			new PUDUtility.ContainerPayload(new PUD_Container__c(Type__c='Trailer', Expected_Quantity__c=12, Condition__c ='Full'))

		});
		// =====================================
		// Stubbing
		// =====================================
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.anyList())).thenReturn(new List<PUD_Job__c>{jobs[2], jobs[3], jobs[6], jobs[7], jobs[8]});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDJobTriggerHandler.getUnitOfWorkSObjectTypes());
		PUDJobDispatchSystemSyncModule module = PUDJobDispatchSystemSyncModule.newInstance();

		module.onBeforeUpdate(jobs, new Map<Id, PUD_Job__c>(oldJobs), uow);

		Test.stopTest();

		fflib_ArgumentCaptor jobsCaptor = fflib_ArgumentCaptor.forClass(List<PUD_Job__c>.class);

		//verify that PUDUtility is called once with expected list of jobs
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>) jobsCaptor.capture());

		List<PUD_Job__c> jobsForDispatch = (List<PUD_Job__c>) jobsCaptor.getValue();
		System.assertNotEquals(null, jobsForDispatch, 'Expected a list of pud jobs to be passed in for dispatch; but passed null.');
		System.assertEquals(5, jobsForDispatch.size(), 'Expected only five pud jobs to be passed in for dispatch');

		Map<Id, PUD_Job__c> jobsForDispatchMap = new Map<Id, PUD_Job__c>(jobsForDispatch);
		System.assertEquals(true, jobsForDispatchMap.containsKey(jobs[2].Id), 'Expected to dispatch current day job in Schedule status when job information updated.');
		System.assertEquals(true, jobsForDispatchMap.containsKey(jobs[3].Id), 'Expected to dispatch current day job when status updated to Cancel.');
		//Confirm Revenue Check flag update trigger the sync to dispatch system
		System.assertEquals(true, jobsForDispatchMap.get(jobs[6].Id).Revenue_Check__c, 'Expected Revenue Check change to trigger the dispatch system when job status is Accepted');
		System.assertEquals(true, jobsForDispatchMap.get(jobs[7].Id).Revenue_Check__c, 'Expected Revenue Check change to trigger the dispatch system when job status is Schedule');
		//Confirm container payload update trigger the sync to dispatch system
		System.assertEquals(jobs[8].Containers_Payload__c, jobsForDispatchMap.get(jobs[8].Id).Containers_Payload__c, 'Expected containers payload change to trigger the dispatch system when job status is Schedule');
	}

	@IsTest
	static void testEndToEndTriggerIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		Network__c network = ApplicationTestDataFactory.getNetworks(1, false)[0];
		network.recordTypeId = PUDTestDataFactory.businessHubNetworkRecordType;
		network.ORG_UNIT_ADDR_2__c ='1 Main St';
		network.ORG_UNIT_ADDR_3__c ='Melbourne';
		network.State__c  ='VIC';
		network.Post_Code__c ='3121';
		network.Integrated_Job_Dispatch_Enabled__c = true;
		insert(network);

		PUD_Booking_Location__c pudBookingLocation = PUDTestDataFactory.getPUDNetworkBookingLocations(1, network.Id, false)[0];
		insert(pudBookingLocation);

		PUD_Booking__c pudBooking = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, pudBookingLocation.Id, network.Id, Date.today(), Date.today().addDays(90), null, false)[0];
		insert(pudBooking);

		PUD_Job__c pudJob = PUDTestDataFactory.getPUDJobs(1, pudBooking.Id, PUDConstants.PUD_JOB_STATUS_NEW, false)[0];
		pudJob.Depot__c = network.Id;

		// =====================================
		// Stubbing
		// =====================================
		//NONE

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// insert the job
		insert(pudJob);

		Test.stopTest();

		PUD_Job__c job = PUDJobsSelector.newInstance().selectById(new Set<Id>{pudJob.Id})[0];

		System.assertEquals(PUDConstants.PUD_JOB_STATUS_SCHEDULE, job.Status__c, 'Expected job status to update to Schedule on sending the job to dispatch system');
		System.assertEquals(false, job.Send_to_Dispatch_System__c, 'Expected \'Send to Dispatch System\' flag to be reset after triggering outbound message; but the flag is still set.');
	}
}