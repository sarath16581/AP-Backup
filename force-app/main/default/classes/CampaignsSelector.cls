/* @author Mathew Jose
 * @group Selector
 * @tag Selector
 * @tag Campaign
 * @domain 
 * @description A very simple selector class.
 * @changelog
 * 2022-01-15 - Mathew Jose - Created
 * 2022-02-02 - Nathan Franklin - Updated child selectors to pass selectorOptions
 */
public virtual inherited sharing class CampaignsSelector extends ApplicationSelector{

	public enum Options {
		WITH_CAMPAIGNMEMBERS, WITH_CONTACTASSIGMENTS
	}
	
	public static CampaignsSelector newInstance() {
		return (CampaignsSelector)Application.Selectors.newInstance(CampaignsSelector.class);
	}

	public static CampaignsSelector newInstance(Integer recordLimit) {
		return (CampaignsSelector)Application.Selectors.newInstance(CampaignsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static CampaignsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		CampaignsSelector selector = (CampaignsSelector)Application.Selectors.newInstance(CampaignsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Campaign.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Campaign.Id, Campaign.ContactAssignmentDefaultStatus__c	   
		};
	}
	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<Campaign> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<Campaign> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Campaign.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());

	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CAMPAIGNMEMBERS)) {
			// remove the risk of recursion if selector options also include CampaignMembersSelector.Options.WITH_CAMPAIGN (for whatever reason)
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_CAMPAIGNMEMBERS);
			builder.addSubQuery(CampaignMembersSelector.newInstance().newQueryBuilder(clonedOptions), 'CampaignMembers');
		}

		if(selectorOptions.contains(Options.WITH_CONTACTASSIGMENTS)) {
			builder.addSubQuery(CampaignContactAssignmentsSelector.newInstance().newQueryBuilder(new Set<Object>{CampaignContactAssignmentsSelector.Options.WITH_ORGANISATION}), 'Campaign_Contact_Assignments__r');
		}

		return builder;
	}	
	
}