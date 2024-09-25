/**
 * @author Mohamed.Atheek@bluewolf.com
 * @date 2014/01/14
 * @group 
 * @tag Util
 *
 * @description
 * 	- Type:		Wrapper class for SObjects that makes them comparable
 * 	- Purpose:	Makes an SObject comparable by the given Number type field
 * 	- Used By: 	for eg to sort a list of SObjects based on a Number field value
 * 
 * @changelog:
 * 	Rewritten to extend its capabilities sorting on all kinds of fields
 *  Added support for using SObjectFields
 *  Added support for order ASC/DESC
 **/
public without sharing class ComparableSObjectWrapper implements Comparable {
	public SObject sObj;
	private String fieldToCompare;				// Here for legacy support
	private SObjectField sObjFieldToCompare;
	private String sortDirection;

	/*
	 * SUPPORT FOR LEGACY USE
	 * parameter sObj : wrapped SObject
	 * parameter fieldToCompare : the Number type field of which values are used to compare the SObjects
	 */
	public ComparableSObjectWrapper(SObject sObj, String fieldToCompare) {
    	this.sObj = sObj;
    	this.fieldToCompare = fieldToCompare;
	}

	public ComparableSObjectWrapper(SObject record, SObjectField orderByField) {
		this(record, String.valueOf(orderByField));
		this.sObjFieldToCompare = orderByField;
	}

	public Integer compareTo(Object compareTo) {
		ComparableSObjectWrapper other = (ComparableSObjectWrapper)compareTo;
		Object thisValue = getSObjectValue(this.sObj);
		Object otherValue = getSObjectValue(other.sObj);

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

	private Object getSObjectValue(SObject record) {
		if (sObjFieldToCompare != null) {
			return record.get(sObjFieldToCompare);
		} else {
			return record.get(fieldToCompare);
		}
	}

	public static List<SObject> sortRecords(List<SObject> recordList, SObjectField orderByField) {
		return sortRecords(recordList, orderByField, 'ASC');
	}

	public static List<SObject> sortRecords(List<SObject> recordList, String orderByField) {
		return sortRecords(recordList, orderByField, 'ASC');
	}

	public static List<SObject> sortRecords(List<SObject> recordList, Object orderByField, String sortDirection) {
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
			ComparableSObjectWrapper comparisonInstance = orderByField instanceof SObjectField
				? new ComparableSObjectWrapper(record, (SObjectField)orderByField)
				: new ComparableSObjectWrapper(record, (String)orderByField);

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
}