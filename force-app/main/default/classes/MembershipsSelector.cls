/**
*@author Disha Kariya
* @date 2020-05-08
* @group Selector
* @tag Selector
* @tag Membership__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - Disha Kariya - Created
 */

public virtual inherited sharing class MembershipsSelector extends ApplicationSelector {

    public enum Options {
        FILTER_ACTIVE_STATUS
    }

    public static MembershipsSelector newInstance() {
        return (MembershipsSelector)Application.Selectors.newInstance(MembershipsSelector.class);
    }
    public static MembershipsSelector newInstance(Integer recordLimit) {
        return (MembershipsSelector)Application.Selectors.newInstance(MembershipsSelector.class).setLimit(recordLimit);
    }

    public override SObjectType getSObjectType() {
        return Membership__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                Membership__c.Id, Membership__c.Status__c, Membership__c.Licensee_Type__c
        };
    }

    /**
	 * @description Run a simple query to get records based on Id's
	 */
    public Map<Id, Membership__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
	 * @description Run a simple query to get records based on Id's
	 */
    public Map<Id, Membership__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Membership__c.Id + ' in :ids')).endConditions();
        System.debug(qb.toSoqlString());
        return new Map<Id, Membership__c>((List<Membership__c>)Database.query(qb.toSoqlString()));
    }
    
	
    /**
	 * Select Memberships based on Record Type Names
	 * @param ids list of Membership Ids.
	 * @param recordTypeIds If supplied, Only select Memberships for the Record Type names passed in. 
	 * @return matching Membership records
	 */
	public virtual Map<Id, Membership__c> selectByRecordTypeNames(Set<Id> ids,Set<Object> selectorOptions,Set<String> recordTypeNames) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition(Membership__c.Id + ' in :ids'));
		if (recordTypeNames != null && !recordTypeNames.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('RecordType.' + RecordType.Name + ' in :recordTypeNames'));
		} 
		String soql = conditions.endConditions().toSoqlString();
		return new Map<Id, Membership__c>((List<Membership__c>)Database.query(soql));
	}

    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if (selectorOptions.contains(Options.FILTER_ACTIVE_STATUS)) {
            builder.addConditions().add(new QueryBuilder.CompareCondition(Membership__c.Status__c).eq('Active')).endConditions();
        }

        return builder;
    }
}