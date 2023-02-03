/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for DSR
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public without sharing class SalesDSRSharingBatchable extends SalesRecordSharingBatchable {

	public SalesDSRSharingBatchable() {
		super(Deal_Support_Request__c.SObjectType, new Set<Id>());
	}

	public SalesDSRSharingBatchable(Set<Id> accountIds) {
		super(Deal_Support_Request__c.SObjectType, accountIds);
	}

	@TestVisible protected override Database.QueryLocator getQueryLocator(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return DealSupportRequestsSelector.newInstance(fieldOverrides).selectByAccountOrderByAccountIdQueryLocator(this.accountIds, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
		});
	}
}