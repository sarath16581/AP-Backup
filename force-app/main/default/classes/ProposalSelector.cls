/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Credit Assessment
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-18 - Shashwat.Nath@austpost.com.au - Created
 * 2023.04.19 Ken McGuire  Proposal field migration to opportunity
 * 2023-07-06 - Yatika Bansal - Added fields APT_Use_Offline_Rates__c,Apttus_Proposal__Proposal_Name__c in the query
 * 2023-07-17 - Yatika Bansal - Added field APT_Contract_Number__c  in the query
 */
public with sharing class ProposalSelector extends ApplicationSelector{

	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER
	}

	public static ProposalSelector newInstance() {
		return (ProposalSelector)Application.Selectors.newInstance(ProposalSelector.class);
	}

	public static ProposalSelector newInstance(Integer recordLimit) {
		return (ProposalSelector)Application.Selectors.newInstance(ProposalSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */

	public static ProposalSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ProposalSelector selector = (ProposalSelector)Application.Selectors.newInstance(ProposalSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ProposalSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ProposalSelector selector = (ProposalSelector)Application.Selectors.newInstance(ProposalSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus_Proposal__Proposal__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
	  Apttus_Proposal__Proposal__c.Id, Apttus_Proposal__Proposal__c.Name, Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c, Apttus_Proposal__Proposal__c.APT_Use_Offline_Rates__c, Apttus_Proposal__Proposal__c.Apttus_Proposal__Proposal_Name__c, Apttus_Proposal__Proposal__c.APT_Contract_Number__c //,Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__r.APTMinimumMonthlySpend__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	*/
	public virtual Map<Id, Apttus_Proposal__Proposal__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Apttus_Proposal__Proposal__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.Id + ' in :ids')).endConditions();

		return new Map<Id, Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}
		return builder;
	}
}