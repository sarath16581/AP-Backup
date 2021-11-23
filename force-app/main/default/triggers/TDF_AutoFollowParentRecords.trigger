/** 
* @author Gaurav 
* @date 2018-?-?
* @domain Field Service 
* @description 
*
* @changelog 
* 2020-07-01 - Andrew Judd - Commented out code as no longer required.  
*                               Work Order follow was required for push notification messaging, however the new solution does not 
*                               rely on push notifications
* 2020-09-11 - Andrew Judd - Commented out code entirely and trigger deactivated
*/
trigger TDF_AutoFollowParentRecords on AssignedResource (after insert, before delete, after update) {
    //Commented out call to helper as not required
    // if (Trigger.isInsert) {
    //     //TDF_AutoFollowHelper.follow(Trigger.new);
    // } else if (Trigger.isDelete) {
    //     //TDF_AutoFollowHelper.unfollow(Trigger.old);
    // } else if (Trigger.isUpdate) {
    //     //TDF_AutoFollowHelper.updateFollow(Trigger.oldMap, Trigger.new);
    // }
}