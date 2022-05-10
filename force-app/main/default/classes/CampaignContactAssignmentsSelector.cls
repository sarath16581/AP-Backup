/* @author Mathew Jose
 * @group Selector
 * @tag Selector
 * @tag CampaignContactAssignment__c
 * @domain 
 * @description A very simple selector class.
 * @changelog
 * 2021-12-21 - Mathew Jose - Created
 */
	
public virtual inherited sharing class CampaignContactAssignmentsSelector extends ApplicationSelector{
	
	public enum Options {
		WITH_CONTACT, WITH_ORGANISATION
	}


	public static CampaignContactAssignmentsSelector newInstance() {
		return (CampaignContactAssignmentsSelector)Application.Selectors.newInstance(CampaignContactAssignmentsSelector.class);
	}

	public static CampaignContactAssignmentsSelector newInstance(Integer recordLimit) {
		return (CampaignContactAssignmentsSelector)Application.Selectors.newInstance(CampaignContactAssignmentsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static CampaignContactAssignmentsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		CampaignContactAssignmentsSelector selector = (CampaignContactAssignmentsSelector)Application.Selectors.newInstance(CampaignContactAssignmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static CampaignContactAssignmentsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CampaignContactAssignmentsSelector selector = (CampaignContactAssignmentsSelector)Application.Selectors.newInstance(CampaignContactAssignmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return CampaignContactAssignment__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			CampaignContactAssignment__c.Id,CampaignContactAssignment__c.Contact__c, CampaignContactAssignment__c.Organisation__c, CampaignContactAssignment__c.Campaign__c, CampaignContactAssignment__c.Description__c		 
		};
	}
	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<CampaignContactAssignment__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<CampaignContactAssignment__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(CampaignContactAssignment__c.Id + ' in :ids')).endConditions();	   
		return (List<CampaignContactAssignment__c>)Database.query(qb.toSoqlString());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<CampaignContactAssignment__c> selectByCampaignAndContact(Set<Id> campaignIds, Set<Id> contactIds,  Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().
															add(new QueryBuilder.SimpleCondition(CampaignContactAssignment__c.Campaign__c + ' in :campaignIds')).
															add(new QueryBuilder.SimpleCondition(CampaignContactAssignment__c.Contact__c + ' in :contactIds')).endConditions();	   
		return (List<CampaignContactAssignment__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(selectorOptions), 'Contact__r');
		}
		if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(selectorOptions), 'Organisation__r');
		}			
		return builder;
	}		

}