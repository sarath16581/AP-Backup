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
		super(Apttus_Proposal__Proposal__c.SObjectType);
	}

	@TestVisible
	protected override Database.QueryLocator getQueryLocator() {
		return APT_ProposalObjectsSelector.newInstance(fieldOverride).selectByAccountRelationshipQueryLocator(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER, APT_ProposalObjectsSelector.Options.WITH_ACCOUNT});
	}
}