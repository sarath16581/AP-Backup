/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for APR
 * @Test SalesAPRSharingBatchable_Test
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public without sharing class SalesAPRSharingBatchable extends SalesRecordSharingBatchable {

	public SalesAPRSharingBatchable() {
		super(APR__c.SObjectType, new Set<Id>());
	}

	public SalesAPRSharingBatchable(Set<Id> accountIds) {
		super(APR__c.SObjectType, accountIds);
	}

	@TestVisible protected override Database.QueryLocator getQueryLocator(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return APRsSelector.newInstance(fieldOverrides).selectByAccountOrderByAccountIdQueryLocator(this.accountIds, new Set<Object>{
				APRsSelector.Options.WITH_ORGANISATION
		});
	}
}