/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 21/02/2016
  * @description  : Trigger on CaseComment Object to call the Handler class to perform necessary action
  */
trigger CaseCommentTrigger on CaseComment(before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete){    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(CaseComment.sObjectType))){     // verify if triggers are disabled
        CaseCommentTriggerHandler.execute();  // CaseComment handler dispatches appropriate event
    }
}