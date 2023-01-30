/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for Proposal
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public without sharing class SalesProposalSharingBatchable extends SalesRecordSharingBatchable {

	public SalesProposalSharingBatchable() {
		super(Apttus_Proposal__Proposal__c.SObjectType, new Set<Id>());
	}

	public SalesProposalSharingBatchable(Set<Id> accountIds) {
		super(Apttus_Proposal__Proposal__c.SObjectType, accountIds);
	}

	@TestVisible protected override Database.QueryLocator getQueryLocator(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return APT_ProposalObjectsSelector.newInstance(fieldOverrides).selectByAccountOrderByAccountIdQueryLocator(this.accountIds, new Set<Object>{
				APT_ProposalObjectsSelector.Options.WITH_ORGANISATION
		});
	}
}