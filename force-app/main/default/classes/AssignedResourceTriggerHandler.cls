/**
 * @author       : Andrew Judd
 * @date         : 2020-09-09
 * @description  : Handler Class for AssignedResourceTrigger trigger 
 * @changelog
 * 2020-09-22 - Andrew Judd - Removed future check condition
 * 2021-10-12 - Alvin Zhou -  Add the beforeHandler()
 * 2021-10-24 - Alvin Zhou -  Add the skipValidations()
 */
public class AssignedResourceTriggerHandler {

        // Variables
        private static TDF_AssignedResourceTriggerHandler tdfAssignedResourceTriggerHandler;    // Helper class variable
        /**
          * @description       This method is invoked from trigger which in turn calls the handlers
                               for before and after event.
          * @param             NA
          * @return            Void
          * @throws            NA
          */
          public static void execute() {
    
            tdfAssignedResourceTriggerHandler = new TDF_AssignedResourceTriggerHandler();   // instance of helper class TDF trigger
            // Check trigger event type
            if(Trigger.isAfter) {
                afterHandler();        // invoke of before handler
            } else if (Trigger.isBefore) {
                beforeHandler();
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
            if(Trigger.isInsert) {
                // To reassign the service crew if there is any service crew.
                tdfAssignedResourceTriggerHandler.checkServiceCrew(trigger.new);
            } else if(Trigger.isUpdate) {
                // To reassign the service crew if there is any service crew.
                tdfAssignedResourceTriggerHandler.checkServiceCrew(trigger.new, Trigger.oldMap);
            }
        }
        /**
          * @description       This method is handler for before events invoked by execute method.
                               Method invokes the helper class methods based on the scenario.
          * @param             NA
          * @return            Void
          * @throws            NA
          */    
        private static void afterHandler() {
            // Check for type of operation
            if(Trigger.isInsert) { 
                // Methods to be invoked for before insert event 
                tdfAssignedResourceTriggerHandler.setServiceAppointmentPrimarySR(Trigger.new,(Map<Id,AssignedResource>)Trigger.oldMap);
                
            } else if(Trigger.isUpdate) {

                // Methods to be invoked for before update event
                tdfAssignedResourceTriggerHandler.setServiceAppointmentPrimarySR(Trigger.new,(Map<Id,AssignedResource>)Trigger.oldMap);
                // To skip the validations
                tdfAssignedResourceTriggerHandler.skipValidations(trigger.new, Trigger.oldMap);
                
            }
        } 

}