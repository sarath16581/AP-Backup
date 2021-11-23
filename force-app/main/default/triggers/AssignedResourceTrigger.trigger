/**
 * @author Andrew Judd ajudd@salesforce.com
 * @date 2020-09-21
 * @domain Field Service
 * @description Handle changes to Assigned Resource
 *                Created to replace TDF_SetServiceAppointmentPrimarySR using trigger handler contruct
 *
 * @changelog
 * 2021-10-12 - Alvin Zhou -  Add the before insert, before update tags
 */
trigger AssignedResourceTrigger on AssignedResource(
    after insert,
    after update,
    before update,
    before insert
) {
    // Verify if triggers are disabled
    if (!TriggerHelper.isTriggerDisabled(String.valueOf(AssignedResource.sObjectType))) {
        AssignedResourceTriggerHandler.execute(); // Handler dispatches appropriate event
    }
}