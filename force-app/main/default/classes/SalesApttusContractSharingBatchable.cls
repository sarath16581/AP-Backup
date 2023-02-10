/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for Apttus Contract
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public without sharing class SalesApttusContractSharingBatchable extends SalesRecordSharingBatchable {

	public SalesApttusContractSharingBatchable() {
		super(Apttus__APTS_Agreement__c.SObjectType, new Set<Id>());
	}

	public SalesApttusContractSharingBatchable(Set<Id> accountIds) {
		super(Apttus__APTS_Agreement__c.SObjectType, accountIds);
	}

	@TestVisible protected override Database.QueryLocator getQueryLocator(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return ApttusContractsSelector.newInstance(fieldOverrides).selectByAccountOrderByAccountIdQueryLocator(this.accountIds, new Set<Object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION
		});
	}
}