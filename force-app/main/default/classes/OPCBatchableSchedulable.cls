/**************************************************
*  @Test OPCBatchableSchedulable
Type:       Apex Schedulable Batch Job Class for Generation of Opportunity Product Classification (OPC)
Purpose:    Generates the Opportunity Product Classification (OPC) record from their source revenue schedule(s) and 
            finds any matching actual revenue against it from the current financial year and last financial year
Used By:    
History:
--------------------------------------------------
13.08.2012  M. Isidro (Cloud Sherpas)   Created
04.09.2012  M. Isidro (Cloud Sherpas)   Added test coverage
28/06/2022 KMcGuire	Modified for including related account sales in OPC classification
**************************************************/
@istest
global class OPCBatchableSchedulable implements Schedulable {

    global void execute(SchedulableContext sc) {
        GenerateOPCBatchable genOPC = new GenerateOPCBatchable();
        Database.executeBatch(genOPC);
        //Database.executeBatch(genOPC, 30);
    }
 

    private static testMethod void testOPCBatchableSchedulable() {
        
        //Abort jobs to allow for test class to set the schedule
        //list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        
        // 26 November 2015 (christopher.henschke@auspost.com.au) updated SOQL to include CronJobDetail.JobType and stop test class from failing
		// using scheduled apex (jobtype 7) and batch job (jobtype 9)
		list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where state!='DELETED' AND (CronJobDetail.JobType = '7' OR CronJobDetail.JobType = '9')]);
		
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        test.startTest();
        OPCBatchableSchedulable ops = new OPCBatchableSchedulable();
        String schedule = '0 0 23 * * ?';
        system.schedule('OPCBatchableSchedulable', schedule, ops);
        test.stopTest();
    }        
}