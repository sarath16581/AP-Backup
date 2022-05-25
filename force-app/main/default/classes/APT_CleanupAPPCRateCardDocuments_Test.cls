@IsTest
public class APT_CleanupAPPCRateCardDocuments_Test {

   	@IsTest
    static void testScheduler()
    {
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2023';
        Id jobId = System.schedule('test Scheduler', CRON_EXP, new APT_CleanupAPPCRateCardDocuments());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }
}