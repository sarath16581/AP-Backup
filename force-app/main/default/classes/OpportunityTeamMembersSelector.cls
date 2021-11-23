/* @author Nathan Franklin
 * @date 2020-10-01
 * @group Selector
 * @tag Selector
 * @tag OpportunityTeamMembers
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 */
public virtual inherited sharing class OpportunityTeamMembersSelector extends ApplicationSelector {
    public enum Options {
		  
    }
    public static OpportunityTeamMembersSelector newInstance() {
		return (OpportunityTeamMembersSelector)Application.Selectors.newInstance(OpportunityTeamMembersSelector.class);
	}
	public static OpportunityTeamMembersSelector newInstance(Integer recordLimit) {
		return (OpportunityTeamMembersSelector)Application.Selectors.newInstance(OpportunityTeamMembersSelector.class).setLimit(recordLimit);
    }
    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunityTeamMembersSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OpportunityTeamMembersSelector selector = (OpportunityTeamMembersSelector)Application.Selectors.newInstance(OpportunityTeamMembersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunityTeamMembersSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OpportunityTeamMembersSelector selector = (OpportunityTeamMembersSelector)Application.Selectors.newInstance(OpportunityTeamMembersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	} 

	public virtual override SObjectType getSObjectType() {
		return OpportunityTeamMember.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			OpportunityTeamMember.Id,OpportunityTeamMember.UserId, OpportunityTeamMember.TeamMemberRole, OpportunitySplit.OpportunityId
		};
	}  
    /**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, OpportunityTeamMember> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
    /**
	 * @description Run a simple query to get records based on account Id's
	 */
	public Map<Id, OpportunityTeamMember> selectByOpportunity(Set<Id> opportunitiesIds) {
		return selectByOpportunity(opportunitiesIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Account Id's
	 */
	public Map<Id, OpportunityTeamMember> selectByOpportunity(Set<Id> opportunitiesIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunityTeamMember.opportunityId + ' in :opportunitiesIds')).endConditions();
		return new Map<Id, OpportunityTeamMember>((List<OpportunityTeamMember>)Database.query(qb.toSoqlString()));
        
	}
    /**
	 * @description Run a simple query to get records based on account Id's
	 */
	public Map<Id, OpportunityTeamMember> selectByOpportunityAndUsers(Set<Id> opportunitiesIds, Set<Id> usersIds) {
		return selectByOpportunityAndUsers(opportunitiesIds, usersIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Account Id's
	 */
	public Map<Id, OpportunityTeamMember> selectByOpportunityAndUsers(Set<Id> opportunitiesIds, Set<Id> usersIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition(OpportunityTeamMember.opportunityId + ' in :opportunitiesIds'))
		.add(new QueryBuilder.SimpleCondition(OpportunityTeamMember.UserId + ' in :usersIds'))
		.endConditions();
		
        return new Map<Id, OpportunityTeamMember>((List<OpportunityTeamMember>)Database.query(qb.toSoqlString()));
        
	}
    
    /**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, OpportunityTeamMember> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunityTeamMember.Id + ' in :ids')).endConditions();
              
        return new Map<Id, OpportunityTeamMember>((List<OpportunityTeamMember>)Database.query(qb.toSoqlString()));
	}	
}