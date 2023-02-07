/*****************************************************************************************
@description:   Trigger class for Deal Support Request object
                Provide Email Routing and Email notification upon Submission of Deal Support Request of "Credit Management Request" record type
@author: Seth Heang
History:
-----------------------------------------------------------------------------------------
10/12/2020   	seth.heang@auspost.com.au			                created
02/06/2022      dattaraj.deshmukh@slalom.com     Added a trigger handler framework and created DealSupportRequestTriggerHandler2 class. 
                                                 All future updates to trigger should be done using trigger handler framework.
05/12/2022 ken.mcguire added after update for sharing
*****************************************************************************************/
trigger DealSupportRequestTrigger on Deal_Support_Request__c (before insert, before update, after insert, after update) {
    
    
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