/**************************************************
Type:       Class for executing Batch Jobs 
Purpose:    
History:
--------------------------------------------------
06.09.2012    M. Isidro (Cloud Sherpas)         Created
28-Feb-2013 Manu Erwin (Salesforce.com)         ECLM - Updated in Phase 3 for Opportunity Fixed Term Renewal (OFTR) batch functionality
28-Feb-2013 Manu Erwin (Salesforce.com)         ECLM - Update API version to 27.0
01-Mar-2013 Manu Erwin (Salesforce.com)         ECLM - Updated in Phase 3 for Opportunity Open Ended Review (OOER) batch functionality
12-Sep-2013 Clinton McIntyre (Salesforce.com)   OPC Rebuild - Added OPC Validation Batch
**************************************************/
@isTest (SeeAllData=TRUE) 
public with sharing class RunBatchJobs {

    public PageReference executeOPCBatchableSchedulable() {
        ExecuteGenerateOPCBatch.execGenerateOPCBatch();
        return null;
    }   
    
    public PageReference executeBudgetRevenueBatchable() {
        ExecuteBudgetRevenueBatch.execBudgetRevenueBatch();
        return null;
    }
    
    public PageReference executeSegmentationChangeRequest() {
        ExecuteSegmentationChangeRequestBatch.execSegmentationChangeRequest();
        return null;    
    }
    
    public PageReference scheduleOpportunityFixedTermRenewal() {
        OpportunityFixedTermRenewal_Schedule.scheduleOFTR();
        return null;    
    }
    
    public PageReference scheduleOpportunityOpenEndedReview() {
        OpportunityOpenEndedReview_Schedule.scheduleOOER();
        return null;
    }
    
    public PageReference scheduleOPCValidationService() {
        OPCValidationService_Schedule.scheduleOPCValidation();
        return null;
    }
        
    private static void testRunBatchJobs() {
        //Abort jobs to allow for test class to set the schedule
        list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        RunBatchJobs rbj = new RunBatchJobs();
        rbj.executeOPCBatchableSchedulable();
        rbj.executeBudgetRevenueBatchable();
        rbj.executeSegmentationChangeRequest();
        rbj.scheduleOpportunityFixedTermRenewal();
        rbj.scheduleOpportunityOpenEndedReview();
    }       
}