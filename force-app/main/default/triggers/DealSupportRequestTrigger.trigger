/**
 * @description Trigger class for Deal Support Request object
 *              Provide Email Routing and Email notification upon Submission of Deal Support Request of "Credit Management Request" record type
 * @author: Seth Heang
 * @changelog
 * 2020-12-10 - Seth Heang - Created
 * 2022-06-02 - Dattaraj Deshmukh - Added a trigger handler framework and created DealSupportRequestTriggerHandler2 class.
 *                                  All future updates to trigger should be done using trigger handler framework.
 * 2022-12-05 - Ken Mcguire - Added after update for sharing
 * 2023-02-14 - Ranjeewa Silva - Added support for before delete, after delete and after undelete trigger events
 */
trigger DealSupportRequestTrigger on Deal_Support_Request__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    
    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Deal_Support_Request__c.SObjectType))) {
		(new DealSupportRequestTriggerHandler2()).dispatch();
	}
    
 
    // ************************************************* WARNING *************************************************************
    // WARNING: Please do not use the approach below. All new functionalities should be done using the Handler method above. 
    // ************************************************* WARNING *************************************************************



    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            DealSupportRequestTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}