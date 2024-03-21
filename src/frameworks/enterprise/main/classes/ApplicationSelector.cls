/**
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @domain Core
 * @description The ApplicationSelector class the base super class that all other Selectors extend from.
 * The ApplicationSelector class defines key methods and properties that are required by all other Selectors to implement or override as necessary.
 * NOTE: It's very important that a Selector does not define explicit sharing. It should always inherit sharing based on the preference of the calling code. This allows the class to be flexible enough to be used in any circumstance that requires data.
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-02 - Nathan Franklin - Add field overrides
 * 2020-10-12 - Jansi - Added offsetLimit
 * 2022-04-12 - Ranjeewa Silva - Added new selector option to build queries with no default ordering applied
 * 2023-03-22 - Nathan Franklin - Add method for validating search params and minor changes to order by method
 * 2024-03-07 - Mahesh Parvathaneni - Added ability to include FOR UPDATE in the query
 */
public inherited sharing abstract class ApplicationSelector {

	public enum Options {
		ID_FIELD_ONLY, WITHOUT_DEFAULT_ORDER
	}

	/**
	 * Can be set when a call to newInstance is made. 0 means unlimited
	 */
	protected Integer recordLimit = 0;
	protected Integer offsetLimit = 0;
	protected Boolean forUpdate = false;

	/**
	 * Specific selectors may implement an option to override default fields. This is used in scenarios were only a small number of fields are required and this dataset is not passed around to other methods
	 * Using this approach removes data consistency and prevents any possible caching of results that will be implemented in the future
	 * It's generally not recommended to use this approach in triggers where consistency and reusability requirements are high.
	 *
	 * This allows storage of not only the current selectors field overrides but also the related objects.
	 */
	protected Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>();

	/**
	 * Creates a new instance of the Selector. Most (if not all) Selectors will use their own implementations of newInstance since this gives the benefit of a concrete-type return
	 * Using a newInstance static method allows for better flexibility around dependency injection, particularly when it comes to unit testing and mocking. Stubbed implementations are injected extensively during unit tests.
	 * @param selectorType The Selector type that is a subclass of ApplicationSelector
	 * @return New instance of the selectorType type or a Stubbed class used for mocking
	 */
	public static Object newInstance(Type selectorType) {
		return Application.Selectors.newInstance(selectorType);
	}

	/**
	 * Defines the SObject to use for this Selector class. This relates directly to the SObject used when building a SOQL using QueryBuilder
	 * @return SObjectType The name of the SObject that is the focus of this Selector class
	 */
	protected abstract SObjectType getSObjectType();

	/**
	 * Defines a list of fields that is selected when querying data using this Selector.
	 * NOTE: Exposing a single list of fields per Selector offers the primary advantage of maintaining a consistent dataset for use in the application. It increases the confidence that the result can be used across multiple functions.
	 * There is one exception to this rule and that is if you only need to select the Id field in which case that ApplicationSelector.SELECTOR_OPTION_ID_FIELD_ONLY can be passed into any method that supports a 'selector option'
	 * @return List of fields that will be included in the query
	 */
	protected abstract Set<SObjectField> getSObjectFieldList();

	// TODO: Activate Cache
	//	/**
	//	 * Important to NOTE. It's not expected that cache will necessarily save time and speed things up.
	//	 * The most important function of cache is to minimise the number of hits to the database for commonly used soqls in a single transaction
	//	 * Most notably, inside a trigger
	//	 *
	//	 * Important to NOTE. Using cache will skew ordered data, When using a combination between cached results and a db query, the order will be mixed up.
	//	 */
	//	public static SelectorCache Cache;
	//
	//	static {
	//		Cache = new SelectorCache();
	//	}

	/**
	 * Grab the name of the class for various actions. Since Apex does not provide class Reflection then it's necessary to use this in order to know what the name of the most subclassed class is.
	 */
	public String className {
		get {
			if(String.isEmpty(className)) {
				className = String.valueOf(this).substringBefore(':');
			}
			return className;
		}
		private set;
	}

	/**
	 * Forces a LIMIT to be defined when building a query using QueryBuilder
	 * @return Returns an instance of self for chaining purposes.
	 */
	public ApplicationSelector setLimit(Integer recordLimit) {
		this.recordLimit = recordLimit;
		return this;
	}

	/**
	 * Forces a OFFSET to be defined when building a query using QueryBuilder
	 * @return Returns an instance of self for chaining purposes.
	 */
	public ApplicationSelector setOffset(Integer offsetLimit) {
		this.offsetLimit = offsetLimit;
		return this;
	}

	/**
	 * Forces a FOR UPDATE to be defined when building a query using QueryBuilder
	 * @return Returns an instance of self for chaining purposes.
	 */
	public ApplicationSelector setForUpdate(Boolean forUpdate) {
		this.forUpdate = forUpdate;
		return this;
	}


	/**
	 * Specific selectors may implement an option to override default fields. This is used in scenarios were only a small number of fields are required and this dataset is not passed around to other methods
	 * Using this approach removes data consistency and prevents any possible caching of results that will be implemented in the future
	 * It's generally not recommended to use this approach in triggers where consistency and reusability requirements are high.
	 */
	public ApplicationSelector setFieldOverrides(Set<SObjectField> fieldOverrides) {
		this.fieldOverrides.put(getSObjectType(), fieldOverrides);
		return this;
	}

	/**
	 * Specific selectors may implement an option to override default fields. This is used in scenarios were only a small number of fields are required and this dataset is not passed around to other methods
	 * Using this approach removes data consistency and prevents any possible caching of results that will be implemented in the future
	 * It's generally not recommended to use this approach in triggers where consistency and reusability requirements are high.
	 *
	 * This specific method allows the caller to pass in additional field overrides for other related objects that are augmented with selector options,
	 */
	public ApplicationSelector setFieldOverrides(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		this.fieldOverrides = fieldOverrides;
		return this;
	}

	// TODO: Activate Cache
	//	/**
	//	 * Builds a list of sobjects that were present in a query based on the selectorOptions.
	//	 * By tracking all sobjects used in a query, we can accurately invalidate any cache that may become stale after DML operations occur for those objects
	//	 * The invalidating is done as a part of the execution of the trigger
	//	 */
	//	protected virtual Set<String> getUsedCachedSObjects(Integer selectorOptions) {
	//		return new Set<String>{String.valueOf(getSObjectType())};
	//	}

	/**
	 * Forces an order to be applied to any query built with QueryBuilder. This can be overridden if needed
	 */
	public virtual List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('CreatedDate', 'Desc')};
	}

	/**
	 * newQueryBuilder is a key part of the ApplicationSelector and most subclasses will override this method and call the super method it in order to get a QueryBuilder starting point based on the config defined in the instance
	 */
	public virtual QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	/**
	 * newQueryBuilder is a key part of the ApplicationSelector and most subclasses will override this method and call the super method it in order to get a QueryBuilder starting point based on the config defined in the instance
	 */
	public virtual QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder qb = QueryBuilder.newInstance(Type.forName(className));
		if(selectorOptions.contains(Options.ID_FIELD_ONLY)) {
			qb.addField('Id');
		} else {
			// loop through any field overrides passed into the selector and only add them to the query builder if they match this selectors SObject type
			// this allows the caller to pass in fields of different object types and use it in conjunction with selector options to enrich the data set with other objects
			if(fieldOverrides.get(getSObjectType()) != null && !fieldOverrides.get(getSObjectType()).isEmpty()) {
				qb.addFields(fieldOverrides.get(getSObjectType()));
			} else {
				qb.addFields(getSObjectFieldList());
			}
		}
		qb.addFrom(String.valueOf(getSObjectType()));
		if (!selectorOptions.contains(Options.WITHOUT_DEFAULT_ORDER)) {
			List<QueryBuilder.Order> o = getOrderBy();
			if(o != null) {
				qb.addOrder(o);
			}
		}

		if(recordLimit != null && recordLimit != 0) {
			qb.setLimit(recordLimit);
		}

		if(offsetLimit != null && offsetLimit != 0) {
			qb.setOffset(offsetLimit);
		}

		if(forUpdate != null && forUpdate) {
			qb.setForUpdate(forUpdate);
		}

		return qb;
	}

	/**
	 * Returns a list of the all createable fields in the selector instance
	 */
	public List<SObjectField> getCreateableFields() {
		List<SObjectField> createableFields = new List<SObjectField>();
		for(SObjectField field : (fieldOverrides.get(getSObjectType()) != null && !fieldOverrides.get(getSObjectType()).isEmpty() ? fieldOverrides.get(getSObjectType()) : getSObjectFieldList())) {
			if(field.getDescribe().isCreateable()) {
				createableFields.add(field);
			}
		}
		return createableFields;
	}

	/**
	 * Iterates over an SObject and creates a list of all the fields the current user has create permissions on.
	 * This should be used sparingly!
	 **/
	public static Set<SObjectField> getAllCreatableFieldsBySObjectType(SObjectType objectType) {
		Set<SObjectField> createableFields = new Set<SObjectField>();
		for(SObjectField field : objectType.getDescribe().fields.getMap().values()) {
			if(field.getDescribe().isCreateable()) {
				createableFields.add(field);
			}
		}
		return createableFields;
	}

	/**
	 * Will force an exception to be thrown if the search params are invalid
	 */
	protected void validateSearchParams(Set<String> paramsPassed, Set<String> validParams) {
		Set<String> remainingOptions = paramsPassed.clone();
		remainingOptions.removeAll(validParams);
		if(!remainingOptions.isEmpty()) {
			throw new SelectorException('Invalid search parameters received');
		}
	}

	// TODO: Activate Cache
	//	/**
	//	 * This class manages cache of queries.
	//	 * It's a bit dumb and will cache based on key that must be specified by caller. Generally, the key will be the name of the method that is calling the cache functionality.
	//	 *
	//	 * The query cache provides the ability to share the same dataset across modular code execution without each 'module' or 'code block' needing to go back to the database for the same data.
	//	 * The cache is implemented individually across each selector as needed.
	//	 *
	//	 * It's not expected that cache will necessarily save time and speed things up.
	//	 * The most important function of cache is to minimise the number of hits to the database for commonly used soqls in a single transaction, most notably, inside a trigger
	//	 *
	//	 * Important to NOTE. If the cache is only able to fulfil partial results based on the query, an additional call to the database will need to be made by the caller to retrieve the remaining records not being cached.
	//	 * If this happens, this can skew the results of the data where an Order By clause is used. Where the 'order' of the data is important, caching should be avoided unless the calling code manually re-orders the data.
	//	 */
	//	public class SelectorCache {
	//
	//		private Map<String, Map<Id, SObject>> cache;
	//		private Map<String, Map<String, Map<Id, SObject>>> cacheByRelated;
	//		private Map<String, Set<String>> cacheSObjectKeyMapping;
	//
	//		public SelectorCache() {
	//			cache = new Map<String, Map<Id, SObject>>();
	//			cacheByRelated = new Map<String, Map<String, Map<Id, SObject>>>();
	//			cacheSObjectKeyMapping = new Map<String, Set<String>>();
	//		}
	//
	//		/**
	//		 * Grab any stored cache entries
	//		 * This relies on a unique key for each calling method to ensure the records returned are unique to that method
	//		 */
	//		public CacheResult getByRecordId(ApplicationSelector selectorClass, Set<Id> ids, String key, Integer selectorOptions) {
	//			key += selectorClass.className + String.valueOf(selectorClass.getSObjectType()) + String.valueOf(selectorOptions);
	//			Map<Id, SObject> cachedResults = (cache.get(key) == null ? new Map<Id, SObject>() : cache.get(key).clone());
	//			Set<Id> inverseIds = cachedResults.keySet().clone();
	//			inverseIds.removeAll(ids);
	//			cachedResults.keySet().removeAll(inverseIds);
	//			return new CacheResult(cachedResults.keySet(), cachedResults);
	//		}
	//
	//		/**
	//		 * Store records in the cache using the Ids of the records.
	//		 * This relies on a unique key for each calling method to ensure the records returned are unique to that method
	//		 * This is done by using a unique 'key' approach where by the following are factored in:
	//		 * 1. the className of the calling class
	//		 * 2. a key defined by the caller (can be anything)
	//		 * 3. the 'selector options' used for this particular query (to ensure each unique combination of the data is stored as separate entries...)
	//		 *
	//		 * NOTE: Some selectorOptions include additional related objects and subqueries which is why the selectorOptions value is included in the key.
	//		 *
	//		 * Any item added to the Cache must be purged after DML operations occur for the objects contained within the specific cache entry. This is stop cache from becoming stale
	//		 * This is handle by a special call in a trigger handler to invalidate any cache entries linked to the Object that was just updated/inserted/deleted/undeleted (TODO)
	//		 */
	//		public void putByRecordId(ApplicationSelector selectorClass, Map<Id, SObject> rows, String key, Integer selectorOptions) {
	//			key += selectorClass.className + String.valueOf(selectorClass.getSObjectType()) + String.valueOf(selectorOptions);
	//			if(cache.get(key) == null) {
	//				cache.put(key, new Map<Id, SObject>());
	//			}
	//			cache.get(key).putAll(rows);
	//
	//			Set<String> sObjects = selectorClass.getUsedCachedSObjects(selectorOptions);
	//			for(String sObj : sObjects) {
	//				if(cacheSObjectKeyMapping.get(sObj) == null) {
	//					cacheSObjectKeyMapping.put(sObj, new Set<String>());
	//				}
	//				cacheSObjectKeyMapping.get(sObj).add(key);
	//			}
	//		}
	//
	//		/**
	//		 * Grab any stored cache entries
	//		 */
	//		public CacheResult getByRelatedValue(ApplicationSelector selectorClass, Set<String> values, String key, Integer selectorOptions) {
	//			//ids = WhatIds (org)
	//			// cache might have multiple records per each Id
	//			// for all the records for each id needs to be returned
	//
	//			key += selectorClass.className + selectorClass.getSObjectType() + String.valueOf(selectorOptions);
	//			Map<String, Map<Id, SObject>> cachedResults = (cacheByRelated.get(key) == null ? new Map<String, Map<Id, SObject>>() : cacheByRelated.get(key).clone());
	//			Set<String> inverseFieldValues = cachedResults.keySet().clone();
	//			inverseFieldValues.removeAll(values);
	//			cachedResults.keySet().removeAll(inverseFieldValues);
	//
	//			Set<String> retrievedValues = new Set<String>();
	//			Map<Id, SObject> output = new Map<Id, SObject>();
	//
	//			for(String relatedValue : cachedResults.keySet()) {
	//				output.putAll(cachedResults.get(relatedValue));
	//				retrievedValues.add(relatedValue);
	//			}
	//
	//			return new CacheResult(retrievedValues, output);
	//		}
	//
	//		/**
	//		 * Store records in the cache using the value of a specific field in the result.
	//		 * This will store results as an array against the value retrieved from the field of each record
	//		 * This should be used for ALL caching requirements not being cached by Id.
	//		 */
	//		public void putByRelatedValue(ApplicationSelector selectorClass, Map<Id, SObject> rows, SObjectField field, String key, Integer selectorOptions) {
	//			key += selectorClass.className + String.valueOf(selectorClass.getSObjectType()) + String.valueOf(selectorOptions);
	//
	//			Map<String, Map<Id, SObject>> rowsToCache = new Map<String, Map<Id, SObject>>();
	//			for(SObject row : rows.values()) {
	//				String fieldValue = String.valueOf(row.get(field));
	//				if(rowsToCache.get(fieldValue) == null) {
	//					rowsToCache.put(fieldValue, new Map<Id, SObject>());
	//				}
	//
	//				rowsToCache.get(fieldValue).put(row.Id, row);
	//			}
	//
	//			if(cacheByRelated.get(key) == null) {
	//				cacheByRelated.put(key, new Map<String, Map<Id, SObject>>());
	//			}
	//			cacheByRelated.get(key).putAll(rowsToCache);
	//
	//			Set<String> sObjects = selectorClass.getUsedCachedSObjects(selectorOptions);
	//			for(String sObj : sObjects) {
	//				if(cacheSObjectKeyMapping.get(sObj) == null) {
	//					cacheSObjectKeyMapping.put(sObj, new Set<String>());
	//				}
	//				cacheSObjectKeyMapping.get(sObj).add(key);
	//			}
	//		}
	//
	//		public void invalidate(String sObjectName) {
	//			if(cacheSObjectKeyMapping.get(sObjectName) != null) {
	//				cache.keySet().removeAll(cacheSObjectKeyMapping.get(sObjectName));
	//				cacheByRelated.keySet().removeAll(cacheSObjectKeyMapping.get(sObjectName));
	//				cacheSObjectKeyMapping.put(sObjectName, new Set<String>());
	//			}
	//		}
	//
	//	}
	//
	//	public class CacheResult {
	//		public Set<Id> recordIds { get; private set; }
	//		public Set<String> relatedValues { get; private set; }
	//		public Map<Id, SObject> rows { get; private set; }
	//
	//		CacheResult(Set<Id> recordIds, Map<Id, SObject> rows) {
	//			this.recordIds = recordIds;
	//			this.rows = rows;
	//		}
	//		CacheResult(Set<String> relatedValues, Map<Id, SObject> rows) {
	//			this.relatedValues = relatedValues;
	//			this.rows = rows;
	//		}
	//	}

	public class SelectorException extends Exception {}
}