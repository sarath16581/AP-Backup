/* @author Dattaraj Deshmukh
 * @group Selector
 * @tag Selector
 * @tag PUD_Container__c
 * @domain PUD
 * @description A very simple selector class.
 * @changelog
 * 2022-06-28 - Dattaraj Deshmukh - Created
 */
public with sharing class PUDContainersSelector extends ApplicationSelector{
    public static PUDContainersSelector newInstance() {
		return (PUDContainersSelector)Application.Selectors.newInstance(PUDContainersSelector.class);
	}

	public static PUDContainersSelector newInstance(Integer recordLimit) {
		return (PUDContainersSelector)Application.Selectors.newInstance(PUDContainersSelector.class).setLimit(recordLimit);
    }

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static PUDContainersSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PUDContainersSelector selector = (PUDContainersSelector)Application.Selectors.newInstance(PUDContainersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	

	public virtual override SObjectType getSObjectType() {
		return PUD_Container__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			PUD_Container__c.Id, PUD_Container__c.Actual_Quantity__c, PUD_Container__c.Booking__c, PUD_Container__c.Condition__c, PUD_Container__c.Expected_Quantity__c,
			PUD_Container__c.Job__c, PUD_Container__c.Type__c,PUD_Container__c.RecordTypeId
		};
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Container__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Container__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Container__c.Id + ' in :ids')).endConditions();       
        return (List<PUD_Container__c>)Database.query(qb.toSoqlString());
	}

    /**
	* @description Run a simple query to get records based on Job__c Id's
	*/
    public virtual List<PUD_Container__c> selectByJobIds(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Container__c.Job__c + ' in :ids')).endConditions();       
        return (List<PUD_Container__c>)Database.query(qb.toSoqlString());
	}
	
    
	/**
	* @description Run a simple query to get records based on Job__c Id's
	*/
    public virtual List<PUD_Container__c> selectByBookingIds(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Container__c.Booking__c + ' in :ids')).endConditions();       
        return (List<PUD_Container__c>)Database.query(qb.toSoqlString());
	}
	
    
	
}
