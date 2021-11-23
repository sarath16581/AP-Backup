/**
 * @author       : Andrew Judd
 * @date         : 2020-09-09
 * @description  : Handler Class for ServiceResourceTrigger trigger 
 * @changelog
 */
public class ServiceResourceTriggerHandler {
    
    // Variables
    private static TDF_ServiceResourceTriggerHandler tdfServiceResourceTriggerHandler;    // Helper class variable
    /**
      * @description       This method is invoked from trigger which in turn calls the handlers
                           for before and after event.
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    public static void execute() {

        // Bypass trigger execution for future methods
        if(!System.isFuture()) {
            tdfServiceResourceTriggerHandler = new TDF_ServiceResourceTriggerHandler();   // instance of helper class TDF trigger
            // Check trigger event type
            if(Trigger.isBefore) {
                beforeHandler();        // invoke of before handler
            }
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
            tdfServiceResourceTriggerHandler.setExternalName(Trigger.new, null);
            
        } else if(Trigger.isUpdate) {
            // Methods to be invoked for before update event
            tdfServiceResourceTriggerHandler.setExternalName(Trigger.new, (Map<Id,ServiceResource>)Trigger.oldMap);
        }
    } 
}