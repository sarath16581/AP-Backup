/* @author Arjun Singh
 * @group Selector
 * @tag Selector
 * @tag PUD Booking
 * @domain PUD
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-08-13 - arjun.singh@austpost.com.au - Created
 * 2022-03-13 - Ranjeewa Silva - Added support for more selector options.
 */
public virtual inherited sharing class PUDBookingsSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE, WITH_ROUTE, WITH_PARENT_BOOKING
	}

	public static PUDBookingsSelector newInstance() {
		return (PUDBookingsSelector) Application.Selectors.newInstance(PUDBookingsSelector.class);
	}

	public static PUDBookingsSelector newInstance(Integer recordLimit) {
		return (PUDBookingsSelector) Application.Selectors.newInstance(PUDBookingsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static PUDBookingsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PUDBookingsSelector selector = (PUDBookingsSelector) Application.Selectors.newInstance(PUDBookingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static PUDBookingsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDBookingsSelector selector = (PUDBookingsSelector) Application.Selectors.newInstance(PUDBookingsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static PUDBookingsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PUDBookingsSelector selector = (PUDBookingsSelector) Application.Selectors.newInstance(PUDBookingsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return PUD_Booking__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				PUD_Booking__c.Id, PUD_Booking__c.Name, PUD_Booking__c.Status__c, PUD_Booking__c.Article_Count__c, PUD_Booking__c.Parent_Booking__c,
				PUD_Booking__c.Route_Lookup__c, PUD_Booking__c.Start_Time__c, PUD_Booking__c.Booking_Comments__c,
				PUD_Booking__c.Display_Start_Time__c, PUD_Booking__c.Dwell_Time_Planned__c, PUD_Booking__c.Street__c,
				PUD_Booking__c.City__c, PUD_Booking__c.State__c, PUD_Booking__c.Post_Code__c, PUD_Booking__c.Booking_Type__c,
				PUD_Booking__c.RecordTypeId, PUD_Booking__c.Location__c, PUD_Booking__c.Booking_Location_Street__c, PUD_Booking__c.Booking_Location_City__c,
				PUD_Booking__c.Booking_Location_Name_LU__c, PUD_Booking__c.Comments__c,PUD_Booking__c.Key_Number__c, PUD_Booking__c.Dock_Number__c
		};
	}

	/**
	 * Define the ordering applied for results returned by this selector.
	 * @return default ordering
	 */
	public override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{
				new QueryBuilder.Order('Start_Time__c', 'Asc')
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
		return (List<PUD_Booking__c>) Database.query(qb.toSoqlString());
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
		return (List<PUD_Booking__c>) Database.query(qb.toSoqlString());
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
		if (selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}
		if (selectorOptions.contains(Options.WITH_ROUTE)) {
			builder.addRelatedFields(PUDRoutesSelector.newInstance(fieldOverrides).newQueryBuilder(), 'Route_Lookup__r');
		}
		if (selectorOptions.contains(Options.WITH_PARENT_BOOKING)) {
			builder.addRelatedFields(PUDBookingsSelector.newInstance(fieldOverrides).newQueryBuilder(), 'Parent_Booking__r');
		}
		return builder;
	}
}