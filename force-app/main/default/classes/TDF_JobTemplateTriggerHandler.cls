/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-06-23
* @domain Field Service  
* @description Handler to process changes to Job Templates detected in Job_Template_Trigger
*
* @changelog 
* 2020-06-23 - Andrew Judd - Added updateTasks method to update the Duty Template lookup on child Task Templates
*                               if the Duty Template against the Job Template is changed
* 2020-06-24 - Andrew Judd - Added deleteTasks method to delete Task Templates if a Job Template is deleted and it is the last Job Template
*                               parent
* 2020-09-09 - Andrew Judd - Refactored based on implmentation of JobTemplateTriggerHandler
*/
public with sharing class TDF_JobTemplateTriggerHandler {

    //Initialise store set of Ids processed in the transation
    Public static Set<Id> jobTempIdProcessedSet = new Set<Id>();

    //Method on update of JT Duty Template Id, to update the Duty Template Id on tasks to the new duty and dereference jobs in the old duty
    //-Note that not all can be processed as async as the DTID field is used in a lookup filter for the CF and DT lookups
    public void updateTasks(List<Job_Template__c> jobTempList,Map<Id,Job_Template__c> oldMap){

        Map<Id,Id> jobTempIdToDutyIdMap = new Map<Id,Id>();

        //For each updated job template record
        for(Job_Template__c jobTemplate : jobTempList){

            //If the Duty Id is updated
            if(oldMap.get(jobTemplate.Id).Route_Template__c != jobTemplate.Route_Template__c){
                
                //If job template has not been processed in this transaction
                if(jobTempIdProcessedSet.contains(jobTemplate.Id) == false){

                    //Then add to the map
                    jobTempIdToDutyIdMap.put(jobTemplate.Id,jobTemplate.Route_Template__c);

                    //Add processed Ids to the set
                    jobTempIdProcessedSet.add(jobTemplate.Id);
                }
            }
        }
        
        //If any Jobs have had their Duty Template updated
        if(jobTempIdToDutyIdMap.size() > 0){
            
            //Then update related Task Templates
            List<Task_Template__c> taskTempList = new List<Task_Template__c>();
        
            //Get all tasks relating to job templates with updated duties
            taskTempList = [SELECT Id,  DTID__c, Collect_From_Job_Template__c, Deliver_To_Job_Template__c FROM Task_Template__c 
                            WHERE (Collect_From_Job_Template__c = :jobTempIdToDutyIdMap.keySet() OR Deliver_To_Job_Template__c = :jobTempIdToDutyIdMap.keySet())];
            
            //For each task
            for(Task_Template__c tt : taskTempList){
                //If the task Collect From JT is changing duty
                if(jobTempIdToDutyIdMap.get(tt.Collect_From_Job_Template__c) != null){
                    //Update duty template id to new value
                    tt.DTID__c = jobTempIdToDutyIdMap.get(tt.Collect_From_Job_Template__c);
                    //Clear deliver to job template (i.e. dereference the jt in the old duty)
                    tt.Deliver_To_Job_Template__c = null;
                }
                //Else the task Deliver To is a JT with changing duty
                else{
                    //Update duty template id to new value
                    tt.DTID__c = jobTempIdToDutyIdMap.get(tt.Deliver_To_Job_Template__c);
                    //Clear collect from job template (i.e. dereference the jt in the old duty)
                    tt.Collect_From_Job_Template__c = null;
                }
            }
            
            //Update tasks
            update taskTempList;
        }
    }

    //Method to delete Task Templates if a Job Template is deleted and it is the last Job Template parent
    public void deleteTasks(Map<Id,Job_Template__c> oldMap){

        Set<Id> jobTempIdSet = oldMap.keySet();

        List<Task_Template__c> taskTempList = new List<Task_Template__c>();
        
        //Get all tasks relating to job templates
        taskTempList = [SELECT Id FROM Task_Template__c 
                        WHERE ( (Collect_From_Job_Template__c = :jobTempIdSet) 
                        OR      (Deliver_To_Job_Template__c = :jobTempIdSet))];
        
        if(taskTempList.size() > 0){
        
            //Delete tasks
            delete taskTempList;
        }
    } 
}