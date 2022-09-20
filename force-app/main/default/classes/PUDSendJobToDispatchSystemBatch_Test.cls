/*-------------------------    
    Overview: Test class for PUDSendJobToDispatchSystemBatch
	History:
	27/07/2021	arjun.singh@austpost.com.au - Created
	24/08/2022  Dattaraj Deshmukh - Updated selectJobsByDateAndStatusQueryLocator params to pass dates.
	-------------------------  
*/
@IsTest
private class PUDSendJobToDispatchSystemBatch_Test {

	@IsTest
	static void testBatchStart() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		PUDJobsSelector mockSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);
		Database.QueryLocator queryLocator = Database.getQueryLocator([Select Id from PUD_Job__c]);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectJobsByDateAndStatusQueryLocator((Date) fflib_Match.anyDate(), (Date) fflib_Match.anyDate(), (String) fflib_Match.anyString())).thenReturn(queryLocator);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDSendJobToDispatchSystemBatch batch = new PUDSendJobToDispatchSystemBatch();
		Database.QueryLocator ql = batch.start(null);

		Test.stopTest();

		System.assertNotEquals(null, ql, 'Expect a valid query locator to be returned');
		//verify that selector is called once with expected arguments to get the query locator
		((PUDJobsSelector) MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectJobsByDateAndStatusQueryLocator((Date) fflib_Match.eqDate(PUDUtility.JOB_DISPATCH_FROM_DATE), (Date) fflib_Match.eqDate(PUDUtility.JOB_DISPATCH_TO_DATE), (String) fflib_Match.eqString(PUDConstants.PUD_JOB_STATUS_NEW));

	}

	@IsTest
	static void testBatchExecute() {
		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Job__c> pudJobList = PUDTestDataFactory.getPUDJobs(5, null, PUDConstants.PUD_JOB_STATUS_NEW, true);

		// =====================================
		// Stubbing
		// =====================================        
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.eqList(pudJobList))).thenReturn(new List<PUD_Job__c>(pudJobList));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyList(), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PUDSendJobToDispatchSystemBatch batchJob = new PUDSendJobToDispatchSystemBatch();
		batchJob.execute(null, pudJobList);
		Test.stopTest();

		// should have updated the job
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) fflib_Match.anyList(), (Boolean) fflib_Match.anyBoolean());
	}

	@IsTest
	static void testBatchExecuteUnexpectedException() {
		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Job__c> pudJobList = PUDTestDataFactory.getPUDJobs(5, null, PUDConstants.PUD_JOB_STATUS_NEW, true);

		// =====================================
		// Stubbing
		// =====================================
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPUDUtil.setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>)fflib_Match.eqList(pudJobList))).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PUDSendJobToDispatchSystemBatch batchJob = new PUDSendJobToDispatchSystemBatch();
		batchJob.execute(null, pudJobList);
		Test.stopTest();

		// verify that no updates has been done
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>) fflib_Match.anyList(), (Boolean) fflib_Match.anyBoolean());
	}

	@IsTest
	static void testBatchJobEndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================

		//insert custom settings to disable booking and job triggers.
		//Disabling triggers will allow to TEST if job status are changed by BATCH only.
        insert new SystemSwitch__c(SetupOwnerId=UserInfo.getOrganizationId(),
		DisableTriggers__c=true, ObjectTriggersToBeDisabled__c= 'PUD_Booking__c,PUD_Job__c,');

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

		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(20, pudBookingLocation.Id, network.Id, Date.today(), Date.today().addDays(90), null, false);
		insert(bookings);

		List<PUD_Job__c> jobs = new List<PUD_Job__c>();
		for (PUD_Booking__c booking: bookings) {
			PUD_Job__c job = PUDTestDataFactory.getPUDJobs(1, booking.Id, PUDConstants.PUD_JOB_STATUS_NEW, false)[0];
			job.Depot__c = network.Id;
			jobs.add(job);
		}
		insert(jobs);

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PUDSendJobToDispatchSystemBatch batchJob = new PUDSendJobToDispatchSystemBatch();
		// run the scheduler
		batchJob.execute(null);
		Test.stopTest();

		//asserting job's status changed by BATCH.
		List<PUD_Job__c> updatedJobs = PUDJobsSelector.newInstance().selectById(new Map<Id,PUD_Job__c>(jobs).keySet());
		for (PUD_Job__c job: updatedJobs) {
			System.assertEquals(PUDConstants.PUD_JOB_STATUS_SCHEDULE, job.Status__c, 'Expected job status to be updated after sending to Dispatch system');
		}
	}

	private class MockException extends Exception{}
}