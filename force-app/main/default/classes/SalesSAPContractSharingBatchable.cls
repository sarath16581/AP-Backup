/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for SAP Contract
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public without sharing class SalesSAPContractSharingBatchable extends SalesRecordSharingBatchable {

	public SalesSAPContractSharingBatchable() {
		super(APT_SAP_Contracts__c.SObjectType, new Set<Id>());
	}

	public SalesSAPContractSharingBatchable(Set<Id> accountIds) {
		super(APT_SAP_Contracts__c.SObjectType, accountIds);
	}

	@TestVisible protected override Database.QueryLocator getQueryLocator(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return SAPContractsSelector.newInstance(fieldOverrides).selectByAccountOrderByAccountIdQueryLocator(this.accountIds, new Set<Object>{
				SAPContractsSelector.Options.WITH_ORGANISATION
		});
	}
}