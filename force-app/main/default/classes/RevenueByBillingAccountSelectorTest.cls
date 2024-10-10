/**
 * @author Swati Mogadala
 * @date 2024-10-10
 * @group Tests
 * @group Selector
 * @tag Selector
 * @tag Revenue by Billing Account
 * @domain Core
 * @description A simple selector class that sits in the base domain
 * @changelog
 * 2024-10-10 - Swati Mogadala - Created
 */
@isTest
public class RevenueByBillingAccountSelectorTest {
@isTest
	static void test_selectByDups(){
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
		
        Account testAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
      	
        testAccount.LEGACY_ID__c='60000000';
		
        insert testAccount;
        
       	Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1, testAccount.Id, 'TEAM', false)[0];
		
        insert billingAcc;
		
		// Positive test case
		Revenue_by_Billing_Account__c revenue = ApplicationTestDataFactory.getRevByBillingAcc(1, testAccount.Id,billingAcc.Id, false)[0];
        
        revenue.Customer__c=testAccount.id;
        
        revenue.Billing_Account__c=billingAcc.Id;
		
        insert revenue;
        
        revenue.Unique_Id__c=revenue.Customer__r.Customer_number__c +'Test1';
        
        update revenue;
        
        // Negative test case
        Revenue_by_Billing_Account__c duplicate = ApplicationTestDataFactory.getRevByBillingAcc(1, testAccount.Id,billingAcc.Id, false)[0];
       
        duplicate.Customer__c=testAccount.id;
        
        duplicate.Billing_Account__c=billingAcc.Id;
        
        duplicate.Unique_Id__c='66000000Test2';
        
        insert duplicate;
        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();

		RevenueByBillingAccountSelector selector = RevenueByBillingAccountSelector.newInstance();
		
        List<Revenue_by_Billing_Account__c> results = selector.selectByDups();
        
		// Make sure we only get back the positive test record
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		
        Assert.areEqual(duplicate.Id, results[0].Id, 'Expected duplicate revenue record');

		Test.stopTest();
	}
}