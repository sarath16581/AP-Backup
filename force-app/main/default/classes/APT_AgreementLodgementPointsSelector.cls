/* @author Seth Heang
 * @date 2021-06-08
 * @group Selector
 * @tag Selector
 * @tag APT_Agreement_Lodgement_Point__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * 2022-07-07 - madhuri.awasthi@auspost.com. - REQ2800825 Filtering Status for LP before sending in SAP
 * * @changelog
 * 2022-05-31 - Seth Heang - Added related list WITH_BILLING_ACCOUNT, WITH_CHARGE_ACCOUNT_REQ, WITH_SUB_ACCOUNT_REQ and update getSObjectFieldList
 * 2022-08-04 - Seth Heang - Added related list WITH_ORGANISATION, WITH_CONTRACT
 */
public virtual inherited sharing class APT_AgreementLodgementPointsSelector extends ApplicationSelector {
	public enum Options {
		WITH_NETWORK,
		WITH_BILLING_ACCOUNT,
		WITH_CHARGE_ACCOUNT_REQ,
		WITH_SUB_ACCOUNT_REQ,
		WITH_ORGANISATION,
		WITH_CONTRACT,
		FILTER_ACTIVE_STATUS
	}

    public static APT_AgreementLodgementPointsSelector newInstance() {
        return (APT_AgreementLodgementPointsSelector)Application.Selectors.newInstance(APT_AgreementLodgementPointsSelector.class);
    }
    public static APT_AgreementLodgementPointsSelector newInstance(Integer recordLimit) {
        return (APT_AgreementLodgementPointsSelector)Application.Selectors.newInstance(APT_AgreementLodgementPointsSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return APT_Agreement_Lodgement_Point__c.getSObjectType();
    }    
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			APT_Agreement_Lodgement_Point__c.Id, APT_Agreement_Lodgement_Point__c.APT_Lodgement_Point_Lookup__c, APT_Agreement_Lodgement_Point__c.APT_Agreement__c, 
			APT_Agreement_Lodgement_Point__c.Name, APT_Agreement_Lodgement_Point__c.APT_Organisation__c, APT_Agreement_Lodgement_Point__c.Rating_Plan_Id__c,
			APT_Agreement_Lodgement_Point__c.APT_Billing_Account__c, APT_Agreement_Lodgement_Point__c.APT_Charge_Account__c, APT_Agreement_Lodgement_Point__c.APT_Sub_Account__c,
			APT_Agreement_Lodgement_Point__c.APT_Product__c
		};
	}
    
    /**
     * @description Run a simple query to get records based on charge Account request Id
     */
    public virtual Map<Id, APT_Agreement_Lodgement_Point__c> selectByApttusContractId(Set<Id> ids) {
        return selectByApttusContractId(ids, new Set<Object>());
    }
    
    /**
     * @description Run a simple query to get records based on charge Account request Id
     */
    public virtual Map<Id, APT_Agreement_Lodgement_Point__c> selectByApttusContractId(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions)
            .addConditions()
            .add(new QueryBuilder.SimpleCondition(APT_Agreement_Lodgement_Point__c.APT_Agreement__c + ' in :ids'))
            .endConditions();
        return new Map<Id, APT_Agreement_Lodgement_Point__c>((List<APT_Agreement_Lodgement_Point__c>)Database.query(qb.toSoqlString()));
    }
    
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }
    
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_NETWORK)) {
			builder.addRelatedFields(NetworksSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Lodgement_Point_Lookup__r');
		}
		if(selectorOptions.contains(Options.FILTER_ACTIVE_STATUS)) {
            builder.addConditions().add(new QueryBuilder.CompareCondition(APT_Agreement_Lodgement_Point__c.APT_Status__c).eq(APT_Constants.ACTIVE)).endConditions();
        }
		if(selectorOptions.contains(Options.WITH_BILLING_ACCOUNT)) {
			builder.addRelatedFields(BillingAccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Billing_Account__r');
		}
		if(selectorOptions.contains(Options.WITH_CHARGE_ACCOUNT_REQ)) {
			builder.addRelatedFields(ChargeAccountRequestSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Charge_Account__r');
		}
		if(selectorOptions.contains(Options.WITH_SUB_ACCOUNT_REQ)) {
			builder.addRelatedFields(SubAccountRequestsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Sub_Account__r');
		}
		if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Organisation__r');
		}
		if(selectorOptions.contains(Options.WITH_CONTRACT)) {
			builder.addRelatedFields(ApttusContractsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Agreement__r');
		}
		return builder;
	}
}