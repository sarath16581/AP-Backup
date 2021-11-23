/**************************************************
Type:       Class to schedule OpportunityOpenEndedReview_Schedulable
Purpose:    Obtains BatchJobSettings custom setting values and schedules the OpportunityOpenEndedReview_Schedulable class.
Used By:    RunBatchJobs.cls
History:
--------------------------------------------------
28-Feb-2013 Manu Erwin (Salesforce.com)     ECLM: Phase 3: Created
**************************************************/
@isTest (SeeAllData=TRUE) 
public without sharing class OpportunityOpenEndedReview_Schedule {

    public static void scheduleOOER() {
        String optionalYear = BatchJobSettings__c.getInstance().OOER_Optional_Year__c;  
        System.assert(optionalYear != null, 'BatchJobSettings custom setting value for optionalYear is required (* acceptable): ' + optionalYear);

        String month = BatchJobSettings__c.getInstance().OOER_Month__c;
        System.assert(month != null, 'BatchJobSettings custom setting value for month is required (* acceptable): ' + month);

        String dayOfMonth = BatchJobSettings__c.getInstance().OOER_Day_Of_Month__c;
        System.assert(dayOfMonth != null, 'BatchJobSettings custom setting value for dayOfMonth is required (* acceptable): ' + dayOfMonth);

        String hours = BatchJobSettings__c.getInstance().OOER_Hours__c;
        System.assert(hours != null, 'BatchJobSettings custom setting value for hours is required (* acceptable): ' + hours);

        String minutes = BatchJobSettings__c.getInstance().OOER_Minutes__c;
        System.assert(minutes != null, 'BatchJobSettings custom setting value for minutes is required (* acceptable): ' + minutes);

        String seconds = BatchJobSettings__c.getInstance().OOER_Seconds__c;
        System.assert(seconds != null, 'BatchJobSettings custom setting value for seconds is required (* acceptable): ' + seconds);

        String dayOfWeek = BatchJobSettings__c.getInstance().OOER_Day_Of_Week__c;
        System.assert(dayOfWeek != null, 'BatchJobSettings custom setting value for dayOfWeek is required (* acceptable): ' + dayOfWeek);

        OpportunityOpenEndedReview_Schedulable OOERSchedule = new OpportunityOpenEndedReview_Schedulable();
        String scheduleString = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek + ' ' + optionalYear;
        System.debug('##DEBUG:scheduleString: ' + scheduleString);
        System.schedule('OpportunityOpenEndedReview', scheduleString, OOERSchedule);
    }

    private static void testScheduleOOER() {
        //Abort jobs to allow for test class to set the schedule
        list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where state!='DELETED']);
        for(CronTrigger CT : cron){
            system.abortjob(CT.Id);
        }
        
        OpportunityOpenEndedReview_Schedule.scheduleOOER();
    }
}