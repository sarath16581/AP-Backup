/**
 * @author Ranjeewa Silva
 * @date 2022-03-18
 * @group Selector
 * @tag Selector
 * @tag PUD_Route__c
 * @domain PUD
 * @description A very simple selector class that sits in PUD domain
 * @changelog
 * 2022-03-18 - Ranjeewa Silva - Created
 * 2022-07-06 - Kamil Szyc added selectByIdWithAllBookings method for printing full duty board
 * 2022-07-14 - Kamil Szyc added selectByIdWithJobs for selecting routes with jobs
 * 2022-07-21 - Kamil Szyc added getChildJobsSubQueryBuilder for building jobs query
 * 2022-09-21 - Ranjeewa Silva - Refactored to introduce new selector method inplace of selectByIdWithAllBookings
 */
public virtual inherited sharing class PUDRoutesSelector extends ApplicationSelector {
	public enum Options {
		WITH_DEPOT
	}
	public static PUDRoutesSelector newInstance() {
		return (PUDRoutesSelector) Application.Selectors.newInstance(PUDRoutesSelector.class);
	}

	public static PUDRoutesSelector newInstance(Integer recordLimit) {
		return (PUDRoutesSelector) Application.Selectors.newInstance(PUDRoutesSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDRoutesSelector newInstance(Set<SObjectField> fieldOverrides) {
		PUDRoutesSelector selector = (PUDRoutesSelector) Application.Selectors.newInstance(PUDRoutesSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDRoutesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PUDRoutesSelector selector = (PUDRoutesSelector) Application.Selectors.newInstance(PUDRoutesSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDRoutesSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDRoutesSelector selector = (PUDRoutesSelector) Application.Selectors.newInstance(PUDRoutesSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static PUDRoutesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDRoutesSelector selector = (PUDRoutesSelector) Application.Selectors.newInstance(PUDRoutesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return PUD_Route__c.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				PUD_Route__c.Id, PUD_Route__c.Name, PUD_Route__c.Depot__c
		};
	}

	public override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{
				new QueryBuilder.Order('Name', 'Asc')
		};
	}

	/**
	 * Run a simple query to get records based on Id's
	 * @param ids route ids
	 *
	 * @return list of route records
	 */
	public virtual List<PUD_Route__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * Run a simple query to get records based on Id's
	 * @param ids route ids
	 * @param selectorOptions additional selector options
	 *
	 * @return list of route records
	 */
	public virtual List<PUD_Route__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Route__c.Id + ' in :ids')).endConditions();
		return ((List<PUD_Route__c>) Database.query(qb.toSoqlString()));
	}

	/**
	 * Query routes based on Id's. Query results also include Active child bookings based on the booking record type ids.
	 *
	 * @param ids route ids to query
	 * @param bookingRecordTypeIds booking record type ids to filter active bookings (Optional). include all active bookings
	 *							 if not supplied.
	 *
	 * @return list of route records. result set include active child bookings matching the record type ids passed in.
	 */
	public virtual List<PUD_Route__c> selectByIdWithActiveBookings(Set<Id> ids, Set<Id> bookingRecordTypeIds) {
		return selectByIdWithActiveBookings(ids, bookingRecordTypeIds, new Set<Object>());
	}

	/**
	 * Query routes based on Id's. Query results also include Active child bookings based on the booking record type ids.
	 *
	 * @param ids route ids to query
	 * @param bookingRecordTypeIds booking record type ids to filter active bookings (Optional). include all active bookings
	 *							 if not supplied.
	 * @param selectorOptions additional selector options
	 *
	 * @return list of route records. result set include active child bookings matching the record type ids passed in.
	 */
	public virtual List<PUD_Route__c> selectByIdWithActiveBookings(Set<Id> ids, Set<Id> bookingRecordTypeIds, Set<Object> selectorOptions) {
		return selectByIdWithBookings(ids, new Set<String>{PUDConstants.PUD_BOOKING_STATUS_ACTIVE}, bookingRecordTypeIds, selectorOptions);
	}

	/**
	 * Query routes based on Id's. Query results also include child bookings based on the booking record type ids and the status.
	 *
	 * @param ids route ids to query
	 * @param bookingStatus booking status to filter bookings (Optional). include all bookings in all status if not supplied.
	 * @param bookingRecordTypeIds booking record type ids to filter bookings (Optional). include bookings in all record types
	 *							 if not supplied.
	 *
	 * @return list of route records. result set include child bookings matching the record type ids and status passed in.
	 */
	public virtual List<PUD_Route__c> selectByIdWithBookings(Set<Id> ids, Set<String> bookingStatus, Set<Id> bookingRecordTypeIds) {
		return selectByIdWithBookings(ids, bookingStatus, bookingRecordTypeIds, new Set<Object>());
	}

	/**
	 * Query routes based on Id's. Query results also include child bookings based on the booking record type ids and the status.
	 *
	 * @param ids route ids to query
	 * @param bookingStatus booking status to filter bookings (Optional). include all bookings in all status if not supplied.
	 * @param bookingRecordTypeIds booking record type ids to filter bookings (Optional). include bookings in all record types
	 *							 if not supplied.
	 * @param selectorOptions additional selector options
	 *
	 * @return list of route records. result set include child bookings matching the record type ids and status passed in.
	 */
	public virtual List<PUD_Route__c> selectByIdWithBookings(Set<Id> ids, Set<String> bookingStatus, Set<Id> bookingRecordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PUD_Route__c.Id + ' in :ids')).endConditions();
		qb.addSubQuery(getChildBookingsSubQueryBuilder(bookingStatus, bookingRecordTypeIds, selectorOptions), 'Bookings__r');
		return ((List<PUD_Route__c>) Database.query(qb.toSoqlString()));
	}

	/**
	 * Returns a Query Builder for child bookings based on the record types, status and selector options passed in.
	 *
	 * @param bookingStatus status to filter bookings
	 * @param bookingRecordTypeIds record type ids to filter the bookings. optional.
	 * @param selectorOptions set of additional selector options to augment the child bookings result set
	 *
	 * @return query builder instance for child bookings.
	 */
	private QueryBuilder getChildBookingsSubQueryBuilder(Set<String> bookingStatus, Set<Id> bookingRecordTypeIds, Set<Object> selectorOptions) {

		QueryBuilder subQueryBuilder = PUDBookingsSelector.newInstance(fieldOverrides).newQueryBuilder(selectorOptions);

		QueryBuilder.ConditionsManager subQueryConditions = subQueryBuilder.addConditions();
		if (bookingStatus != null && !bookingStatus.isEmpty()) {
			subQueryConditions.add(new QueryBuilder.SimpleCondition(PUD_Booking__c.Status_Calc__c + ' in :bookingStatus'));
		}
		if (bookingRecordTypeIds != null && !bookingRecordTypeIds.isEmpty()) {
			subQueryConditions.add(new QueryBuilder.SimpleCondition(PUD_Booking__c.RecordTypeId + ' in :bookingRecordTypeIds'));
		}
		subQueryConditions.endConditions();

		return subQueryBuilder;
	}

	/**
	 * Query routes based on Id's. Query results also include Active child bookings based on the booking record type ids.
	 * NOTE: To avoid enforcing filtering by groups to which the user belongs, provide null value for depotIds
	 * @param ids route ids to query
	 * @param bookingRecordTypes set of booking record types of the jobs to be returned
	 * @param jobDates set of dates
	 * @param depotIds ids of the parent depot records. Set to NULL if the method should not filter the results by public groups to which user belongs to
	 * @param selectorOptions additional selector options
	 *
	 * @return list of route records. result set include active child bookings matching the record type ids passed in.
	 */
	public virtual List<PUD_Route__c> selectByIdAndDepotWithJobs(Set<Id> ids, Set<Id> depotIds, Set<String> bookingRecordTypes, Set<Date> jobDates, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(PUD_Route__c.Id + ' IN :ids'))
				.endConditions();
		if (depotIds != null) {
			qb.addConditions().add(new QueryBuilder.SimpleCondition(PUD_Route__c.Depot__c + ' IN :depotIds')).endConditions();
		}
		qb.addSubQuery(getChildJobsSubQueryBuilder(jobDates, bookingRecordTypes, selectorOptions)
				, 'Jobs__r');
		return ((List<PUD_Route__c>) Database.query(qb.toSoqlString()));
	}
	/**
	 * Returns a Query Builder for child jobs based on the record types, status and selector options passed in.
	 *
	 * @param dates jobs dates
	 * @param bookingRecordTypes record type ids to filter the jobs. optional.
	 * @param selectorOptions set of additional selector options to augment the child bookings result set
	 *
	 * @return query builder instance for child bookings.
	 */
	private QueryBuilder getChildJobsSubQueryBuilder(Set<Date> dates, Set<String> bookingRecordTypes, Set<Object> selectorOptions) {
		selectorOptions.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);
		QueryBuilder jobsQb = PUDJobsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager subQueryConditions = jobsQb.addConditions();
		if (!bookingRecordTypes.isEmpty()) {
			subQueryConditions.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Booking_Record_Type__c + ' IN :bookingRecordTypes'));
		}
		if (!dates.isEmpty()) {
			subQueryConditions.add(new QueryBuilder.SimpleCondition(PUD_Job__c.Date__c + ' IN :jobDates'));
		}
		subQueryConditions.endConditions();
		jobsQb.addOrderAsc(PUD_Job__c.Date__c)
				.addOrderAsc(PUD_Job__c.Start_Time__c);

		return jobsQb;
	}

	/**
	 * Grabs a new QueryBuilder based on the selector options passed in
	 *
	 * @param selectorOptions set of additional selector options to augment the result set
	 * @return new QueryBuilder instance
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_DEPOT)) {
			builder.addRelatedFields(PUDNetworksSelector.newInstance(fieldOverrides).newQueryBuilder(), 'Depot__r');
		}
		return builder;
	}
}