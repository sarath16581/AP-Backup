/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag Opportunity
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 *				IMPORTANT - Deprecated. Do not use. Please use OpportunitiesSelector instead.
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 * 2021-06-08 - Seth.heang@auspost.com.au - Added Sender_name_to_appear_on_parcel_label__c field into query
 * 2023-03-29 - Harry Wang - Added new selector options WITH_CHILD_PROPOSALS
 * 2023-03-07 - nasir.jawed2@auspost.com.au - Added KeyContact__c,name, closedate field into query
 * 2023-07-07 - nasir.jawed2@auspost.com.au - Added WITH_USER,WITH_KEY_CONTACT,WITH_OWNER as Options
 * 2023-08-31 - Ranjeewa Silva - Deprecated this selector(with sharing) in favour of OpportunitiesSelector(inherited sharing)
 * --------------------------------------------------------------------------------------------
 * IMPORTANT - Deprecated. Do not use. Please use OpportunitiesSelector instead.
 * --------------------------------------------------------------------------------------------
 */

 public with sharing class OpportunitySelector extends ApplicationSelector{

	public enum Options {
		WITH_CHILD_PROPOSALS,
		WITH_USER,
		WITH_KEY_CONTACT,
		WITH_OWNER
	}

	public static OpportunitySelector newInstance() {
		return (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class);
	}

	public static OpportunitySelector newInstance(Integer recordLimit) {
		return (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static OpportunitySelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OpportunitySelector selector = (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static OpportunitySelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OpportunitySelector selector = (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Opportunity.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
		Opportunity.Id, Opportunity.Primary_Pick_Up_Location__c, Opportunity.Sender_name_to_appear_on_parcel_label__c, Opportunity.Opportunity_Number__c,Opportunity.Stagename, Opportunity.APTPostcodeSuburb__c,Opportunity.APTMinimumMonthlySpend__c,Opportunity.IsStartrackProposal__c,Opportunity.AccountID,
					Opportunity.KeyContact__c,Opportunity.Name,Opportunity.CloseDate,Opportunity.OwnerId
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Opportunity> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */

	public virtual Map<Id, Opportunity> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Opportunity.Id + ' in :ids')).endConditions();
		return new Map<Id, Opportunity>((List<Opportunity>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if(selectorOptions.contains(Options.WITH_CHILD_PROPOSALS)) {
			builder.addSubQuery(APT_ProposalObjectsSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Apttus_Proposal__R00N70000001yUfDEAU__r');
		}
		if(selectorOptions.contains(Options.WITH_USER)) {
			builder.addSubQuery(UsersSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'USER');
		}
		if(selectorOptions.contains(Options.WITH_KEY_CONTACT)) {
			builder.addSubQuery(ContactsSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'KeyContact__r');
		}
		if (selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}
	return builder;
 	}
}