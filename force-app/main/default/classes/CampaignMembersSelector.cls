/* @author Mathew Jose
 * @group Selector
 * @tag Selector
 * @tag CampaignMember
 * @domain 
 * @description A very simple selector class.
 * @changelog
 * 2021-12-21 - Mathew Jose - Created
 * 2022-02-02 - Nathan Franklin - Added search method and updated child selectors to pass selectorOptions
 */
public virtual inherited sharing class CampaignMembersSelector extends ApplicationSelector{
	
	public enum Options {
		WITH_CONTACT, WITH_CAMPAIGN,

		// Filter to ensure only records with contact ids are returned
		FILTER_CONTACTS_ONLY
	}


	public static CampaignMembersSelector newInstance() {
		return (CampaignMembersSelector)Application.Selectors.newInstance(CampaignMembersSelector.class);
	}

	public static CampaignMembersSelector newInstance(Integer recordLimit) {
		return (CampaignMembersSelector)Application.Selectors.newInstance(CampaignMembersSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static CampaignMembersSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		CampaignMembersSelector selector = (CampaignMembersSelector)Application.Selectors.newInstance(CampaignMembersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static CampaignMembersSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CampaignMembersSelector selector = (CampaignMembersSelector)Application.Selectors.newInstance(CampaignMembersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return CampaignMember.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			CampaignMember.Id, CampaignMember.CampaignId, CampaignMember.ContactId,CampaignMember.LeadId,CampaignMember.Status		   
		};
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<CampaignMember> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<CampaignMember> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(CampaignMember.Id + ' in :ids')).endConditions();	   
		return (List<CampaignMember>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 campaignIds: maps to Campaign (Set<Id>/Id)
	 *						 contactIds: maps to Contact (Set<Id>/Id)
	 *						 statuses: maps to Status (Set<String>/String) -> It goes without saying, do not search for this attribute alone :)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<CampaignMember> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		QueryBuilder builder = newQueryBuilder(selectorOptions);

		// add our tracking query
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Set<Id> campaignIds = (Set<Id>)(searchParams.get('campaignIds') == null ? new Set<Id>() : (searchParams.get('campaignIds') instanceof Set<Id> ? searchParams.get('campaignIds') : new Set<Id>{(Id)searchParams.get('campaignIds')}));
		Set<Id> contactIds = (Set<Id>)(searchParams.get('contactIds') == null ? new Set<Id>() : (searchParams.get('contactIds') instanceof Set<Id> ? searchParams.get('contactIds') : new Set<Id>{(Id)searchParams.get('contactIds')}));
		Set<String> statuses = (Set<String>)(searchParams.get('statuses') == null ? new Set<String>() : (searchParams.get('statuses') instanceof Set<String> ? searchParams.get('statuses') : new Set<String>{String.valueOf(searchParams.get('statuses'))}));

		Integer conditionCount = 0;
		if(searchParams.containsKey('campaignIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(CampaignMember.CampaignId + ' in :campaignIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('contactIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(CampaignMember.ContactId + ' in :contactIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('statuses')) {
			conditions.add(new QueryBuilder.SimpleCondition(CampaignMember.Status + ' in :statuses'));
			conditionCount++;
		}

		// build our condition string which would end up being something liek the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		String soql = conditions.endConditions().toSoqlString();
		return (List<CampaignMember>)Database.query(soql);
	}

	/**
	* @description Run a simple query to get records based on Campaign Id's
	*/
	public virtual List<CampaignMember> selectByCampaignId(Set<Id> campaignIds) {
		return selectByCampaignId(campaignIds, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Campaign Id's
	*/
	public virtual List<CampaignMember> selectByCampaignId(Set<Id> campaignIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().
															add(new QueryBuilder.SimpleCondition(CampaignMember.CampaignId + ' in :campaignIds')).endConditions();
		return (List<CampaignMember>)Database.query(qb.toSoqlString());
	}	
	
	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(selectorOptions), 'Contact');
		}
		if(selectorOptions.contains(Options.WITH_CAMPAIGN)) {
			builder.addRelatedFields(CampaignsSelector.newInstance().newQueryBuilder(selectorOptions), 'Campaign');
		}
		if (selectorOptions.contains(Options.FILTER_CONTACTS_ONLY)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(CampaignMember.ContactId + ' != null')).endConditions();
		}				
		return builder;
	}

}