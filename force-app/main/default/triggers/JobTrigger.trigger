/**
* Date            Version          Owner               Desription
* 10-Apr-19       1.0              Anshul Goyal        This is the trigger for the the custom object "Job__c"
*/

trigger JobTrigger on Job__c (before insert, before update) {

    if (trigger.isbefore){
        if (trigger.isUpdate){
            JobTriggerHandler.beforeUpdateTriggerHandler(Trigger.oldMap, Trigger.new);
        }
    }

}