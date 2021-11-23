/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Handler Class for FeedComment object trigger which includes context-specific methods 
                    that are automatically called when a trigger is executed.

  * 20.08.20 ajudd@salesforce.com     Added call to TDF_UpdateServiceAppointmentOnMessage in afterHander method
  */
public with sharing class FeedCommentTriggerHandler{
    
    // Variables
    private static FeedCommentTriggerHelper helper;    // Helper class variable to call methods based on scenario
    
    /**
      * @description       This method is invoked from trigger which in-turn calls the handlers
                           for before and after event.
      * @param             NA 
      * @return            Void
      * @throws            NA
      */        
    public static void execute(){
        helper = new FeedCommentTriggerHelper();   // instance of helper class for Contact trigger
        
        // Check for event type of trigger
        if(Trigger.isBefore){
            beforeHandler();        // invoke of before handler
        }
        else if(Trigger.isAfter){
            afterHandler();         // invoke of after handler
        }
    }
    
    /**
      * @description       This method is handler for before events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.                       
      * @param             NA 
      * @return            Void
      * @throws            NA
      */  
    private static void beforeHandler(){
        // Check for type of operation 
        if(Trigger.isInsert){
            // Methods to be invoked for before insert event 
            helper.verifyAccess(Trigger.new);     // verify if user is authorized to post  
        }
        else if(Trigger.isUpdate){
            // Methods to be invoked for before update event
        }
        else if(Trigger.isDelete){
            // Methods to be invoked for before update event
            // RSolomon - check if User can delete Chatter Posts
            if (!DisableChatterDeleteDelegate.allowDelete()) {
                for(FeedComment f:(List<FeedComment>)Trigger.old){
                    f.addError(DisableChatterDeleteDelegate.ChatterDeleteErrorMsg());  
                 }
            }
        }
    }
    
    /**
      * @description       This method is handler for after events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.                          
      * @param             NA 
      * @return            Void
      * @throws            NA
      */  
    private static void afterHandler(){
        // Check for type of operation
        if(Trigger.isInsert){
            // Methods to be invoked for after insert event
            StarTrackTaskHandler.updateTaskUpdateField((List<FeedComment>)Trigger.new);

            //TDF Enhance 20.08.2020: Add call to process comment posts on Work Orders
            TDF_UpdateServiceAppointmentOnMessage.updateOnComment((List<FeedComment>)Trigger.new);

        }
        else if(Trigger.isUpdate){
            // Methods to be invoked for after update event
        }
        else if(Trigger.isDelete){
            // Methods to be invoked for after delete event
        }
        else if(Trigger.isUndelete){
            // Methods to be invoked for after undelete event
        }
    }
}