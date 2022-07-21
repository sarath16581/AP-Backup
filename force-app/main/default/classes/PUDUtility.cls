/*-------------------------
Overview: Utility functions for Pickup and Delivery functionality

Three primary functions:
1) addNewJobs - Adds new jobs to bookings passed in
2) refreshJobs - Refreshes all jobs against bookings passed in
3) refreshJobsOnException - get bookings associated to exceptions and calls refreshJobs

1 and 2 call sub function:
- getNewJobList - returns list of jobs based on current state of bookings

History:
27/08/2019	ajudd@salesforce.com	Created
09/10/2019  ajudd@salesforce.com	Added Product and Presentation fields
17/10/2019  ajudd@salesforce.com	Added Booking Comments field
20/11/2019  ajudd@salesforce.com	Added new fields - Revenue Check, Article Info, Booking Type, Confidence, Source Address fields
20/11/2019  ajudd@salesforce.com	Added days logic to Booking Exception 
26/11/2019  ajudd@salesforce.com	Updated booking route field from Route__c to Route_Lookup__c
26/11/2019  ajudd@salesforce.com	Updated job route field from Route__c to Route_Lookup__c
02/12/2019  dheeraj.mandavilli@auspost.com.au	Added new field - Stop Credit
04/12/2019  ajudd@salesforce.com	Added Start Time field
21/01/2020  dheeraj.mandavilli@auspost.com.au	Added new field - Key Number
22/01/2020  dheeraj.mandavilli@auspost.com.au	Added new field - Display Start Time
03/02/2020  dheeraj.mandavilli@auspost.com.au	Added "with sharing" at class level.
18/03/2020  dheeraj.mandavilli@auspost.com.au	Added new field - Article Count
2021-08-12 - Ranjeewa Silva - Implemented changes to support dispatch system (MobileSTAR) integration.
2021-09-29 - Ranjeewa Silva - Populate additional address details (frontage geocode and side of street) on jobs.
2021-10-12 - Ranjeewa Silva - Added Start Time to the list of fields updateable on jobs in 'Schedule' and 'Accepted' status.
2021-11-09 - Mathew Jose - Updated refreshjobs method to Cancel the current day's jobs in 'Schedule' and 'Accepted' statuses when a No Pickup is raised(Booking Exception).
2022-02-09 - Seth Heang - REQ2742514 Added 'Revenue_Check__c' into the comparation fields check in order to trigger the job update when Job is in 'Schedule' and 'Accepted' Status
2022-02-23 - Seth Heang - Added Container Type fields and Product Type fields into the sync functionality from booking and job and to the Dispatch System as part of Metro Transport Enhancements
2022-02-23 - Seth Heang - Serialised container type fields information into a JSON format and populate to a new long text field called Containers Payload
2022-07-02 - Dattaraj Deshmukh - Added logic to create container type records when a container type at booking level is created/updated and jobs are added as a part of batch job.
-------------------------
*/
public with sharing class PUDUtility {

	//Get date range based on offset value from custom setting
	public static Date DATE_FROM = date.today();
	public static Date DATE_TO {
		get {
			if (DATE_TO == null) {
				DATE_TO = DATE_FROM.addDays((pickupBookingSettings != null ? Integer.valueOf(pickupBookingSettings.Job_Offset_Days__c) : 7));
			}
			return DATE_TO;
		}
		private set;
	}

	// set of fields used for comparing an existing job in 'New' status to a new instance based on latest booking configuration.
	//!!!---WARNING - Fields below must be included in jobsNewList query in function getNewJobList and jobsExistingList query in function refreshJobs ---!!!
	private static final Set<SObjectField> COMPARABLE_FIELD_SET_NEW_JOBS {
		get {
			if (COMPARABLE_FIELD_SET_NEW_JOBS == null) {
				COMPARABLE_FIELD_SET_NEW_JOBS = new Set<SObjectField> {
						PUD_Job__c.Booking__c, PUD_Job__c.Date__c, PUD_Job__c.Street__c, PUD_Job__c.City__c, PUD_Job__c.Post_Code__c,
						PUD_Job__c.State__c, PUD_Job__c.Start_Time__c, PUD_Job__c.Display_Start_Time__c, PUD_Job__c.Earliest_Start_Time__c,
						PUD_Job__c.Latest_End_Time__c, PUD_Job__c.Route_Lookup__c, PUD_Job__c.Booking_Location__c, PUD_Job__c.Depot__c,
						PUD_Job__c.Contact_Name__c, PUD_Job__c.Contact_Phone_Number__c, PUD_Job__c.Contact_Email__c, PUD_Job__c.Hazards__c,
						PUD_Job__c.Site_Instructions__c, PUD_Job__c.Comments__c, PUD_Job__c.Dwell_Time_Planned__c, PUD_Job__c.Location__c,
						PUD_Job__c.Customer__c, PUD_Job__c.Network__c, PUD_Job__c.Booking_Id__c, PUD_Job__c.Geo__Latitude__s,
						PUD_Job__c.Geo__Longitude__s, PUD_Job__c.Pallets_Quantity__c, PUD_Job__c.Tubs_Quantity__c, PUD_Job__c.Bags_Quantity__c,
						PUD_Job__c.Trays_Quantity__c, PUD_Job__c.Volume_Cubic_Metre__c, PUD_Job__c.Large_Letter_Tubs__c, PUD_Job__c.Small_Letter_Trays__c,
						PUD_Job__c.White_Bags__c, PUD_Job__c.Express_Bags__c, PUD_Job__c.Blue_Bags__c, PUD_Job__c.Red_Tubs__c,
						PUD_Job__c.Booking_Comments__c, PUD_Job__c.Revenue_Check__c, PUD_Job__c.Article_Info__c, PUD_Job__c.Booking_Type__c,
						PUD_Job__c.Source_Street__c, PUD_Job__c.Source_City__c, PUD_Job__c.Source_Post_Code__c, PUD_Job__c.Source_State__c,
						PUD_Job__c.Confidence__c, PUD_Job__c.Stop_Credit__c, PUD_Job__c.Key_Number__c, PUD_Job__c.Article_Count__c,
						PUD_Job__c.Location_Frontage_Geo__Latitude__s, PUD_Job__c.Location_Frontage_Geo__Longitude__s,
						PUD_Job__c.Location_Side_Of_Street_Code__c, PUD_Job__c.Location_DPID__c, PUD_Job__c.Regular_Product__c, PUD_Job__c.Express_Product__c, 
						PUD_Job__c.International_Product__c, PUD_Job__c.Empty_Aircan__c, PUD_Job__c.Empty_Cage__c, PUD_Job__c.Empty_CardULD__c, PUD_Job__c.Empty_Colby__c,
						PUD_Job__c.Empty_Pallets__c, PUD_Job__c.Empty_Trailer__c, PUD_Job__c.Empty_ULD__c, PUD_Job__c.Full_Aircan__c, PUD_Job__c.Full_Cage__c,
						PUD_Job__c.Full_CardULD__c, PUD_Job__c.Full_Colby__c, PUD_Job__c.Full_Pallets__c, PUD_Job__c.Full_Trailer__c, PUD_Job__c.Full_ULD__c, PUD_Job__c.Containers_Payload__c
				};
			}
			return COMPARABLE_FIELD_SET_NEW_JOBS;
		}
		set;
	}

	// set of fields used for comparing an existing job in 'Schedule' and 'Accepted' status to a new instance based on latest booking configuration.
	//!!!---WARNING - Fields below must be included in jobsNewList query in function getNewJobList and jobsExistingList query in function refreshJobs ---!!!
	private static final Set<SObjectField> COMPARABLE_FIELD_SET_SCHEDULED_JOBS {
		get {
			if (COMPARABLE_FIELD_SET_SCHEDULED_JOBS == null) {
				COMPARABLE_FIELD_SET_SCHEDULED_JOBS = new Set<SObjectField>{
						PUD_Job__c.Contact_Name__c, PUD_Job__c.Contact_Phone_Number__c, PUD_Job__c.Contact_Email__c, PUD_Job__c.Earliest_Start_Time__c,
						PUD_Job__c.Latest_End_Time__c, PUD_Job__c.Dwell_Time_Planned__c, PUD_Job__c.Booking_Comments__c, PUD_Job__c.Display_Start_Time__c,
						PUD_Job__c.Site_Instructions__c, PUD_Job__c.Comments__c, PUD_Job__c.Hazards__c, PUD_Job__c.Key_Number__c,
						PUD_Job__c.Pallets_Quantity__c, PUD_Job__c.Bags_Quantity__c, PUD_Job__c.Volume_Cubic_Metre__c, PUD_Job__c.Tubs_Quantity__c,
						PUD_Job__c.Trays_Quantity__c, PUD_Job__c.Large_Letter_Tubs__c, PUD_Job__c.White_Bags__c, PUD_Job__c.Blue_Bags__c,
						PUD_Job__c.Small_Letter_Trays__c, PUD_Job__c.Express_Bags__c, PUD_Job__c.Red_Tubs__c, PUD_Job__c.Start_Time__c, PUD_Job__c.Revenue_Check__c, 
						PUD_Job__c.Regular_Product__c, PUD_Job__c.Express_Product__c, PUD_Job__c.International_Product__c, PUD_Job__c.Empty_Aircan__c, PUD_Job__c.Empty_Cage__c,
						PUD_Job__c.Empty_CardULD__c, PUD_Job__c.Empty_Colby__c, PUD_Job__c.Empty_Pallets__c, PUD_Job__c.Empty_Trailer__c, PUD_Job__c.Empty_ULD__c, PUD_Job__c.Full_Aircan__c,
						PUD_Job__c.Full_Cage__c, PUD_Job__c.Full_CardULD__c, PUD_Job__c.Full_Colby__c, PUD_Job__c.Full_Pallets__c, PUD_Job__c.Full_Trailer__c, PUD_Job__c.Full_ULD__c, PUD_Job__c.Containers_Payload__c
				};
			}
			return COMPARABLE_FIELD_SET_SCHEDULED_JOBS;
		}
		set;
	}

	
	// container type conditions
	private static final String CONTAINER_CONDITION_EMPTY = 'Empty';
	private static final String CONTAINER_CONDITION_FULL = 'Full';

	// grab settings configured in custom setting
	private static Pickup_Booking_Settings__c pickupBookingSettings {
		get {
			if(pickupBookingSettings == null) {
				pickupBookingSettings = Pickup_Booking_Settings__c.getInstance();
			}
			return pickupBookingSettings;
		}
		private set;
	}

	// get record type id for job containers
	public static Id jobContainerRecordTypeId {
		get {
			if (jobContainerRecordTypeId == null) {
				jobContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{ 'Job_Container' }).values()[0].Id;
			}
			return jobContainerRecordTypeId;
		}
		private set;
	}

	// get record type id for booking containers
	public static Id bookingContainerRecordTypeId {
		get {
			if (bookingContainerRecordTypeId == null) {
				bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{ 'Booking_Container' }).values()[0].Id;
			}
			return bookingContainerRecordTypeId;
		}
		private set;
	}

	/**
	 * Creates a new instance. This allows use to use dependency injection for mocking
	 * @return the new instance
	 */
	public static PUDUtility getInstance() {
		return (PUDUtility) Application.Utilities.getInstance(PUDUtility.class);
	}

	//****0. Primary function called from PUDCreateJobBatch
	//Note that this is required to ensure the values in the sobj compare are identical
	//Using List from Database.getQueryLocator results in some subtle differences (e.g. number in Dwell_Time_Planned__c = 0.0, c.f. 0)
	//Note that data type of booking and job fields must be the same
	public void createJobs(Set<Id> bookingIdSet, Boolean bolRefreshAll){

		// note that this is a stopgap until the pattern for using Unit of Work for service operations are endorsed.
		// using Unit Of Work allows to gain some of the benefits of ApplicationUnitOfWork such as austomatically
		// resolving dependencies among related records during the commit phase.
		ApplicationUnitOfWork uow = newUnitOfWork();

		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
		
		//Todo: Call booking selector with field overrides
		//PUDBookingsSelector.newInstance().selectById(bookingIdSet, new Set<Object>{PUDBookingsSelector.Options.WITH_CONTAINERS});

		bookingList = [SELECT Id, Name, Effective_Date__c, Expiry_Date__c, Sunday__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c,
				Street__c, City__c, Post_Code__c, State__c, Start_Time__c, Earliest_Start_Time__c, Latest_End_Time__c, Booking_Location__c, Depot__c, Route_Lookup__c,
				Contact_Name__c, Contact_Phone_Number__c, Contact_Email__c, Hazards__c, Site_Instructions__c, Comments__c, Dwell_Time_Planned__c,
				Parent_Monday__c, Parent_Tuesday__c, Parent_Wednesday__c, Parent_Thursday__c, Parent_Friday__c, Parent_Saturday__c, Parent_Sunday__c,
				Parent_Booking__c, Parent_Route__c, Location__c, Customer__c, Network__c,
				Effective_Date_Calc__c, Expiry_Date_Calc__c, Geo__Latitude__s, Geo__Longitude__s,
				Pallets_Quantity__c,Tubs_Quantity__c,Bags_Quantity__c,Trays_Quantity__c,Volume_Cubic_Metre__c,
				Large_Letter_Tubs__c,Small_Letter_Trays__c,White_Bags__c,Express_Bags__c,Blue_Bags__c,Red_Tubs__c,
				Booking_Comments__c, Revenue_Check__c, Article_Info__c, Booking_Type__c,
				Source_Street__c, Source_City__c, Source_Post_Code__c, Source_State__c, Confidence__c,
				Route_Lookup__r.Name,Stop_Credit__c,Key_Number__c,Display_Start_Time__c,Article_Count__c,
				Frontage_Geo__Latitude__s, Frontage_Geo__Longitude__s, DPID__c, Side_Of_Street_Code__c, Regular_Product__c, Express_Product__c, International_Product__c,
				Empty_Aircan__c, Empty_Cage__c, Empty_CardULD__c, Empty_Colby__c, Empty_Pallets__c, Empty_Trailer__c, Empty_ULD__c,
				Full_Aircan__c, Full_Cage__c, Full_CardULD__c, Full_Colby__c, Full_Pallets__c, Full_Trailer__c, Full_ULD__c,
				(SELECT Id, Actual_Quantity__c, Booking__c, Condition__c, Expected_Quantity__c, Job__c, Type__c, RecordTypeId, Name 
					FROM Containers__r WHERE RecordTypeId =: bookingContainerRecordTypeId ORDER BY CreatedDate Desc) 
				
		FROM PUD_Booking__c WHERE Id IN:bookingIdSet];

		//Call function depending on input parameter
		//Refresh will update all existing jobs from now into future
		//Add New will assume all existing jobs are in correct state, and only insert jobs that are not present
		if(bolRefreshAll){
			refreshJobs(bookingList, uow);
		}
		else{
			addNewJobs(bookingList, uow);
		}

		// ensure Unit of Work is committed.
		uow.commitWork();
	}

	//*****1. ADD NEW JOBS - Primary Function*****
	//Description:
	//Adds new jobs to list of bookings passed in.
	//Assumes that if booking has a job for a particular day, then this day can be skipped.
	//Primarily called from scheduled PUDCreateJobBatch to add the next days of jobs to the future schedule.
	private void addNewJobs(List<PUD_Booking__c> bookingList, ApplicationUnitOfWork uow){

		Map<Id, PUD_Booking__c> bookings = new Map<Id, PUD_Booking__c>(bookingList);
		Set<String> jobExistingBookingDateSet = new Set<String>(); //key BookingId-Date for existing job for booking: assumes booking has either 0 or 1 job for each day.
		List<PUD_Job__c> jobsExistingList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();

		//Get list of of all existing jobs in future.
		jobsExistingList = [SELECT Id, Date__c, Booking__c
		FROM PUD_Job__c
		WHERE Booking__c IN :bookings.keySet()
		AND Date__c >= :DATE_FROM];

		//#Build key set of job by BookingId-Date (e.g. <Id>-2019-08-28) : assumes booking has either 0 or 1 job for each day.
		for(PUD_Job__c job : jobsExistingList){
			jobExistingBookingDateSet.add(job.Booking__c + job.Date__c.format());
		}

		System.debug('job Existing count = ' + jobExistingBookingDateSet.size());

		//Call function to get list of new jobs
		jobsNewList = getNewJobList(bookingList, jobExistingBookingDateSet);

		//insert jobs
		System.debug('Insert Job count = ' + jobsNewList.size());
		if(jobsNewList.size() > 0){
			//insert jobsNewList;
			uow.registerNew(jobsNewList, true, 'PUDUtility.addNewJobs');
		}
		refreshContainerTypes(bookings, jobsNewList, uow);
	}

	//*****2. REFRESH JOBS - Primary Function*****
	//Description:
	//This function refreshes all jobs for bookings in list passed in.
	//Refresh compares existing jobs with new jobs based on any changes to bookings, and either inserts records (if new), updates records (if modified), or deletes records (if not valid)
	public void refreshJobs(List<PUD_Booking__c> bookingList, ApplicationUnitOfWork uow){

		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobInsertList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobUpdateList = new List<PUD_Job__c>();   //consider merge insert and update to upsert
		List<PUD_Job__c> jobDeleteList = new List<PUD_Job__c>();   //delete while blujay not integrated
		Set<String> jobExistingBookingDateSet = new Set<String>(); //passed in as empty as only for batch
		Map<String,PUD_Job__c> jobsNewMap = new Map<String, PUD_Job__c>();
		Map<String,PUD_Job__c> jobsExistingMap = new Map<String, PUD_Job__c>();

		Map<Id, PUD_Booking__c> bookingsMap = new Map<Id, PUD_Booking__c>(bookingList); //Ids of valid bookings based on date range

		//#Get all future Jobs for bookings in set. Note SOQL must match statement in PUDUtility (used for jobsNewList) for compare
		// retrieve all existing Jobs independent of status.
		//!!!---WARNING - Fields below must be an IDENTICAL match to jobsNewList record create in getNewJobList below ---!!!
		List<PUD_Job__c> jobsExistingList = [SELECT
				Booking__c,
				Date__c,
				Street__c,
				City__c,
				Post_Code__c,
				State__c,
				Start_Time__c,
				Display_Start_Time__c,
				Earliest_Start_Time__c,
				Latest_End_Time__c,
				Route_Lookup__c,
				Booking_Location__c,
				Depot__c,
				Contact_Name__c,
				Contact_Phone_Number__c,
				Contact_Email__c,
				Hazards__c,
				Site_Instructions__c,
				Comments__c,
				Dwell_Time_Planned__c,
				Location__c,
				Customer__c,
				Network__c,
				Booking_Id__c,
				Geo__Latitude__s,
				Geo__Longitude__s,
				Pallets_Quantity__c,
				Tubs_Quantity__c,
				Bags_Quantity__c,
				Trays_Quantity__c,
				Volume_Cubic_Metre__c,
				Large_Letter_Tubs__c,
				Small_Letter_Trays__c,
				White_Bags__c,
				Express_Bags__c,
				Blue_Bags__c,
				Red_Tubs__c,
				Booking_Comments__c,
				Revenue_Check__c,
				Article_Info__c,
				Article_Count__c,
				Booking_Type__c,
				Source_Street__c,
				Source_City__c,
				Source_Post_Code__c,
				Source_State__c,
				Confidence__c,
				Stop_Credit__c,
				Key_Number__c,
				Location_Frontage_Geo__Latitude__s,
				Location_Frontage_Geo__Longitude__s,
				Location_Side_Of_Street_Code__c,
				Location_DPID__c,
				Status__c,
				Regular_Product__c,
				Express_Product__c,
				International_Product__c,
				Empty_Aircan__c,
				Empty_Cage__c,
				Empty_CardULD__c,
				Empty_Colby__c,
				Empty_Pallets__c,
				Empty_Trailer__c,
				Empty_ULD__c,
				Full_Aircan__c, 
				Full_Cage__c, 
				Full_CardULD__c, 
				Full_Colby__c, 
				Full_Pallets__c, 
				Full_Trailer__c, 
				Full_ULD__c,
				Containers_Payload__c
		FROM PUD_Job__c
		WHERE Booking__c IN:bookingsMap.keySet()
		AND Date__c >= :DATE_FROM];

		//System.debug('jobsExistingList = ' + jobsExistingList);

		//#Call function to return new list of jobs based on changed booking $$$MOVED HERE FROM BELOW
		jobsNewList = getNewJobList(bookingList, jobExistingBookingDateSet);


		bookingList.clear();

		//#Build existing job map (keystring[bookingid-date],Job Record) : assumes booking has either 0 or 1 job for each day.
		for(PUD_Job__c job : jobsExistingList){
			jobsExistingMap.put(job.Booking__c + job.Date__c.format(),job);
		}
		jobsExistingList.clear(); //no longer required as loaded into map

		//#Build new job map (keystring[bookingid-date],Job Record) : assumes booking has either 0 or 1 job for each day.
		for(PUD_Job__c job : jobsNewList){
			jobsNewMap.put(job.Booking__c + job.Date__c.format(),job);
		}
		jobsNewList.clear(); //no longer required as loaded into map

		//#Loop thru new jobs and compare with a clone of matching existing job to determine if Insert or Update is required
		for(String strBookingDateKey : jobsNewMap.keySet()){

			//Get the new job from the map
			PUD_Job__c jobNew = jobsNewMap.get(strBookingDateKey);

			//If an existing job is found for same booking and date
			if(jobsExistingMap.containsKey(strBookingDateKey)){

				PUD_Job__c jobExisting = jobsExistingMap.get(strBookingDateKey);

				// check if existing job needs to be updated. add to jobUpdateList if an update is necessary.
				PUD_Job__c updatable = getUpdatableJob(jobNew, jobExisting);
				if (updatable != null) {
					jobUpdateList.add(updatable);
				}
			} else {
				//Else no existing job found for same booking and date, so add new record to jobInsertList
				jobInsertList.add(jobNew);
			}
		}//end jobNew loop


		//#Loop thru existing jobs and compare with new job to determine if Cancel (delete until blujay connected) is required
		for(String strBookingDateKey : jobsExistingMap.keySet()){

			//Get new job record for same booking and date
			PUD_Job__c jobNew = new PUD_Job__c();
			jobNew = jobsNewMap.get(strBookingDateKey);

			// If no new job found for same booking and date, then add to jobDeleteList if existing job is still in 'New' status.
			// IMPORTANT - Jobs are not allowed to be deleted (cancelled) through the parent booking after it has been sent to dispatch system.
			// In this scenario, updates must be cancelled individually on the Job.
			if(jobNew == null && jobsExistingMap.get(strBookingDateKey).Status__c == PUDConstants.PUD_JOB_STATUS_NEW){
				// existing job is in 'New' status. delete the job as this is no longer needed.
				PUD_Job__c jobExisting = new PUD_Job__c();
				jobExisting = jobsExistingMap.get(strBookingDateKey);
				jobDeleteList.add(jobExisting);				
			}else if(jobNew == null && (jobsExistingMap.get(strBookingDateKey).Status__c == PUDConstants.PUD_JOB_STATUS_SCHEDULE || jobsExistingMap.get(strBookingDateKey).Status__c == PUDConstants.PUD_JOB_STATUS_ACCEPTED)){
				//If no new Job found for the same booking and date, provided the current job statuses are either in Accepted or Schedule.
				//Update the existing Job status to 'Cancel' status. This is introduced as an enhancement to 'No Pickup' action on the booking record.
				PUD_Job__c jobExisting = jobsExistingMap.get(strBookingDateKey);
				//Change - Updating the Job status to 'Cancel' rather than deleting the job
				jobExisting.Status__c = PUDConstants.PUD_JOB_STATUS_CANCEL;
				jobUpdateList.add(jobExisting);				
			}
		}//end jobExisting loop

		//insert update and cancel/delete jobs
		if(jobInsertList.size() > 0){
			//insert jobInsertList;
			uow.registerNew(jobInsertList, true, 'PUDUtility.refreshJobs');
			refreshContainerTypes(bookingsMap, jobInsertList, uow);
		}
		if(jobUpdateList.size() > 0){
			//update jobUpdateList;
			uow.registerDirty(jobUpdateList, true, 'PUDUtility.refreshJobs');
		}
		if(jobDeleteList.size() > 0){
			//delete jobDeleteList;
			uow.registerDeleted(jobDeleteList, true, 'PUDUtility.refreshJobs');
		}

	}

	//*****3. GET NEW JOB LIST - Sub Function*****
	//Description:
	//This function returns a list of jobs required for a list of bookings passed in.
	//The input argument jobBookingDateSet is for the Batch Generation call context - it exludes any job record in list returned where a job already exists for a particular date.
	//This function is called from addNewJobs and refreshJobs
	public static List<PUD_Job__c> getNewJobList(List<PUD_Booking__c> bookingList, Set<String> jobExistingBookingDateSet){

		Date dateSunday = Date.newInstance(1900, 1, 7);
		Date dateProcess;
		Date dateBookingExp;
		Date dateBookingEff;
		Integer intProcessDay;
		String strRoute;
		Boolean bolMon;
		Boolean bolTue;
		Boolean bolWed;
		Boolean bolThu;
		Boolean bolFri;
		Boolean bolSat;
		Boolean bolSun;
		Boolean bolSingleDayBooking = false;
		Set<Id> bookingIdSet = new Set<Id>(); //Ids of bookings in list - used to get all booking exceptions
		Set<Id> tempChildSet = new Set<Id>();
		Map<Id,Set<Id>> bookingParentIdToChildIdSetMap = new Map<Id,Set<Id>>(); //Map to related child to parent booking
		Set<String> bookingExNoVisitBookingDateSet = new Set<String>(); //key BookingId-Date for 'no visit' exception for booking: assumes booking has either 0 or 1 job for each day.
		List<PUD_Booking_Exception__c> bookingExceptionList = new List<PUD_Booking_Exception__c>();
		List<PUD_Booking_Exception__c> bookingExceptionParentList = new List<PUD_Booking_Exception__c>();
		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();

		//#Build Booking Id and Parent Booking Id sets
		for(PUD_Booking__c booking : bookingList){
			//Add id of booking to set
			bookingIdSet.add(booking.Id);
			//If booking has a parent
			if(booking.Parent_Booking__c != null){
				//Build map of parent booking id (key) with set of all child booking id
				if(bookingParentIdToChildIdSetMap.containsKey(booking.Parent_Booking__c)){
					tempChildSet = bookingParentIdToChildIdSetMap.get(booking.Parent_Booking__c);
				}
				else{
					tempChildSet = new Set<Id>();
				}
				tempChildSet.add(booking.Id); //add this child to the set
				bookingParentIdToChildIdSetMap.put(booking.Parent_Booking__c,tempChildSet);
			}
		}

		//#Get all Booking Exceptions for date range, for bookings being processed
		bookingExceptionList = [SELECT Id, Start_Date__c, End_Date__c, Booking__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c
		FROM PUD_Booking_Exception__c
		WHERE Booking__c IN:bookingIdSet
		AND (Start_Date__c <= :DATE_TO AND End_Date__c >= :DATE_FROM)];

		//#Get all Booking Exceptions for date range, for PARENT of bookings being processed
		bookingExceptionParentList = [SELECT Id, Start_Date__c, End_Date__c, Booking__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c
		FROM PUD_Booking_Exception__c
		WHERE Booking__c IN :bookingParentIdToChildIdSetMap.keySet()
		AND (Start_Date__c <= :DATE_TO AND End_Date__c >= :DATE_FROM)];

		//#Build key set of 'no visit' booking exceptions by BookingId-Date (e.g. <Id>-2019-08-28) : assumes booking has either 0 or 1 no visit booking exception for each day.
		for(PUD_Booking_Exception__c bookex : bookingExceptionList){
			dateProcess = DATE_FROM;

			//Get active exception day values
			bolMon = bookex.Monday__c;
			bolTue = bookex.Tuesday__c;
			bolWed = bookex.Wednesday__c;
			bolThu = bookex.Thursday__c;
			bolFri = bookex.Friday__c;
			bolSat = bookex.Saturday__c;
			bolSun = bookex.Sunday__c;

			//For each date (from From to To)
			while(dateProcess <= DATE_TO){
				//If exception is valid for date range
				if(bookex.Start_Date__c <= dateProcess && bookex.End_Date__c >= dateProcess){

					//Get day value of date being evaluated
					intProcessDay = Math.Mod(dateSunday.daysBetween(dateProcess), 7); //0-Sunday -> 6-Saturday

					//If the applicable Day checkbox is check for exception day
					if( (bolSun && intProcessDay == 0) ||
							(bolMon && intProcessDay == 1) ||
							(bolTue && intProcessDay == 2) ||
							(bolWed && intProcessDay == 3) ||
							(bolThu && intProcessDay == 4) ||
							(bolFri && intProcessDay == 5) ||
							(bolSat && intProcessDay == 6) ){

						//Then add to no visit exception set
						bookingExNoVisitBookingDateSet.add(bookex.Booking__c + dateProcess.format());
					}
				}
				//increment process date
				dateProcess = dateProcess.addDays(1);
			}
		}

		//#Build key set of 'no visit' booking exceptions by BookingId-Date for PARENT derived exceptions
		//i.e. Parent booking exceptions are dictated to child bookings.
		//Loop thru exceptions for parent bookings
		for(PUD_Booking_Exception__c bookex : bookingExceptionParentList){
			dateProcess = DATE_FROM;

			//Get active exception day values
			bolMon = bookex.Monday__c;
			bolTue = bookex.Tuesday__c;
			bolWed = bookex.Wednesday__c;
			bolThu = bookex.Thursday__c;
			bolFri = bookex.Friday__c;
			bolSat = bookex.Saturday__c;
			bolSun = bookex.Sunday__c;

			//For each date (from From to To)
			while(dateProcess <= DATE_TO){
				//If exception is valid for date range
				If(bookex.Start_Date__c <= dateProcess && bookex.End_Date__c >= dateProcess){

					//Get day value of date being evaluated
					intProcessDay = Math.Mod(dateSunday.daysBetween(dateProcess), 7); //0-Sunday -> 6-Saturday

					//If the applicable Day checkbox is checked for exception day
					if( (bolSun && intProcessDay == 0) ||
							(bolMon && intProcessDay == 1) ||
							(bolTue && intProcessDay == 2) ||
							(bolWed && intProcessDay == 3) ||
							(bolThu && intProcessDay == 4) ||
							(bolFri && intProcessDay == 5) ||
							(bolSat && intProcessDay == 6) ){

						//#Then for each child booking associated to this parent add a no visit exception to the Set
						//Get all child booking ids for parent
						tempChildSet = bookingParentIdToChildIdSetMap.get(bookex.Booking__c);
						//add all found to exception set
						for(Id childBookingId : tempChildSet){
							bookingExNoVisitBookingDateSet.add(childBookingId + dateProcess.format());
						}
					}
				}
				//increment process date
				dateProcess = dateProcess.addDays(1);
			}
		}

		System.debug('booking Exception No Visit instance count = ' + bookingExNoVisitBookingDateSet.size());

		//#Loop thru each booking and each date. if job needs to be created, and does not exist, then add to list to insert
		for(PUD_Booking__c booking : bookingList){

			//Get effective and expiry dates
			dateBookingExp = booking.Expiry_Date_Calc__c;
			dateBookingEff = booking.Effective_Date_Calc__c;

			//If dates the same then set flag to ignore day values - i.e. if booking for a single day, then must be required for that day of the week
			bolSingleDayBooking = false;
			if(dateBookingExp == dateBookingEff){
				bolSingleDayBooking = true;
			}

			//#Get booking values
			//If parent booking is not set
			//Then get detail from this booking
			if(booking.Parent_Booking__c == null)
			{
				//Get active day values
				bolMon = booking.Monday__c;
				bolTue = booking.Tuesday__c;
				bolWed = booking.Wednesday__c;
				bolThu = booking.Thursday__c;
				bolFri = booking.Friday__c;
				bolSat = booking.Saturday__c;
				bolSun = booking.Sunday__c;

				//Get Route
				strRoute = booking.Route_Lookup__c;
			}
			//Get detail from parent booking
			else{
				//- CONSIDER changing these fx fields to _Calc return value from Parent in parent set
				//- This allows additional logic to be applied in formula without a code change (e.g. overide)
				//Get active day values
				bolMon = booking.Parent_Monday__c;
				bolTue = booking.Parent_Tuesday__c;
				bolWed = booking.Parent_Wednesday__c;
				bolThu = booking.Parent_Thursday__c;
				bolFri = booking.Parent_Friday__c;
				bolSat = booking.Parent_Saturday__c;
				bolSun = booking.Parent_Sunday__c;

				//Get Route
				strRoute = booking.Parent_Route__c;
			}

			dateProcess = DATE_FROM;

			//For each date (from From to To)
			while(dateProcess <= DATE_TO){

				//If booking effective for date
				if(dateBookingEff <= dateProcess && (dateBookingExp >= dateProcess || dateBookingExp == null)){

					//If job for date required = true
					intProcessDay = Math.Mod(dateSunday.daysBetween(dateProcess), 7); //0-Sunday -> 6-Saturday

					//If process day is an active booking day, or booking is a single day booking, then continue
					If( (bolSun && intProcessDay == 0) ||
							(bolMon && intProcessDay == 1) ||
							(bolTue && intProcessDay == 2) ||
							(bolWed && intProcessDay == 3) ||
							(bolThu && intProcessDay == 4) ||
							(bolFri && intProcessDay == 5) ||
							(bolSat && intProcessDay == 6) ||
							bolSingleDayBooking){

						//If booking doesnt already have a job for this date (for Batch run only - in Realtime call Set will be empty)
						If(!jobExistingBookingDateSet.contains(booking.Id + dateProcess.format())){

							//If there is no 'no visit' exception for this booking
							If(!bookingExNoVisitBookingDateSet.contains(booking.Id + dateProcess.format())){

								//Then add job record to list
								//!!!---WARNING - Fields below must be an IDENTICAL match to jobsExistingList query and 'Set<SObjectField> updatableFieldsOnNewJobs' ---!!!
								PUD_Job__c jobRec = new PUD_Job__c();
								jobRec.Booking__c 				= booking.Id;
								jobRec.Date__c 					= dateProcess;
								jobRec.Street__c 				= booking.Street__c;
								jobRec.City__c 					= booking.City__c;
								jobRec.Post_Code__c 				= booking.Post_Code__c;
								jobRec.State__c 					= booking.State__c;
								jobRec.Start_Time__c 			= booking.Start_Time__c;
								jobRec.Display_Start_Time__c 	= booking.Display_Start_Time__c;
								jobRec.Earliest_Start_Time__c 	= booking.Earliest_Start_Time__c;
								jobRec.Latest_End_Time__c 		= booking.Latest_End_Time__c;
								jobRec.Route_Lookup__c 			= strRoute;
								jobRec.Booking_Location__c 		= booking.Booking_Location__c;
								jobRec.Depot__c 					= booking.Depot__c;
								jobRec.Contact_Name__c 			= booking.Contact_Name__c;
								jobRec.Contact_Phone_Number__c 	= booking.Contact_Phone_Number__c;
								jobRec.Contact_Email__c 			= booking.Contact_Email__c;
								jobRec.Hazards__c 				= booking.Hazards__c;
								jobRec.Site_Instructions__c 		= booking.Site_Instructions__c;
								jobRec.Comments__c 				= booking.Comments__c;
								jobRec.Dwell_Time_Planned__c		= booking.Dwell_Time_Planned__c;
								jobRec.Location__c 				= booking.Location__c;
								jobRec.Customer__c 				= booking.Customer__c;
								jobRec.Network__c 				= booking.Network__c;
								jobRec.Booking_Id__c 			= booking.Name;
								jobRec.Geo__Latitude__s			= booking.Geo__Latitude__s;
								jobRec.Geo__Longitude__s			= booking.Geo__Longitude__s;
								jobRec.Pallets_Quantity__c		= booking.Pallets_Quantity__c;
								jobRec.Tubs_Quantity__c			= booking.Tubs_Quantity__c;
								jobRec.Bags_Quantity__c			= booking.Bags_Quantity__c;
								jobRec.Trays_Quantity__c			= booking.Trays_Quantity__c;
								jobRec.Volume_Cubic_Metre__c		= booking.Volume_Cubic_Metre__c;
								jobRec.Large_Letter_Tubs__c		= booking.Large_Letter_Tubs__c;
								jobRec.Small_Letter_Trays__c		= booking.Small_Letter_Trays__c;
								jobRec.White_Bags__c				= booking.White_Bags__c;
								jobRec.Express_Bags__c			= booking.Express_Bags__c;
								jobRec.Blue_Bags__c			    = booking.Blue_Bags__c;
								jobRec.Red_Tubs__c			    = booking.Red_Tubs__c;
								jobRec.Booking_Comments__c		= booking.Booking_Comments__c;
								jobRec.Revenue_Check__c			= booking.Revenue_Check__c;
								jobRec.Article_Info__c			= booking.Article_Info__c;
								jobRec.Booking_Type__c			= booking.Booking_Type__c;
								jobRec.Source_Street__c			= booking.Source_Street__c;
								jobRec.Source_City__c			= booking.Source_City__c;
								jobRec.Source_Post_Code__c		= booking.Source_Post_Code__c;
								jobRec.Source_State__c			= booking.Source_State__c;
								jobRec.Confidence__c				= booking.Confidence__c;
								jobRec.Stop_Credit__c			= booking.Stop_Credit__c;
								jobRec.Key_Number__c				= booking.Key_Number__c;
								jobRec.Article_Count__c          = booking.Article_Count__c;
								jobRec.Location_Frontage_Geo__Latitude__s = booking.Frontage_Geo__Latitude__s;
								jobRec.Location_Frontage_Geo__Longitude__s = booking.Frontage_Geo__Longitude__s;
								jobRec.Location_Side_Of_Street_Code__c = booking.Side_Of_Street_Code__c;
								jobRec.Location_DPID__c          = booking.DPID__c;
								jobRec.Regular_Product__c       = booking.Regular_Product__c;
								jobRec.Express_Product__c       = booking.Express_Product__c;
								jobRec.International_Product__c = booking.International_Product__c;
								jobRec.Empty_Aircan__c          = booking.Empty_Aircan__c;
								jobRec.Empty_Cage__c            = booking.Empty_Cage__c;
								jobRec.Empty_CardULD__c         = booking.Empty_CardULD__c;
								jobRec.Empty_Colby__c           = booking.Empty_Colby__c;
								jobRec.Empty_Pallets__c         = booking.Empty_Pallets__c;
								jobRec.Empty_Trailer__c         = booking.Empty_Trailer__c;
								jobRec.Empty_ULD__c             = booking.Empty_ULD__c;
								jobRec.Full_Aircan__c           = booking.Full_Aircan__c;
								jobRec.Full_Cage__c             = booking.Full_Cage__c;
								jobRec.Full_CardULD__c          = booking.Full_CardULD__c;
								jobRec.Full_Colby__c            = booking.Full_Colby__c;
								jobRec.Full_Pallets__c          = booking.Full_Pallets__c;
								jobRec.Full_Trailer__c          = booking.Full_Trailer__c;
								jobRec.Full_ULD__c              = booking.Full_ULD__c;

								jobsNewList.add(jobRec);
							}
						}
					}
				}
				//increment process date
				dateProcess = dateProcess.addDays(1);
			}
		}
		//Return jobNew List
		return jobsNewList;
	}


	//*****1. ADD NEW JOBS - Primary Function*****
	//Description:
	//Adds new jobs to list of bookings passed in.
	//Assumes that if booking has a job for a particular day, then this day can be skipped.
	//Primarily called from scheduled PUDCreateJobBatch to add the next days of jobs to the future schedule.
	@AuraEnabled
	public static string noPickupfromBookingLocation(Id bookingLocId){
		System.debug('bookingLocId = ' + bookingLocId);
		string bookingId = null;
		List<PUD_Booking__c> bookingRec= [Select Id,Name,Status__c from PUD_Booking__c where Booking_Location__c =:bookingLocId and Status__c = 'Active'];
		System.debug('bookingRec = ' + bookingRec);

		if(bookingRec.size() == 1){
			System.debug('booking Rec:::'+bookingRec);
			bookingId=bookingRec[0].Id;
			return bookingId;
		}else if(bookingRec.size() > 1){
			System.debug('There is more than one active bookings for this Booking Location.');
			bookingId ='There is more than one active booking for this Location. Please navigate to actual booking for making No Pickup.';
			return bookingId;
		}else{
			System.debug('There are no active bookings');
			bookingId='There are no active bookings for this Location.';
			return bookingId;
		}
	}

	/**
	 * Check eligibility of Jobs for sending to external dispatch system and set 'Send_to_Dispatch_System__c' flag
	 * on eligible jobs to trigger an outbound message to external dispatch system. Note that no DML is performed by
	 * this method and it is up to the calling classes to perform DML if necessary.
	 *
	 * Only those jobs related to an eligible depot (Network__c.Integrated_Job_Dispatch_Enabled__c = true) should be
	 * sent to dispatch system.
	 *
	 * @param pudJobs List jobs to send to dispatch system if eligible
	 *
	 * @return list of eligible jobs
	 */
	public List<PUD_Job__c> setEligibleJobsToTriggerDispatchSystemSync(List<PUD_Job__c> pudJobs) {

		// check eligibility and get a list of eligible jobs.
		List<PUD_Job__c> eligibleJobs = getJobsEligibleForDispatchSystemSync(pudJobs);

		for (PUD_Job__c job: eligibleJobs) {
			job.Send_to_Dispatch_System__c = true;
			job.Last_Pushed_to_Dispatch_System__c = System.now();

			if (job.Status__c == PUDConstants.PUD_JOB_STATUS_NEW) {
				job.Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
			}

			// populate schedule / cancellation request timestamps.
			if (job.Status__c == PUDConstants.PUD_JOB_STATUS_SCHEDULE && job.Schedule_Request_Timestamp__c == null) {
				job.Schedule_Request_Timestamp__c = System.now();
			} else if (job.Status__c == PUDConstants.PUD_JOB_STATUS_CANCEL && job.Cancellation_Request_Timestamp__c == null) {
				job.Cancellation_Request_Timestamp__c = System.now();
			}
		}

		return eligibleJobs;
	}

	/**
	 * Get the jobs eligible for sending to external dispatch system.
	 *
	 * @param pudJobs list of jobs to check
	 *
	 * @return eligible jobs
	 */
	private List<PUD_Job__c> getJobsEligibleForDispatchSystemSync(List<PUD_Job__c> pudJobs) {

		List<PUD_Job__c> eligibleJobs = new List<PUD_Job__c>();

		// grab the list of parent depots to check for integration enabled flag
		Set<Id> depotIds = new Set<Id>();
		for (PUD_Job__c job: pudJobs) {
			if (job.Depot__c != null) {
				depotIds.add(job.Depot__c);
			}
		}

		if (!depotIds.isEmpty()) {
			Map<Id, Network__c> depots = NetworksSelector.newInstance(new Set<SObjectField>{Network__c.Id,
					Network__c.Integrated_Job_Dispatch_Enabled__c}).selectById(depotIds);

			for (PUD_Job__c job: pudJobs) {
				if ((depots.containsKey(job.Depot__c) && depots.get(job.Depot__c).Integrated_Job_Dispatch_Enabled__c)
						&& !job.Stop_Credit__c) {

					eligibleJobs.add(job);
				}
			}
		}

		return eligibleJobs;
	}

	/**
	 * Compare the two job instances and determines if the existingJob instance needs to be updated. Fields used for
	 * comparison are based on the status of existing job.
	 * Returns an updatable version of the record if an update is necessary. Otherwise returns null.
	 *
	 * @param newJob job instance based on latest configuration in booking
	 * @param existingJob existing job instance
	 *
	 * @return an updatable version of the record if an update is necessary. Otherwise returns null.
	 */
	private PUD_Job__c getUpdatableJob(PUD_Job__c newJob, PUD_Job__c existingJob) {

		// IMPORTANT - Jobs are not allowed to be updated through the parent booking after the job has been
		// completed or cancelled.

		if (existingJob.Status__c == PUDConstants.PUD_JOB_STATUS_NEW) {
			// existing job in 'New' status. compare the new job and existing job based on the comparable fields.
			// if existing job is same as the new job, then no need to do anything => existing job is same as the new job.
			if (hasChanged(newJob, existingJob, COMPARABLE_FIELD_SET_NEW_JOBS)) {
				// new job is different to the existing job then update existing job with new job
				newJob.Id = existingJob.Id;
				return newJob;
			}

		} else if (existingJob.Status__c == PUDConstants.PUD_JOB_STATUS_SCHEDULE || existingJob.Status__c == PUDConstants.PUD_JOB_STATUS_ACCEPTED) {
			// existing job in 'Schedule' or 'Accepted' status. compare the new job and existing job based on the comparable fields.
			// updates are still allowed for subset of fields in these status.
			if (hasChanged(newJob, existingJob, COMPARABLE_FIELD_SET_SCHEDULED_JOBS)) {
				// new job is different to the existing job - update existing job (note that only a subset of fields are updated)
				PUD_Job__c updatable = new PUD_Job__c(Id=existingJob.Id);
				for (SObjectField field: COMPARABLE_FIELD_SET_SCHEDULED_JOBS) {
					updatable.put(field, newJob.get(field));
				}
				return updatable;
			}
		}

		// no need to update the job. either no updates are allowed based on job status or none of the updatable fields have changed
		// simply return null
		return null;
	}

	/**
	 * Compare the two SObject instances passed in by doing a field by field comparison for the set of fields
	 * Returns true if at least one field is different.
	 *
	 * @param newRecord SObject for comparison
	 * @param existingRecord SObject for comparison
	 * @param comparisonFields fields to compare
	 *
	 * @return true if at least one field from the interested field set is different. false otherwise.
	 */
	private Boolean hasChanged(SObject newRecord, SObject existingRecord, Set<SObjectField> comparisonFields) {
		if (newRecord != null && existingRecord != null) {
			for (SObjectField field : comparisonFields) {
				if(newRecord.get(field) != existingRecord.get(field)) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Generate the JSON payload representing container type data on the Job record.
	 * @param list of containers under a new job.
	 * @return container types JSON payload (JSON array)
	 */
	private static String generateContainerTypePayload(List<PUD_Container__c> containers){

		if (containers != null && !containers.isEmpty()) {
			List<ContainerPayload> payloads = new List<ContainerPayload>();

			// generate container payloads based on the configuration in CONTAINER_TYPE_MAPPINGS
			for (PUD_Container__c container : containers) {
				payloads.add(new ContainerPayload(container));
			}

			payloads.sort();

			// Serialise container payload and suppress null value
			return JSON.serialize(payloads, true);
		}

		return null;
	}

	
	public void refreshContainerTypes(Set<Id> bookingIds, ApplicationUnitOfWork uow) {
		Set<String> jobStatus = new Set<String>{PUDConstants.PUD_JOB_STATUS_NEW, PUDConstants.PUD_JOB_STATUS_SCHEDULE, PUDConstants.PUD_JOB_STATUS_ACCEPTED};
		
		//query bookings with booking containers
		Map<Id, PUD_Booking__c> bookings = new Map<Id, PUD_Booking__c> (PUDBookingsSelector.newInstance().selectById(bookingIds, new Set<Object>{PUDBookingsSelector.Options.WITH_CONTAINERS}));

		//query current/future Jobs with Job containers.
		List<PUD_Job__c> jobs = new List<PUD_Job__c>(); 

		jobs = PUDJobsSelector.newInstance().selectByBookingIdStatusAndFromDate(bookingIds, Date.today(), jobStatus, new Set<Object>{PUDJobsSelector.Options.WITH_CONTAINERS});
		
		refreshContainerTypes(bookings,jobs, uow);
	}

	public void refreshContainerTypes(Map<Id, PUD_Booking__c> bookings, List<PUD_Job__c> jobs, ApplicationUnitOfWork uow) {

		Map<String, PUD_Container__c> bookingContainersByUniqueKeyMap = getBookingContainersMapByUniqueKey(bookings.values());

		for (PUD_Job__c job: jobs) {
			Map<String, PUD_Container__c> jobContainersByUniqueKeyMap = getContainersMapByUniqueKey(job.Booking__c, job.Containers__r);

			List<PUD_Container__c> bookingContainers = bookings.get(job.Booking__c).Containers__r;
			if (bookingContainers != null && !bookingContainers.isEmpty()) {
				for (PUD_Container__c bookingContainer: bookingContainers) {
					String key = job.Booking__c + '-' + bookingContainer.Type__c + '-' + bookingContainer.Condition__c;
					if (jobContainersByUniqueKeyMap.containsKey(key)) {
						// existing job container - update
						PUD_Container__c jobContainer = jobContainersByUniqueKeyMap.get(key);
						jobContainer.Expected_Quantity__c = bookingContainer.Expected_Quantity__c;
						uow.registerDirty(jobContainer, new List<SObjectField>{PUD_Container__c.Expected_Quantity__c});
					} else {
						// new job container
						PUD_Container__c newContainer = newJobContainer(job, bookingContainer);
						uow.registerNew(newContainer, PUD_Container__c.Job__c, job, true, 'PUDUtility.refreshContainerTypes');
					}
				}

				job.Containers_Payload__c = generateContainerTypePayload(bookingContainers);

				system.debug('Jobs updated Payload: '+ job.Containers_Payload__c);
				system.debug('Job: '+ job.Id);
				
				if (job.Id != null) {
					uow.registerDirty(job);
				}

			} else if (String.isNotBlank(job.Containers_Payload__c)) {
				// update containers payload on job if not blank
				job.Containers_Payload__c = null;
				if (job.Id != null) {
					uow.registerDirty(job);
				}
			}

			if (job.Containers__r != null && !job.Containers__r.isEmpty()) {
				for (PUD_Container__c jobContainer: job.Containers__r) {
					String key = job.Booking__c + '-' + jobContainer.Type__c + '-' + jobContainer.Condition__c;
					if (!bookingContainersByUniqueKeyMap.containsKey(key)) {
						// delete
						uow.registerDeleted(jobContainer, true, 'PUDUtility.refreshContainerTypes');
					}
				}
			}
		}
	}

	private Map<String, PUD_Container__c> getBookingContainersMapByUniqueKey(List<PUD_Booking__c> bookings) {
		Map<String, PUD_Container__c> bookingContainersMapByUniqueKey = new Map<String, PUD_Container__c>();
		for (PUD_Booking__c booking: bookings) {
			if (!booking.Containers__r.isEmpty()) {
				bookingContainersMapByUniqueKey.putAll(getContainersMapByUniqueKey(booking.Id, booking.Containers__r));
			}
		}
		return bookingContainersMapByUniqueKey;
	}

	private Map<String, PUD_Container__c> getContainersMapByUniqueKey(Id parentId, List<PUD_Container__c> containers) {
		Map<String, PUD_Container__c> containersMapByUniqueKey = new Map<String, PUD_Container__c>();
		for (PUD_Container__c container: containers) {
			String key = parentId + '-' + container.Type__c + '-' + container.Condition__c;
			containersMapByUniqueKey.put(key, container);
		}
		return containersMapByUniqueKey;
	}
	

	
	/**
     * Unit of work that encapsulates all the required objects for this Service.
     * Note that this is a stopgap until the pattern for using Unit of Work for service operations are defined.
     *
     * @return unit or work instance
     */
	private ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(new List<SObjectType>{
				PUD_Job__c.SObjectType,
				PUD_Container__c.SObjectType
		});
	}

	private PUD_Container__c newJobContainer(PUD_Job__c job, PUD_Container__c bookingContainer) {
		PUD_Container__c jobContainer = new PUD_Container__c();
		jobContainer.RecordTypeId = jobContainerRecordTypeId;
		jobContainer.Booking__c = job.Booking__c;
		jobContainer.Type__c = bookingContainer.Type__c;
		jobContainer.Condition__c = bookingContainer.Condition__c;
		jobContainer.Expected_Quantity__c = bookingContainer.Expected_Quantity__c;
		return jobContainer;
	}


	

	/**
	* The class stores container related information such as Name, Quantity and Condition.
	* The classed is used to be serialised into a list in JSON format and value to be populated to the Containers Payload Long Text field.
	* Containers Payload will then send out to TIBCO, and then dispatch system
	*/
	@TestVisible private class ContainerPayload implements Comparable {
		public String Name {get; private set;}
		public Decimal Quantity {get; private set;}
		public String Condition {get; private set;}
		public ContainerPayload(String Name, Decimal Quantity, String Condition){
			this.Name = Name;
			this.Quantity = Quantity;
			this.Condition = Condition;
		}
		public ContainerPayload(String Name, String Condition){
			this.Name = Name;
			this.Condition = Condition;
		}
		public ContainerPayload(PUD_Container__c c) {
			this.Name = c.Type__c;
			this.Condition = c.Condition__c;
			this.Quantity = c.Expected_Quantity__c;
		}

		public Integer compareTo(Object compareTo) {
			ContainerPayload compareToContainer = (ContainerPayload)compareTo;
			return (this.Name > compareToContainer.Name ? 1 :
						(this.Name < compareToContainer.Name ? -1 :
							(this.Condition > compareToContainer.Condition ? 1 :
			                    (this.Condition < compareToContainer.Condition ? -1 : 0))));
		}
	}

}