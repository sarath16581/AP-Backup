/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-06-23
* @domain Field Service 
* @description Handle changes to Job Templates
*
* @changelog 
* 2020-06-23 - Andrew Judd - Added call to TDF_JobTemplateTriggerHandler.updateTasks to update the Duty Template lookup on child Task Templates
*                               if the Duty Template against the Job Template is changed
* 2020-06-24 - Andrew Judd - Added call to TDF_JobTemplateTriggerHandler.deleteTasks to delete Task Templates if a Job Template is deleted and 
*                               it is the last Job Template parent
* 2020-09-09 - Andrew Judd - Refactored to use JobTemplateTriggerHandler
*/
trigger Job_Template_Trigger on Job_Template__c (before update, before delete) {

    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Job_Template__c.sObjectType))){     // verify if triggers are disabled
        JobTemplateTriggerHandler.execute();  // Handler dispatches appropriate event
    }
}