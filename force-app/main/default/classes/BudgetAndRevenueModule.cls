/***
 * @author Ken McGuire
 * @date 2022-10-30
 * @description Send Surveys out to a Case that has meet survey entry criteria.  
 * @changelog
 */
public inherited sharing  class BudgetAndRevenueModule extends ApplicationModule {

    /*
     * Creates a new instance of the utility to facilitate dependency injection for mocking
     * @return the new instance
     */
    public static BudgetAndRevenueModule newInstance() {
        return (BudgetAndRevenueModule )Application.Utilities.newInstance(BudgetAndRevenueModule.class);
    }
    
    // Constructor
    public BudgetAndRevenueModule() {
        // Setup which triggers this module should respond to
        getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableAfterUpdate();
    }

    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow)  {
        try {
            populateUID((List<Budget_And_Revenue__c>)records);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onBeforeInsert', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
    }
    
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) { 
        try {
            updateGroupedRevenues((List<Budget_And_Revenue__c>)records,null,uow);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterInsert', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
    }

    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) { 
        try {
            list<Budget_And_Revenue__c> recordsToUpdate = new list<Budget_And_Revenue__c>();
            for (Budget_And_Revenue__c record : (List<Budget_And_Revenue__c>)records) {
                if (record.uid__c == null) {
                    recordsToUpdate.add(record);
                }
            }
            if (!recordsToUpdate.isEmpty()) {
                populateUID(recordsToUpdate);
            }
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterInsert', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
    }
    
    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
        try {
            updateGroupedRevenues((List<Budget_And_Revenue__c>)records, (Map<Id,Budget_And_Revenue__c>)existingRecords, uow);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
    }
    

    
    private void updateGroupedRevenues(List<Budget_And_Revenue__c> records, Map<Id, Budget_And_Revenue__c> existingRecords, ApplicationUnitOfWork uow) {
      List<GroupedAccountProductRevenue__c> updatedRecords = ProductRevenueService.getInstance().updateGroupedRevenues(records,existingRecords);
        if (updatedRecords.isEmpty() == false) {
            uow.registerDirty(updatedRecords);
        }
    }
    
    private void populateUID(List<Budget_And_Revenue__c> records) {
        for(Budget_And_Revenue__c record : records) {
            record.UID__c = ProductRevenueService.getUID(record);
        }
    }

}