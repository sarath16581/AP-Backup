/**************************************************
Purpose:    Used to add session and eventually platform level caching
				to Salesforce to improve performance throughout the system
--------------------------------------------------
2017-09-27  nathan.franklin@auspost.com.au  Created
2018-11-28  nathan.franklin@auspost.com.au  Updated to include TTL parameter override.
**************************************************/
public class CacheManager {

	@testVisible
	private static CacheSettings__c settings;
	private static Cache.SessionPartition sessionPartition;

	private static Map<String, CacheKeySetting__mdt> loadedCacheKeys = new Map<String, CacheKeySetting__mdt>();

	static {
		settings = CacheSettings__c.getInstance();

		if(isSessionCacheAvailable()) {
			sessionPartition = Cache.Session.getPartition('local.PlatformCache');
		}
	}

	/**
	 * Add value to the cache. The key must be registered in the CacheKeySetting__mdt metadata type.
	 */
	public static void put(String cacheKey, Object value) {
		put(cacheKey, '', value);
	}

	/**
	 * Add value to the cache. The key must be registered in the CacheKeySetting__mdt metadata type.
	 */
	public static void put(String cacheKey, String suffix, Object value) {
		put(cacheKey, suffix, value, null);
	}

	public static void put(String cacheKey, String suffix, Object value, Integer ttlOverride) {
		if(!settings.CacheEnabled__c) return;

		CacheKeySetting__mdt key = getCacheKey(cacheKey);
		if(key != null) {
			if(!key.Enabled__c) return;

			String keyName = normaliseCacheKey(key.KeyName__c + suffix);
			if (key.CacheType__c == 'Session') {
				putSessionValue(keyName, value, (ttlOverride != null ? ttlOverride : Integer.valueOf(key.TTL__c)));
			} else if (key.CacheType__c == 'Org') {
				putOrgValue(keyName, value, (ttlOverride != null ? ttlOverride : Integer.valueOf(key.TTL__c)));
			}
		}
	}

	/**
	 * Retrieve a value from the cache if it exists. The key must be registered in the CacheKeySetting__mdt metadata type.
	 */
	public static Object get(String cacheKey) {
		return get(cacheKey, '');
	}

	/**
	 * Retrieve a value from the cache if it exists. The key must be registered in the CacheKeySetting__mdt metadata type.
	 */
	public static Object get(String cacheKey, String suffix) {
		if(!settings.CacheEnabled__c) return null;
		CacheKeySetting__mdt key = getCacheKey(cacheKey);
		if(key != null) {
			if(!key.Enabled__c) return null;

			String keyName = normaliseCacheKey(key.KeyName__c + suffix);
			if (key.CacheType__c == 'Session') {
				return getSessionValue(keyName);
			} else if (key.CacheType__c == 'Org') {
				return getOrgValue(keyName);
			}
		}

		return null;
	}

	/**
	 * Retrieve a value from the session cache.
	 */
	private static Object getSessionValue(String key) {
		if(!settings.CacheEnabled__c || sessionPartition == null || !isSessionCacheAvailable()) return null;

		Object value = sessionPartition.get(key);
		if(value != null) {
			System.debug('Session Cache Hit: ' + key);
		} else {
			System.debug('Session Cache Miss: ' + key);
		}

		return value;
	}

	/**
	 * Retrieve a value from the org cache.
	 */
	private static Object getOrgValue(String key) {
		if(!settings.CacheEnabled__c) return null; // || orgPartition == null) return null;

		Object value;
		try {
			value = Cache.Org.get(key); //orgPartition.get(key);
			if (value != null) {
				System.debug('Org Cache Hit: ' + key);
			} else {
				System.debug('Org Cache Miss: ' + key);
			}
		} catch(Exception e) {
			System.debug('Org Cache Error: ' + e.getMessage());
		}

		return value;
	}

	/**
	 * Add a value to the session cache.
	 */
	private static void putSessionValue(String key, Object value, Integer ttl) {
		if (!settings.CacheEnabled__c || sessionPartition == null || !isSessionCacheAvailable()) return;
		sessionPartition.put(key, value, ttl);
	}

	/**
	 * Add a value to the org cache.
	 */
	private static void putOrgValue(String key, Object value, Integer ttl) {
		if(!settings.CacheEnabled__c) return; // || orgPartition == null) return;

		try {
			Cache.Org.put(key, value, ttl); //orgPartition.put(key, value, ttl);
		} catch(Exception e) {
			System.debug('Org Cache Error: ' + e.getMessage());
		}
	}


	/**
	 * Is an async context, it seems Cache.Session.isAvailable throws an error
	 * Class.cache.PlatformCacheDelegateWrapper.getSessionDefault: line 16, column 1
	 *	Class.cache.Session.getDefault: line 99, column 1
	 *	Class.cache.Session.isAvailable: line 91, column 1
	 */
	private static Boolean isSessionCacheAvailable() {
		// Always assume the session cache is available in tests
		// Cache.Session.isAvailable() only returns true for Syncronous context,
		// and tests can be run in both sync and async, therefore without this,
		// the results will be inconsistent
		if (Test.isRunningTest()) return true;

		try {
			return (UserInfo.getSessionId() != null ? Cache.Session.isAvailable() : false);
		} catch(Exception e) {
			return false;
		}
	}

	/**
	 * Since cache requires use of only alpha numeric keys, this method will normalise all keys
	 * This does not use partitioning and will replace all periods with the letter A
	 */
	private static String normaliseCacheKey(String key) {
		key = key.replaceAll('[^A-Za-z0-9]', 'A'); // removing all non Alpha numeric keys amd replace them with a letter so the key will still be unique.
		return key;
	}

	/**
	 * Loads a key from the CacheKeySetting metadata. This also caches this key to prevent additional SOQL's.
	 */
	private static CacheKeySetting__mdt getCacheKey(String cacheKey) {
		String normalisedKey = normaliseCacheKey(cacheKey);

		if(loadedCacheKeys.get(cacheKey) != null) {
			return loadedCacheKeys.get(cacheKey);
		} else {
			List<CacheKeySetting__mdt> keySettings = [Select DeveloperName, CacheType__c, KeyName__c, TTL__c, Enabled__c From CacheKeySetting__mdt Where DeveloperName = :cacheKey];
			if(!keySettings.isEmpty()) {
				loadedCacheKeys.put(keySettings[0].DeveloperName, keySettings[0]);

				return keySettings[0];
			} else {
				throw new CacheKeyNotFoundException();
			}
		}

		return null;
	}

	public class CacheKeyNotFoundException extends Exception { }


//	TODO implement a better approach.
//  /**
//	 * This will get the cache value but ensure it's of a specific return type.
//	 * If the type does not match, then a null value is returned to prevent any exceptions from mismatches data types.
//	 */
//	public static Object getOrgValue(String key, Type returnType) {
//		Object value = getOrgValue(key);
//		if(value == null) return null;
//
//		// if the value type is empty it means the method didn't work
//		String valueType = getCacheType(value);
//		if(valueType.isNotEmpty() && valueType != returnType.getName()) {
//			return null;
//		}
//
//		return value;
//	}

//	TODO Implement a cleaner approach
//  /**
//	 * Unfortunately, there is no easy way to get the type name of an Object variable (or any variable for that matter)
//	 * This will force an exception to be thrown and will catch the runtype exception and use a regex to grab the actual type of the variable
//	 */
//	private static String getCacheType(Object value) {
//		try {
//			CacheTypeKiller killer = (CacheTypeKiller)value;
//		} catch(System.TypeException e) {
//			Pattern typePattern = Pattern.compile('.*?runtime type (.*?) to.*');
//			Matcher typeMatcher = typePattern.matcher(e.getMessage());
//			if(typeMatcher.matches() && typeMatcher.groupCount() == 1) {
//				return typeMatcher.group(1);
//			}
//		}
//
//		// the method didn't work which means there was likely a change in the exception string format
//		return '';
//	}
//
//	private class CacheTypeKiller { }

}