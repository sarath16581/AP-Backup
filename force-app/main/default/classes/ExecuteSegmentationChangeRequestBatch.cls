/**************************************************
Type:       Class for executing Batch Job for Segmentation Change Request
Purpose:    
History:
--------------------------------------------------
06.09.2012    M. Isidro (Cloud Sherpas)         Created
**************************************************/
@isTest
public with sharing class ExecuteSegmentationChangeRequestBatch {
    public static void execSegmentationChangeRequest() {
        String sYear = BatchJobSettings__c.getInstance().SCR_Optional_Year__c;  
        if (sYear == null) sYear = '*';
        String sMonth = BatchJobSettings__c.getInstance().SCR_Month__c;
        if (sMonth == null) sMonth = '*';
        String sDay = BatchJobSettings__c.getInstance().SCR_Day_Of_Month__c;
        if (sDay == null) sDay = '*';
        String sHour = BatchJobSettings__c.getInstance().SCR_Hours__c;
        if (sHour == null) sHour = '*';
        String sMinute = BatchJobSettings__c.getInstance().SCR_Minutes__c;
        if (sMinute == null) sMinute = '0';
        String sSecond = BatchJobSettings__c.getInstance().SCR_Seconds__c;
        if (sSecond == null) sSecond = '0';
        String sDayOfWeek = BatchJobSettings__c.getInstance().SCR_Day_Of_Week__c;
        if (sDayOfWeek == null) sDayOfWeek = '?';
        
        SegmentationChangeRequest scr = new SegmentationChangeRequest();
        //String sch = '0 3 19 26 7 ?';
        String sched = sSecond + ' ' + sMinute + ' ' + sHour + ' ' + sDay + ' ' + sMonth + ' ' + sDayOfWeek + '' + sYear;
        system.debug('***sched: ' + sched);
        system.schedule('SegmentationChangeRequest', sched, scr);       
    }
    
    
    private static testMethod void testExecuteSegmentationChangeRequestBatch() {
        
        //list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        
        // 26 November 2015 (christopher.henschke@auspost.com.au) updated SOQL to include CronJobDetail.JobType and stop test class from failing
		// using scheduled apex (jobtype 7) and batch job (jobtype 9)
		list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where state!='DELETED' AND (CronJobDetail.JobType = '7' OR CronJobDetail.JobType = '9')]);
		
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        ExecuteSegmentationChangeRequestBatch.execSegmentationChangeRequest();
    }   
}