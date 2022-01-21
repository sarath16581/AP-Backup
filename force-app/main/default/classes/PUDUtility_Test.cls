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
		String strJobCreatedContact;
		String strJobUpdatedContact;
		Boolean bolJobContactMatch;

		//Create Test Data
		recordIdMap = PUDTestUtility.createPUDBasicRecords();

		Test.startTest();

		//Create a Booking for customer booking location
		PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;

		//Update booking contact name - which will update job contact name
		booking.Contact_Name__c = 'Donald Duck';
		update booking;

		Test.stopTest();

		//Get job contact name for updated job
		jobsList = [SELECT Contact_Name__c FROM PUD_Job__c WHERE Booking__c = :booking.Id];
		strJobUpdatedContact = jobsList[0].Contact_Name__c;

		strJobCreatedContact = BOOKING_CONTACT;

		//Compare routes values
		bolJobContactMatch = (strJobCreatedContact == strJobUpdatedContact);

		//Confirm route was changed
		System.assertNotEquals(true, bolJobContactMatch);

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
		insert booking;

		Test.stopTest();

		//Get booking
		bookingList = [SELECT
				City__c,
				Contact_Email__c,
				Contact_Name__c,
				Contact_Phone_Number__c,
				Customer__c,
				Depot__c,
				Dwell_Time_Planned__c,
				Earliest_Start_Time__c,
				Hazards__c,
				Latest_End_Time__c,
				Network__c,
				Post_Code__c,
				Route_Lookup__c,
				Site_Instructions__c,
				State__c,
				Street__c
				FROM PUD_Booking__c WHERE Id = :booking.Id];

		//Get jobs
		jobsList = [SELECT
				City__c,
				Contact_Email__c,
				Contact_Name__c,
				Contact_Phone_Number__c,
				Customer__c,
				Depot__c,
				Dwell_Time_Planned__c,
				Earliest_Start_Time__c,
				Hazards__c,
				Latest_End_Time__c,
				Network__c,
				Post_Code__c,
				Route_Lookup__c,
				Site_Instructions__c,
				State__c,
				Street__c
				FROM PUD_Job__c WHERE Booking__c = :booking.Id];

		//Get job field values
		strJobFieldValues = 	jobsList[0].City__c +
				jobsList[0].Contact_Email__c +
				jobsList[0].Contact_Name__c +
				jobsList[0].Contact_Phone_Number__c +
				jobsList[0].Customer__c +
				jobsList[0].Depot__c +
				jobsList[0].Dwell_Time_Planned__c +
				jobsList[0].Earliest_Start_Time__c +
				jobsList[0].Hazards__c +
				jobsList[0].Latest_End_Time__c +
				jobsList[0].Network__c +
				jobsList[0].Post_Code__c +
				jobsList[0].Route_Lookup__c +
				jobsList[0].Site_Instructions__c +
				jobsList[0].State__c +
				jobsList[0].Street__c;

		//Get booking field values
		strBookingFieldValues = bookingList[0].City__c +
				bookingList[0].Contact_Email__c +
				bookingList[0].Contact_Name__c +
				bookingList[0].Contact_Phone_Number__c +
				bookingList[0].Customer__c +
				bookingList[0].Depot__c +
				bookingList[0].Dwell_Time_Planned__c +
				bookingList[0].Earliest_Start_Time__c +
				bookingList[0].Hazards__c +
				bookingList[0].Latest_End_Time__c +
				bookingList[0].Network__c +
				bookingList[0].Post_Code__c +
				bookingList[0].Route_Lookup__c +
				bookingList[0].Site_Instructions__c +
				bookingList[0].State__c +
				bookingList[0].Street__c;

		system.debug('strJobFieldValues ' + strJobFieldValues);
		system.debug('strBookingFieldValues ' + strBookingFieldValues);

		//Compare field values
		bolBookingJobMatch = (strJobFieldValues == strBookingFieldValues);

		//Confirm field values the same
		System.assertEquals(true, bolBookingJobMatch);
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
		insert booking;

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
		update booking;

		Test.stopTest();

		//Get job contact name for updated job
		jobs = [SELECT Id, Date__c, Status__c, Contact_Name__c FROM PUD_Job__c];

		for (PUD_Job__c job: jobs) {
			if (job.Status__c == PUDConstants.PUD_JOB_STATUS_COMPLETED) {
				// job has been pushed to dispatch system.
				System.assertNotEquals(booking.Contact_Name__c, job.Contact_Name__c, 'Expected completed Job not to be updated from Booking');
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
}