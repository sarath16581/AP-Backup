/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Concrete batch class for SAP Contract
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public class SalesSAPContractSharingBatchable extends SalesRecordSharingBatchable {

	public SalesSAPContractSharingBatchable() {
		super(APT_SAP_Contracts__c.SObjectType);
	}

	@TestVisible
	protected override Database.QueryLocator getQueryLocator() {
		return SAPContractsSelector.newInstance(fieldOverride).selectByAccountRelationshipQueryLocator(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER, SAPContractsSelector.Options.WITH_ORGANISATION});
	}
}