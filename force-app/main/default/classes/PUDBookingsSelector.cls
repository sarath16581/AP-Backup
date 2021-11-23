/* @author Arjun Singh
 * @group Selector
 * @tag Selector
 * @tag PUD Booking
 * @domain PUD
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-08-13 - arjun.singh@austpost.com.au - Created
 */
public virtual inherited sharing class PUDBookingsSelector extends ApplicationSelector{
    public static PUDBookingsSelector newInstance() {
		return (PUDBookingsSelector)Application.Selectors.newInstance(PUDBookingsSelector.class);
	}
    public static PUDBookingsSelector newInstance(Integer recordLimit) {
		return (PUDBookingsSelector)Application.Selectors.newInstance(PUDBookingsSelector.class).setLimit(recordLimit);
    }
    /**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static PUDBookingsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PUDBookingsSelector selector = (PUDBookingsSelector)Application.Selectors.newInstance(PUDBookingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
    /**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static PUDBookingsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDBookingsSelector selector = (PUDBookingsSelector)Application.Selectors.newInstance(PUDBookingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	public virtual override SObjectType getSObjectType() {
		return PUD_Booking__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			PUD_Booking__c.Id, PUD_Booking__c.Status__c, PUD_Booking__c.Article_Count__c, PUD_Booking__c.Parent_Booking__c
		};
	}
	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Booking__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}    
	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Booking__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Booking__c.Id + ' in :ids')).endConditions();       
        return (List<PUD_Booking__c>)Database.query(qb.toSoqlString());
	}
	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Booking__c> selectByParentBookingId(Set<Id> ids) {
		return selectByParentBookingId(ids, new Set<Object>());
	}    
	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Booking__c> selectByParentBookingId(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Booking__c.Parent_Booking__c + ' in :ids')).endConditions();       
        return (List<PUD_Booking__c>)Database.query(qb.toSoqlString());
	}
	
}