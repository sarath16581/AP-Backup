/**
* Date            Version          Owner               Desription
* 10-Apr-19       1.0              Anshul Goyal        This is the trigger handler class for the trigger "JobTrigger"
*/

public class JobTriggerHandler {

    /* @created by: Anshul Goyal
     * @description This method handles all the before update operations for the trigger on the custom object job__c
     */
    public static void beforeUpdateTriggerHandler(Map <Id, Job__c> oldMap, List <Job__c> newJobList){
        //set of case Ids
        Set <Id> caseIds= new Set <Id>();
        
        for(Job__c job: newJobList){
            if( (job.Case__c!=null) && (job.Job_Type__c=='Special Services') && (job.Status__c=='Allocated') &&(oldMap.get(job.id).status__c=='New') && (!job.is_Allocated__c)){
                caseIds.add(job.Case__c);
                job.is_Allocated__c = true;
                
            }
        }

        //querying the cases related to the jobs
        if(caseIds.size()>0) {
            List <Case> updatedCasesList = new List <Case>();
            for (Case caseRecord : [SELECT Id,status FROM Case WHERE ID IN:caseIds]) {
                caseRecord.status = 'In Progress';
                updatedCasesList.add(caseRecord);
            }

            if (!updatedCasesList.isEmpty()) {
                update updatedCasesList;
            }
         }
    }
}