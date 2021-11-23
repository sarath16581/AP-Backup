/**************************************************
Type:       Apex Schedulable Batch Job Class for Budget and Revenue Object
Purpose:    Creates a summary of Billed Revenue and Budget data coming into Salesforce from a legacy system
Used By:    
History:
--------------------------------------------------
17.08.2012  M. Isidro (Cloud Sherpas)   Created
04.09.2012  M. Isidro (Cloud Sherpas)   Added test coverage
**************************************************/
@istest
global with sharing class BudgetRevenueSchedulable implements Schedulable {

    global void execute(SchedulableContext sc) {
        BudgetRevenueBatchable genBARBYM = new BudgetRevenueBatchable();
        //Database.executeBatch(genBARBYM);
        // Make the batch size 1000
        Database.executeBatch(genBARBYM, 1000);
    }
    private static testMethod void testBudgetRevenueSchedulable() {
        
        //Abort jobs to allow for test class to set the schedule
        //list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
		
		// 25 November 2015 (christopher.henschke@auspost.com.au) updated SOQL to include CronJobDetail.JobType and stop test class from failing
		// using scheduled apex (jobtype 7) and batch job (jobtype 9)
		list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where state!='DELETED' AND (CronJobDetail.JobType = '7' OR CronJobDetail.JobType = '9')]);
		
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        test.startTest();
        BudgetRevenueSchedulable brs = new BudgetRevenueSchedulable();
        String schedule = '0 0 23 * * ?';
        system.schedule('BudgetRevenueSchedulable', schedule, brs);
        test.stopTest();
    }  
}