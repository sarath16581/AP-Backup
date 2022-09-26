/**
* @author Rajneewa Silva
* @date 2021-08-10
* @domain PUD
* @description Constants used across classes in PUD domain.
* @changelog
* 2021-08-10 - Ranjeewa Silva - Created.
* 2021-10-13 - Ranjeewa Silva - Added new constant values.
* 2022-03-16 - Ranjeewa Silva - Added new constant PUD_BOOKING_STATUS_ACTIVE.
* 2022-07-08 - Kamil Szyc - Added booking record type names
* 2022-07-26 - Dattaraj Deshmukh - Added Booking and Job container record types.
* 2022-08-17 - Dattaraj Deshmukh - Added new constant PUD_BOOKING_TYPE_MEAL_BREAK
* 2022-09-21 - Ranjeewa Silva - Added new constant for booking status 'Planned'
*/
public inherited sharing class PUDConstants {

	public static final String PICKUP_BOOKING_APP = 'PUD Pickup Booking';

	// PUD Booking status
	public static final String PUD_BOOKING_STATUS_EXPIRED = 'Expired';
	public static final String PUD_BOOKING_STATUS_ACTIVE = 'Active';
	public static final String PUD_BOOKING_STATUS_PLANNED = 'Planned';

	//PUD Booking record types
	public static final String PUD_BOOKING_RECORD_TYPE_AD_HOC_PICKUP_DELIVERY = 'Adhoc Pickup/Delivery';
	public static final String PUD_BOOKING_RECORD_TYPE_PERMANENT_PICKUP_DELIVERY = 'Permanent Pickup/Delivery';

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

	//list of fields referenced in job print controllers
	public static final Map<SObjectType,Set<SObjectField>> PUD_JOB_PRINT_FIELDS = new Map<SObjectType,Set<SObjectField>>{
			PUD_Job__c.getSObjectType() => new Set<SObjectField> {PUD_Job__c.Start_Time__c, PUD_Job__c.Location_Information__c, PUD_Job__c.Booking_Type_Fx__c, PUD_Job__c.Booking_Comments__c,
					PUD_Job__c.Deliver_Product__c, PUD_Job__c.Key_Number__c},
			PUD_Route__c.getSObjectType() => new Set <SObjectField>{
					PUD_Route__c.Name, PUD_Route__c.Depot__c,
					PUD_Route__c.Monday__c, PUD_Route__c.Tuesday__c, PUD_Route__c.Wednesday__c, PUD_Route__c.Thursday__c, PUD_Route__c.Friday__c,
					PUD_Route__c.Saturday__c, PUD_Route__c.Sunday__c, PUD_Route__c.Overtime_Allowance__c,
					PUD_Route__c.Start_Time__c, PUD_Route__c.End_Time__c, PUD_Route__c.Start_Date__c, PUD_Route__c.End_Date__c}
	};
	//Booking Container Record Type
	public static final String PUD_BOOKING_CONTAINER_RECORD_TYPE = 'Booking_Container';

	//Booking Container Record Type
	public static final String PUD_JOB_CONTAINER_RECORD_TYPE = 'Job_Container';

}