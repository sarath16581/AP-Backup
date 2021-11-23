/**************************************************
Type:       Apex Schedulable Batch Job Class for batchMonthlyTimeUtilisation
Purpose:    Executes the batchMonthlyTimeUtilisation class at end of each month
Used By:    UST
History:    Brett Ashworth requests this feature. 
--------------------------------------------------
06-10-2015  Eric Shen (AusPost)    Time Utilisation Schedule class
**************************************************/
 
global without sharing class MonthlyTimeUtilisation_Schedulable implements Schedulable {

 // public static Integer BATCH_SIZE = BatchJobSettings__c.getInstance().OPC_Validation_Batch_Size__c.intValue();

  global void execute(SchedulableContext sc) {
   // System.assert(BATCH_SIZE != null, 'BATCH_SIZE cannot be null!');
 
      batchMonthlyTimeUtilisation bTU = new batchMonthlyTimeUtilisation();
        Database.executeBatch(bTU);
  }
}