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
		super(Apttus__APTS_Agreement__c.SObjectType);
	}

	@TestVisible
	protected override Database.QueryLocator getQueryLocator() {
		return ApttusContractsSelector.newInstance(fieldOverride).selectByAccountRelationshipQueryLocator(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER, ApttusContractsSelector.Options.WITH_ACCOUNT});
	}
}