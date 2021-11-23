/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Helper Class for FeedCommentTrigge
  */
public with sharing class FeedCommentTriggerHelper{
    
    /**
      * @description       This method is invoked from FeedCommentTriggerHandler to
                           verify if user is authorized to post to chatter group
      * @param             recList - List<SObject> 
      * @return            Void
      * @throws            Method might throw exception which is handled by verifyAccess 
                           method of FeedItemTriggerHelper
      */    
    public void verifyAccess(List<SObject> recList){
        // invoke verifyAccess method from FeedItemTriggerHandler to check user access
        new FeedItemTriggerHelper().verifyAccess(recList);
    }
}