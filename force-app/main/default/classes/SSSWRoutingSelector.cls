/* @author Seth Heang
 * @date 2020-12-18
 * @group Selector
 * @tag Selector
 * @tag SSSWRouting__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 */
public virtual inherited sharing class SSSWRoutingSelector extends ApplicationSelector {
    public enum Options {
    }

    public static SSSWRoutingSelector newInstance() {
        return (SSSWRoutingSelector)Application.Selectors.newInstance(SSSWRoutingSelector.class);
    }
    public static SSSWRoutingSelector newInstance(Integer recordLimit) {
        return (SSSWRoutingSelector)Application.Selectors.newInstance(SSSWRoutingSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return SSSWRouting__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            SSSWRouting__c.Id,SSSWRouting__c.RecordTypeId, SSSWRouting__c.Credit_Person_Code__c, SSSWRouting__c.DSR_Queue_Name__c , 
            SSSWRouting__c.Credit_Representative_Email__c, SSSWRouting__c.Credit_DSR_Routing__c 
        };
    }

	/**
	 * @description Run a simple query to get records based on opportunity Id's
	 */
	public virtual Map<Id, SSSWRouting__c> selectByRecordTypeId(Set<Id> ids) {
		return selectByRecordTypeId(ids, new Set<Object>());
    }
    
    /**
     * @description Run a simple query to get records based on record type Id's
     */
    public virtual Map<Id, SSSWRouting__c> selectByRecordTypeId(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
        .add(new QueryBuilder.SimpleCondition(SSSWRouting__c.RecordTypeId + ' = :ids'))
        .endConditions();
        return new Map<Id, SSSWRouting__c>((List<SSSWRouting__c>)Database.query(qb.toSoqlString()));
    }
}