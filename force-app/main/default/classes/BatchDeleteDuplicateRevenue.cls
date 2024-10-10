/**
* @description Batchable class to delete duplicate customer revenue recods and revenue by billing account records when organisations are merge.
*
* Called from:
*        - BatchDeleteDuplicateRevenueScheduler schedule
*
* @changelog
* 2024-10-10 - Swati Mogadala - Created
*/
public class BatchDeleteDuplicateRevenue implements Database.Batchable<SObject>{

    public List<sObject> start(Database.BatchableContext c)
    {
        List<sObject> scope = new List<sObject>();
        BudgetAndRevenueSelector customerRevSel = BudgetAndRevenueSelector.newInstance();
        RevenueByBillingAccountSelector revenueBillAccSel = RevenueByBillingAccountSelector.newInstance();
        scope.addAll(customerRevSel.selectByDups());
        scope.addAll(revenueBillAccSel.selectByDups());
        return scope;
    }

   
    public void execute(Database.BatchableContext c, List<sObject> scope) {
        List<Budget_and_Revenue__c> customerRevToDelete = new List<Budget_and_Revenue__c>();
        List<Revenue_by_Billing_Account__c> revenueByBillAccToDelete = new List<Revenue_by_Billing_Account__c>();

        for (sObject obj : scope) {
            if (obj instanceof Budget_and_Revenue__c) {
                customerRevToDelete.add((Budget_and_Revenue__c) obj);
            } else if (obj instanceof Revenue_by_Billing_Account__c) {
                revenueByBillAccToDelete.add((Revenue_by_Billing_Account__c) obj);
            }
        }
        System.debug('###DEBUG: Batch Process BatchDeleteDuplicateRevenue Process Started');
		Savepoint sp = Database.setSavepoint();
        try {
            if (!customerRevToDelete.isEmpty()) {
                delete customerRevToDelete;
            }
            if (!revenueByBillAccToDelete.isEmpty()) {
                delete revenueByBillAccToDelete;
            }
        } catch (DmlException e) {
            // Log the error with detailed information
            System.debug('Error deleting accounts: ' + e.getMessage());
            System.debug('Failed records: ' +customerRevToDelete );
            System.debug('Failed records: ' +revenueByBillAccToDelete );
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'BatchDeleteDuplicateRevenue', BatchDeleteDuplicateRevenue.class.getName(), 'execute', 'BatchDeleteDuplicateRevenue', LoggingLevel.ERROR);
            Database.rollback(sp);
		
        }
    }
	public void finish(Database.BatchableContext bc) {
	
        System.debug('Batch process completed.');
    }
}