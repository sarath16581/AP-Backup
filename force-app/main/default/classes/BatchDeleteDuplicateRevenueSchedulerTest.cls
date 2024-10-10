/**
* @description Test class for BatchDeleteDuplicateRevenueScheduler 
* @date 2024-10-10
* @group Tests
* @group Selector
* @changelog
* 2024-10-10 - Swati Mogadala - Created
*/
@isTest
public class BatchDeleteDuplicateRevenueSchedulerTest {
public static String cronExp = '0 0 12 * * ?';
	@isTest
	static void testBatchDeleteDuplicateRevenueScheduler() {
		// Set up test data
		// Created dummy revenue records that the batch will process.
		MockUtility.disableTriggerExecution();
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
	  	testAccount.LEGACY_ID__c='60000000';
		insert testAccount;
		
	   	Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1, testAccount.Id, 'TEAM', false)[0];
		insert billingAcc;
		
		// Positive test case
		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAccount.Id, false)[0];
		revenue.Unique_Id__c=revenue.CustomerNumber__c + 'Test1';
		insert revenue;
		// Negative test case
		Budget_and_Revenue__c duplicate = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAccount.Id, false)[0];
		revenue.Unique_Id__c='60000008Test1';
		insert duplicate;
		
		// Positive test case
		Revenue_by_Billing_Account__c rev = ApplicationTestDataFactory.getRevByBillingAcc(1, testAccount.Id,billingAcc.Id, false)[0];
		rev.Customer__c=testAccount.id;
		rev.Billing_Account__c=billingAcc.Id;
		insert rev;
		rev.Unique_Id__c=rev.Customer__r.Customer_number__c +'Test1';
		update rev;
		// Negative test case
		Revenue_by_Billing_Account__c dup = ApplicationTestDataFactory.getRevByBillingAcc(1, testAccount.Id,billingAcc.Id, false)[0];
		dup.Customer__c=testAccount.id;
		dup.Billing_Account__c=billingAcc.Id;
		dup.Unique_Id__c='66000000Test2';
		insert dup;

		// Schedule the batch job
		Test.startTest();
		BatchDeleteDuplicateRevenueScheduler scheduler = new BatchDeleteDuplicateRevenueScheduler();
		String jobId = System.schedule('Test Batch Delete Duplicate Revenue Scheduler', cronExp, scheduler);

		// Verify that the job was scheduled
		CronTrigger ct = [SELECT Id, CronExpression,NextFireTime,State FROM CronTrigger WHERE Id = :jobId];
		// Verify the expressions are the same
		System.assertEquals(cronExp, ct.CronExpression);
		// Verify the next time the job will run
		System.assertEquals('WAITING', ct.State);
		// Assert the NextFireTime
		DateTime nextFireTime = ct.NextFireTime;
		
		// Check if the NextFireTime is not null
		System.assertNotEquals(null, nextFireTime, 'NextFireTime should not be null.');
		
		// Execute the batch manually to test functionality
	   
		BatchDeleteDuplicateRevenue batch = new BatchDeleteDuplicateRevenue();
		Database.executeBatch(batch, 200);
		Test.stopTest();

		// Verify the expected outcomes after batch execution	  
		// The logic is to keep one and delete duplicates, check remaining records.
	
		System.assertEquals(1, [SELECT COUNT() FROM Budget_and_Revenue__c]);
		System.assertEquals(1, [SELECT COUNT() FROM Revenue_by_Billing_Account__c]);

	}
}