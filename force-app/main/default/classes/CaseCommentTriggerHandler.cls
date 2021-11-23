/**************************************************
Description:    Handler Class for CaseComment object trigger which includes context-specific methods
                    that are automatically called when a trigger is executed.
History:
--------------------------------------------------
21/02/2016  nandan.narasappa@auspost.com.au  Created
2018-06-16  Disha.Kariya@auspost.com.au  Removed NPS check on Case comment after insert.
2018-12-01  John.Mapanao@auspost.com.au  Added CaseActivity__c integration for first response SLA reporting
2018-12-12  ramtej.juloori@auspost.com.au  Added call to method to send email notification on case comment insert/update.
**************************************************/
public with sharing class CaseCommentTriggerHandler{
    
    // Variables
    private static CaseCommentTriggerHelper helper;    // Helper class variable to call methods based on scenario
    
    /**
      * @description       This method is invoked from trigger which in-turn calls the handlers
                           for before and after event.
      * @param             NA 
      * @return            Void
      * @throws            NA
      */        
    public static void execute(){
        helper = new CaseCommentTriggerHelper();   // instance of helper class for Case trigger

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
        }
        else if(Trigger.isUpdate){
            // Methods to be invoked for before update event

        }
        else if(Trigger.isDelete){
            // Methods to be invoked for before update event
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
            helper.completeFirstCustomerResponse((Map<Id,CaseComment>)Trigger.newMap);  // completes first customer response milestone

            // create CaseActivity__c record for SLA first response Reporting
            SLAReportingUtility.generateCaseActivity((List<CaseComment>)Trigger.new);
            //Below code is added on 10/12/2018 to send email notification on case comment insert.
            //Method to send email notification on case comment creation.
            helper.sendCaseCommentsNotification((Map<Id,CaseComment>)Trigger.newMap);
        } else if(Trigger.isUpdate) {
            // Methods to be invoked for after update event
            //Below code is added on 10/12/2018 to send email notification on case comment update.
            //Method to send email notification on case comment update.
            helper.sendCaseCommentsNotification((Map<Id,CaseComment>)Trigger.newMap);
        } else if(Trigger.isDelete) {
            // Methods to be invoked for after delete event
        } else if(Trigger.isUndelete) {
            // Methods to be invoked for after undelete event
        }
    }
}