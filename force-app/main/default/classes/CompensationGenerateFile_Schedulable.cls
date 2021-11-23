/**************************************************
Description:       Handles the schedule for CompensationGenerateFile_Batchable.
History:
--------------------------------------------------
2018-09-18  dilshan.egodawela@auspost.com.au  Created
**************************************************/

global without sharing class CompensationGenerateFile_Schedulable implements Schedulable {
	global void execute(SchedulableContext SC) {
		CompensationGenerateFile_Batchable batch = new CompensationGenerateFile_Batchable();
		Database.executeBatch(batch, 200);
	}
}