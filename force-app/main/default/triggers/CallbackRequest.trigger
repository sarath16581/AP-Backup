/*
* @author: Rajesh P. (Mav3rik)
* @description: Trigger on Callback Request Object to update Re-execution time when status changes.
* @description: Also 
* @history: 17-APR-2019, Trigger created.
*/
trigger CallbackRequest on Callback_Request__c (before update, after update, before insert) {
    if (Trigger.IsUpdate && Trigger.IsAfter) {
        //.. Validate if case required callback request and create.
        CallbackRequestTriggerHandler.ValidateAndScheduleCallbackRequest(Trigger.New);
        
        //.. create feed item for every changes.
        CallbackRequestTriggerHandler.addFeedItem(Trigger.New);
        
        //.. route callback reminder to Agent if online, otherwise assigne to queue for standard routing.
        CallbackRequestTriggerHandler.routeCallbackReminder(Trigger.Old, Trigger.New);
    }
    
    if(Trigger.IsUpdate && Trigger.IsBefore){ 
        //..Vaidate Due Time within shift hours.
      //  CallbackRequestTriggerHandler.validateDueDateTimeWithShiftHours(Trigger.New);
    }
    
    if(Trigger.IsInsert && Trigger.IsBefore){
        //..Vaidate Due Time within shift hours.
        CallbackRequestTriggerHandler.validateDueDateTimeWithShiftHours(Trigger.New);
    }
}