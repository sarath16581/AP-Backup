/**
 * @description Order any List of SObjects by a single field
 * 	NOTE:
 * 	- Type:		Wrapper class for SObjects that makes them comparable
 * 	- Purpose:	Makes an SObject comparable by the given Number type field
 * 	- Used By: 	for eg to sort a list of SObjects based on a Number field value
 * @author Mohamed.Atheek@bluewolf.com
 * @date 2014/01/14
 * @group
 * @tag Util
 *
 * @changelog:
 * 	2024-08-27 - Paul Perry - modified 	
 *	- Rewritten to extend its capabilities sorting on all kinds of fields required for GenesysAttributeSync
 *  	- Sorting on any field
 *  	- Order ASC/DESC
 */
public without sharing class ComparableSObjectWrapper implements Comparable {
	/**
	 * Returns provided list sorted by give orderByField and sortDirection on default Ascending order
	 * @param recordList - List of SObjects
	 * @param orderByField - SObjectField to sort by
	 */
	public static List<SObject> sortRecords(List<SObject> recordList, SObjectField orderByField) {
		return sortRecords(recordList, orderByField, 'ASC');
	}

	/**
	 * Returns provided list sorted by give orderByField and sortDirection on default Ascending order
	 * @param recordList - List of SObjects
	 * @param orderByField - String of FieldApiName to sort by
	 */
	public static List<SObject> sortRecords(List<SObject> recordList, String orderByField) {
		return sortRecords(recordList, orderByField, 'ASC');
	}

	/**
	 * Returns provided list sorted by give orderByField and sortDirection
	 * @param recordList - List of SObjects
	 * @param orderByField - SObjectField to sort by
	 * @param sortDirection - ASC or DESC
	 */
	public static List<SObject> sortRecords(List<SObject> recordList, SObjectField orderByField, String sortDirection) {
		return sortRecords(recordList, String.valueOf(orderByField), sortDirection);
	}

	/**
	 * Returns provided list sorted by give orderByField and sortDirection
	 * @param recordList - List of SObjects
	 * @param orderByField - String of FieldApiName to sort by
	 * @param sortDirection - ASC or DESC
	 */
	public static List<SObject> sortRecords(List<SObject> recordList, String orderByField, String sortDirection) {
		// Validate input parameters
		if (recordList == null || recordList.isEmpty() || orderByField == null || String.isBlank(sortDirection)) {
			return recordList;
		}

		// Normalize sort direction
		sortDirection = sortDirection.toUpperCase();

		if (sortDirection != 'ASC' && sortDirection != 'DESC') {
			sortDirection = 'ASC';
		}

		// Create a list of wrapper objects for sorting
		List<ComparableSObjectWrapper> wrapperList = new List<ComparableSObjectWrapper>();

		for (SObject record :recordList) {
			ComparableSObjectWrapper comparisonInstance = new ComparableSObjectWrapper(record, orderByField);
			wrapperList.add(comparisonInstance);
		}

		// Sort the wrapper list
		wrapperList.sort();

		// Create the sorted SObject list
		List<SObject> sortedList = new List<SObject>();

		for (ComparableSObjectWrapper wrapper :wrapperList) {
			if (sortedList.isEmpty() || sortDirection == 'ASC') {
				sortedList.add(wrapper.sObj);
			} else {
				// Descending order, insert all at the front of the list
				sortedList.add(0, wrapper.sObj);
			}
		}

		return sortedList;
	}

	public SObject sObj;
	private String fieldToCompare;				// Legacy support
	private String sortDirection;

	/**
	 * SUPPORT FOR LEGACY USE
	 * @param sObj wrapped SObject
	 * @param fieldToCompare : the Number type field of which values are used to compare the SObjects
	 */
	public ComparableSObjectWrapper(SObject sObj, String fieldToCompare) {
		this.sObj = sObj;
		this.fieldToCompare = fieldToCompare;
	}

	/**
	 * Default Constructor
	 * @param sObj wrapped SObject
	 * @param SObjectField : the Number type field of which values are used to compare the SObjects
	 */
	public ComparableSObjectWrapper(SObject record, SObjectField orderByField) {
		this(record, String.valueOf(orderByField));
	}

	/**
	 * Comparable implementation of compareTo
	 * @param compareTo - SObjectWrapper instance to compare to
	 * @return <0, 0 or >0 if this instance is less than, equal to or greater than the provided instance
	 */
	public Integer compareTo(Object compareTo) {
		ComparableSObjectWrapper other = (ComparableSObjectWrapper)compareTo;
		Object thisValue = this.sObj.get(fieldToCompare);
		Object otherValue = other.sObj.get(fieldToCompare);

		if (thisValue == null && otherValue == null) {
			return 0;
		} else if (thisValue == null) {
			return -1;
		} else if (otherValue == null) {
			return 1;
		}

		if (thisValue instanceof String) {
			return ((String)thisValue).compareTo((String)otherValue);
		} else if (thisValue instanceof Integer) {
			return ((Integer)thisValue) - ((Integer)otherValue);
		} else if (thisValue instanceof Decimal) {
			Decimal thisDecimal = (Decimal)thisValue;
			Decimal otherDecimal = (Decimal)otherValue;
			return thisDecimal > otherDecimal ? 1 : (thisDecimal < otherDecimal ? -1 : 0);
		} else if (thisValue instanceof Date) {
			Date thisDate = (Date)thisValue;
			Date otherDate = (Date)otherValue;
			return thisDate > otherDate ? 1 : (thisDate < otherDate ? -1 : 0);
		} else if (thisValue instanceof DateTime) {
			DateTime thisDateTime = (DateTime)thisValue;
			DateTime otherDateTime = (DateTime)otherValue;
			return thisDateTime > otherDateTime ? 1 : (thisDateTime < otherDateTime ? -1 : 0);
		} else if (thisValue instanceof Boolean) {
			Boolean thisBoolean = (Boolean)thisValue;
			Boolean otherBoolean = (Boolean)otherValue;
			return (thisBoolean == otherBoolean) ? 0 : (thisBoolean ? 1 : -1);
		} else {
			// For any other types, convert to string and compare
			return String.valueOf(thisValue).compareTo(String.valueOf(otherValue));
		}
	}
}