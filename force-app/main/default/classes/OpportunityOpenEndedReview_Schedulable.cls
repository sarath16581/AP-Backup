/**************************************************
Type:       Apex Schedulable Batch Job Class for Opportunity Open Ended Review processing
Purpose:    Executes the OpportunityOpenEndedReview_Batchable class
Used By:    
History:
--------------------------------------------------
28-Feb-2013 Manu Erwin (Salesforce.com)     ECLM: Phase 3: Created
18-Dec-2013 CMcIntyre (Salesforce.com)     Resolve daisy chaining batch issue ('No more than one executeBatch can be called')

**************************************************/
@isTest (SeeAllData=True) 
global without sharing class OpportunityOpenEndedReview_Schedulable implements Schedulable {

    public static Integer BATCH_SIZE = BatchJobSettings__c.getInstance().OOER_Batch_Size__c.intValue();

    global void execute(SchedulableContext sc) {
        System.assert(BATCH_SIZE != null, 'BATCH_SIZE cannot be null!');
        OpportunityOpenEndedReview_Batchable batch = new OpportunityOpenEndedReview_Batchable(false);
        if(!Test.IsRunningTest()){  
            Database.executeBatch(batch, BATCH_SIZE);
        }
    }

    private static void testOpportunityOpenEndedReview_Schedulable() {
        //Abort jobs to allow for test class to set the schedule
        list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }

        Test.startTest();
        OpportunityOpenEndedReview_Schedulable schedule = new OpportunityOpenEndedReview_Schedulable();
        String scheduleTiming = '0 0 23 * * ?';
        system.schedule('OpportunityOpenEndedReview_TEST', scheduleTiming, schedule);
        Test.stopTest();
    } 
}