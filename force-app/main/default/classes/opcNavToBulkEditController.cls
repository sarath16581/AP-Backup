/**
 * @author SteveL
 * @date 2024-03-11
 * @description controller class for Aura component opcNavToBulkEdit
 *
 * @change log: SteveL, created 2024-03-11
 */

public with sharing class opcNavToBulkEditController {
	@AuraEnabled
	public static Opportunity getOpportunity(String oppId) {
		Map<Id,Opportunity> oppMap = OpportunitiesSelector.newInstance(1).selectById(new Set<Id>{oppId});
		return oppMap.get(oppId);
	}

	@AuraEnabled
	public static Boolean recalculateRevenue(String oppId) {
		try {
			ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
			GroupedLineItemSalesModule.newInstance().performRevenueUpdates(new Set<Id>{oppId}, uow);
			uow.commitWork();
			return true;
		} catch (Exception ex) {
  			System.debug('***** Error: ' + ex.getMessage());
    		System.debug('***** Stack Trace: ' + ex.getStackTraceString());
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'opcNavToBulkEditController', opcNavToBulkEditController.class.getName(), 'recalculateRevenue', 'opcNavToBulkEditController', LoggingLevel.ERROR);
			return false;
		}
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				OpportunityLineItem.SObjectType,
				GroupedAccountProductRevenue__c.SObjectType
		};
	}
}