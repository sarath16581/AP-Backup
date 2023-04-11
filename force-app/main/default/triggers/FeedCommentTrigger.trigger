/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Trigger on FeedComment  Object to call the Handler class to perform necessary action
  */
trigger FeedCommentTrigger on FeedComment(before insert,before update,before delete,
                                            after insert,after update,after delete,after undelete){    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(FeedComment.sObjectType))){      // verify if triggers are disabled
        FeedCommentTriggerHandler.execute();  // FeedComment  handler dispatches appropriate event
    }
                                                
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        cpFeedCommentHandler commentHandler = new cpFeedCommentHandler();
    	commentHandler.updateCaseStatus(trigger.new);
    }
}