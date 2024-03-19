/**
 * @author SteveL
 * @date 2024-03-11
 * @description controller class for Aura component opcNavToBulkEdit
 *
 * @change log: SteveL, created 2024-03-11
 */

public with sharing class opcNavToBulkEditController {
	@AuraEnabled
	public static Boolean recalculateRevenue(String oppId) {
		try {
			GroupedLineItemSalesModule.newInstance().performRevenueUpdates(new Set<Id>{oppId}, ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes()));
			return true;
		} catch (Exception ex) {
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