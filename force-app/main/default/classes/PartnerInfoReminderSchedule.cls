/**************************************************
Type:       Schedule Class for Partner Info Reminder Batch
Purpose:    Starts the Batch class
Used By:    
History:
--------------------------------------------------
07.08.2015  Ritika Dhandia (Salesforce.com)     Created
**************************************************/
global with sharing class PartnerInfoReminderSchedule implements Schedulable{

    global void execute(SchedulableContext sc) {
        
    	PartnerInfoReminderBatch batch = new PartnerInfoReminderBatch();
    	Database.executeBatch(batch);

    }

}