@isTest
public class SLAforCaseSchedulerTest {
    
    // Dummy CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    @TestSetup
    static void setup(){
      //  TriggerControlService.disableAllTriggers();
        /*** Create Case record records. */
        Case cs = new Case();
       
        cs.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs.Type ='General Enquiry';
        cs.Origin ='Phone';
        cs.ProductCategory__c='Domestic Parcels';
        cs.ProductSubCategory__c ='Cash on Delivery';
        cs.Priority='Low';
        cs.Subject='Testing 5 Days SLA';
        cs.Status=SSSWConstants.CASE_SLA_STATUS;
        cs.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        insert cs;
        
    }
    
    @isTest
    public static void testScheduleJob(){
        
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest',CRON_EXP, new SLAforCaseScheduler());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(SLAforCaseSchedulerTest.CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
        
    }
}