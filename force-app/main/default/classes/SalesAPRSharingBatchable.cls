/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for APR
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public without sharing class SalesAPRSharingBatchable extends SalesRecordSharingBatchable {

	public SalesAPRSharingBatchable() {
		super(APR__c.SObjectType);
	}

	@TestVisible
	protected override Database.QueryLocator getQueryLocator() {
		return APRsSelector.newInstance(fieldOverride).selectByAccountRelationshipQueryLocator(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER, APRsSelector.Options.WITH_LEGAL_ENTITY});
	}
}