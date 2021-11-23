/**
 * @author       : Andrew Judd
 * @date         : 2020-09-09
 * @description  : Handler Class for Job_Template_Trigger trigger 
 * @changelog
 * 2020-09-22 - Andrew Judd - Removed future check condition
 */
public with sharing class JobTemplateTriggerHandler {
    
    // Variables
    private static TDF_JobTemplateTriggerHandler tdfJobTemplateTriggerHandler;    // Helper class variable
    /**
      * @description       This method is invoked from trigger which in turn calls the handlers
                           for before and after event.
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    public static void execute() {

        tdfJobTemplateTriggerHandler = new TDF_JobTemplateTriggerHandler();   // instance of helper class TDF trigger
        // Check trigger event type
        if(Trigger.isBefore) {
            beforeHandler();        // invoke of before handler
        }
    } 
    /**
      * @description       This method is handler for before events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.
      * @param             NA
      * @return            Void
      * @throws            NA
      */    
    private static void beforeHandler() {
        // Check for type of operation
        if(Trigger.isInsert) { 
            // Methods to be invoked for before insert event 
            
        } else if(Trigger.isUpdate) {
            // Methods to be invoked for before update event
            tdfJobTemplateTriggerHandler.updateTasks(Trigger.new,(Map<Id,Job_Template__c>)Trigger.oldMap);
        }
        else if(Trigger.isDelete) {
            // Methods to be invoked for before delete event
            tdfJobTemplateTriggerHandler.deleteTasks((Map<Id,Job_Template__c>)Trigger.oldMap);
        }
    } 
}