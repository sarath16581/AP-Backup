/**
 * @description
 * A very simple selector class that sits in the base domain
 * NOTE: Does not have need to support fieldOverrides since the dataset is small
 *
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag RecordType SObject
 * @domain Core
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-07-31 - Nathan Franklin - Added new method selectByName and transactional cache to minimise the need for platform cache
 * 2023-06-13 - Nathan Franklin - Added selectByDeveloperNamesLike and small performance gain with not hitting app cache all the time
 * 2024-08-30 - Nick Guia 		- Added overloaded methods which accept SObjectType.
 * 								- updated API version
 * 								- deprecated methods that accept String SObject name
 * 								- updated local cache (transactionRecordTypes) to private
 */
public inherited sharing class RecordTypesSelector extends ApplicationSelector {

	@TestVisible
	private static Map<String, Map<Id, RecordType>> transactionRecordTypes = new Map<String, Map<Id, RecordType>>();

	public static RecordTypesSelector newInstance() {
		return (RecordTypesSelector)Application.Selectors.newInstance(RecordTypesSelector.class);
	}

	public override SObjectType getSObjectType() {
		return RecordType.getSObjectType();
	}

	public override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				RecordType.Id, RecordType.Name, RecordType.DeveloperName
		};
	}

	/**
	 * @description Retrieve record types by Developer Name
	 * @param SObjectType primarySObjectType
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByDeveloperName(SObjectType primarySObjectType, Set<String> developerNames) {
		
		Map<Id, RecordType> output = new Map<Id, RecordType>();

		// grab a list of all the record types on a particular object
		// this is cached so it shouldn't be too slow.
		List<RecordType> recordTypes = selectBySObject(primarySObjectType).values();

		for(RecordType rt : recordTypes) {
			// this will prioritise a developer name over just a name
			if(developerNames.contains(rt.DeveloperName)) {
				output.put(rt.Id, rt);
			}
		}

		return output;
	}

	/**
	 * @description Retrieve record types by Name
	 * @param SObjectType primarySObjectType
	 * @param names List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByName(SObjectType primarySObjectType, Set<String> recordTypeNames) {
		
		Map<Id, RecordType> output = new Map<Id, RecordType>();

		// grab a list of all the record types on a particular object
		// this is cached so it shouldn't be too slow.
		List<RecordType> recordTypes = selectBySObject(primarySObjectType).values();

		for(RecordType rt : recordTypes) {
			// this will prioritise a developer name over just a name
			if(recordTypeNames.contains(rt.Name)) {
				output.put(rt.Id, rt);
			}
		}

		return output;
	}

	/**
	 * @description Retrieve record types by a partial match of a developer name
	 * @param SObjectType primarySObjectType
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByDeveloperNameLike(SObjectType primarySObjectType, String developerName) {
		return selectByDeveloperNamesLike(primarySObjectType, new Set<String> { developerName });
	}

	/**
	 * @description Retrieve record types by a partial match of a developer name
	 * @param SObjectType primarySObjectType
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByDeveloperNamesLike(SObjectType primarySObjectType, Set<String> developerNames) {
		Map<Id, RecordType> output = new Map<Id, RecordType>();
		Map<Id, RecordType> recordTypes = selectBySObject(primarySObjectType);
		for(RecordType rt : recordTypes.values()) {
			for(String developerName : developerNames) {
				if(rt.DeveloperName.startsWith(developerName)) {
					output.put(rt.Id, rt);
					break;
				}
			}
		}
		return output;
	}

	/**
	* @description Returns a list of record types for a particular object and then caches the result
    * All other Record type methods in this class should call this method
	* @param SObjectType sObjType 
	* @return Map<Id, RecordType> 
	**/
	public Map<Id, RecordType> selectBySObject(SObjectType sObjType) {

		Map<Id, RecordType> output;

		if(sObjType != null) {

			String objName = String.valueOf(sObjType);

			// check local cache in case of platform cache miss
			if(transactionRecordTypes.get(objName) != null) {
				return transactionRecordTypes.get(objName);
			}

			// check platform cache
			output = (Map<Id, RecordType>) CacheManager.get('UTILITY_RECORD_TYPES', objName);
			if(output != null) {
				return output;
			}

			// fetch recordtype details
			output = new Map<Id, RecordType>();
			for(Schema.RecordTypeInfo result : sObjType.getDescribe().getRecordTypeInfos()) {
				output.put(
					result.getRecordTypeId(), 
					new RecordType(
						Id = result.getRecordTypeId(), 
						Name = result.getName(), 
						DeveloperName = result.getDeveloperName()
				));
			}

			transactionRecordTypes.put(objName, output);
			CacheManager.put('UTILITY_RECORD_TYPES', objName, output);
		}
		return output;
	}

	/**
	 * @description Retrieve record types by Developer Name
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 * @deprecated use the SObjectType overload instead
	 */
	public Map<Id, RecordType> selectByDeveloperName(String primaryObjectName, Set<String> developerNames) {
		SObjectType sObjType = convertNameToType(primaryObjectName);
		return selectByDeveloperName(sObjType, developerNames);
	}

	/**
	 * @description Retrieve record types by Name
	 * @param String primaryObjectName
	 * @param names List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 * @deprecated use the SObjectType overload instead
	 */
	public Map<Id, RecordType> selectByName(String primaryObjectName, Set<String> recordTypeNames) {
		SObjectType sObjType = convertNameToType(primaryObjectName);
		return selectByName(sObjType, recordTypeNames);
	}

	/**
	 * @description Retrieve record types by a partial match of a developer name
	 * @param String primaryObjectName
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 * @deprecated use the SObjectType overload instead
	 */
	public Map<Id, RecordType> selectByDeveloperNameLike(String primaryObjectName, String developerName) {
		SObjectType sObjType = convertNameToType(primaryObjectName);
		return selectByDeveloperNamesLike(sObjType, new Set<String> { developerName } );
	}

	/**
	 * @description Retrieve record types by a partial match of a developer name
	 * @param String primaryObjectName
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 * @deprecated use the SObjectType overload instead
	 */
	public Map<Id, RecordType> selectByDeveloperNamesLike(String primaryObjectName, Set<String> developerNames) {
		SObjectType sObjType = convertNameToType(primaryObjectName);
		return selectByDeveloperNamesLike(sObjType, developerNames);
	}

	/**
	* @description Returns a list of record types for a particular object and then caches the result
    * This is because the getGlobalDescribe can be very expensive in such a large org
    * All other Record type methods in this class should call this method
	* @param String objName 
	* @return Map<Id, RecordType> 
	* @deprecated use the SObjectType overload instead
	**/
	public Map<Id, RecordType> selectBySObject(String objName) {
		SObjectType sObjType = convertNameToType(objName);
		return selectBySObject(sObjType);
	}

	/**
	* @description converts String SObject name to SObjectType
	* @param String sObjName 
	* @return SObjectType 
	* @throws RecordTypesSelectorException
	**/
	@TestVisible
	private SObjectType convertNameToType(String sObjName) {

		SObjectType sObjType;

		try {
			sObjType = ((SObject) Type.forName(sObjName).newInstance()).getSObjectType();
		} catch(Exception e) {
			throw new RecordTypesSelectorException(e.getMessage());
		}

		return sObjType;
	}

	public class RecordTypesSelectorException extends Exception { }
}