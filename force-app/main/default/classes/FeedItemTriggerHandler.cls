/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Handler Class for FeedItem object trigger which includes context-specific methods 
                    that are automatically called when a trigger is executed.

  * 20.08.20 ajudd@salesforce.com     Added call to TDF_UpdateServiceAppointmentOnMessage in afterHander method
  */
public with sharing class FeedItemTriggerHandler{
    
    // Variables
    private static FeedItemTriggerHelper helper;    // Helper class variable to call methods based on scenario
    
    /**
      * @description       This method is invoked from trigger which in-turn calls the handlers
                           for before and after event.
      * @param             NA 
      * @return            Void
      * @throws            NA
      */        
    public static void execute(){
        helper = new FeedItemTriggerHelper();   // instance of helper class for Contact trigger
        
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
            helper.verifyAccess(Trigger.new);    // verify if user is authorized to post                
        }
        else if(Trigger.isUpdate){
            // Methods to be invoked for before update event
        }
        else if(Trigger.isDelete){
            // Methods to be invoked for before update event
            // RSolomon - check if User can delete Chatter Posts
            if (!DisableChatterDeleteDelegate.allowDelete()) {                
                for(FeedItem f:(List<FeedItem>)Trigger.old){
                    if (((String)f.parentId).startsWith('00Q') && f.type == 'TrackedChange') {
                        // ok to ignore
                    }
                    else {
                        f.addError(DisableChatterDeleteDelegate.ChatterDeleteErrorMsg()); 
                   }
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
             //  Exclude SF Automated processing user to workaround Salesforce issue around when User methods are run as System Users
            if (userinfo.getUserType() != 'AutomatedProcess') {
                StarTrackTaskHandler.updateTaskUpdateField((List<FeedItem>)Trigger.new);

                //TDF Enhance 20.08.2020: Add call to process posts on Work Orders
               // TDF_UpdateServiceAppointmentOnMessage.updateOnPost((List<FeedItem>)Trigger.new);
            }
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