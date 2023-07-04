/* @author Nathan Franklin
 * @date 2020-10-01
 * @group Selector
 * @tag Selector
 * @tag OpportunitySplit
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 * 2023-05-17 - Ranjeewa Silva - Added new selector option to filter by split type 'overlay contribution'
 */
public virtual inherited sharing class OpportunitiesSplitSelector extends ApplicationSelector {
	public enum Options {
		WITH_OWNER, WITH_SPLIT_TYPE, FILTER_OVERLAY_SPLITS
	}
	public static OpportunitiesSplitSelector newInstance() {
		return (OpportunitiesSplitSelector)Application.Selectors.newInstance(OpportunitiesSplitSelector.class);
	}
	public static OpportunitiesSplitSelector newInstance(Integer recordLimit) {
		return (OpportunitiesSplitSelector)Application.Selectors.newInstance(OpportunitiesSplitSelector.class).setLimit(recordLimit);
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunitiesSplitSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OpportunitiesSplitSelector selector = (OpportunitiesSplitSelector)Application.Selectors.newInstance(OpportunitiesSplitSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunitiesSplitSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OpportunitiesSplitSelector selector = (OpportunitiesSplitSelector)Application.Selectors.newInstance(OpportunitiesSplitSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	} 

	public virtual override SObjectType getSObjectType() {
		return OpportunitySplit.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			OpportunitySplit.Id,OpportunitySplit.Overlay_Type__c, OpportunitySplit.SplitPercentage, OpportunitySplit.OpportunityId, OpportunitySplit.SplitTypeId,
			OpportunitySplit.Split_Member_Role_At_Opportunity_Closure__c,OpportunitySplit.SplitOwnerId,OpportunitySplit.Role_Name_at_Opportunity_Closure__c
		};
	}  
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, OpportunitySplit> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on account Id's
	 */
	public virtual Map<Id, OpportunitySplit> selectByOpportunity(Set<Id> opportunitiesIds) {
		return selectByOpportunity(opportunitiesIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Account Id's
	 */
	public virtual Map<Id, OpportunitySplit> selectByOpportunity(Set<Id> opportunitiesIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunitySplit.opportunityId + ' in :opportunitiesIds')).endConditions();
				 
		return new Map<Id, OpportunitySplit>((List<OpportunitySplit>)Database.query(qb.toSoqlString()));

	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, OpportunitySplit> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunitySplit.Id + ' in :ids')).endConditions();
		return new Map<Id, OpportunitySplit>((List<OpportunitySplit>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);	

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'SplitOwner');
		}

		if (selectorOptions.contains(Options.FILTER_OVERLAY_SPLITS)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition('SplitType.DeveloperName').eq('Opportunity_00N9000000EOb4X_Overlay')).endConditions();
		}

		return builder;
	}
}