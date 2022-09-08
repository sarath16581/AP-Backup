/**
* @author Andrew Judd
* @date 2019-09-17
* @group PUD Project
* @tag Test Class
* @tag PUD_Booking_Location__c & PUD_Booking__c
* @domain Interoperability PUD Project
* @description Overview: Test Class to test PUD_Booking_Location__c,PUD_Booking__c object Triggers
* Note that the Network trigger is testing in TestNetworkUtil.testNetworkAddressUpdate
* 2019-10-09 - ajudd@salesforce.com  - Added custom setting set in dataSetup
* 2019-11-20 - ajudd@salesforce.com  - Added set of Depot on create booking
* 2019-12-06 - ajudd@salesforce.com  - Updated validate03UpdateBookingJobUpdated to update contact name instead of route - as route now a lookup field
* 2020-06-17 - Dheeraj Mandavilli    - Updated the Comments format to latest format.
* 2020-08-09 - arjun.singh@auspost.com.au - Test method for  update of network on Booking and jobs when network changes on location
* 2021-08-17 - Ranjewa Silva - Added tests for triggering dispatch system sync for eligible jobs
* 2021-09-28 - Ranjewa Silva - Added tests to verify additional address fields (dpid, frontage geocode, side of street code) are
*                              populated on Job records.
* 2021-11-22 - Mathew Jose - Added tests for job cancellation on Booking Exception creation provided jobs are not completed.
* 2022-02-10 - Seth Heang - Added test method for updating booking location details to also flow to booking and job details where job status is schedule or accepted
* 2022-02-28 - Seth Heang - Update test methods to test containers and product types for the booking-job sync validation for jobs with status 'New', 'Schedule', 'Accept' and 'Completed'
* 2022-04-11 - Seth Heang - Added test method to test booking's before insert trigger and validate booking's default depot from route's depot
* 2022-07-23 - Dattaraj Deshmukh - Added test methods for container types, removed references OLD Empty_/Full_ fields for containers from PUD_JOb__c object. 
* 2022-09-06 - Dattaraj Deshmukh - updated test methods 'validate03UpdateBookingJobUpdated' and 'validate05BookingJobMatch' to assert synchronisation of fields from booking onto jobs.
*/
@isTest
public with sharing class PUDUtility_Test {

	public static Date DATE_TODAY = date.today();
	public static String BOOKING_CONTACT = 'Don';

	@testSetup static void dataSetup() {

		// Create Custom Settings
		Pickup_Booking_Settings__c custSettings = new Pickup_Booking_Settings__c();
		custSettings.Job_Offset_Days__c = 7;
		insert custSettings;

	}

	//Validate that when creating an active contacted customer booking - jobs are created and associated to the booking location and account
	testmethod static void validate01CreateBookingActiveCustomer(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;

		Test.stopTest();

		//Confirm jobs associated to booking location
		jobsNewList = [SELECT Id FROM PUD_Job__c WHERE Booking_Location__c = :recordIdMap.get('blCust')];
		System.assertNotEquals(0, jobsNewList.size());

		//Confirm jobs associated to customer account
		jobsNewList = [SELECT Id FROM PUD_Job__c WHERE Customer__c = :recordIdMap.get('acc')];
		System.assertNotEquals(0, jobsNewList.size());


	}

	//Validate that when creating an active contacted network booking - jobs are created and associated to the booking location and network
	testmethod static void validate02CreateBookingActiveNetwork(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create a Booking for network booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blNetLPO'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;

		Test.stopTest();

		//Confirm jobs associated to booking location
		jobsNewList = [SELECT Id FROM PUD_Job__c WHERE Booking_Location__c = :recordIdMap.get('blNetLPO')];
		System.assertNotEquals(0, jobsNewList.size());

		//Confirm jobs associated to the network
		jobsNewList = [SELECT Id FROM PUD_Job__c WHERE Network__c = :recordIdMap.get('netLPO')];
		System.assertNotEquals(0, jobsNewList.size());
	}

	//Validate that when updating a booking with a job, where the update DOES update job detail, that job is updated and its field is changed to the new value
	//Update booking contact name
	testmethod static void validate03UpdateBookingJobUpdated(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Job__c> jobsList = new List<PUD_Job__c>();
		
		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;

		//Update booking contact name and dock number - which will update job contact name
		booking.Contact_Name__c = 'Donald Duck';
		booking.Dock_Number__c = '15';
		update booking;

		Test.stopTest();

		//Get job contact name for updated job
		jobsList = [SELECT Contact_Name__c, Dock_Number__c FROM PUD_Job__c WHERE Booking__c = :booking.Id];

		//assert contact name and dock number on booking is synchronised with job
		System.assertEquals(booking.Contact_Name__c, jobsList[0].Contact_Name__c);
		System.assertEquals(booking.Dock_Number__c, jobsList[0].Dock_Number__c);

	}

	//Validate that when updating a booking with a job, where the update DOES NOT update any job detail, that job is not updated
	//Update booking future end date from null to 30 days in future
	testmethod static void validate04UpdateBookingJobNotUpdated(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Job__c> jobsList = new List<PUD_Job__c>();
		DateTime dtJobCreated;
		DateTime dtJobModified;
		Boolean bolJobCreatedModifiedMatch;

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;

		//Update booking route - which will update job route
		booking.Expiry_Date__c = DATE_TODAY.addDays(30);
		update booking;

		Test.stopTest();

		//Get jobs for booking, and get created and modified times
		jobsList = [SELECT CreatedDate, LastModifiedDate FROM PUD_Job__c WHERE Booking__c = :booking.Id];
		dtJobCreated = jobsList[0].CreatedDate;
		dtJobModified = jobsList[0].LastModifiedDate;

		//Compare created and updated times
		bolJobCreatedModifiedMatch = (dtJobCreated == dtJobModified);

		//Confirm date and update times the same (i.e. updating the booking did not result in the job being updated)
		System.assertEquals(true, bolJobCreatedModifiedMatch);

	}
	//Validate that when a job is created from a booking that the job fields match the booking fields
	testmethod static void validate05BookingJobMatch(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
		List<PUD_Job__c> jobsList = new List<PUD_Job__c>();

		String strJobFieldValues;
		String strBookingFieldValues;
		Boolean bolBookingJobMatch;

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		// Add product type details, dock number to test on newly created jobs with 'New' Status
		booking.Regular_Product__c = true;
		booking.International_Product__c = false;
		booking.Express_Product__c = true;
		booking.Dock_Number__c = '2';

		insert booking;

		Test.stopTest();

		//Get jobs
		jobsList = [SELECT
				Regular_Product__c,
				International_Product__c,
				Express_Product__c,
				Dock_Number__c 
				FROM PUD_Job__c WHERE Booking__c = :booking.Id];
		
		//asserting booking fields are synchronised on jobs
		system.assertEquals(booking.Regular_Product__c, jobsList[0].Regular_Product__c, 'Expected fields values to be same, but found different');
		system.assertEquals(booking.International_Product__c, jobsList[0].International_Product__c, 'Expected fields values to be same, but found different');
		system.assertEquals(booking.Express_Product__c, jobsList[0].Express_Product__c, 'Expected fields values to be same, but found different');
		system.assertEquals(booking.Dock_Number__c, jobsList[0].Dock_Number__c, 'Expected fields values to be same, but found different');
		
	}

	//Validate that when adding a booking exception the job for the parent and child (delivery booking) is cancelled
	testmethod static void validate06DeliveryAndBookingExceptionTest(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Job__c> jobsPUList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobsDelList = new List<PUD_Job__c>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create Pickup Booking for customer booking location
		PUD_Booking__c bookingPU = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert bookingPU;

		//Create a Delivery Booking for network booking location (setting parent as  the customer booking)
		PUD_Booking__c bookingDel = PUDTestUtility.createBooking('AP_Dependant_Delivery', recordIdMap.get('blNetLPO'),null, bookingPU.Id, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert bookingDel;

		//Create a booking exception for today
		PUD_Booking_Exception__c bookingEx = PUDTestUtility.createBookingException(bookingPU.Id, DATE_TODAY, DATE_TODAY);
		insert bookingEx;

		Test.stopTest();

		//Confirm the pickup job has been cancelled
		jobsPUList = [SELECT Id FROM PUD_Job__c WHERE Booking__c = :bookingPU.Id AND Date__c = :DATE_TODAY AND Status__c = 'New'];
		System.assertEquals(0, jobsPUList.size());

		//Confirm the delivery job has been cancelled
		jobsDelList = [SELECT Id FROM PUD_Job__c WHERE Booking__c = :bookingDel.Id AND Date__c = :DATE_TODAY AND Status__c = 'New'];
		System.assertEquals(0, jobsDelList.size());
	}

	//Validate that when updating the dicated fields on the Booking Location, these are updated on the dependent records
	testmethod static void validate07BookingLocationUpdateTest(){

		//Create Test Data
		Map<String, Id> recordIdMap = PUDTestUtility.createPUDBasicRecords();

		//Create Pickup Booking for customer booking location
		PUD_Booking__c activeBooking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		PUD_Booking__c expiredBooking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		expiredBooking.Effective_Date__c = Date.today().addDays(-7);
		expiredBooking.Expiry_Date__c = Date.today().addDays(-6);
		insert new PUD_Booking__c[]{activeBooking, expiredBooking};

		Test.startTest();

		//Update the address details on the location
		List<PUD_Booking_Location__c> bookingLocationList = [SELECT Id, Street__c FROM PUD_Booking_Location__c WHERE Id = :recordIdMap.get('blCust')];
		for(PUD_Booking_Location__c bookingLocation : bookingLocationList) {
			bookingLocation.Street__c = '99 New St';
			bookingLocation.Geo__Latitude__s = -36.827371;
			bookingLocation.Geo__Longitude__s = 145.12342;
			bookingLocation.Side_Of_Street_Code__c = 'ANY';
			bookingLocation.Frontage_Geo__Latitude__s = -36.82737222;
			bookingLocation.Frontage_Geo__Longitude__s = 145.12342333;
			bookingLocation.DPID__c = '11111111';
		}
		update bookingLocationList;

		Test.stopTest();

		//Confirm the address details on the booking has been updated
		PUD_Booking__c updatedBooking = [SELECT DPID__c, Street__c, Geo__Latitude__s, Geo__Longitude__s, Frontage_Geo__Latitude__s, Frontage_Geo__Longitude__s, Side_Of_Street_Code__c FROM PUD_Booking__c WHERE Id = :activeBooking.Id];
		System.assertEquals(bookingLocationList[0].Street__c, updatedBooking.Street__c, 'Expected the booking street to be updated to match booking location street');
		System.assertEquals(bookingLocationList[0].DPID__c, updatedBooking.DPID__c, 'Expected the booking dpid to be updated to match booking location dpid');
		System.assertEquals(bookingLocationList[0].Geo__Latitude__s, updatedBooking.Geo__Latitude__s, 'Expected the booking geo code to be updated to match booking location geo code');
		System.assertEquals(bookingLocationList[0].Geo__Longitude__s, updatedBooking.Geo__Longitude__s, 'Expected the booking geo code to be updated to match booking location geo code');
		System.assertEquals(bookingLocationList[0].Frontage_Geo__Latitude__s, updatedBooking.Frontage_Geo__Latitude__s, 'Expected the booking frontage geo code to be updated to match booking location frontage geo code');
		System.assertEquals(bookingLocationList[0].Frontage_Geo__Longitude__s, updatedBooking.Frontage_Geo__Longitude__s, 'Expected the booking frontage geo code to be updated to match booking location frontage geo code');
		System.assertEquals(bookingLocationList[0].Side_Of_Street_Code__c, updatedBooking.Side_Of_Street_Code__c, 'Expected the booking side of street code to be updated to match booking location');

		//Confirm the address details on the job has been updated
		PUD_Job__c updatedJob = [SELECT Location_DPID__c, Street__c, Geo__Latitude__s, Geo__Longitude__s, Location_Frontage_Geo__Latitude__s, Location_Frontage_Geo__Longitude__s, Location_Side_Of_Street_Code__c FROM PUD_Job__c WHERE Booking__c = :activeBooking.Id AND Date__c=TODAY];
		System.assertEquals(bookingLocationList[0].Street__c, updatedJob.Street__c, 'Expected the job to be updated to match booking location street');
		System.assertEquals(bookingLocationList[0].DPID__c, updatedJob.Location_DPID__c, 'Expected the job to be updated to match booking location dpid');
		System.assertEquals(bookingLocationList[0].Geo__Latitude__s, updatedJob.Geo__Latitude__s, 'Expected the job to be updated to match booking location geo code');
		System.assertEquals(bookingLocationList[0].Geo__Longitude__s, updatedJob.Geo__Longitude__s, 'Expected the job to be updated to match booking location geo code');
		System.assertEquals(bookingLocationList[0].Frontage_Geo__Latitude__s, updatedJob.Location_Frontage_Geo__Latitude__s, 'Expected the job to be updated to match booking location frontage geo code');
		System.assertEquals(bookingLocationList[0].Frontage_Geo__Longitude__s, updatedJob.Location_Frontage_Geo__Longitude__s, 'Expected the job to be updated to match booking location frontage geo code');
		System.assertEquals(bookingLocationList[0].Side_Of_Street_Code__c, updatedJob.Location_Side_Of_Street_Code__c, 'Expected the job to be updated to match booking location');

		// confirm the expired booking is not updated
		expiredBooking = [SELECT DPID__c, Street__c FROM PUD_Booking__c WHERE Id = :expiredBooking.Id];
		System.assertNotEquals(bookingLocationList[0].Street__c, expiredBooking.Street__c, 'Expected expired booking to remain unchanged when booking location is updated.');
		System.assertNotEquals(bookingLocationList[0].DPID__c, expiredBooking.DPID__c, 'Expected expired booking to remain unchanged when booking location is updated.');
	}

	//Test batch class refreshing all
	static testMethod void validate10BatchClassTestRefreshAll()
	{
		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
		List<PUD_Job__c> jobsList = new List<PUD_Job__c>();
		Set<Id> bookingIdSet = new Set<Id>();
		Boolean bolRefreshAll = true;

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		//Create some bookings
		for(Integer i=0 ; i<2; i++)
		{
			PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
			bookingList.add(booking);
		}

		insert bookingList;
		bookingIdSet = (new Map<Id,PUD_Booking__c>(bookingList)).keySet();

		//Delete all Jobs
		jobsList = [SELECT Id FROM PUD_Job__c WHERE Booking__c IN :bookingIdSet];
		delete jobsList;

		//Confirm no jobs
		jobsList = [SELECT Id FROM PUD_Job__c WHERE Booking__c IN :bookingIdSet];
		System.assertEquals(0, jobsList.size());

		Test.startTest();
		//Call batch process to refresh jobs
		Id batchInstanceId = Database.executeBatch(new PUDCreateJobBatch(bolRefreshAll),1000);
		Test.stopTest();

		//Confirm Jobs created
		jobsList = [SELECT Id FROM PUD_Job__c WHERE Booking__c IN :bookingIdSet];
		System.assertNotEquals(0, jobsList.size());
	}

	//Test batch class just adding new
	static testMethod void validate11BatchClassTestCreateNew()
	{
		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
		List<PUD_Job__c> jobsList = new List<PUD_Job__c>();
		Set<Id> bookingIdSet = new Set<Id>();
		Boolean bolRefreshAll = false;

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		//Create some bookings
		for(Integer i=0 ; i<2; i++)
		{
			PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
			bookingList.add(booking);
		}

		insert bookingList;
		bookingIdSet = (new Map<Id,PUD_Booking__c>(bookingList)).keySet();

		//Delete all Jobs
		jobsList = [SELECT Id FROM PUD_Job__c WHERE Booking__c IN :bookingIdSet];
		delete jobsList;

		//Confirm no jobs
		jobsList = [SELECT Id FROM PUD_Job__c WHERE Booking__c IN :bookingIdSet];
		System.assertEquals(0, jobsList.size());

		Test.startTest();
		//Call batch process to refresh jobs
		Id batchInstanceId = Database.executeBatch(new PUDCreateJobBatch(bolRefreshAll),1000);
		Test.stopTest();

		//Confirm Jobs created
		jobsList = [SELECT Id FROM PUD_Job__c WHERE Booking__c IN :bookingIdSet];
		System.assertNotEquals(0, jobsList.size());
	}
	//Test scheduled class
	static testMethod void validate12ScheduleClassTest(){
		String sch = '0 0 23 * * ?';

		Test.StartTest();

		PUDCreateJobBatchScheduler sh1 = new PUDCreateJobBatchScheduler();
		System.Schedule('Test check', sch, sh1);

		Test.stopTest();
	}
	//Test no Pickup from Booking Location Method
	static testMethod void noPickupfromBookingLocationTest_Positive(){
		Map<String, Id> recordIdMap = new Map<String,Id>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		Insert booking;

		Test.StartTest();

		string bookingId= PUDUtility.noPickupfromBookingLocation(recordIdMap.get('blCust'));
		system.debug('Booking Id:::'+bookingId);
		Test.stopTest();
	}
	//Test no Pickup from Booking Location Method
	static testMethod void noPickupfromBookingLocationTest_Negative(){
		Map<String, Id> recordIdMap = new Map<String,Id>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();


		Test.StartTest();

		string bookingId= PUDUtility.noPickupfromBookingLocation(recordIdMap.get('blCust'));
		system.debug('Booking Id:::'+bookingId);
		Test.stopTest();
	}
	//Validate that when updating Network on the Booking Location, these are updated on the dependent Booking and Jobs
	testmethod static void validateBookingLocationNetworkUpdateTest(){

		Map<String, Id> recordIdMap = new Map<String,Id>();
		List<PUD_Booking_Location__c> bookingLocationList = new List<PUD_Booking_Location__c>();
		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
		List<PUD_Job__c> jobsList = new List<PUD_Job__c>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		PUD_Booking__c bookingPU = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert bookingPU;

		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Dependant_Delivery', recordIdMap.get('blNetLPO'),null, bookingPU.Id, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;

		Test.startTest();

		//Update the Network on the location
		Network__c networkSPB =[Select Id from Network__c where recordType.developerName= 'Street_Posting_Box_6'];

		bookingLocationList = [SELECT Id, Street__c FROM PUD_Booking_Location__c WHERE Id = :recordIdMap.get('blNetLPO')];
		for(PUD_Booking_Location__c bookingLocation : bookingLocationList){
			bookingLocation.Network__c = networkSPB.Id;
		}
		update bookingLocationList;

		Test.stopTest();

		//Confirm the Network.. on the booking has been updated
		bookingList = [SELECT Network__c FROM PUD_Booking__c WHERE Id = :booking.Id];
		System.assertEquals(bookingList[0].Network__c, networkSPB.Id);

		//Confirm the Network.. on the job has been updated
		jobsList = [SELECT Network__c FROM PUD_Job__c WHERE Booking__c = :booking.Id];
		System.assertEquals(jobsList[0].Network__c, networkSPB.Id);

	}

	// validate triggering dispatch system sync for eligible depots
	testmethod static void validateSetEligibleJobsToTriggerDispatchSystemSync() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Network__c> depots = ApplicationTestDataFactory.getNetworks(2, true);
		// depot[0] has integrated job dispatch enabled
		depots[0].Integrated_Job_Dispatch_Enabled__c = true;
		// depot[0] has integrated job dispatch disabled
		depots[1].Integrated_Job_Dispatch_Enabled__c = false;

		PUD_Job__c jobForIntegrationEnabledDepot = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];
		jobForIntegrationEnabledDepot.Depot__c = depots[0].Id;

		PUD_Job__c jobForIntegrationDisabledDepot = PUDTestDataFactory.getPUDJobs(1, null, PUDConstants.PUD_JOB_STATUS_NEW, true)[0];
		jobForIntegrationDisabledDepot.Depot__c = depots[1].Id;

		// =====================================
		// Stubbing
		// =====================================
		NetworksSelector mockSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Network__c>(depots));
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<PUD_Job__c> eligibleJobs = PUDUtility.getInstance().setEligibleJobsToTriggerDispatchSystemSync(new List<PUD_Job__c> {jobForIntegrationEnabledDepot, jobForIntegrationDisabledDepot});

		Test.stopTest();

		System.assertEquals(1, eligibleJobs.size(), 'Expected to filter out PUD Jobs for depots not enabled for integrated job dispatch');
		System.assertEquals(jobForIntegrationEnabledDepot.Id, eligibleJobs[0].Id, 'Expected to filter out PUD Jobs for depots not enabled for integrated job dispatch');
		System.assertEquals(true, eligibleJobs[0].Send_to_Dispatch_System__c, 'Expected Send_to_Dispatch_System__c flag to be set to true on eligible jobs');
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_SCHEDULE, eligibleJobs[0].Status__c, 'Expected Job status to be set to ' + PUDConstants.PUD_JOB_STATUS_SCHEDULE + ' on eligible jobs');

		// ensure the selector is called once
		((NetworksSelector)MockUtility.Mocks.verify(mockSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
	}

	// validate that updating the booking does not update job after the job has been completed.
	// Update booking contact name
	testmethod static void validateUpdatingBookingDoesNotUpdateJobAlreadyCompleted(){

		Map<String, Id> recordIdMap = new Map<String,Id>();

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		// Add container and product type details
		booking.Regular_Product__c = true;
		booking.International_Product__c = false;
		booking.Express_Product__c = true;

		insert booking;


		List<PUD_Container__c> bookingContainersToInsert = new List<PUD_Container__c>();

		//create booking containers
		PUD_Container__c bookingContainerTrailer = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Trailer', 'Empty', false )[0];
		bookingContainerTrailer.Expected_Quantity__c = 5;
		bookingContainersToInsert.add(bookingContainerTrailer);

		PUD_Container__c bookingContainerULD = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'ULD', 'Empty', false )[0];
		bookingContainerULD.Expected_Quantity__c = 4;
		bookingContainersToInsert.add(bookingContainerULD);


		PUD_Container__c bookingContainerColby = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Colby', 'Full', false )[0];
		bookingContainerColby.Expected_Quantity__c = 3;
		bookingContainersToInsert.add(bookingContainerColby);


		PUD_Container__c bookingContainerPallet = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Pallet', 'Full', false )[0];
		bookingContainerPallet.Expected_Quantity__c = 2;
		bookingContainersToInsert.add(bookingContainerPallet);

		insert bookingContainersToInsert;

		List<PUD_Container__c> bookingContainersToUpdate = new List<PUD_Container__c>();


		// call PUDUtility to create jobs
		PUDUtility.getInstance().createJobs(new Set<Id>{booking.Id}, true);

		List<PUD_Job__c> jobs = [Select Id, Date__c, Status__c from PUD_Job__c Where Date__c = :Date.today()];
		System.assertEquals(1, jobs.size(), 'Expected a Job to be created for current day; but not found.');
		// update status of today's job to 'Completed'
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_COMPLETED;
		update jobs[0];

		Test.startTest();

		//Update booking contact name - which will update job contact name if not completed
		booking.Contact_Name__c = 'Joe Blogs';
		booking.Regular_Product__c = false;
		booking.International_Product__c = true;
		booking.Express_Product__c = false;

		//update booking containers with Expected Quantity
		bookingContainerTrailer.Expected_Quantity__c = 23;
		bookingContainerULD.Expected_Quantity__c = 34;
		bookingContainerColby.Expected_Quantity__c = 67;
		bookingContainerPallet.Expected_Quantity__c = 56;
		
		bookingContainersToUpdate.add(bookingContainerTrailer);
		bookingContainersToUpdate.add(bookingContainerULD);
		bookingContainersToUpdate.add(bookingContainerColby);
		bookingContainersToUpdate.add(bookingContainerPallet);
		
	
		update booking;

		//update booking containers to reflect expected quantity
		update bookingContainersToUpdate;

		Test.stopTest();

		//Get job contact name for updated job
		jobs = [SELECT Id, Date__c, Status__c, Contact_Name__c, Regular_Product__c, Express_Product__c, International_Product__c, Containers_Payload__c,
		(Select Expected_Quantity__c, Type__c, Condition__c from Containers__r) FROM PUD_Job__c];

		 
		for (PUD_Job__c job: jobs) {
			if (job.Status__c == PUDConstants.PUD_JOB_STATUS_COMPLETED) {
				// job has been pushed to dispatch system.
				System.assertNotEquals(booking.Contact_Name__c, job.Contact_Name__c, 'Expected completed Job not to be updated from Booking');
				System.assertNotEquals(booking.Regular_Product__c, job.Regular_Product__c, 'Expected Regular product flag not to be updated from Booking');
				System.assertNotEquals(booking.Express_Product__c, job.Express_Product__c, 'Expected Express product flag not to be updated from Booking');
				System.assertNotEquals(booking.International_Product__c, job.International_Product__c, 'Expected International product flag not to be updated from Booking');
				
				for(PUD_Container__c pContainer : job.Containers__r){
					//if Job Container's type is matched with booking container then compare expected quantity.
					//Job Container's Expected Quantity should NOT be same as Booking Container's expected Quantity as this job is already completed. 
					if(pContainer.Type__c == bookingContainerTrailer.Type__c){
						System.assertNotEquals(bookingContainerTrailer.Expected_Quantity__c, pContainer.Expected_Quantity__c, 'Expected Empty ULD quantity not to be updated from Booking');
					}
				}
			} else if (job.Status__c == PUDConstants.PUD_JOB_STATUS_NEW) {
				System.assertEquals(booking.Contact_Name__c, job.Contact_Name__c, 'Expected Job to be updated from Booking');
			}
		}
	}

	//To check if the jobs are in Schedule status , creation of booking exception will mark the jobs in Cancel status.
	testmethod static void validateJobCancellationOfScheduleJobsOnBookingException(){
		// =====================================
		// Data Preparation
		// =====================================

		Map<String, Id> recordIdMap = PUDTestUtility.createPUDBasicRecords();
		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;
		// call PUDUtility to create jobs
		PUDUtility.getInstance().createJobs(new Set<Id>{booking.Id}, true);
		List<PUD_Job__c> jobs = new list<PUD_Job__c>([Select Id, Date__c, Status__c from PUD_Job__c Where Booking__c =: booking.Id]);
		//Update today's job status to Schedule.
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		update jobs[0];

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		//Create a booking exception for today
		PUD_Booking_Exception__c bookingEx = PUDTestUtility.createBookingException(booking.Id, DATE_TODAY, DATE_TODAY);
		insert bookingEx;
		Test.stopTest();

		//Check if today's job is set to Cancel status
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_CANCEL, [Select id,Date__c,Status__c from PUD_Job__c Where Date__c = :Date.today()][0].Status__c);
	}

	//To check if the jobs are in Accepted status , creation of booking exception will mark the jobs in Cancel status.
	testmethod static void validateJobCancellationOfAcceptedJobsOnBookingException(){
		// =====================================
		// Data Preparation
		// ===================================== 

		Map<String, Id> recordIdMap = PUDTestUtility.createPUDBasicRecords();
		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;
		// call PUDUtility to create jobs
		PUDUtility.getInstance().createJobs(new Set<Id>{booking.Id}, true);
		List<PUD_Job__c> jobs = new list<PUD_Job__c>([Select Id, Date__c, Status__c from PUD_Job__c Where Booking__c =: booking.Id]);
		//Update today's job status to Accepted.
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_ACCEPTED;
		update jobs[0];

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		//Create a booking exception for today
		PUD_Booking_Exception__c bookingEx = PUDTestUtility.createBookingException(booking.Id, DATE_TODAY, DATE_TODAY);
		insert bookingEx;
		Test.stopTest();
		//Check if today's job is set to Cancel status
		System.assertEquals(PUDConstants.PUD_JOB_STATUS_CANCEL, [Select id,Date__c,Status__c from PUD_Job__c Where Date__c = :Date.today()][0].Status__c);
	}
    
	//Validate that when updating details on Booking Location, these are also updated on the dependent Booking and Jobs where status is 'Schedule' or 'Accepted'
	testmethod static void validateUpdateBookingDetailsFLowToBookingAndJobDetailsWhereStatusIsScheduleORAccepted(){

		Map<String, Id> recordIdMap = new Map<String, Id>();
		List<PUD_Booking_Location__c> bookingLocationList = new List<PUD_Booking_Location__c>();
		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
		//Create Booking location
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		//Create Pickup Booking for customer booking location
		PUD_Booking__c booking1 = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		PUD_Booking__c booking2 = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		PUD_Booking__c booking3 = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert new PUD_Booking__c[]{booking1, booking2, booking3};
			
		// Call PUDUtility to create jobs
		PUDUtility.getInstance().createJobs(new Set<Id>{booking1.Id, booking2.Id, booking3.Id}, true);

		List<PUD_Job__c> jobs = [Select Booking__c, Id, Date__c, Status__c from PUD_Job__c WHERE Booking__c IN (:booking1.Id,:booking2.Id,:booking3.Id) AND Date__c=TODAY];
		// update status of one of today's jobs to 'Schedule' and another to 'Accepted'
		jobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		jobs[1].Status__c = PUDConstants.PUD_JOB_STATUS_ACCEPTED;
		jobs[2].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		update jobs;

		Test.startTest();
			
		//Update the Revenue_Check__c flag on the booking location
		bookingLocationList = [SELECT Id, Revenue_Check__c FROM PUD_Booking_Location__c WHERE Id = :recordIdMap.get('blCust')];
		for(PUD_Booking_Location__c bookingLocation : bookingLocationList) {
			bookingLocation.Revenue_Check__c = true;
		}
		update bookingLocationList;

		//list of new booking containers to insert
		List<PUD_Container__c> bookingContainersToInsert = new List<PUD_Container__c>();

		//Update the containers and product types on the booking
		bookingList = [SELECT Id, Regular_Product__c, Express_Product__c, International_Product__c 
						FROM PUD_Booking__c WHERE Id IN (:booking1.Id, :booking2.Id, :booking3.Id) ];
		for(PUD_Booking__c booking : bookingList) {
			booking.Regular_Product__c = true;
			booking.Express_Product__c = true;
			booking.International_Product__c = true;
			// update the container type details on the booking1 and booking2 only, while booking3 is used to test blank container type scenario
			if(booking.Id != booking3.Id){                
			
				//creating container types for booking1 and booking2 as per original logic.
				PUD_Container__c bookingContainerFullAircan = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Aircan', 'Empty', false )[0];
				bookingContainerFullAircan.Expected_Quantity__c = 1;
				bookingContainersToInsert.add(bookingContainerFullAircan);

				PUD_Container__c bookingContainerEmptyAircan = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Aircan', 'Full', false )[0];
				bookingContainerEmptyAircan.Expected_Quantity__c = 11;
				bookingContainersToInsert.add(bookingContainerEmptyAircan);


				PUD_Container__c bookingContainerTrailer = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Trailer', 'Empty', false )[0];
				bookingContainerTrailer.Expected_Quantity__c = 2;
				bookingContainersToInsert.add(bookingContainerTrailer);


				PUD_Container__c bookingContainerCardULD = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Cardboard ULD', 'Full', false )[0];
				bookingContainerCardULD.Expected_Quantity__c = 3;
				bookingContainersToInsert.add(bookingContainerCardULD);

				PUD_Container__c bookingContainerPallet = PUDTestDataFactory.getPUDBookingContainers(1, booking.Id, 'Pallet', 'Full', false )[0];
				bookingContainerPallet.Expected_Quantity__c = 4;
				bookingContainersToInsert.add(bookingContainerPallet);
			}
		}
		update bookingList;

		String sampleContainerPayload = '[{"Quantity":1.0,"Name":"Aircan","Condition":"Empty"}, {"Quantity":11.0,"Name":"Aircan","Condition":"Full"},'+
										'{"Quantity":2.0,"Name":"Trailer","Condition":"Empty"},{"Quantity":3.0,"Name":"Cardboard ULD","Condition":"Full"},{"Quantity":4.0,"Name":"Pallet","Condition":"Full"}'+
										']';
		

		//create booking containers
		insert bookingContainersToInsert;

		Map<String, PUD_Container__c> uniqueKeyVsContainer = new Map<String, PUD_Container__c>();
		for(PUD_Container__c container : bookingContainersToInsert){
			String uniqueKey = container.Booking__c+'-'+container.Type__c+'-'+container.Condition__c;
			uniqueKeyVsContainer.put(uniqueKey, container);
		}

		Map<Id, PUD_Booking_Location__c> bookingLocationMap = new Map<Id, PUD_Booking_Location__c>(bookingLocationList);
		Map<Id, PUD_Booking__c> bookingMap = new Map<Id, PUD_Booking__c>(bookingList);

		Test.stopTest();


		//Confirm the Revenue Check flag on the booking has been updated
		for (PUD_Booking__c updatedBooking: [SELECT Revenue_Check__c FROM PUD_Booking__c WHERE Id IN (:booking1.Id, :booking2.Id)]) {
			System.assertEquals(updatedBooking.Revenue_Check__c, bookingLocationMap.get(bookingLocationList[0].Id).Revenue_Check__c, 'Expected the revenue check flag on booking to be updated to match booking location revenue check flag');
		}

		Map<Id, PUD_Job__c> updatedJobsMap = new Map<Id, PUD_Job__c>(
			[SELECT Booking__c, Revenue_Check__c,Regular_Product__c, Express_Product__c, International_Product__c, Containers_Payload__c,
			(Select Expected_Quantity__c, Type__c, Condition__c from Containers__r) 
				FROM PUD_Job__c WHERE Booking__c IN(:booking1.Id,:booking2.Id,:booking3.Id) AND Date__c=TODAY]);
		//Confirm the Revenue Check flag on the Job has been updated
		System.assertEquals(updatedJobsMap.get(jobs[0].Id).Revenue_Check__c, bookingLocationMap.get(bookingLocationList[0].Id).Revenue_Check__c, 'Expected the Revenue Check to be set to TRUE where Job Status is Schedule');
		System.assertEquals(updatedJobsMap.get(jobs[1].Id).Revenue_Check__c, bookingLocationMap.get(bookingLocationList[0].Id).Revenue_Check__c, 'Expected the Revenue Check to be set to TRUE where Job Status is Accepted');

		//Confirm the containers and product types on the Job has been updated for Job with 'Schedule' Status
		System.assertEquals(updatedJobsMap.get(jobs[0].Id).Regular_Product__c, bookingMap.get(booking1.Id).Regular_Product__c, 'Expected the Regular Product flag on Job to match the Regular Product flag on booking');
		System.assertEquals(updatedJobsMap.get(jobs[0].Id).Express_Product__c, bookingMap.get(booking1.Id).Express_Product__c, 'Expected the Express Product flag on Job to match the Express Product flag on booking');
		System.assertEquals(updatedJobsMap.get(jobs[0].Id).International_Product__c, bookingMap.get(booking1.Id).International_Product__c, 'Expected the International Product flag on Job to match the International Product flag on booking');
		
		for(PUD_Container__c jobContainer : updatedJobsMap.get(jobs[0].Id).Containers__r){
			String uniqueyKey = jobs[0].Booking__c+'-'+jobContainer.Type__c+'-'+jobContainer.Condition__c;
			PUD_Container__c bookingContainer = uniqueKeyVsContainer.containsKey(uniqueyKey) ?  uniqueKeyVsContainer.get(uniqueyKey) : null;
			
			if(bookingContainer != null){
				System.assertEquals(jobContainer.Expected_Quantity__c, bookingContainer.Expected_Quantity__c, 'Expected the Empty Aircan quantity on Job to match the Empty Aircan quantity on booking');
			}			

		}
			
		
		//Confirm the containers and product types on the Job has been updated for Job with 'Accepted' Status
		System.assertEquals(updatedJobsMap.get(jobs[1].Id).Regular_Product__c, bookingMap.get(booking1.Id).Regular_Product__c, 'Expected the Regular Product flag on Job to match the Regular Product flag on booking');
		System.assertEquals(updatedJobsMap.get(jobs[1].Id).Express_Product__c, bookingMap.get(booking1.Id).Express_Product__c, 'Expected the Express Product flag on Job to match the Express Product flag on booking');
		System.assertEquals(updatedJobsMap.get(jobs[1].Id).International_Product__c, bookingMap.get(booking1.Id).International_Product__c, 'Expected the International Product flag on Job to match the International Product flag on booking');
		
		
		for(PUD_Container__c jobContainer : updatedJobsMap.get(jobs[1].Id).Containers__r){
			String uniqueyKey = jobs[1].Booking__c+'-'+jobContainer.Type__c+'-'+jobContainer.Condition__c;
			PUD_Container__c bookingContainer = uniqueKeyVsContainer.containsKey(uniqueyKey) ?  uniqueKeyVsContainer.get(uniqueyKey) : null;
			
			if(bookingContainer != null){
				System.assertEquals(jobContainer.Expected_Quantity__c, bookingContainer.Expected_Quantity__c, 'Expected the Empty Aircan quantity on Job to match the Empty Aircan quantity on booking');
			}			

		}
		

		//assert that containers payload on job and expected payloads are same.
		//system.assertEquals(sampleContainerPayload, updatedJobsMap.get(jobs[0].Id).Containers_Payload__c, ' Expected container payload to be same');
		
		// Test the Blank Containers Payload scenario where the container informaiton is not populated at the booking record
		System.assertEquals(updatedJobsMap.get(jobs[2].Id).Containers_Payload__c, null, 'Expected the Containers Payload JSON Structure on Job to be null as no container type details were populated on booking');
	}

	//Validate that when creating an a new booking then depot is automatically populated from related Route's depot if Route exists and depot is not filled
	testmethod static void validateDepotPopulationOnNewBookingCreation(){

		// =====================================
		// Data Preparation
		// =====================================
		List<Network__c> newDepotList = ApplicationTestDataFactory.getNetworks(2, false);
		newDepotList[0].recordtypeId = newDepotList[1].recordTypeId = PUDTestDataFactory.businessHubNetworkRecordType; 
		newDepotList[0].ORG_UNIT_ADDR_1__c  = newDepotList[1].ORG_UNIT_ADDR_1__c  = '111 Bourke Street';
		newDepotList[0].ORG_UNIT_ADDR_2__c  = newDepotList[1].ORG_UNIT_ADDR_2__c  = 'Unit 11';
		insert newDepotList;

		List<PUD_Route__c> newRouteList = PUDTestDataFactory.getPUDRoutes(2, null, false);
		newRouteList[0].Depot__c = newDepotList[0].id;
		newRouteList[1].Depot__c = newDepotList[1].id;
		insert newRouteList;

		List<PUD_Booking_Location__c> bookingLocationList = PUDTestDataFactory.getPUDNetworkBookingLocations(2, newDepotList[1].Id, false);
		bookingLocationList[0].Route__c = newRouteList[1].Id;
		insert bookingLocationList;

		//Create a Booking with a location with related Route, a route and BLANK depot
		PUD_Booking__c booking1 = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(1, bookingLocationList[0].Id, null, Date.today().addDays(-7), Date.today().addDays(7), null, false)[0];
		booking1.Route_Lookup__c = newRouteList[0].Id;

		//Create a Booking with a location with related Route, BLANK route and BLANK depot
		PUD_Booking__c booking2 = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(1, bookingLocationList[0].Id, null, Date.today().addDays(-7), Date.today().addDays(7), null, false)[0];

		//Create a Booking with a location with related BLANK route, BLANK route and BLANK depot
		PUD_Booking__c booking3 = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(1, bookingLocationList[1].Id, null, Date.today().addDays(-7), Date.today().addDays(7), null, false)[0];

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<Database.SaveResult> results = Database.insert(new List<PUD_Booking__c>{booking1, booking2, booking3}, false);
		Test.stopTest();
		// Loop through database result and assert for successful and failed booking creation
		for(Database.SaveResult sr : results){
			if(sr.isSuccess()){
				// booking1 and booking2 should be successful
				Set<Id> successfulBooking = new Set<Id>{booking1.Id, booking2.Id};
				System.assertEquals(true, successfulBooking.contains(sr.Id), 'Encounter error while inserting a valid booking');
			}
			else{
				// booking3 should be failing
				System.assertEquals(booking3.Id, sr.getId(), 'Expected mandatory Depot validation error is not thrown');
			}
		}
		//Confirm bookings' depot are populated from route's depot
		Map<Id, PUD_Booking__c> bookingMap = new Map<Id, PUD_Booking__c>([SELECT Id, Depot__c FROM PUD_Booking__c WHERE Id IN(:booking1.Id,:booking2.Id)]);
		System.assertEquals(newDepotList[0].Id, bookingMap.get(booking1.Id).Depot__c, 'Expected Depot name was incorrect!');
		System.assertEquals(newDepotList[1].Id, bookingMap.get(booking2.Id).Depot__c, 'Expected Depot name was incorrect!');
	}

	//Validate that when booking containers are created then all job containers are also created for jobs under those bookings.
	testmethod static void validateRefreshContainerTypesForInsertion(){

		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//create a booking container
		PUD_Container__c bookingContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallet', 'Empty', true )[0];

		//associating containers with bookings.
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{bookingContainer}});


		// =====================================
		// Stubbing
		// =====================================
		//PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector mockJobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockBookingSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(pudBookingList);
		MockUtility.Mocks.when(mockJobSelector.selectByBookingIdStatusAndFromDate((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyDate(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(jobs);
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (SObjectField)fflib_Match.anyObject(), (SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		
		//creating instance of MockDMLUpdate.
		//Instance is required to verify updates to fields at Job level.
		AnswerJobDMLUpdated jobDMlAnswerMockInstance = new AnswerJobDMLUpdated();
		MockUtility.Mocks.when(mockUow.registerDirty((SObject)fflib_Match.anyObject())).thenAnswer(jobDMlAnswerMockInstance);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();


		PUDUtility.getInstance().refreshContainerTypes(new Set<Id>{pudBookingList[0].Id}, mockUow);

		Test.stopTest();

		//verify containers are created
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 6)).registerNew((SObject)fflib_Match.anyObject(), (SObjectField)fflib_Match.anyObject(), (SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());

		//verify jobs are updated
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 6)).registerDirty((SObject)fflib_Match.anyObject());

		//verify that job containers are added under jobs as per booking containers.
		system.assertEquals(6, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected to create 6 job containers, one for each 6 jobs');
		system.assertEquals('Pallet', ((PUD_Container__c)MockUtility.mockUnitOfWorkDMLs[0]).Type__c, 'Expected to match type with job container\'s, type.');
		system.assertNotEquals(null, ((PUD_Job__c)jobDMlAnswerMockInstance.mockJobDMLUpdatedRecords[0]).Containers_Payload__c, 'Expected to update Job\'s container payload and not null.');
	}

	//Validate that when booking containers are updated then all job containers are also updated for jobs under those bookings.
	testmethod static void validateRefreshContainerTypesForUpdates(){

		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//create a booking container
		PUD_Container__c bookingContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallet', 'Empty', true )[0];
		bookingContainer.Expected_Quantity__c = 20;
		//associating containers with bookings.
		pudBookingList[0] = (PUD_Booking__c)ApplicationTestDataFactory.setChildRelationships(pudBookingList[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{bookingContainer}});

		//create job containers.
		List<PUD_Container__c> containers = PUDTestDataFactory.getPUDJobContainers(6, pudBookingList[0].Id, null, 'Pallet', 'Empty', true );
		containers[0].Job__c = jobs[0].Id;
		containers[0].Expected_Quantity__c = 10; 
		containers[1].Job__c = jobs[1].Id;
		containers[1].Expected_Quantity__c = 10;
		containers[2].Job__c = jobs[2].Id;
		containers[2].Expected_Quantity__c = 10;
		containers[3].Job__c = jobs[3].Id;
		containers[3].Expected_Quantity__c = 10;
		containers[4].Job__c = jobs[4].Id;
		containers[4].Expected_Quantity__c = 10;
		containers[5].Job__c = jobs[5].Id;
		containers[5].Expected_Quantity__c = 10;

		//associate child job containers
		jobs[0] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[0]}});
		jobs[1] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[1], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[1]}});
		jobs[2] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[2], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[2]}});
		jobs[3] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[3], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[3]}});
		jobs[4] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[4], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[4]}});
		jobs[5] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[5], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[5]}});

		

		// =====================================
		// Stubbing
		// =====================================
		//PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector mockJobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		//PUDContainersSelector mockContainerSelector = (PUDContainersSelector)MockUtility.mockSelector(PUDContainersSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockBookingSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(pudBookingList);
		MockUtility.Mocks.when(mockJobSelector.selectByBookingIdStatusAndFromDate((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyDate(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(jobs);
		MockUtility.Mocks.when(mockUow.registerDirty((SObject)fflib_Match.anyObject(), (List<Schema.SObjectField>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		//creating instance of MockDMLUpdate.
		//Instance is required to verify updates to Container Payload at Job level.
		AnswerJobDMLUpdated jobDMlAnswerMockInstance = new AnswerJobDMLUpdated();
		MockUtility.Mocks.when(mockUow.registerDirty((SObject)fflib_Match.anyObject())).thenAnswer(jobDMlAnswerMockInstance);


		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		bookingContainer.Expected_Quantity__c = 20;

		PUDUtility.getInstance().refreshContainerTypes(new Set<Id>{pudBookingList[0].Id}, mockUow);

		Test.stopTest();

		//verify containers are updated
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 6)).registerDirty((SObject)fflib_Match.anyObject(), (List<Schema.SObjectField>)fflib_Match.anyObject());

		//verify jobs are updated
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 6)).registerDirty((SObject)fflib_Match.anyObject());

		//verify that job containers are added under jobs as per booking containers.
		system.assertEquals(6, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected to create 6 job containers, one for each 6 jobs');
		system.assertEquals(20, ((PUD_Container__c)MockUtility.mockUnitOfWorkDMLs[0]).Expected_Quantity__c, 'Expected to match type with job container\'s, Expected_Quantity__c.');
		system.assertNotEquals(null, ((PUD_Job__c)jobDMlAnswerMockInstance.mockJobDMLUpdatedRecords[0]).Containers_Payload__c, 'Expected to update Job\'s container payload and not null.');
		system.assert(((PUD_Job__c)jobDMlAnswerMockInstance.mockJobDMLUpdatedRecords[0]).Containers_Payload__c.contains('[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]'), 'Expected to update Job\'s container payload with Quantity.');
	}


	//Validate that when booking containers are deleted then all job containers are also deleted for jobs under those bookings.
	testmethod static void validateRefreshContainerTypesForDeletion(){

		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(30), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//keeping booking containers list empty.
		//This will simulate deletion of booking containers under a booking.
		//Jobs will have containers but its booking will not have any containers.
		//Upon successfull tests, job containers should be deleted as its booking doesn't have any containers.

		//create job containers.
		List<PUD_Container__c> containers = PUDTestDataFactory.getPUDJobContainers(6, pudBookingList[0].Id, null, 'Pallet', 'Empty', true );
		containers[0].Job__c = jobs[0].Id;
		containers[0].Expected_Quantity__c = 10; 
		containers[1].Job__c = jobs[1].Id;
		containers[1].Expected_Quantity__c = 10;
		containers[2].Job__c = jobs[2].Id;
		containers[2].Expected_Quantity__c = 10;
		containers[3].Job__c = jobs[3].Id;
		containers[3].Expected_Quantity__c = 10;
		containers[4].Job__c = jobs[4].Id;
		containers[4].Expected_Quantity__c = 10;
		containers[5].Job__c = jobs[5].Id;
		containers[5].Expected_Quantity__c = 10;

		//associate child job containers
		jobs[0] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[0]}});
		jobs[1] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[1], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[1]}});
		jobs[2] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[2], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[2]}});
		jobs[3] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[3], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[3]}});
		jobs[4] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[4], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[4]}});
		jobs[5] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[5], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[5]}});
		
		//set jobs containers
		jobs[0].Containers_Payload__c = '[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]';
		jobs[1].Containers_Payload__c = '[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]'; 
		jobs[2].Containers_Payload__c = '[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]'; 
		jobs[3].Containers_Payload__c = '[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]'; 
		jobs[4].Containers_Payload__c = '[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]'; 
		jobs[5].Containers_Payload__c = '[{"Quantity":20.0,"Name":"Pallet","Condition":"Empty"}]'; 
		

		// =====================================
		// Stubbing
		// =====================================
		//PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector mockJobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockBookingSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(pudBookingList);
		MockUtility.Mocks.when(mockJobSelector.selectByBookingIdStatusAndFromDate((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyDate(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(jobs);
		((ApplicationUnitOfWork)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());

		//creating instance of MockDMLUpdate.
		//Instance is required to verify updates to Container Payload at Job level.
		AnswerJobDMLUpdated jobDMlAnswerMockInstance = new AnswerJobDMLUpdated();
		MockUtility.Mocks.when(mockUow.registerDirty((SObject)fflib_Match.anyObject())).thenAnswer(jobDMlAnswerMockInstance);


		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		PUDUtility.getInstance().refreshContainerTypes(new Set<Id>{pudBookingList[0].Id}, mockUow);

		Test.stopTest();

		//verify containers are updated
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 6)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());
		//As UnitOfWork is used and we are not committing actual DML operations, asserting deletion operation not possible.
		//Above verify() method asserts that delete will be called in actual transaction.
		//Also, Mock framework does not return any list for registerDeleted(). 

		
		//verify jobs are updated
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 6)).registerDirty((SObject)fflib_Match.anyObject());

		system.assertEquals(6, jobDMlAnswerMockInstance.mockJobDMLUpdatedRecords.size(), 'Expected to update Job\'s container payload and upon all container deletion.');
		system.assertEquals(null, ((PUD_Job__c)jobDMlAnswerMockInstance.mockJobDMLUpdatedRecords[0]).Containers_Payload__c, 'Expected to update Job\'s container payload and set to null upon all container deletion.');
	}

	testMethod static void validateCascadeDeleteOfContainerTypesUponJobDeletion(){
		// =====================================
		// Data Preparation
		// =====================================

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, null, null, Date.today(), Date.today().addDays(7), null, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(6, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);

		//keeping booking containers list empty.
		//This will simulate deletion of booking containers under a booking.
		//Jobs will have containers but its booking will not have any containers.
		//Upon successfull tests, job containers should be deleted as its booking doesn't have any containers.

		//create job containers.
		List<PUD_Container__c> containers = PUDTestDataFactory.getPUDJobContainers(6, pudBookingList[0].Id, null, 'Pallet', 'Empty', true );
		containers[0].Job__c = jobs[0].Id;
		containers[0].Expected_Quantity__c = 10; 
		containers[1].Job__c = jobs[1].Id;
		containers[1].Expected_Quantity__c = 10;
		containers[2].Job__c = jobs[2].Id;
		containers[2].Expected_Quantity__c = 10;
		containers[3].Job__c = jobs[3].Id;
		containers[3].Expected_Quantity__c = 10;
		containers[4].Job__c = jobs[4].Id;
		containers[4].Expected_Quantity__c = 10;
		containers[5].Job__c = jobs[5].Id;
		containers[5].Expected_Quantity__c = 10;

		//associate child job containers
		jobs[0] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[0], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[0]}});
		jobs[1] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[1], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[1]}});
		jobs[2] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[2], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[2]}});
		jobs[3] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[3], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[3]}});
		jobs[4] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[4], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[4]}});
		jobs[5] = (PUD_Job__c)ApplicationTestDataFactory.setChildRelationships(jobs[5], new Map<String, List<SObject>>{'Containers__r' => new List<SObject>{containers[5]}});
		
		// Stubbing
		// =====================================
		//PUDUtility mockPUDUtil = (PUDUtility) MockUtility.mockUtility(PUDUtility.class);
		PUDContainersSelector mockContainerSelector = (PUDContainersSelector)MockUtility.mockSelector(PUDContainersSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockContainerSelector.selectByJobIds((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(containers);
		((ApplicationUnitOfWork)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());


		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		PUDUtility.getInstance().cascadeDeleteJobContainers(jobs, mockUow);

		Test.stopTest();

		//verify containers are updated
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDeleted((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());
		//As UnitOfWork is used and we are not committing actual DML operations, asserting deletion operation not possible.
		//Above verify() method asserts that delete will be called in actual transaction.
		//Also, Mock framework does not return any list for registerDeleted(). 


	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerJobDMLUpdated implements fflib_Answer {
		public  List<SObject> mockJobDMLUpdatedRecords = new List<SObject>();
		public Object answer(fflib_InvocationOnMock invocation) {
			Boolean isList = (invocation.getArgument(0) instanceof List<SObject>);		
			List<SObject> records = (isList ? (List<SObject>)invocation.getArgument(0) : new List<SObject>{(SObject)invocation.getArgument(0)});	
			// store a list of the records that were updated when this answer is invoked.
			mockJobDMLUpdatedRecords.addAll(records);	
            return  (isList ? (Object)records : (Object)records[0]);
		}
	}	

	

	
}