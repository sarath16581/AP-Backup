/**************************************************
Provides test coverage to OPCBatchableSchedulable class
History:
--------------------------------------------------

31/08/2023 KMcGuire created
**************************************************/
@isTest
private class OPCBatchableSchedulable_Test {
	@isTest
	private static void testOPCBatchableSchedulable() {
		
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
		Id jobId = system.schedule('OPCBatchableSchedulable', schedule, ops);
		test.stopTest();
		system.assert(jobId != null);
	}
}