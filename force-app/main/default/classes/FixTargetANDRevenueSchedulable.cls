/*Created By: Haider Raza*/
/*Created On: 02/08/2013*/
/*Purpose: Schedule class to be executed in order to update the Current Year field on Target and Revenue.*/

@isTest
global with sharing class FixTargetANDRevenueSchedulable implements Schedulable {

    global void execute(SchedulableContext sc) {
        batchClassFixTargetANDRevenue fixTNR = new batchClassFixTargetANDRevenue();
        Database.executeBatch(fixTNR);
        // Make the batch size 1000
        Database.executeBatch(fixTNR, 1000);
    }
    
    private static testMethod void testFixTargetANDRevenueSchedulable() {
        
        //Abort jobs to allow for test class to set the schedule
        //list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        
        // 26 November 2015 (christopher.henschke@auspost.com.au) updated SOQL to include CronJobDetail.JobType and stop test class from failing
		// using scheduled apex (jobtype 7) and batch job (jobtype 9)
		list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where state!='DELETED' AND (CronJobDetail.JobType = '7' OR CronJobDetail.JobType = '9')]);
		
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        test.startTest();
        FixTargetANDRevenueSchedulable tnr = new FixTargetANDRevenueSchedulable ();
        String schedule = '0 0 23 * * ?';
        system.schedule('FixTargetANDRevenueSchedulable', schedule, tnr);
        
        Account a=new Account();
        a.Name='test';
        
        insert a;
        
        Budget_and_Revenue__c br=new Budget_and_Revenue__c();
        br.Organisation__c=a.Id;
        br.Name='test';
        br.Financial_Year__c='2013';
        br.Current_Year__c=true;
        
        insert br;
        
        br.Current_Year__c=true;
        
        update br;
        
        test.stopTest();
    }  
}