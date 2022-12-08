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
		super(Deal_Support_Request__c.SObjectType);
	}

	@TestVisible
	protected override Database.QueryLocator getQueryLocator() {
		return DealSupportRequestsSelector.newInstance(fieldOverride).selectByAccountRelationshipQueryLocator(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER, DealSupportRequestsSelector.Options.WITH_ORGANISATION});
	}
}