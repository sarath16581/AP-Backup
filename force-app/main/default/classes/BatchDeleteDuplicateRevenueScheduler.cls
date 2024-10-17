/**
* @description Scheduler for BatchDeleteDuplicateRevenue 
*
* @changelog
* 2024-10-10 - Swati Mogadala - Created
*/
public with sharing class BatchDeleteDuplicateRevenueScheduler implements Schedulable {
public void execute(SchedulableContext sc) {
// Instantiate the batch class
BatchDeleteDuplicateRevenue batch = new BatchDeleteDuplicateRevenue();

// Execute the batch with a specified batch size (e.g., 200)
Database.executeBatch(batch, 200);
	}
}