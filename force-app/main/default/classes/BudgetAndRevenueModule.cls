/***
 * @author Ken McGuire
 * @date 2022-10-30
 * @description Send Surveys out to a Case that has meet survey entry criteria.  
 * @changelog
 * 2024-07-09  modify for line items of closed opportunities 
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
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate().enableAfterUpdate();
	}
	
    // add a unique identifier to new records.
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow)  {
		try {
			populateUID((List<Budget_and_Revenue__c>)records);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onBeforeInsert', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
		}
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateGroupedRevenues((List<Budget_and_Revenue__c>)records,null,uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterInsert', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
		}
	}

    // add a unique identifier to existing records that may not have one.
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<Budget_and_Revenue__c> recordsToUpdate = new List<Budget_and_Revenue__c>();
			for (Budget_and_Revenue__c record : (List<Budget_and_Revenue__c>)records) {
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
	
    // update grouped revenues with the revised values of budget and revenue
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
		try {
            Set<SObjectField> monitoredFields = getMonitoredFields();
            String context = 'updateGroupedRevenues.action';
            List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, records, existingRecords, monitoredFields); 
             system.debug('****** changedRecords '+changedRecords);
			List<Budget_and_Revenue__c> updatedRecordsWithRevenue = getBudgetAndRevenueRecordsToProcess(records, changedRecords);
            system.debug('****** calling update grouped revenues for records '+updatedRecordsWithRevenue);
            updateGroupedRevenues((List<Budget_and_Revenue__c>) updatedRecordsWithRevenue, (Map<Id,Budget_and_Revenue__c>)existingRecords, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
		}
	}
    
   /**
    * Filters updated budget and revenue recorsd for those with revenue.
    * @param revenue Records the updated revenue records
    * @param changedRecords - a list of changed records
    * @return List<Budget_and_Revenue__c> - a list of changed records with revenue.
    */
    private List<Budget_and_Revenue__c> getBudgetAndRevenueRecordsToProcess(List<Budget_and_Revenue__c> revenueRecords,List<ApplicationRecursion.RecordState> changedRecords) {
        Map<Id,Budget_and_Revenue__c>  recordsWithRevenue = new  Map<Id,Budget_and_Revenue__c>();
        Set<Id> changedIds = new Set<Id>();
        for (ApplicationRecursion.RecordState recordState : changedRecords) {
            changedIds.add(recordState.record.Id);
        }
        system.debug('**** changedIds '+changedIds);
        system.debug('***** revenue recoreds '+revenueRecords);
        for (Budget_and_Revenue__c br : revenueRecords) {
            if (changedIds.contains(br.id)) 
            {
               recordsWithRevenue.put(br.id,br);
            }
        }
        return recordsWithRevenue.values();
    }

	private void updateGroupedRevenues(List<Budget_and_Revenue__c> records, Map<Id, Budget_and_Revenue__c> existingRecords, ApplicationUnitOfWork uow) {
        if (records.isEmpty()) {
            return;
        }
		Map<String,GroupedAccountProductRevenue__c> recordsChanged = ProductRevenueService.getInstance().updateGroupedRevenues(records,existingRecords);
		List<GroupedAccountProductRevenue__c> recordsToCreate = new List<GroupedAccountProductRevenue__c>();
		List<GroupedAccountProductRevenue__c> recordsToUpdate = new List<GroupedAccountProductRevenue__c>();
		for (GroupedAccountProductRevenue__c record : recordsChanged.values()) {
			if (record.id == null) {
				recordsToCreate.add(record);
			}
			else {
				recordsToUpdate.add(record);
			}
		}
		if (!recordsToCreate.isEmpty()) {
			uow.registerNew(recordsToCreate);
		}
		if (!recordsToUpdate.isEmpty()) {
			uow.registerDirty(recordsToUpdate);
		}
	}

	private void populateUID(List<Budget_and_Revenue__c> records) {
		for(Budget_and_Revenue__c record : records) {
			record.uid__c = ProductRevenueService.getUID(record);
		}
	}
    
    private static Set<SObjectField> getMonitoredFields() {
        return new Set<SObjectField>{
                Budget_And_Revenue__c.Jan_Revenue_Amount__c,
                Budget_And_Revenue__c.Feb_Revenue_Amount__c,
                Budget_And_Revenue__c.Mar_Revenue_Amount__c,
                Budget_And_Revenue__c.Apr_Revenue_Amount__c,
                Budget_And_Revenue__c.May_Revenue_Amount__c,
                Budget_And_Revenue__c.Jun_Revenue_Amount__c,
                Budget_And_Revenue__c.Jul_Revenue_Amount__c,
                Budget_And_Revenue__c.Aug_Revenue_Amount__c,
                Budget_And_Revenue__c.Sep_Revenue_Amount__c,
                Budget_And_Revenue__c.Oct_Revenue_Amount__c,
                Budget_And_Revenue__c.Nov_Revenue_Amount__c,
                Budget_And_Revenue__c.Dec_Revenue_Amount__c
            };
    }
    
    private  Set<SObjectField> getPastMonthsFields(Integer numberOfMonths) {
        Set<SObjectField> monitoredFields = new Set<SObjectField>();
        Date targetDate = date.today();
		Integer targetYear = getAustralianFinancialYear(targetDate);
		Integer targetMonth = targetDate.month(); 
		monitoredFields.add(getMonthField(targetMonth));
		for (Integer i = 1; i <= numberOfMonths; i++) {
			// adjust target month and financial year.
			targetMonth -= 1;
			if (targetMonth == 6) {
				break;
			}
			else if (targetMonth==0) {
				targetMonth = 12;
			}
			monitoredFields.add(getMonthField(targetMonth));
	 	}
        return monitoredFields;
	}
    
    private static SObjectField getMonthField(Integer month) {
        switch on month {
            when 1 { return Budget_And_Revenue__c.Jan_Revenue_Amount__c; }
            when 2 { return Budget_And_Revenue__c.Feb_Revenue_Amount__c; }
            when 3 { return Budget_And_Revenue__c.Mar_Revenue_Amount__c; }
            when 4 { return Budget_And_Revenue__c.Apr_Revenue_Amount__c; }
            when 5 { return Budget_And_Revenue__c.May_Revenue_Amount__c; }
            when 6 { return Budget_And_Revenue__c.Jun_Revenue_Amount__c; }
            when 7 { return Budget_And_Revenue__c.Jul_Revenue_Amount__c; }
            when 8 { return Budget_And_Revenue__c.Aug_Revenue_Amount__c; }
            when 9 { return Budget_And_Revenue__c.Sep_Revenue_Amount__c; }
            when 10 { return Budget_And_Revenue__c.Oct_Revenue_Amount__c; }
            when 11 { return Budget_And_Revenue__c.Nov_Revenue_Amount__c; }
            when 12 { return Budget_And_Revenue__c.Dec_Revenue_Amount__c; }
        }
        return null; // Default return in case the month doesn't match
    }
    
	private static Integer getAustralianFinancialYear(Date dateToConvert) {
		return dateToConvert.month() >= 7 ? dateToConvert.year() + 1 : dateToConvert.year();
	}

}