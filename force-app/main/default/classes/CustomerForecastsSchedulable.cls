@istest
global with sharing class CustomerForecastsSchedulable implements Schedulable {

    global void execute(SchedulableContext sc) {
        CustomerQuarterlyForecasts genBARBYM = new CustomerQuarterlyForecasts();
        //Database.executeBatch(genBARBYM);
        // Make the batch size 1000
        Database.executeBatch(genBARBYM, 100);
    }  
    private static testMethod void testCustomerForecastsSchedulable() {
        
        //Abort jobs to allow for test class to set the schedule
        //list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        
        // 26 November 2015 (christopher.henschke@auspost.com.au) updated SOQL to include CronJobDetail.JobType and stop test class from failing
		// using scheduled apex (jobtype 7) and batch job (jobtype 9)
		list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where state!='DELETED' AND (CronJobDetail.JobType = '7' OR CronJobDetail.JobType = '9')]);
		
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        test.startTest();
        CustomerForecastsSchedulable brs = new CustomerForecastsSchedulable();
        String schedule = '0 0 23 * * ?';
        system.schedule('CustomerForecastsSchedulable1', schedule, brs);
        test.stopTest();
    } 
}