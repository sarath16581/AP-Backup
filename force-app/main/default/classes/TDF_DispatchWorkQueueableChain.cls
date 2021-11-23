/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-01
* @domain Field Service 
* @description Queueable Class to call dispatch work as queueable requests syncronously.
*               This allowS each to be called individually but not in parallel to avoid the UNABLE TO LOCK ROW error that occurs with inserting
*               records that reference Service Territory.  These conflicts appear to be related to the FSL managed package triggers
*               and logic.
* @changelog 
* 2020-08-01 - Andrew Judd - Created 
*/
public class TDF_DispatchWorkQueueableChain implements Queueable {
    
    Set<Id> srIdSet;
    
    public TDF_DispatchWorkQueueableChain(Set<Id> srIdSet){
        this.srIdSet = srIdSet;
    }
    
    public void execute(QueueableContext context) {
        
        String dispatchResultString;
        Id srId;
        
        //If Set contains values
        if(srIdSet.size() > 0){	
        
            //Get an Id from the set
            for(Id sr : srIdSet){
                srId = sr;
            }
            
            //Remove this value from the set for next recursive call
            srIdSet.remove(srId);
            
            try{
                //Call Dispatch Work function for duty
                System.debug('Call Dispatch Work for dutyId ' + srId);
                dispatchResultString = TDF_DispatchWork.dispatch(srId);
                System.debug('Dispatch Work result = ' + dispatchResultString);
                
            }
            catch(Exception exp) {
                //Log error to Exception object for analysis
                UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'TDF', 'TDF_DispatchWorkQueueableChain', 'execute', 'TDF_DispatchWorkScheduler', LoggingLevel.ERROR);
                System.debug('ERROR Logged');
            }
            
            //If there are still more records in the set to process
            if(srIdSet.size() > 0 ){
                //Call class again with the remaining set
                Id dwcJobID = System.enqueueJob(new TDF_DispatchWorkQueueableChain(srIdSet));
            }
        }
    }    
}