/*****************************************************************************************
@description:   Trigger class for Deal Support Request object
                Provide Email Routing and Email notification upon Submission of Deal Support Request of "Credit Management Request" record type
@author: Seth Heang
History:
-----------------------------------------------------------------------------------------
10/12/2020   	seth.heang@auspost.com.au			                created

*****************************************************************************************/
trigger DealSupportRequestTrigger on Deal_Support_Request__c (after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            DealSupportRequestTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}