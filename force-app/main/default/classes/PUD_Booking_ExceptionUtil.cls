/**
* @description Util class for hadling the functionality related to Booking Location.
* @changelog
* 2021-08-17 - Arjun Singh - Added a new method to validate related jobs at the time of booking exception creation.
* 2021-11-09 - Mathew Jose - Updated the Validate method to exclude Schedule and Accepted job statuses from throwing Validation errors.
*/
public inherited sharing class PUD_Booking_ExceptionUtil {

	//Method called from PUD_Booking_ExceptionTrigger to refresh jobs associated to changed booking exceptions
	public static void refreshJobs(List<PUD_Booking_Exception__c> bookingExList) {

		Set<Id> bookingIdSet = new Set<Id>(); //Ids of bookings exceptions changed against
		List<PUD_Booking__c> bookingChildList = new List<PUD_Booking__c>();

		//Get all bookings for exceptions
		for (PUD_Booking_Exception__c bookingEx : bookingExList) {
			bookingIdSet.add(bookingEx.Booking__c);
		}

		//Get any child bookings for bookings with exceptions.  This is because parent booking exceptions are dictated to child (delivery) bookings
		bookingChildList = [SELECT Id
							FROM PUD_Booking__c
							WHERE Parent_Booking__c
							IN :bookingIdSet];
		for (PUD_Booking__c booking : bookingChildList) {
			bookingIdSet.add(booking.Id);
		}

		//If bookings to process
		if (bookingIdSet.size() > 0) {
			//If this is being called from a future or batch method, then call createJobs directly
			if (System.IsBatch() == true || System.isFuture() == true) {
				PUDUtility.getInstance().createJobs(bookingIdSet, true);
			}
			//Else call future Util method to refresh jobs for bookings
			else {
				refreshJobsAsync(bookingIdSet);
			}
		}

	}

	@future
	//Async method to update jobs associated bookings
	public static void refreshJobsAsync(Set<Id> bookingIdSet) {
		try {
			PUDUtility.getInstance().createJobs(bookingIdSet, true);
		} catch (Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'Pickup Booking', 'PUD_Booking_ExceptionUtil', 'refreshJobsAsync', 'PUD_Booking_ExceptionTrigger', LoggingLevel.ERROR);
		}
	}

	/**
	 * Validate exception on creation and updating exception details.
	 * Check the status of Jobs for the date range and days selected in the booking exception. If jobs has already been
	 * pushed to dispatch system and status of it is not yet 'Completed', do not allow exception to be added / updated.
	 *
	 * @param bookingExList list of booking exceptions to validate
	 */
	public static void validate(List<PUD_Booking_Exception__c> bookingExList) {

		// parent booking ids where the jobs are to be checked.
		Set<Id> bookingIds = new Set<Id>();

		for (PUD_Booking_Exception__c bookingException : bookingExList) {
			bookingIds.add(bookingException.Booking__c);
		}

		// there could be dependent bookings on the parent booking where the exception has been added.
		// in this scenario the validation should also check the jobs of dependent bookings.

		// get dependent bookings on the parent bookings
		List<PUD_Booking__c> dependentBookings = PUDBookingsSelector.newInstance().selectByParentBookingId(bookingIds);

		// iterate through the dependent bookings and construct a map of dependent booking ids to their parent booking ids.
		// this will be used to determine the list of jobs for dependent bookings that should be checked
		Map<Id, Id> dependentBookingIdsMap = new Map<Id, Id>();

		for (PUD_Booking__c booking : dependentBookings) {
			// add dependent booking ids to the bookingIds.
			bookingIds.add(booking.Id);
			// populate dependent booking id map (key= dependent booking Id, value = parent booking id)
			dependentBookingIdsMap.put(booking.Id, booking.Parent_Booking__c);
		}
		//Validation error criteria is updated such that it is thrown only if Jobs are in 'Completed', 'Failed', 'Cancelled' or 'Cancel' status.
		//If not 'Completed', the code is updated to mark the jobs as 'Cancelled'
		//Previously the validation error was thrown if the Jobs are in any of Schedule, Accepted or Completed statuses
		Set<String> jobStatus = new Set<String>{PUDConstants.PUD_JOB_STATUS_COMPLETED, PUDConstants.PUD_JOB_STATUS_FAILED, PUDConstants.PUD_JOB_STATUS_CANCELLED, PUDConstants.PUD_JOB_STATUS_CANCEL};
		Map<Id, List<PUD_Job__c>> jobsByParentBookingId = selectAllJobsByStatusAndParentBookingIds(bookingIds, dependentBookingIdsMap, jobStatus);

		for (PUD_Booking_Exception__c bookingException : bookingExList) {
			// check if the booking has jobs for the exception date range
			if (jobsByParentBookingId.containsKey(bookingException.Booking__c)) {
				for (PUD_Job__c pudJob : jobsByParentBookingId.get(bookingException.Booking__c)) {

					if (pudJob.Date__c != null && pudJob.Date__c >= bookingException.Start_Date__c && pudJob.Date__c <= bookingException.End_Date__c) {

						// get day of week number for the job date being evaluated (1 = Monday, ..., 7 = Sunday).
						Integer jobDayOfWeek = Integer.valueOf(((Datetime) pudJob.Date__c).format('u'));

						// check if applicable day checkbox is checked for exception day
						if ((bookingException.Monday__c && jobDayOfWeek == 1) ||
								(bookingException.Tuesday__c && jobDayOfWeek == 2) ||
								(bookingException.Wednesday__c && jobDayOfWeek == 3) ||
								(bookingException.Thursday__c && jobDayOfWeek == 4) ||
								(bookingException.Friday__c && jobDayOfWeek == 5) ||
								(bookingException.Saturday__c && jobDayOfWeek == 6) ||
								(bookingException.Sunday__c && jobDayOfWeek == 7)) {

							bookingException.addError(String.format(Label.PUDJobsAlreadyPushedToDispatchSystemErrorMessage, new List<String>{pudJob.Status__c}));
							break;
						}
					}
				}
			}
		}
	}

	/**
	 * Retrieve a map of Jobs indexed by their booking id. When the job is for a dependent booking, then
	 * parent booking id of the dependent booking is used.
	 *
	 * @param bookingIds booking ids to query for the jobs
	 * @param dependentBookingIdsMap map of dependent booking ids to their parent booking id
	 * @param jobStatus set of relevant statuses to filter the jobs by
	 *
	 * @return map of Jobs indexed by their parent booking id.
	 */
	private static Map<Id, List<PUD_Job__c>> selectAllJobsByStatusAndParentBookingIds(Set<Id> bookingIds, Map<Id, Id> dependentBookingIdsMap, Set<String> jobStatus) {

		// get future dated schedule/scheduled/dispatched jobs
		List<PUD_Job__c> jobs = PUDJobsSelector.newInstance().selectByBookingIdStatusAndFromDate(bookingIds, Date.today(), jobStatus);

		Map<Id, List<PUD_Job__c>> jobsByParentBookingId = new Map<Id, List<PUD_Job__c>>();
		for (PUD_Job__c pudJob : jobs) {
			Id relevantBookingId = pudJob.Booking__c;
			// if the booking is a dependent booking, then get the parent booking id as the exception details are
			// propagated from that.
			if (dependentBookingIdsMap.containsKey(relevantBookingId)) {
				relevantBookingId = dependentBookingIdsMap.get(relevantBookingId);
			}

			if (!jobsByParentBookingId.containsKey(relevantBookingId)) {
				jobsByParentBookingId.put(relevantBookingId, new List<PUD_Job__c>());
			}
			jobsByParentBookingId.get(relevantBookingId).add(pudJob);
		}

		return jobsByParentBookingId;
	}
}