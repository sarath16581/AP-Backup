/**************************************************
Type:       Apex Schedulable Batch Job Class for Opportunity Fixed Term Renewal processing
Purpose:    Executes the OpportunityFixedTermRenewal_Batchable class
Used By:    
History:
--------------------------------------------------
27-Feb-2013 Manu Erwin (Salesforce.com)     ECLM: Phase 3: Created
**************************************************/
@isTest (SeeAllData=TRUE) 
global without sharing class OpportunityFixedTermRenewal_Schedulable implements Schedulable {

    public static Integer BATCH_SIZE = BatchJobSettings__c.getInstance().OFTR_Batch_Size__c.intValue();

    global void execute(SchedulableContext sc) {
        System.assert(BATCH_SIZE != null, 'BATCH_SIZE cannot be null!');
        OpportunityFixedTermRenewal_Batchable oftr = new OpportunityFixedTermRenewal_Batchable(false);
        if(!Test.IsRunningTest()){
        
        Database.executeBatch(oftr, BATCH_SIZE);
        }
    }

    private static void testOpportunityFixedTermRenewal_Schedulable() {
        //Abort jobs to allow for test class to set the schedule
        List<CronTrigger> cron = new List<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }

        Test.startTest();
        OpportunityFixedTermRenewal_Schedulable oftrs = new OpportunityFixedTermRenewal_Schedulable();
        String schedule = '0 0 23 * * ?';
        system.schedule('OpportunityFixedTermRenewal_Schedulable', schedule, oftrs);
        Test.stopTest();
    }
}