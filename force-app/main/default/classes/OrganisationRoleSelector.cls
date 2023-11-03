/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Deal Support Request
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-25 - Shashwat.nath@auspost.com.au - Created
 * 2022-02-18 - Naveen.Rajanna@auspost.com.au - INC1911242 - Include Role_Type__c field to do bug fix
 * 2023-10-30 - Ranjeewa Silva - New select methods to select by OrganisationId.
 */

public inherited sharing class OrganisationRoleSelector extends ApplicationSelector{
	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER , FILTER_PROSPECT_KNOWN
	}
	public static OrganisationRoleSelector newInstance() {
		return (OrganisationRoleSelector )Application.Selectors.newInstance(OrganisationRoleSelector .class);
	}
	public static OrganisationRoleSelector newInstance(Integer recordLimit) {
		return (OrganisationRoleSelector)Application.Selectors.newInstance(OrganisationRoleSelector.class).setLimit(recordLimit);
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static OrganisationRoleSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OrganisationRoleSelector selector = (OrganisationRoleSelector)Application.Selectors.newInstance(OrganisationRoleSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static OrganisationRoleSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OrganisationRoleSelector selector = (OrganisationRoleSelector)Application.Selectors.newInstance(OrganisationRoleSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	public virtual override SObjectType getSObjectType() {
		return Organisation_Role__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Organisation_Role__c.Id,Organisation_Role__c.Role_Type__c
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Organisation_Role__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */

	public virtual Map<Id, Organisation_Role__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Organisation_Role__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Organisation_Role__c>((List<Organisation_Role__c>)Database.query(qb.toSoqlString()));
	}

	public List<Organisation_Role__c> selectByOrganisationId(Set<Id> organisationIds) {
		return selectByOrganisationId(organisationIds, new Set<Object>());
	}

	public List<Organisation_Role__c> selectByOrganisationId(Set<Id> organisationIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Organisation_Role__c.Organisation__c + ' in :organisationIds')).endConditions();
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

		if(selectorOptions.contains(Options.FILTER_PROSPECT_KNOWN)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Organisation_Role__c.Role_Type__c).eq('Prospect')).endConditions();
			builder.addConditions().add(new QueryBuilder.CompareCondition(Organisation_Role__c.Role_Type__c).eq('Known')).setConditionOrder('1 OR 2').endConditions();
			//conditions.setConditionOrder('1 OR 2');
		}

		return builder;
	}
}