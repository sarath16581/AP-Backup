/* @author Arjun Singh
 * @group Selector
 * @tag Selector
 * @tag PUD_Job__c
 * @domain PUD
 * @description A very simple selector class.
 * @changelog
 * 2021-07-27 - Arjun Sing - Created
 * 2021-11-11 - Ranjeewa Silva - Added more fields to the set of selected fields.
 * 2022-07-19 - Dattaraj Deshmukh - Added Options enum. Added overriden QueryBuilder method.
 */
public virtual inherited sharing class PUDJobsSelector extends ApplicationSelector{

	public enum Options {
		WITH_CONTAINERS
	}

	public static PUDJobsSelector newInstance() {
		return (PUDJobsSelector)Application.Selectors.newInstance(PUDJobsSelector.class);
	}

	public static PUDJobsSelector newInstance(Integer recordLimit) {
		return (PUDJobsSelector)Application.Selectors.newInstance(PUDJobsSelector.class).setLimit(recordLimit);
    }

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static PUDJobsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PUDJobsSelector selector = (PUDJobsSelector)Application.Selectors.newInstance(PUDJobsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/	
	public static PUDJobsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDJobsSelector selector = (PUDJobsSelector)Application.Selectors.newInstance(PUDJobsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return PUD_Job__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			PUD_Job__c.Id, PUD_Job__c.Date__c, PUD_Job__c.Depot__c, PUD_Job__c.Name, PUD_Job__c.Send_to_Dispatch_System__c,
			PUD_Job__c.Status__c, PUD_Job__c.Stop_Credit__c,PUD_Job__c.Booking__c, PUD_Job__c.Schedule_Request_Timestamp__c,
			PUD_Job__c.Cancellation_Request_Timestamp__c, PUD_Job__c.Schedule_Confirmed_Timestamp__c, PUD_Job__c.Last_Pushed_to_Dispatch_System__c,
			PUD_Job__c.Cancellation_Confirmed_Timestamp__c, PUD_Job__c.Containers_Payload__c
		};
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Job__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<PUD_Job__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Job__c.Id + ' in :ids')).endConditions();       
		return (List<PUD_Job__c>)Database.query(qb.toSoqlString());
	}

    public virtual Database.QueryLocator selectJobsByDateAndStatusQueryLocator(Date fromDate, Date toDate, String statusVar) {
		QueryBuilder qb = selectJobsByDateAndStatusQueryLocator(fromDate, toDate, statusVar, new Set<Object>());
        return Database.getQueryLocator(qb.toSoqlString());
	}
	
	/**
    * @description : simple query to get records based on date flag, status flag and send to dispatch system flag
    */
	public virtual QueryBuilder selectJobsByDateAndStatusQueryLocator(Date fromDate, Date toDate, String statusVar, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Date__c + ' >= :fromDate'))
		.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Date__c + ' <= :toDate'))
		.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Status__c + ' = :statusVar'))
		.endConditions();
		
        return qb;        
    }

	/**
	 * @description Run a simple query to get records based on Booking Id's and the from date and status
	 *
	 * @param bookingIds set of parent booking ids
	 * @param fromDate from date to filter jobs (inclusive)
	 * @param jobStatus set of status to filter jobs
	 *
	 * @return list of jobs
	 */
	public List<PUD_Job__c> selectByBookingIdStatusAndFromDate(Set<Id> bookingIds, Date fromDate, Set<String> jobStatus) {
		return selectByBookingIdStatusAndFromDate(bookingIds, fromDate, jobStatus, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Booking Id's and the from date and status
	 *
	 * @param bookingIds set of parent booking ids
	 * @param fromDate from date to filter jobs (inclusive)
	 * @param jobStatus set of status to filter jobs
	 * @param selectorOptions selector options
	 *
	 * @return list of jobs
	 */
	public List<PUD_Job__c> selectByBookingIdStatusAndFromDate(Set<Id> bookingIds, Date fromDate, Set<String> jobStatus, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions)
						 	.addConditions()
							.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Booking__c + ' in :bookingIds'))
							.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Date__c + ' >= :fromDate'))
							.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Status__c + ' = :jobStatus'))
							.endConditions();       
        return (List<PUD_Job__c>)Database.query(qb.toSoqlString());
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
		if (selectorOptions.contains(Options.WITH_CONTAINERS)) {
			builder.addSubQuery(PUDContainersSelector.newInstance(fieldOverrides).newQueryBuilder(), 'Containers__r');
		}
		return builder;
	}
	
}