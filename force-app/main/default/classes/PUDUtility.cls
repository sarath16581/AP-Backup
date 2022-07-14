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

	// container type mappings used for generating container type payload (JSON format) for a Job. Container type payload
	// is included in the Job dispatch interface (outbound message).
	private static final Map<String, ContainerTypeMapping> CONTAINER_TYPE_MAPPINGS = new Map<String, ContainerTypeMapping>{
			'Aircan' => new ContainerTypeMapping('Aircan', PUD_Job__c.Empty_Aircan__c, PUD_Job__c.Full_Aircan__c),
			'Cage' =>  new ContainerTypeMapping('Cage', PUD_Job__c.Empty_Cage__c, PUD_Job__c.Full_Cage__c),
			'CardULD' => new ContainerTypeMapping('CardULD', PUD_Job__c.Empty_CardULD__c, PUD_Job__c.Full_CardULD__c),
			'Colby' => new ContainerTypeMapping('Colby', PUD_Job__c.Empty_Colby__c, PUD_Job__c.Full_Colby__c),
			'Pallets' => new ContainerTypeMapping('Pallets', PUD_Job__c.Empty_Pallets__c, PUD_Job__c.Full_Pallets__c),
			'Trailer' => new ContainerTypeMapping('Trailer', PUD_Job__c.Empty_Trailer__c, PUD_Job__c.Full_Trailer__c),
			'ULD' => new ContainerTypeMapping('ULD', PUD_Job__c.Empty_ULD__c, PUD_Job__c.Full_ULD__c)
	};

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

		List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
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
				Full_Aircan__c, Full_Cage__c, Full_CardULD__c, Full_Colby__c, Full_Pallets__c, Full_Trailer__c, Full_ULD__c
		FROM PUD_Booking__c WHERE Id IN:bookingIdSet];

		//Call function depending on input parameter
		//Refresh will update all existing jobs from now into future
		//Add New will assume all existing jobs are in correct state, and only insert jobs that are not present
		if(bolRefreshAll){
			refreshJobs(bookingList);
		}
		else{
			addNewJobs(bookingList);
		}
	}

	//*****1. ADD NEW JOBS - Primary Function*****
	//Description:
	//Adds new jobs to list of bookings passed in.
	//Assumes that if booking has a job for a particular day, then this day can be skipped.
	//Primarily called from scheduled PUDCreateJobBatch to add the next days of jobs to the future schedule.
	public void addNewJobs(List<PUD_Booking__c> bookingList){

		Set<Id> bookingIdSet = new Set<Id>();
		Set<String> jobExistingBookingDateSet = new Set<String>(); //key BookingId-Date for existing job for booking: assumes booking has either 0 or 1 job for each day.
		List<PUD_Job__c> jobsExistingList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();

		//#Build set of booking Ids
		for(PUD_Booking__c booking : bookingList){
			bookingIdSet.add(booking.Id);
		}

		//Get list of of all existing jobs in future.
		jobsExistingList = [SELECT Id, Date__c, Booking__c
		FROM PUD_Job__c
		WHERE Booking__c IN:bookingIdSet
		AND Date__c >= :DATE_FROM];

		//#Build key set of job by BookingId-Date (e.g. <Id>-2019-08-28) : assumes booking has either 0 or 1 job for each day.
		for(PUD_Job__c job : jobsExistingList){
			jobExistingBookingDateSet.add(job.Booking__c + job.Date__c.format());
		}

		System.debug('job Existing count = ' + jobExistingBookingDateSet.size());

		//Call function to get list of new jobs
		//jobsNewList = getNewJobList(bookingList, jobExistingBookingDateSet);

		//Call function to get list of new jobs and containers to be created under those jobs.
		JobsAndContainers jobsAndContainersWrappers = getNewJobList(bookingList, jobExistingBookingDateSet);
		
		System.debug('Insert Job count = ' + jobsAndContainersWrappers.newJobs);
		if(jobsAndContainersWrappers.newJobs != null && !jobsAndContainersWrappers.newJobs.isEmpty()){
			
			//insert jobs
			insert jobsAndContainersWrappers.newJobs;

			//associated Job IDs with associated container types
			List<PUD_Container__c> allContainersAgainstAllNewJobs = handleContainers(jobsAndContainersWrappers);

			//insert containers
			if(!allContainersAgainstAllNewJobs.isEmpty()){
				system.debug('Containers size: '+allContainersAgainstAllNewJobs.size());
				insert allContainersAgainstAllNewJobs;
			}
		}
	}

	//*****2. REFRESH JOBS - Primary Function*****
	//Description:
	//This function refreshes all jobs for bookings in list passed in.
	//Refresh compares existing jobs with new jobs based on any changes to bookings, and either inserts records (if new), updates records (if modified), or deletes records (if not valid)
	public void refreshJobs(List<PUD_Booking__c> bookingList){


		List<PUD_Job__c> jobsNewList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobInsertList = new List<PUD_Job__c>();
		List<PUD_Job__c> jobUpdateList = new List<PUD_Job__c>();   //consider merge insert and update to upsert
		List<PUD_Job__c> jobDeleteList = new List<PUD_Job__c>();   //delete while blujay not integrated
		Set<String> jobExistingBookingDateSet = new Set<String>(); //passed in as empty as only for batch
		Map<String,PUD_Job__c> jobsNewMap = new Map<String, PUD_Job__c>();
		Map<String,PUD_Job__c> jobsExistingMap = new Map<String, PUD_Job__c>();

		Set<Id> bookingIdSet = new Set<Id>(); //Ids of valid bookings based on date range
		List<PUD_Job__c> jobsExistingList = new List<PUD_Job__c>();

		//#Build Booking Id Set
		for(PUD_Booking__c booking : bookingList){
			bookingIdSet.add(booking.Id);
		}

		//#Get all future Jobs for bookings in set. Note SOQL must match statement in PUDUtility (used for jobsNewList) for compare
		// retrieve all existing Jobs independent of status.
		//!!!---WARNING - Fields below must be an IDENTICAL match to jobsNewList record create in getNewJobList below ---!!!
		jobsExistingList = [SELECT
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
		WHERE Booking__c IN:bookingIdSet
		AND Date__c >= :DATE_FROM];

		//System.debug('jobsExistingList = ' + jobsExistingList);

		//#Call function to return new list of jobs based on changed booking $$$MOVED HERE FROM BELOW
		//jobsNewList = getNewJobList(bookingList, jobExistingBookingDateSet);

		//Call function to get list of new jobs and containers to be created under those jobs.
		JobsAndContainers jobsAndContainersWrappers = getNewJobList(bookingList, jobExistingBookingDateSet);

		bookingList.clear();

		//#Build existing job map (keystring[bookingid-date],Job Record) : assumes booking has either 0 or 1 job for each day.
		for(PUD_Job__c job : jobsExistingList){
			jobsExistingMap.put(job.Booking__c + job.Date__c.format(),job);
		}
		jobsExistingList.clear(); //no longer required as loaded into map

		//#Build new job map (keystring[bookingid-date],Job Record) : assumes booking has either 0 or 1 job for each day.
		if(jobsAndContainersWrappers.newJobs != null && !jobsAndContainersWrappers.newJobs.isEmpty()){
			for(PUD_Job__c job : jobsAndContainersWrappers.newJobs){
				jobsNewMap.put(job.Booking__c + job.Date__c.format(),job);
			}
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

		//Savepoint - here
		//insert update and cancel/delete jobs
		if(jobInsertList.size() > 0){
			
			//insert new jobs
			insert jobInsertList;	
			
			//associate newly created job ids with container types
			List<PUD_Container__c> allContainersAgainstAllNewJobs = handleContainers(jobsAndContainersWrappers);
			
			//insert new containers
			if(!allContainersAgainstAllNewJobs.isEmpty()){
				system.debug('allContainersAgainstAllNewJobs: '+allContainersAgainstAllNewJobs.isEmpty());
				insert allContainersAgainstAllNewJobs;
			}
		}

		if(jobUpdateList.size() > 0){
			update jobUpdateList;
		}
		if(jobDeleteList.size() > 0){
			delete jobDeleteList;

			//after deletion of jobs, delete containers against them.
			//processJobContainersOnBookingUpdates(jobInsertList, true);
			
			//add save point
			//delete containers
		}
	}

	//*****3. GET NEW JOB LIST - Sub Function*****
	//Description:
	//This function returns a list of jobs required for a list of bookings passed in.
	//The input argument jobBookingDateSet is for the Batch Generation call context - it exludes any job record in list returned where a job already exists for a particular date.
	//This function is called from addNewJobs and refreshJobs
	public static JobsAndContainers getNewJobList(List<PUD_Booking__c> bookingList, Set<String> jobExistingBookingDateSet){

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

		//Map to hold bookings and its containers.
		Map<Id, List<PUD_Container__c>> bookingIdVsContainers = new Map<Id, List<PUD_Container__c>>();
		Map<String, List<PUD_Container__c>> uniqueJobIdVsNewContainers = new Map<String, List<PUD_Container__c>>(); //map to store new containers against new jobs.
		Id jobContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Job_Container'}).values()[0].Id;


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

		//Get all containers under bookgins
		for(PUD_Container__c container : PUDContainersSelector.newInstance().selectByBookingIds(bookingIdSet, new Set<Object>())){ // [Select Id, Type__c, Booking__c, Job__c from PUD_Container__c where Booking__c IN : bookingIds]){
			//containers at Booking level will always have Job__c = NULL.
			if(container.Job__c == null){
				if(!bookingIdVsContainers.containsKey(container.Booking__c)){
					bookingIdVsContainers.put(container.Booking__c, new List<PUD_Container__c>());
				}
				bookingIdVsContainers.get(container.Booking__c).add(container);
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
				If(bookex.Start_Date__c <= dateProcess && bookex.End_Date__c >= dateProcess){

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

								// call method to serialise payload to json format and populate Containers Payload long text field
								//jobRec.Containers_Payload__c = generateContainerTypePayload(jobRec);
								
								List<PUD_Container__c> bookingContainers = new List<PUD_Container__c>();
								if(bookingIdVsContainers.containsKey(booking.Id)){
									//get list of containers related to  booking
									bookingContainers = bookingIdVsContainers.get(booking.Id);
								}

								//create containers for each job.
								List<PUD_Container__c> containersToCreate = new List<PUD_Container__c>();

								for(PUD_Container__c bookingContainer : bookingContainers){
									PUD_Container__c newContainer = new PUD_Container__c();
									newContainer.Type__c = bookingContainer.Type__c;
									newContainer.Booking__c = bookingContainer.Booking__c;
									newContainer.Actual_Quantity__c = bookingContainer.Actual_Quantity__c;
									newContainer.Expected_Quantity__c = bookingContainer.Expected_Quantity__c;
									newContainer.Condition__c = bookingContainer.Condition__c;
									newContainer.RecordTypeId = jobContainerRecordTypeId;
									containersToCreate.add(newContainer);
								}

								//generate container payload for a job being created.
								//Note: This is a potential payload assuming that jobs and its containers creation will be successfull.
								//In the event of DML fails, container payload will need to be recalculated as per available containers.
								//Payload is calculated ahead of container creations, to avoid updating jobs after containers are created.
								jobRec.Containers_Payload__c = generateContainerTypePayloadBasedOnContainers(bookingContainers);
								jobsNewList.add(jobRec);

								
								uniqueJobIdVsNewContainers.put(booking.Id + dateProcess.format(), containersToCreate);
							}
						}
					}
				}
				//increment process date
				dateProcess = dateProcess.addDays(1);
			}
		}
		//Return jobNew List
		//return jobsNewList;

		//Return wrapper
		return new JobsAndContainers(jobsNewList, uniqueJobIdVsNewContainers);
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
	 * @param jobRec job instance for which the payload is generated
	 * @return container types JSON payload (JSON array)
	 */
	private static String generateContainerTypePayload(PUD_Job__c jobRec){

		List<ContainerPayload> payloads = new List<ContainerPayload>();

		// generate container payloads based on the configuration in CONTAINER_TYPE_MAPPINGS
		for (String containerType: CONTAINER_TYPE_MAPPINGS.keySet()) {
			ContainerTypeMapping mapping = CONTAINER_TYPE_MAPPINGS.get(containerType);
			if (jobRec.get(mapping.emptyQuantityField) != null) {
				payloads.add(new ContainerPayload(containerType, (Decimal) jobRec.get(mapping.emptyQuantityField), CONTAINER_CONDITION_EMPTY));
			}
			if (jobRec.get(mapping.fullQuantityField) != null) {
				payloads.add(new ContainerPayload(containerType, (Decimal) jobRec.get(mapping.fullQuantityField), CONTAINER_CONDITION_FULL));
			}
		}

		if (!payloads.isEmpty()) {
			// Serialise container payload and suppress null value
			return JSON.serialize(payloads, true);
		}

		return null;
	}

	/**
	 * Associate containers to newly created job.
	 * @param Wrapper instance containing new job list and their containers.
	 * @return List of containers after populating Job Ids
	 */

	private List<PUD_Container__c> handleContainers(JobsAndContainers jobsAndContainersWrappers){
		List<PUD_Container__c> allContainersAgainstAllNewJobs = new List<PUD_Container__c>();
		for(PUD_Job__c newJob : jobsAndContainersWrappers.newJobs){

			if(jobsAndContainersWrappers.jobUniqueKeyVsNewContainers.containsKey(newJob.Booking__c+newJob.Date__c.format())){

				for(PUD_Container__c container : jobsAndContainersWrappers.jobUniqueKeyVsNewContainers.get(newJob.Booking__c+newJob.Date__c.format())){
					container.Job__c = newJob.Id;
					allContainersAgainstAllNewJobs.add(container);
				}
			}
		}
		return allContainersAgainstAllNewJobs;
	}

	/**
	 * Generate the JSON payload representing container type data on the Job record.
	 * @param list of containers under a new job.
	 * @return container types JSON payload (JSON array)
	 */
	private static String generateContainerTypePayloadBasedOnContainers(List<PUD_Container__c> containers){

		List<ContainerPayload> payloads = new List<ContainerPayload>();

		// generate container payloads based on the configuration in CONTAINER_TYPE_MAPPINGS
		for (PUD_Container__c container : containers) {
				payloads.add(new ContainerPayload(container.Type__c, (Decimal) container.Expected_Quantity__c, container.Condition__c));
		}
		if (!payloads.isEmpty()) {
			// Serialise container payload and suppress null value
			return JSON.serialize(payloads, true);
		}

		return null;
	}


	

	
	/**
	 * Called from refreshJobs/createJobs. Whenever new jobs are created/deleted then containers will be created/update accordingly.
	 * @param: NewJobs/DeletedJobs.
	 */
	private void processJobContainersOnBookingUpdates(List<PUD_Job__c> jobRecords, Boolean isDelete){
		Id jobContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Job_Container'}).values()[0].Id;

		
		//get all container types related to jobs.
		Map<Id, PUD_Job__c> jobIdVsJobs = new Map<Id, PUD_Job__c>();

		//get booking ids
		Set<Id> bookingIds = new Set<Id>();
		for(PUD_Job__c job : jobRecords){
			bookingIds.add(job.Booking__c);		
			jobIdVsJobs.put(job.Id, job);	
		}

		

		Map<Id, List<PUD_Container__c>> bookingIdVsContainers = new Map<Id, List<PUD_Container__c>>();
		Map<Id, List<PUD_Container__c>> jobIdVsContainers = new Map<Id, List<PUD_Container__c>>();

		//query container types at Booking and Job level.
		for(PUD_Container__c container : PUDContainersSelector.newInstance().selectByBookingIds(bookingIds, new Set<Object>())){ // [Select Id, Type__c, Booking__c, Job__c from PUD_Container__c where Booking__c IN : bookingIds]){


			//containers at Booking level will always have Job__c = NULL.
			if(container.Job__c == null){
				if(!bookingIdVsContainers.containsKey(container.Booking__c)){
					bookingIdVsContainers.put(container.Booking__c, new List<PUD_Container__c>());
				}
				bookingIdVsContainers.get(container.Booking__c).add(container);
			}
			//populate containers under JOB
			else{
				if(!jobIdVsContainers.containsKey(container.Job__c)){
					jobIdVsContainers.put(container.Job__c, new List<PUD_Container__c>());
				}
				jobIdVsContainers.get(container.Job__c).add(container);
			}
		}
		
		List<PUD_Container__c> containersToCreate = new List<PUD_Container__c>();
		List<PUD_Container__c> containersToDelete = new List<PUD_Container__c>();

		//get applicable containers under a booking.
		for(Id jobId : jobIdVsJobs.keySet()){

			List<PUD_Container__c> bookingContainers;

			if(bookingIdVsContainers.containsKey(jobIdVsJobs.get(jobId).Booking__c)){
				
				//get list of containers related to job's booking
				bookingContainers = bookingIdVsContainers.get(jobIdVsJobs.get(jobId).Booking__c);

				//for delete operation, delete all containers under a job
				if(isDelete){

					//if job being deleted exists in a map then delete list associated with its Id.
					//jobIdVsContainers will always have containers associated with job being deleted.
					if(jobIdVsContainers.containsKey(jobId)){
						containersToDelete.addAll(jobIdVsContainers.get(jobId));
					}
				}
				else{
					for(PUD_Container__c bookingContainer : bookingContainers){
						PUD_Container__c newContainer = new PUD_Container__c();
						newContainer.Type__c = bookingContainer.Type__c;
						newContainer.Job__c = jobId;
						newContainer.Booking__c = bookingContainer.Booking__c;
						newContainer.Actual_Quantity__c = bookingContainer.Actual_Quantity__c;
						newContainer.Expected_Quantity__c = bookingContainer.Expected_Quantity__c;
						newContainer.Condition__c = bookingContainer.Condition__c;

						containersToCreate.add(newContainer);
					}
				}
			}
		}

		if(!containersToCreate.isEmpty()){
			insert containersToCreate;
		}
		if(!containersToDelete.isEmpty()){
			delete containersToDelete;
		}
					
	} 


	private void deleteJobContainers(List<PUD_Container__c> deletedRecords, List<PUD_Container__c> existingJobContainers, Map<Id, List<PUD_Job__c>> bookingVsJobsMap){
		Map<Id, List<PUD_Container__c>> jobVsExistingContainersMap = new Map<Id, List<PUD_Container__c>>();

		for(PUD_Container__c container : existingJobContainers){
			if(!jobVsExistingContainersMap.containsKey(container.Job__c)){
				jobVsExistingContainersMap.put(container.Job__c, new List<PUD_Container__c>{container});
			}
			else{
				jobVsExistingContainersMap.get(container.Job__c).add(container);
			}
		}

		Map<Id, PUD_Job__c> jobsToUpdateMap = new Map<Id, PUD_Job__c>();
		List<PUD_Container__c> containersToDelete = new List<PUD_Container__c>();

		//iterate deleted booking containers
		for(PUD_Container__c cRecord : deletedRecords){

			List<PUD_Job__c> relatedJobs;
			if(bookingVsJobsMap.containsKey(cRecord.Booking__c)){
				
				//get jobs against  a booking
				relatedJobs = bookingVsJobsMap.get(cRecord.Booking__c);


				//iterate through each job under a booking
				for(PUD_Job__c currentJob : relatedJobs){
					List<PUD_Container__c> jobContainers = new List<PUD_Container__c>();
					
					Boolean isMatchingContainerFound = false;

					//get all containers under a given job.
					if(jobVsExistingContainersMap.containsKey(currentJob.Id)){
						jobContainers = jobVsExistingContainersMap.get(currentJob.Id);
					}
					List<PUD_Container__c> containersToKeep = new List<PUD_Container__c>();
					
					for(PUD_Container__c jobContainer : jobContainers){
						//Type and Condition must be matched.
						//Pallets, Empty and Pallets, Full are considered as two different containers.
						if(jobContainer.Type__c == cRecord.Type__c && jobContainer.Condition__c == cRecord.Condition__c){
							containersToDelete.add(jobContainer);
						}
						else{
							containersToKeep.add(jobContainer);
						}
					}

					if(!containersToKeep.isEmpty()){
						PUD_Job__c jToUpdate = new PUD_Job__c(Id = currentJob.Id);
						jToUpdate.Containers_Payload__c = generateContainerTypePayloadBasedOnContainers(containersToKeep);
						jobsToUpdateMap.put(jToUpdate.Id, jToUpdate);
					}

				}

			}
			
		}

		if(!containersToDelete.isEmpty()){
			delete containersToDelete;
		}
		if(!jobsToUpdateMap.isEmpty()){
			update jobsToUpdateMap.values();
		}
	}
	

	/**
	 * Called from PUDContainerTypeSyncModule to add/update container records under jobs when containers under bookgins are updated.
	 * @param: 1. New Container records, 
	 * 		   2. Old map of containers (in case of update ONLY. In case of New records, this is null).
	 *         3. List of bookings for which new containers are created.  
	 * @desc: This method is called from Container trigger whenever new containers are added against Bookings. 
	 */
	 public void processContainers(List<PUD_Container__c> records, Map<Id, PUD_Container__c> oldRecordsMap, Set<Id> bookingIds, Boolean isDelete){

		Set<String> jobStatus = new Set<String>{PUDConstants.PUD_JOB_STATUS_NEW, PUDConstants.PUD_JOB_STATUS_SCHEDULE, PUDConstants.PUD_JOB_STATUS_ACCEPTED};
        Id jobContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Job_Container'}).values()[0].Id;

		
		List<PUD_Job__c> jobs = PUDJobsSelector.newInstance().selectByBookingIdStatusAndFromDate(bookingIds, Date.today(), jobStatus);

		Set<Id> jobIds = new Set<Id>();
		Map<Id, List<PUD_Job__c>> bookingVsJobsMap = new Map<Id, List<PUD_Job__c>>();

		for(PUD_Job__c job : jobs){
			jobIds.add(job.Id);

			if(!bookingVsJobsMap.containsKey(job.Booking__c)){
				bookingVsJobsMap.put(job.Booking__c, new List<PUD_Job__c>{job});
			}
			else{
				bookingVsJobsMap.get(job.Booking__c).add(job);
			}
		}

		List<PUD_Container__c> containers = PUDContainersSelector.newInstance().selectByJobIds(jobIds, new Set<Object>());//[Select Id, Type__c, Job__c from PUD_Container__c where Job__c IN : jobIds];

		//if containers is null/empty, that means there are jobs without containers.
		//This could happen when jobs are created for the first time.
		List<PUD_Container__c> containersToCreate = new List<PUD_Container__c>();
		List<PUD_Container__c> containersToUpdate = new List<PUD_Container__c>();
		List<PUD_Container__c> containersToDelete = new List<PUD_Container__c>();
		
		//list of jobs to be updated with Container Payload data 
		//when a new container is added or existing is updated under a job via booking.
		List<PUD_Job__c> jobsToBeUpdated = new List<PUD_Job__c>();

		if(containers.isEmpty() && !isDelete){
			//create containers against jobs.
			system.debug('creating new containers');
			for(PUD_Container__c newRecord : records){

				system.debug('bookingVsJobsMap: '+bookingVsJobsMap);
				system.debug('bookingVsJobsMap.get Booking: '+bookingVsJobsMap.get(newRecord.Booking__c));
				
				List<PUD_Job__c> relatedJobs = bookingVsJobsMap.get(newRecord.Booking__c);
				if(relatedJobs != null){
					for(PUD_Job__c currentJob : relatedJobs){

						
						PUD_Container__c newContainer = new PUD_Container__c();
						newContainer.Type__c = newRecord.Type__c;
						newContainer.Job__c = currentJob.Id;
						newContainer.Booking__c = newRecord.Booking__c;
						newContainer.Actual_Quantity__c = newRecord.Actual_Quantity__c;
						newContainer.Expected_Quantity__c = newRecord.Expected_Quantity__c;
						newContainer.Condition__c = newRecord.Condition__c;
						newContainer.RecordTypeId = jobContainerRecordTypeId;
						containersToCreate.add(newContainer);

						//updating corresponding JOb's container payload on creation.
						PUD_Job__c jobToUpdate = new PUD_Job__c(Id = currentJob.Id);
						jobToUpdate.Containers_Payload__c = generateContainerTypePayloadBasedOnContainers(new List<PUD_Container__c>{newContainer});
						jobsToBeUpdated.add(jobToUpdate);
					}
				}
			}
		}
		else if(!containers.isEmpty() && !isDelete){
			Map<Id, List<PUD_Container__c>> jobVsExistingContainersMap = new Map<Id, List<PUD_Container__c>>();

			for(PUD_Container__c container : containers){
				if(!jobVsExistingContainersMap.containsKey(container.Job__c)){
					jobVsExistingContainersMap.put(container.Job__c, new List<PUD_Container__c>{container});
				}
				else{
					jobVsExistingContainersMap.get(container.Job__c).add(container);
				}
			}

			for(PUD_Container__c newRecord : records){

				List<PUD_Job__c> relatedJobs = bookingVsJobsMap.get(newRecord.Booking__c);
				if(relatedJobs != null){

				
				for(PUD_Job__c currentJob : relatedJobs){

					//get existing container payload of current job
					List<ContainerPayload> existingContainerPayloadList = new List<ContainerPayload>();
					if(currentJob.Containers_Payload__c != null){
						existingContainerPayloadList = (List<ContainerPayload>) JSON.deserialize(currentJob.Containers_Payload__c, List<ContainerPayload>.class);
					}

					List<PUD_Container__c> jobContainers = new List<PUD_Container__c>();
					Boolean isMatchingContainerFound = false;

					if(jobVsExistingContainersMap.containsKey(currentJob.Id)){
						jobContainers = jobVsExistingContainersMap.get(currentJob.Id);
					}
					
					for(PUD_Container__c currentContainer : jobContainers){

						//if type and condition is same then copy updated fields in existing records.
						if( (newRecord.Type__c == currentContainer.Type__c  && newRecord.Condition__c == currentContainer.Condition__c ) || (oldRecordsMap != null && 
											oldRecordsMap.get(newRecord.Id).Type__c == currentContainer.Type__c && 
											oldRecordsMap.get(newRecord.Id).Condition__c == currentContainer.Condition__c)){
							isMatchingContainerFound = true;
							
							currentContainer.Type__c = newRecord.Type__c;
							currentContainer.Actual_Quantity__c = newRecord.Actual_Quantity__c;
							currentContainer.Expected_Quantity__c = newRecord.Expected_Quantity__c;
							currentContainer.Condition__c = newRecord.Condition__c;
							
							containersToUpdate.add(currentContainer);
							
							//container payload has value as per old type.
							//update container payload value with new and updated type and condition.
							
							for(ContainerPayload cPayload : existingContainerPayloadList){

								if(cPayload.Name == oldRecordsMap.get(newRecord.Id).Type__c && 
									cPayload.Condition == oldRecordsMap.get(newRecord.Id).Condition__c){

									cPayload.Name = newRecord.Type__c;
									cPayload.Condition = newRecord.Condition__c;
									cPayload.Quantity = newRecord.Expected_Quantity__c;
								}
							}
						}
					}

					//update job
					if(isMatchingContainerFound && !existingContainerPayloadList.isEmpty()){
						PUD_Job__c jobToUpdate = new PUD_Job__c();
						jobToUpdate.Id = currentJob.Id;
						jobToUpdate.Containers_Payload__c = JSON.serialize(existingContainerPayloadList, true);
						jobsToBeUpdated.add(jobToUpdate);
					}
					

					//if container does not exists against a job, then add a container against a job.
					//Also, update the job's container_payload__c for newly added container
					if(!isMatchingContainerFound){
						PUD_Container__c newContainer = new PUD_Container__c();
						newContainer.Type__c = newRecord.Type__c;
						newContainer.Job__c = currentJob.Id;
						newContainer.Booking__c = newRecord.Booking__c;
						newContainer.Actual_Quantity__c = newRecord.Actual_Quantity__c;
						newContainer.Expected_Quantity__c = newRecord.Expected_Quantity__c;
						newContainer.Condition__c = newRecord.Condition__c;
						newContainer.RecordTypeId = jobContainerRecordTypeId;

						containersToCreate.add(newContainer);
						

						PUD_Job__c jobToUpdate = new PUD_Job__c();
						jobToUpdate.Id = currentJob.Id;

						//if this is first containers then set payload 
						if(currentJob.Containers_Payload__c == null){
							jobToUpdate.Containers_Payload__c = JSON.serialize(new List<ContainerPayload>
								{ new ContainerPayload(newRecord.Type__c, newRecord.Expected_Quantity__c, newRecord.Condition__c)}, true);
						}
						//if payload exists then update existing payload with newly added container
						else{
							List<ContainerPayload> payloadList = (List<ContainerPayload>) JSON.deserialize(currentJob.Containers_Payload__c, List<ContainerPayload>.class);
							payloadList.add(new ContainerPayload(newRecord.Type__c, newRecord.Expected_Quantity__c, newRecord.Condition__c));

							jobToUpdate.Containers_Payload__c = JSON.serialize(payloadList, true);
						}

						jobsToBeUpdated.add(jobToUpdate);
					}
				}

				}
			}
		}
		else if(isDelete){
			deleteJobContainers (records, containers, bookingVsJobsMap);
		}

		if(!containersToCreate.isEmpty()){
			insert containersToCreate;
		}
		if(!containersToUpdate.isEmpty()){
			update containersToUpdate;
		}
		if(!jobsToBeUpdated.isEmpty()){
			update jobsToBeUpdated;
		}
	 }


	

	/**
	* The class stores container related information such as Name, Quantity and Condition.
	* The classed is used to be serialised into a list in JSON format and value to be populated to the Containers Payload Long Text field.
	* Containers Payload will then send out to TIBCO, and then dispatch system
	*/
	@TestVisible private class ContainerPayload{
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
	}

	/**
	 * Mapping for a container type. Each container type has an empty and full quantity captured on PUD_Job__c
	 */
	private class ContainerTypeMapping {
		String name;
		SObjectField emptyQuantityField;
		SObjectField fullQuantityField;

		ContainerTypeMapping(String name, SObjectField emptyQuantityField, SObjectField fullQuantityField) {
			this.name = name;
			this.emptyQuantityField = emptyQuantityField;
			this.fullQuantityField = fullQuantityField;
		}
	}


	private class JobsAndContainers {
		List<PUD_Job__c> newJobs;
		Map<String, List<PUD_Container__c>> jobUniqueKeyVsNewContainers;
		
		JobsAndContainers(List<PUD_Job__c> newJobs, Map<String, List<PUD_Container__c>>  jobUniqueKeyVsNewContainers){
			this.newJobs = newJobs;
			this.jobUniqueKeyVsNewContainers = jobUniqueKeyVsNewContainers;
		}


	}
}