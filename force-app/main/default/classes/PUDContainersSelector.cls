/* @author Dattaraj Deshmukh
 * @group Selector
 * @tag Selector
 * @tag PUD_Container__c
 * @domain PUD
 * @description A very simple selector class.
 * @changelog
 * @test PUDContainersSelector_Test
 * 2022-06-28 - Dattaraj Deshmukh - Created
 */
public inherited sharing class PUDContainersSelector extends ApplicationSelector{
	public enum Options {
		FILTER_BOOKING_CONTAINERS
	}

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

		/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDContainersSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDContainersSelector selector = (PUDContainersSelector)Application.Selectors.newInstance(PUDContainersSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static PUDContainersSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDContainersSelector selector = (PUDContainersSelector) Application.Selectors.newInstance(PUDContainersSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}


	

	public virtual override SObjectType getSObjectType() {
		return PUD_Container__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			PUD_Container__c.Id, PUD_Container__c.Actual_Quantity__c, PUD_Container__c.Booking__c, PUD_Container__c.Condition__c, PUD_Container__c.Expected_Quantity__c,
			PUD_Container__c.Job__c, PUD_Container__c.Type__c,PUD_Container__c.RecordTypeId, PUD_Container__c.RecordType.Name
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
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
		.add(new QueryBuilder.SimpleCondition(PUD_Container__c.Job__c + ' in :ids'))
		.endConditions();   

		return (List<PUD_Container__c>)Database.query(qb.toSoqlString());
	}
	
	/**
	* @description Run a simple query to get records based on Job__c Id's
	*/
	public virtual List<PUD_Container__c> selectBookingContainersByBookingIds(Set<Id> ids, Set<Object> selectorOptions) {
		return selectByBookingIds(ids, new Set<String> {PUDConstants.PUD_BOOKING_CONTAINER_RECORD_TYPE}, new Set<Object>());
	}
	

	/**
	* @description Run a simple query to get records based on Job__c Id's
	*/
	public virtual List<PUD_Container__c> selectByBookingIds(Set<Id> bookingIds, Set<String> recordTypes, Set<Object> selectorOptions) {

		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();

		conditions.add(new QueryBuilder.SimpleCondition(PUD_Container__c.Booking__c  + ' in :bookingIds'));

		if (recordTypes != null && !recordTypes.isEmpty()) {
			
			conditions.add(new QueryBuilder.SimpleCondition('PUD_Container__c.RecordType.DeveloperName '+ ' in :recordTypes'));
			conditions.setConditionOrder('1 AND 2');
		} 

		String soql = conditions.endConditions().toSoqlString();
		return (List<PUD_Container__c>)Database.query(soql);
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	/**
	 * Grabs a new QueryBuilder based on the selector options passed in
	 *
	 * @param selectorOptions set of additional selector options to augment the result set
	 * @return new QueryBuilder instance
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.FILTER_BOOKING_CONTAINERS)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition('RecordType.DeveloperName').eq(PUDConstants.PUD_BOOKING_CONTAINER_RECORD_TYPE)).endConditions();
		}
		return builder;
	}

	
	
	
}