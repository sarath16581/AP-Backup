/* @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Opportunity
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 * 2023-05-17 - Ranjeewa Silva - Added new selector option to select child opportunity splits with split type 'overlay contribution'
 * 2023-08-18 - Ranjeewa Silva - Added selector options to select competitor, dsr and apttus contract child records
 * 2023-10-25 - Mahesh Parvathaneni - Added selector options to select opportunity line items child records
 * 2024-06-19 - Harry Wang - Added selector options to select key contact relationship and added selectByAccountId
 */

public virtual inherited sharing class OpportunitiesSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_OVERLAY_SPLITS, WITH_COMPETITORS, WITH_DEAL_SUPPORT_REQUESTS, WITH_APTTUS_CONTRACTS, 
		WITH_OPPORTUNITY_LINE_ITEMS, WITH_KEY_CONTACT
	}

	public static OpportunitiesSelector newInstance() {
		return (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class);
	}
	public static OpportunitiesSelector newInstance(Integer recordLimit) {
		return (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class).setLimit(recordLimit);
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunitiesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OpportunitiesSelector selector = (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	  }

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunitiesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OpportunitiesSelector selector = (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	} 

	public virtual override SObjectType getSObjectType() {
		return Opportunity.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Opportunity.Id,Opportunity.Name,Opportunity.StageName, Opportunity.IsClosed, Opportunity.ownerId
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

	/**
	 * @description Run a simple query to get records based on parent account Id's
	 */
	public virtual List<Opportunity> selectByAccountId(Set<Id> accountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.InCondition(Opportunity.AccountId).inCollection(accountIds))
				.endConditions();
		return Database.query(qb.toSoqlString());
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

		if (selectorOptions.contains(Options.WITH_OVERLAY_SPLITS)) {
			builder.addSubQuery(OpportunitiesSplitSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(new Set<Object>{
					OpportunitiesSplitSelector.Options.FILTER_OVERLAY_SPLITS
			}), 'OpportunitySplits');
		}

		if (selectorOptions.contains(Options.WITH_COMPETITORS)) {
			builder.addSubQuery(CompetitorsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Competitors__r');
		}

		if (selectorOptions.contains(Options.WITH_DEAL_SUPPORT_REQUESTS)) {
			builder.addSubQuery(DealSupportRequestsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Deal_Support_Request__r');
		}

		if (selectorOptions.contains(Options.WITH_APTTUS_CONTRACTS)) {
			builder.addSubQuery(ApttusContractsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus__R00N50000001Xl0FEAS__r');
		}

		if (selectorOptions.contains(Options.WITH_OPPORTUNITY_LINE_ITEMS)) {
			builder.addSubQuery(OpportunityLineItemSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'OpportunityLineItems');
		}

		if(selectorOptions.contains(Options.WITH_KEY_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'KeyContact__r');
		}

		return builder;
	}
}