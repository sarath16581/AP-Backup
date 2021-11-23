/**
* Author: Angelo Rivera
* Name: BatchScheduleDeleteI2CTemporaryDocuments
* Description: Schedule Batch Class BatchDeleteWebFormTemporaryDocuments. This should be scheduled to run every end of day (11:59).
* Revision History
* 07-12-2017 	1.0		AP.Rivera		Created
**/

global without sharing class BatchScheduleDeleteI2CTemporaryDocuments implements Schedulable {
	global void execute(SchedulableContext sc) {
        System.debug('###DEBUG: Schedule Batch Process BatchDeleteWebFormTemporaryDocuments Initiated');
       
        // We now call the batch class to be scheduled
        BatchDeleteWebFormTemporaryDocuments b = new BatchDeleteWebFormTemporaryDocuments ();
       
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(b,100);
	}
}