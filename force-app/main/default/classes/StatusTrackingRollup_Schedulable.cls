/**************************************************
Description:       Handles the schedule for rollup summary batchable for StatusTracking to Case rollups
					This will launch the Delegator batch which is responsible for firing multiple concurrent batches to update Status Tracking rollups
History:
--------------------------------------------------
2017-12-18  nathan.franklin@auspost.com.au  Created
**************************************************/
global without sharing class StatusTrackingRollup_Schedulable implements Schedulable {
	global void execute(SchedulableContext SC) {
		StatusTrackingRollupDelegator batch = new StatusTrackingRollupDelegator();
		Database.executeBatch(batch, 2000);
	}
}