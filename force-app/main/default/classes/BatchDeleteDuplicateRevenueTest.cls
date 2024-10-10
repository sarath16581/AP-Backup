/**
* @description Test class for BatchDeleteDuplicateRevenue
* @date 2024-10-10
* @group Tests
* @group Selector
* @changelog
* 2024-10-10 - Swati Mogadala - Created
*/
@isTest
public class BatchDeleteDuplicateRevenueTest {

    @isTest
    static void testBatchDeleteDuplicateRevenue() {
        // // =====================================
        // Data Preparation
        // =====================================
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
        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        // Step 2: Verify that records are created
        System.assertEquals(2, [SELECT COUNT() FROM Budget_and_Revenue__c]);
        System.assertEquals(2, [SELECT COUNT() FROM Revenue_by_Billing_Account__c]);

        // Step 3: Instantiate the batch class and execute it
        BatchDeleteDuplicateRevenue batch = new BatchDeleteDuplicateRevenue();
        Database.executeBatch(batch);
        Test.stopTest();

        // Step 4: Verify that the records have been deleted
        System.assertEquals(1, [SELECT COUNT() FROM Budget_and_Revenue__c]);
        System.assertEquals(1, [SELECT COUNT() FROM Revenue_by_Billing_Account__c]);
    }

    @isTest
    static void testBatchWithNoRecords() {
        // Step 1: Ensure no records exist
        Test.startTest();
        System.assertEquals(0, [SELECT COUNT() FROM Budget_and_Revenue__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Revenue_by_Billing_Account__c]);

        // Step 2: Instantiate the batch class and execute it
       
        BatchDeleteDuplicateRevenue batch = new BatchDeleteDuplicateRevenue();
        Database.executeBatch(batch);
        Test.stopTest();

        // Step 3: Verify that no exceptions were thrown and that no records exist
        System.assertEquals(0, [SELECT COUNT() FROM Budget_and_Revenue__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Revenue_by_Billing_Account__c]);
    }
}