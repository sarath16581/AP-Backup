/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Trigger on FeedItem Object to call the Handler class to perform necessary action
  */
trigger FeedItemTrigger on FeedItem(before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete){    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(FeedItem.sObjectType))){     // verify if triggers are disabled
        FeedItemTriggerHandler.execute();  // FeedItem handler dispatches appropriate event
    }
                                        
                                        //if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
                                           // cpFeedItemHandler.caseStatusUpdater(trigger.new);
                                       // }
}