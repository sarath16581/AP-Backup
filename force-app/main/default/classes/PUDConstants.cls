/**
* @author Rajneewa Silva
* @date 2021-08-10
* @domain PUD
* @description Constants used across classes in PUD domain.
* @changelog
* 2021-08-10 - Ranjeewa Silva - Created.
* 2021-10-13 - Ranjeewa Silva - Added new constant values.
* 2022-03-16 - Ranjeewa Silva - Added new constant PUD_BOOKING_STATUS_ACTIVE.
*/
public inherited sharing class PUDConstants {

	public static final String PICKUP_BOOKING_APP = 'PUD Pickup Booking';

	// PUD Booking status
	public static final String PUD_BOOKING_STATUS_EXPIRED = 'Expired';
	public static final String PUD_BOOKING_STATUS_ACTIVE = 'Active';

	//PUD Booking type
	public static final String PUD_BOOKING_TYPE_MEAL_BREAK = 'Meal Break';

	//PUD Job status
	// jobs are created in 'New' status. they are not yet pushed to dispatch system
	public static final String PUD_JOB_STATUS_NEW = 'New';

	// job has been sent to dispatch system and awaiting confirmation from dispatch system
	public static final String PUD_JOB_STATUS_SCHEDULE = 'Schedule';

	// job has been accepted by the driver (the driver has logged into the scanner and accepted the job).
	public static final String PUD_JOB_STATUS_ACCEPTED = 'Accepted';

	// job has been completed by the driver.
	public static final String PUD_JOB_STATUS_COMPLETED = 'Completed';

	// cancel request has been sent to dispatch system and awaiting confirmation from dispatch system
	public static final String PUD_JOB_STATUS_CANCEL = 'Cancel';

	// job has been cancelled in dispatch system.
	public static final String PUD_JOB_STATUS_CANCELLED = 'Cancelled';

	// driver couldn't complete the job (for example no one at the address)
    public static final String PUD_JOB_STATUS_FAILED = 'Failed';

}