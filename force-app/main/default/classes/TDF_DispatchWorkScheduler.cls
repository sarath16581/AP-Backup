/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-01
* @domain Field Service 
* @description Scheduled Class to Dispatch Work (set SA Status to Dispatched) for duties approaching start time
*
* @changelog 
* 2020-08-01 - Andrew Judd - Created 
* 2020.08.11 - Andrew Judd - Added set of Not Resourced flag
* 2020.08.12 - Andrew Judd - Removed set of Not Resourced flag as replaced with Unresourced Duties action
*/
global class TDF_DispatchWorkScheduler implements Schedulable{
    
    global void execute(SchedulableContext SC){

        //Initilisation
        Set<Id> srIdSet = new Set<Id>();
        Datetime currentDateTime  = System.Now();
        Integer DISPATCHMINSFROMNOWSTART = -90;
        Integer DISPATCHMINSFROMNOWEND = 30;

        List<AssignedResource> ffdAssResList = new List<AssignedResource>();

        //# Dispatch Work for today
        //Get all duties commencing within next 30 minutes based on Fit For Duty jobs in Scheduled status
        //Limit to 50 records to avoid Queueable limit
        //Any missed will be processed in next run, however limit is not expected to be reached, based on 1000 duties across 24 hrs -> approx 6 per run each 10 mins. 
        //TODO: Currently only dispatches work assigned to a Crew - review this as may be sensible to dispatch driver assigned work (legacy) - would need to remove check on assignment
        ffdAssResList = [SELECT ServiceResourceId, ServiceResource.Name 
                                                FROM AssignedResource 
                                                WHERE ServiceAppointment.Work_Order__r.RecordType.DeveloperName ='Fit_For_Duty' 
                                                AND ServiceResource.ResourceType = 'C'  
                                                AND ServiceAppointment.Status = 'Scheduled'
                                                AND (ServiceAppointment.SchedStartTime > :currentDateTime.addMinutes(DISPATCHMINSFROMNOWSTART)  
                                                AND ServiceAppointment.SchedStartTime < :currentDateTime.addMinutes(DISPATCHMINSFROMNOWEND)) 
                                                ORDER BY ServiceAppointment.SchedStartTime 
                                                LIMIT 50];

        //Add duty Id to the Set
        for(AssignedResource assRes : ffdAssResList){
            srIdSet.add(assRes.ServiceResourceId);
        }
        
        //If set contains records
        if(srIdSet.size() > 0){
            try{
                //Call queueable job to chain requests for each duty
                System.debug('Call Dispatch Queueable Chain job for duties = ' + srIdSet);
                Id dwcJobID = System.enqueueJob(new TDF_DispatchWorkQueueableChain(srIdSet));
            }
            catch(Exception exp) {
                //Log error to Exception object for analysis
                UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'TDF', 'TDF_DispatchWorkScheduler', 'execute', 'System' , LoggingLevel.ERROR);
                System.debug('ERROR Logged');
            }
        }
    }
}