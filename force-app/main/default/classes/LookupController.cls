/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Controller class for LWC lookup component
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
10.02.2020    alex.volkov@auspost.com.au    Added filterMap parameter to hard filter records
**/
public with sharing class LookupController
{
	private static final Integer MAX_RESULTS = 10;

	@AuraEnabled(Cacheable=true)
	public static List<SObject> getSearchResults(String searchTerm, String fieldList, String sobjectName, String fieldsToSearch, Map<String, String> filterMap)
	{
		String query = getQueryString(searchTerm, fieldList, sobjectName, fieldsToSearch, filterMap);
		System.debug(query);
		try
		{
			return Database.query(query);
		} catch (Exception ex)
		{
			throw new AuraHandledException(ex.getMessage());
		}
	}

	private static String getQueryString(String searchTerm, String fieldList, String sobjectName, String fieldsToSearch, Map<String, String> filterMap)
	{
		fieldList = String.isBlank(fieldList) ? 'Id' : fieldList;
		List<String> listOfFieldsToSearch = String.isBlank(fieldsToSearch) ? new List<String>() : fieldsToSearch.split(',');
		String whereClause;
		if (!'Network__c'.equalsIgnoreCase(sobjectName))
		{
			whereClause = getWhereClause(searchTerm, listOfFieldsToSearch, filterMap);
		}
		else
		{
			whereClause = getWhereClauseForNetwork(searchTerm, listOfFieldsToSearch);
		}

		String query = 'SELECT '
				+ fieldList
				+ ' FROM '
				+ sobjectName
				+ whereClause
				+ ' LIMIT ' + MAX_RESULTS;
		return query;
	}

	/**
	*
	* @param searchTerm
	* @param listOfFieldsToSearch
	* @param filterMap Fixed parameters to pre-filter records being searched
	* @return String
	*/
	private static String getWhereClause(String searchTerm, List<String> listOfFieldsToSearch, Map<String, String> filterMap)
	{
		String searchKey = '%' + searchTerm + '%';
		String whereClause = ' WHERE ';
		/** if there is a filter to be applied*/
		if (filterMap != null && !filterMap.isEmpty())
		{
			/** add a condition for every filtered field */
			for (String key : filterMap.keySet())
			{
				whereClause += String.escapeSingleQuotes(key) + '=\'' + String.escapeSingleQuotes(filterMap.get(key)) + '\' AND ';
			}
		}
		if (listOfFieldsToSearch == null || listOfFieldsToSearch.isEmpty())
		{
			listOfFieldsToSearch = new List<String>
			{
					'Name'
			};
		}
		whereClause += '(';
		for (Integer i = 0; i < listOfFieldsToSearch.size(); i++)
		{
			String field = listOfFieldsToSearch[i];
			whereClause += field;
			whereClause += ' LIKE \'' + String.escapeSingleQuotes(searchKey) + '\'';
			if (i + 1 < listOfFieldsToSearch.size()) whereClause += ' OR ';
		}
		whereClause += ')';
		return whereClause;
	}

	private static String getWhereClauseForNetwork(String searchTerm, List<String> listOfFieldsToSearch)
	{
		/*** Record Types for Network to filter the List of Networks ***/
		Set<String> sNetworkRecordTypeNames = new Set<String>
		{
				'Business Hub', 'Delivery', 'Retail'
		};
		Set<Id> sNetworkRecordTypeIds = getRecordTypeIdsByName(String.valueOf(Network__c.getSObjectType()), sNetworkRecordTypeNames);
		System.debug('sNetworkRecordTypeIds' + sNetworkRecordTypeIds);
		List<Id> lst = new List<Id>();
		lst.addAll(sNetworkRecordTypeIds);
		System.debug('lst od ids' + lst);
		String recordTypeIds = '(';
		for (Integer i = 0; i < lst.size(); i++)
		{
			String formattedString = toSOQL(lst[i]);
			if (i <> 0)
			{
				recordTypeIds += ',';
			}
			recordTypeIds += formattedString;
		}
		recordTypeIds += ')';

		String searchKey = '%' + searchTerm + '%';
		String whereClause = ' WHERE ';
		if (listOfFieldsToSearch == null || listOfFieldsToSearch.isEmpty()) listOfFieldsToSearch = new List<String>
		{
				'Name'
		};
		for (Integer i = 0; i < listOfFieldsToSearch.size(); i++)
		{
			String field = listOfFieldsToSearch[i];
			whereClause += field;
			whereClause += ' LIKE \'' + String.escapeSingleQuotes(searchKey) + '\'';
			if (i + 1 < listOfFieldsToSearch.size()) whereClause += ' OR ';
		}
		whereClause += ' AND RecordTypeId IN ' + recordTypeIds;
		return whereClause;
	}

	//.. TODO: Move this method to Utility Class;
	/*** ***/
	public static Set<Id> getRecordTypeIdsByName(String objName, Set<String> setRecordTypeNames)
	{

		Set<Id> recTypeIds;
		// verify if object api name & search string for recordtype is provided
		if (String.isNotBlank(objName) && setRecordTypeNames.size() > 0)
		{
			// check session cache
			recTypeIds = (Set<Id>) CacheManager.get('UTILITY_RECORD_TYPE_IDS', objName + String.valueOf(setRecordTypeNames).left(30));
			if (recTypeIds != null)
			{
				return recTypeIds;
			}

			// Iterate over the record types of sObject using schema methods
			recTypeIds = new Set<Id>();
			for (Schema.RecordTypeInfo result : Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfos())
			{

				if (setRecordTypeNames.contains(result.getName()))
				{
					recTypeIds.add(result.getRecordTypeId());   // add to return set
				}
			}

			CacheManager.put('UTILITY_RECORD_TYPE_IDS', objName + String.valueOf(setRecordTypeNames).left(30), recTypeIds);
		}
		return recTypeIds;
	}

	/**
	* @Description: Convert string to Single Quotes for SQL
	*/
	public static String toSOQL(Object value)
	{
		return '\'' + String.valueOf(value) + '\'';
	}
}