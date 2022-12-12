/**
* @author Rajneewa Silva
* @date 2021-08-10
* @group Controller
* @domain PUD
* @description Controller for PUD Pickup Booking Lightning Application
* @changelog
* 2021-08-10 - Ranjeewa Silva - Created.
* 2022-03-16 - Ranjeewa Silva - Added new methods to support 'Bulk Edit UI'.
* 2022-04-01 - Seth Heang - Added new methods to update job dispatch flag on network and bypass sharing setting
* 2022-04-08 - Ranjeewa Silva - Added methods for retrieving dispatch photo from Digital Repository.
* 2022-08-26 - Dattaraj Deshmukh - Updated 'canCancelJob' and 'canTriggerDispatchSystemSync' method to use date criteria from custom settings from PUDUtility class.
*/
public with sharing class PUDPickupBookingController {

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
	 * Validate the job to see if it is eligible for sending to external dispatch system. If eligible, trigger an
	 * outbound message to dispatch system.
	 *
	 * @param jobId Id of the Job to be sent
	 *
	 * @return Status of triggering the outbound message. Returns an error if the Job is not eligible to be sent to dispatch system.
	 */
	@AuraEnabled
	public static PickupBookingActionResult triggerDispatchSystemSync(Id jobId) {

		try {
			PickupBookingActionResult result = new PickupBookingActionResult();

			List<PUD_Job__c> jobs = PUDJobsSelector.newInstance().selectById(new Set<Id>{jobId});

			if (canTriggerDispatchSystemSync(jobs[0], result)) {

				List<PUD_Job__c> eligibleJobs = PUDUtility.getInstance().setEligibleJobsToTriggerDispatchSystemSync(new List<PUD_Job__c>{jobs[0]});
				if (eligibleJobs.isEmpty()) {
					result.status = Status.ERROR.name();
					result.errorMessage = System.Label.PUDJobDispatchSystemSyncRestrictedDepotErrorMessage;
				} else {
					ApplicationDatabase.getInstance().dmlUpdate(new List<PUD_Job__c>{jobs[0]});
					result.status = Status.SUCCESSFUL.name();
				}
			}

			return result;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Cancel the PUD Job.
	 *
	 * @param jobId Id of the Job to be sent
	 *
	 * @return Status of cancellation. Returns an error if the Job is not eligible to be cancelled.
	 */
	@AuraEnabled
	public static PickupBookingActionResult cancel(Id jobId) {

		try {

			PickupBookingActionResult result = new PickupBookingActionResult();

			List<PUD_Job__c> jobs = PUDJobsSelector.newInstance().selectById(new Set<Id>{jobId});

			// check if the job is allowed to be cancelled
			if (canCancelJob(jobs[0], result)) {
				// job is allowed to be cancelled.
				PUD_Job__c updatableJob = new PUD_Job__c(Id=jobId);
				updatableJob.Status__c = PUDConstants.PUD_JOB_STATUS_CANCEL;
				ApplicationDatabase.getInstance().dmlUpdate(new List<PUD_Job__c>{updatableJob});
				result.status = Status.SUCCESSFUL.name();
			}

			return result;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Runtime config required for Bulk Edit user interface.
	 *
	 * @return runtime config
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> loadBulkEditConfig() {
		return new Map<String, Object>{
				'homeDepotId' => getHomeDepotForCurrentUser()
		};
	}

	/**
	 * Returns the Id of the home depot for currently logged in user. Returns null if home depot is not available OR it
	 * cannot be uniquely identified.
	 *
	 * @return Id of the home depot (Network__c)
	 */
	public static Id getHomeDepotForCurrentUser(){
		try {
			// retrieve the public groups for which, the current user is a member
			Map<Id, GroupMember> groupMemberships = GroupMembersSelector.newInstance().selectByMyGroups(new List<String>(), new Set<Object>{GroupMembersSelector.Options.WITH_GROUP});

			// grab the group names for those public groups
			Set<String> groupNames = new Set<String>();
			for (GroupMember member: groupMemberships.values()) {
				if (member.Group != null && member.Group.Name != null) {
					groupNames.add(member.Group.Name);
				}
			}

			if (!groupNames.isEmpty()) {
				// in PUD project phase 1 home depot is configured via a public group. depot supervisor users are assigned
				// to a public group matching the name of the network record. this only works when public group name matches
				// the network name. this need to be reviewed as network record names can be updated over time.
				List<Network__c> networks = PUDNetworksSelector.newInstance().selectByName(groupNames);

				// if only one network record is returned - we use it as the home depot.
				// we can't accurately determine home depot if there are more than one network records.
				if (networks.size() == 1) {
					return networks[0].Id;
				}
			}

			return null;

		} catch(Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Retrieve depot(Network__c) details for the specified id. All child routes are also returned.
	 *
	 * @param depotId id of the depot(Network__c)
	 *
	 * @return depot record
	 */
	@AuraEnabled
	public static Network__c getDepot(Id depotId) {
		try {
			List<Network__c> networks = PUDNetworksSelector.newInstance().selectById(new Set<Id>{depotId}, new Set<Object>{PUDNetworksSelector.Options.WITH_ROUTES}).values();
			if (!networks.isEmpty()) {
				return networks[0];
			}
			return null;
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Retrieve routes with child bookings for the supplied Ids. Optionally supports passing in a list of booking record type ids
	 * to filter child bookings.
	 *
	 * @param routeIds route ids
	 * @param bookingRecordTypes booking record type ids to filter child bookings returned. Optional.
	 *
	 * @return list of routes with child bookings.
	 */
	@AuraEnabled
	public static List<PUDRoute> getRoutes(List<Id> routeIds, List<Id> bookingRecordTypes) {

		try {

			List<PUDRoute> selectedRoutes = new List<PUDRoute>();

			// retrieve routes with their associated active bookings
			List<PUD_Route__c> routes = PUDRoutesSelector.newInstance().selectByIdWithActiveBookings(new Set<Id>(routeIds), new Set<Id>(bookingRecordTypes), new Set<Object>{
					PUDBookingsSelector.Options.WITH_RECORDTYPE, PUDBookingsSelector.Options.WITH_ROUTE, PUDBookingsSelector.Options.WITH_PARENT_BOOKING
			});

			for (PUD_Route__c route : routes) {
				selectedRoutes.add(new PUDRoute(route));
			}

			return selectedRoutes;

		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Save bookings passed in.
	 *
	 * @param bookings bookings to save
	 */
	@AuraEnabled
	public static void updateBookings(List<PUD_Booking__c> bookings) {
		try {
			// update bookings. note that the feature currently doesn't support partial save.
			ApplicationDatabase.getInstance().dmlUpdate(bookings);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Validate the Job to check if it can be pushed to dispatch system.
	 *
	 * @param job Job instance to check
	 * @param result result to populate error details
	 *
	 * @return true if job can be sent to dispatch system. false otherwise.
	 */
	private static Boolean canTriggerDispatchSystemSync(PUD_Job__c job, PickupBookingActionResult result) {
		
		// only current day and day after jobs are allowed to be sent to dispatch system.
		// throw error if job date range do not fall in between of JOB_DISPATCH_FROM_DATE (today) and JOB_DISPATCH_TO_DATE (tomorrow)
		if (job.Date__c < PUDUtility.JOB_DISPATCH_FROM_DATE || job.Date__c > PUDUtility.JOB_DISPATCH_TO_DATE) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDJobDispatchSystemSyncRestrictedForDateErrorMessage;
			return false;
		}

		// jobs with Stop Credit = true are not allowed to be sent to dispatch system
		if (job.Stop_Credit__c) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDJobDispatchSystemSyncRestrictedForStopCreditJobsErrorMessage;
			return false;
		}

		//TODO - validate status check TBC
		return true;
	}

	/**
	 * Validate the Job to check if it can be cancelled.
	 *
	 * @param job Job instance to check
	 * @param result result to populate error details
	 *
	 * @return true if job can be cancelled. false otherwise.
	 */
	private static Boolean canCancelJob(PUD_Job__c job, PickupBookingActionResult result) {

		// Jobs in past cannot be cancelled.
		if (Date.today() > job.Date__c) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDCannotCancelPastJobsErrorMessage;
			return false;
		}

		// Jobs in 'New' status are not yet sent to dispatch system.
		// Update the booking to cancel such jobs.
		if (job.Status__c == PUDConstants.PUD_JOB_STATUS_NEW) {
			result.status = Status.ERROR.name();
			result.errorMessage = String.format(System.Label.PUDUpdateBookingToCancelNewJobErrorMessage, new List<String>{job.Status__c});
			return false;
		}

		// Only the jobs in 'Schedule' or 'Accepted' status can be cancelled.
		if (job.Status__c != PUDConstants.PUD_JOB_STATUS_SCHEDULE && job.Status__c != PUDConstants.PUD_JOB_STATUS_ACCEPTED) {
			result.status = Status.ERROR.name();
			result.errorMessage = String.format(System.Label.PUDCancelJobsRestrictedStatusErrorMessage, new List<String>{job.Status__c});
			return false;
		}

		return true;
	}

	/**
	 * Asynchronously retrieve photo from digital repository.
	 * @param guidId guid to pass into digital repository to retrieve the image
	 *
	 * @return continuation instance
	 */
	@AuraEnabled(Continuation=true)
	public static Object getDispatchPhoto(String guidId) {
		Continuation con = DigitalRepositoryService.getInstance().getContinuation(guidId + '.JPG', pickupBookingSettings?.Dispatch_Photo_Bucket_Name__c);
		con.continuationMethod = 'dispatchPhotoCallback';
		// Return it to the system for processing
		return con;
	}

	/**
	 * Callback for async callout to digital repository to retrieve dispatch photo. Invoked by the platform on receiving
	 * the response for continuation callout.
	 * @param labels labels associated with the callout request
	 * @param state continuation state
	 *
	 * @return parsed response
	 */
	@AuraEnabled
	public static Object dispatchPhotoCallback(List<String> labels, Object state) {
		HttpResponse resp = Continuation.getResponse(labels[0]);
		String responseBody = resp.getBody();
		System.debug('API RAW REPONSE: ' + responseBody);
		// parse the json
		DigitalRepositoryService.DocumentApiResponse response = DigitalRepositoryService.getInstance().parseResponse(resp);
		System.debug('API PARSED RESPONSE: ' + response);
		return response;
	}

	/**
     * Status of create Case operation.
     */
	public enum Status {
		SUCCESSFUL,
		ERROR
	}

	public class PickupBookingActionResult {
		@AuraEnabled public String status {get; private set;}
		@AuraEnabled public String errorMessage {get; private set;}
	}

	/**
	 * Represents a PUD Route together with it's child bookings.
	 * Used in PUD Bulk Edit UI.
	 */
	public class PUDRoute {
		@AuraEnabled public PUD_Route__c route {get; private set;}
		@AuraEnabled public List<PUDBooking> bookings {get; private set;}
		// start time derived based on the bookings.
		@AuraEnabled public Time startTime {get; private set;}
		// end time derived based on the bookings.
		@AuraEnabled public Time endTime {get; private set;}

		public PUDRoute(PUD_Route__c route) {
			this.route = route;
			this.bookings = new List<PUDBooking>();
			for (PUD_Booking__c booking: route.Bookings__r) {
				addBooking(new PUDBooking(booking));
			}
		}

		/**
		 * Add a child booking to this route.
		 * @param booking PUD Booking
		 */
		public void addBooking(PUDBooking booking) {
			if (booking != null) {
				this.bookings.add(booking);

				Time currentBookingStartTime = booking.getStartTime();
				Time currentBookingEndTime = booking.getEndTime();

				if (this.startTime == null || this.startTime > currentBookingStartTime) {
					this.startTime = currentBookingStartTime;
				}

				if (this.endTime == null || this.endTime < currentBookingEndTime) {
					this.endTime = currentBookingEndTime;
				}
			}
		}
	}

	/**
	 * Represents a PUD Booking. Used in PUD Bulk Edit UI.
	 */
	public class PUDBooking {

		@AuraEnabled public PUD_Booking__c booking;
		@AuraEnabled public List<String> dirtyFields = new List<String>();

		public PUDBooking(PUD_Booking__c booking) {
			this.booking = booking;
		}

		public Time getEndTime() {
			if (this.booking != null && this.booking.Start_Time__c != null) {
				Integer dwellTime = (this.booking.Dwell_Time_Planned__c != null ? Integer.valueOf(this.booking.Dwell_Time_Planned__c): 5);
				return this.booking.Start_Time__c.addMinutes(dwellTime);
			}
			return null;
		}

		public Time getStartTime() {
			return this.booking.Start_Time__c;
		}
	}

	/**
	 * Save the Network record passed in.
	 *
	 * @param network network to save
	 */
	@AuraEnabled
	public static void updateDispatchJobIntegration(Network__c network) {
		try {
			// update networks using without sharing inner class to bypass user's sharing permission on network records
			WithoutSharingDataAccessHelper withoutSharingNetworkUpdate = new WithoutSharingDataAccessHelper();
			withoutSharingNetworkUpdate.updateRecords(new List<Network__c>{network});
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	* Private inner class that elevates access/edit privileges of the current user to edit data without being limited by
	* sharing settings.
	*/
	private without sharing class WithoutSharingDataAccessHelper {

		/**
		 * Update a list of sObject records in system mode
		 * @param List<sObject>
		*/
		private void updateRecords(List<sObject> recordList) {
			try {
				ApplicationDatabase.getInstance().dmlUpdate(recordList);
			} catch (Exception ex) {
				throw new AuraHandledException(ex.getMessage());
			}
		}

	}
}