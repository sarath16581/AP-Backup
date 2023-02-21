/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Trigger on FeedItem Object to call the Handler class to perform necessary action
  * @change log:
  *             23/11/2022 - dattaraj.deshmukh@auspost.com.au - Added domain based trigger framework.
  */
trigger FeedItemTrigger on FeedItem(before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete){    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(FeedItem.sObjectType))){     // verify if triggers are disabled
        FeedItemTriggerHandler.execute();  // FeedItem handler dispatches appropriate event

        //calling domain base trigger dispatch
        //All future implementation should use Domain based approach to call trigger handler and its logic.
        (new FeedItemTriggerHandler2()).dispatch();
    }

   
}