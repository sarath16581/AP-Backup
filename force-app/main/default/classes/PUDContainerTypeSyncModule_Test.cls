/**
 * @description Test class for PUDContainerTypeSyncModule
 * @author Dattaraj Deshmukh
 * @date 2022-07-25
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-07-25 - Dattaraj Deshmukh - Created
  */

@IsTest
private class PUDContainerTypeSyncModule_Test {
	
	
	@IsTest
	public static void testEnsureAfterDeleteContainer() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDContainerTriggerHandler.getUnitOfWorkSObjectTypes());

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);
		
		//associate jobs with bookings
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Jobs__r' => jobs});

		//create a booking container
		PUD_Container__c bookingContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallets', 'Empty', true )[0];

		//associating containers with bookings.
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{bookingContainer}});

		//create a job container and associated it with jobs
		PUD_Container__c jobContainer = PUDTestDataFactory.getPUDJobContainers(1, pudBookingList[0].Id, jobs[0].Id, 'Pallets', 'Empty', true )[0];
		jobs[0] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{jobContainer}});


		// =====================================
		// Stubbing
		// =====================================
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector mockJobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockBookingSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(pudBookingList);
		MockUtility.Mocks.when(mockJobSelector.selectByBookingIdStatusAndFromDate((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyDate(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(jobs);
		
		//mocking PUDUtility method call.
		((PUDUtility)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockPUDUtil)).refreshContainerTypes((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		PUDContainerTypeSyncModule module = PUDContainerTypeSyncModule.newInstance();

		module.onAfterDelete(new List<PUD_Container__c>{bookingContainer}, uow);

		Test.stopTest();

		//verify that PUDUtility is called once with expected list of jobs
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).refreshContainerTypes(new Set<Id>{pudBookingList[0].Id}, uow);

		//verify that correct params are being passed to PUDUtility method.
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).refreshContainerTypes((Set<Id>)fflib_Match.eq(new Set<Id>{pudBookingList[0].Id}), (ApplicationUnitOfWork) fflib_Match.eq(uow));

	}
	
	@IsTest
	public static void testEnsureAfterUpdateContainer() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDContainerTriggerHandler.getUnitOfWorkSObjectTypes());

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);
		
		//associate jobs with bookings
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Jobs__r' => jobs});

		//create a booking container
		PUD_Container__c bookingContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallets', 'Empty', true )[0];

		//associating containers with bookings.
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{bookingContainer}});

		//create a job container
		PUD_Container__c jobContainer = PUDTestDataFactory.getPUDJobContainers(1, pudBookingList[0].Id, jobs[0].Id, 'Pallets', 'Empty', true )[0];
		jobs[0] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{jobContainer}});


		// =====================================
		// Stubbing
		// =====================================
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector mockJobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockBookingSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(pudBookingList);
		MockUtility.Mocks.when(mockJobSelector.selectByBookingIdStatusAndFromDate((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyDate(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(jobs);
		//mocking PUDUtility method call.
		((PUDUtility)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockPUDUtil)).refreshContainerTypes((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());


		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		//updating type for booking container.
		bookingContainer.Type__c = 'Aircan';

		PUDContainerTypeSyncModule module = PUDContainerTypeSyncModule.newInstance();

		module.onAfterUpdate(new List<PUD_Container__c>{bookingContainer}, null, uow);

		Test.stopTest();

		//verify that PUDUtility is called once with expected list of jobs
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).refreshContainerTypes(new Set<Id>{pudBookingList[0].Id}, uow);

		//verify that correct params are being passed to PUDUtility method.
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).refreshContainerTypes((Set<Id>)fflib_Match.eq(new Set<Id>{pudBookingList[0].Id}), (ApplicationUnitOfWork) fflib_Match.eq(uow));

	}

	@IsTest
	public static void testEnsureAfterInsertContainer() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDContainerTriggerHandler.getUnitOfWorkSObjectTypes());

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//create a booking container
		PUD_Container__c c1 = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallets', 'Empty', true )[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector mockJobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockBookingSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(pudBookingList);
		MockUtility.Mocks.when(mockJobSelector.selectByBookingIdStatusAndFromDate((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyDate(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(jobs);
		
		//mocking PUDUtility method call.
		((PUDUtility)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockPUDUtil)).refreshContainerTypes((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PUDContainerTypeSyncModule module = PUDContainerTypeSyncModule.newInstance();

		module.onAfterInsert(new List<PUD_Container__c>{c1}, uow);

		Test.stopTest();

		//verify that PUDUtility is called once with expected list of jobs
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).refreshContainerTypes(new Set<Id>{pudBookingList[0].Id}, uow);

		//verify that correct params are being passed to PUDUtility method.
		((PUDUtility) MockUtility.Mocks.verify(mockPUDUtil, MockUtility.Mocks.times(1))).refreshContainerTypes((Set<Id>)fflib_Match.eq(new Set<Id>{pudBookingList[0].Id}), (ApplicationUnitOfWork) fflib_Match.eq(uow));


		
	}

	@IsTest
	static void testEnsureBeforeInsertTriggerContainerDuplicatePrevention() {
		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		
		PUD_Container__c c1 = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallets', 'Empty', true )[0];
		PUD_Container__c c2 = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Aircan', 'Empty', true )[0];

		PUD_Container__c newDuplicateContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallets', 'Empty', true )[0];

		//associating containers with bookings.
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{c1, c2}});


		// =====================================
		// Stubbing
		// =====================================
		PUDContainersSelector mockContainerSelector = (PUDContainersSelector)MockUtility.mockSelector(PUDContainersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContainerSelector.selectBookingContainersByBookingIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PUD_Container__c>{c1,c2});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PUDContainerTriggerHandler.getUnitOfWorkSObjectTypes());
		PUDContainerTypeSyncModule module = PUDContainerTypeSyncModule.newInstance();


		module.onBeforeInsert(new List<PUD_Container__c>{newDuplicateContainer}, uow);

		// make sure new container creation is prevented under a booking.
		System.assertEquals(true, newDuplicateContainer.hasErrors(), 'Expected validation error duplicated container is being created');

		Test.stopTest();
	}

	
	@IsTest
	static void testEndToEndTriggerIntegrationForInsert() {
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
		insert(pudJob);

		PUD_Container__c bookingContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBooking.Id, 'Pallets', 'Empty', false)[0];


		// =====================================
		// Stubbing
		// =====================================
		//NONE

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		insert(bookingContainer);
		Test.stopTest();


		List<PUD_Container__c> jobContainers = PUDContainersSelector.newInstance().selectByJobIds(new Set<Id>{pudJob.Id}, new Set<Object>());

		System.assertEquals(jobContainers[0].Type__c, bookingContainer.Type__c, 'Expected job containers type to match booking containers type.');
		System.assertEquals(jobContainers[0].Condition__c, bookingContainer.Condition__c, 'Expected job containers type to match booking containers type.');
		System.assertEquals(jobContainers[0].Booking__c, pudBooking.Id, 'Expected job container to be created under same booking where booking container was created.');
		System.assertEquals(jobContainers[0].Job__c, pudJob.Id,'Expected job container is created under a job');
		System.assertEquals(1, jobContainers.size(),' There should be only 1 job container created');
	}
}
