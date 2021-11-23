/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-01
* @domain Field Service 
* @description Queueable Class to call generate work
*                  Called from TDF_GenerateWorkScheduler
*
* @changelog 
* 2020-08-01 - Andrew Judd - Created 
*/
public class TDF_GenerateWorkQueueable implements Queueable {
    
    Date startDate;
    Date endDate;
    String jobBoardTemplateId;
    String jobTemplateId;
    
    public TDF_GenerateWorkQueueable(Date startDate, Date endDate, String jobBoardTemplateId, String jobTemplateId){
        
        this.startDate = startDate;
        this.endDate = endDate;
        this.jobBoardTemplateId = jobBoardTemplateId;
        this.jobTemplateId = jobTemplateId;
    }
    
    public void execute(QueueableContext context) {
        
        TDF_GenerateWork tdfGW = new TDF_GenerateWork();
        
        //Declare savepoint
        Savepoint sp = Database.setSavepoint();
        try{
            //Call Generate Work function for duty
            tdfGW.createJobs(startDate, endDate, jobBoardTemplateId, jobTemplateId);
        }
        catch(Exception exp) {
            //Rollback transaction
            Database.rollback(sp);
            //Log error to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'TDF', 'TDF_GenerateWorkQueueable', 'execute', 'TDF_GenerateWorkScheduler: DTId = ' + jobBoardTemplateId, LoggingLevel.ERROR);
            System.debug('ERROR Logged');
        }
    }    
}