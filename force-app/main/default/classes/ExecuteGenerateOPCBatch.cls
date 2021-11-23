/**************************************************
Type:       Class for executing Batch Job for OPC 
Purpose:    
History:
--------------------------------------------------
27.07.2012    M. Isidro (Cloud Sherpas)         Created
**************************************************/
@istest
public class ExecuteGenerateOPCBatch {
    public static void execGenerateOPCBatch() {
        String sYear = BatchJobSettings__c.getInstance().OPC_Optional_Year__c;  
        if (sYear == null) sYear = '*';
        String sMonth = BatchJobSettings__c.getInstance().OPC_Month__c;
        if (sMonth == null) sMonth = '*';
        String sDay = BatchJobSettings__c.getInstance().OPC_Day_Of_Month__c;
        if (sDay == null) sDay = '*';
        String sHour = BatchJobSettings__c.getInstance().OPC_Hours__c;
        if (sHour == null) sHour = '*';
        String sMinute = BatchJobSettings__c.getInstance().OPC_Minutes__c;
        if (sMinute == null) sMinute = '0';
        String sSecond = BatchJobSettings__c.getInstance().OPC_Seconds__c;
        if (sSecond == null) sSecond = '0';
        String sDayOfWeek = BatchJobSettings__c.getInstance().OPC_Day_Of_Week__c;
        if (sDayOfWeek == null) sDayOfWeek = '?';
        
        OPCBatchableSchedulable gob = new OPCBatchableSchedulable();
        //String sch = '0 3 19 26 7 ?';
        String sched = sSecond + ' ' + sMinute + ' ' + sHour + ' ' + sDay + ' ' + sMonth + ' ' + sDayOfWeek + '' + sYear;
        system.debug('***sched: ' + sched);
        system.schedule('OPCBatchableSchedulable', sched, gob);     
    }
    private static testMethod void testExecuteGenerateOPCBatch() {
        
        //Abort jobs to allow for test class to set the schedule
        //list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        
        // 26 November 2015 (christopher.henschke@auspost.com.au) updated SOQL to include CronJobDetail.JobType and stop test class from failing
		// using scheduled apex (jobtype 7) and batch job (jobtype 9)
		list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where state!='DELETED' AND (CronJobDetail.JobType = '7' OR CronJobDetail.JobType = '9')]);
		
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        ExecuteGenerateOPCBatch.execGenerateOPCBatch(); 
    }
}