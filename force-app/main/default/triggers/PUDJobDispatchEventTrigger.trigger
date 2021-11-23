/**
 * @author Ranjeewa Silva
 * @date 2021-08-25
 * @domain PUD
 * @description Trigger subscribing to platform events published by Tibco related to Job dispatch events.
 * @changelog
 * 2021-08-25 - Ranjeewa Silva - Created
 */

trigger PUDJobDispatchEventTrigger on PUD_Job_Dispatch_Event__e (after insert) {
	// delegate to trigger handler
	PUDJobDispatchEventTriggerHandler.execute();
}