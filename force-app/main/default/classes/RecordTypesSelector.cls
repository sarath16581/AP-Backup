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
 */
public inherited sharing class RecordTypesSelector extends ApplicationSelector {

	public static Map<String, Map<Id, RecordType>> transactionRecordTypes = new Map<String, Map<Id, RecordType>>();

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
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByDeveloperName(String primaryObjectName, Set<String> developerNames) {
		Map<Id, RecordType> output = new Map<Id, RecordType>();

		// grab a list of all the record types on a particular object
		// this is cached so it shouldn't be too slow.
		List<RecordType> recordTypes = selectBySObject(primaryObjectName).values();

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
	 * @param names List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByName(String primaryObjectName, Set<String> recordTypeNames) {
		Map<Id, RecordType> output = new Map<Id, RecordType>();

		// grab a list of all the record types on a particular object
		// this is cached so it shouldn't be too slow.
		List<RecordType> recordTypes = selectBySObject(primaryObjectName).values();

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
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByDeveloperNameLike(String primaryObjectName, String developerName) {
		Map<Id, RecordType> output = new Map<Id, RecordType>();
		Map<Id, RecordType> recordTypes = selectBySObject(primaryObjectName);
		for(RecordType rt : recordTypes.values()) {
			if(rt.DeveloperName.startsWith(developerName)) {
				output.put(rt.Id, rt);
			}
		}
		return output;
	}

	/**
	 * @description Retrieve record types by a partial match of a developer name
	 * @param developerNames List of strings contained (doesn't need to be a full recordtype value) in the record types retrieved (Example: SSSW, or, SSSWDeliveryEnquiry etc..)
	 */
	public Map<Id, RecordType> selectByDeveloperNamesLike(String primaryObjectName, Set<String> developerNames) {
		Map<Id, RecordType> output = new Map<Id, RecordType>();
		Map<Id, RecordType> recordTypes = selectBySObject(primaryObjectName);
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
     * This is because the getGlobalDescribe can be very expensive in such a large org
     * All other Record type methods in this class should call this method
     */
	public Map<Id, RecordType> selectBySObject(String objName) {
		Map<Id, RecordType> output;

		if(String.isNotBlank(objName)) {

			if(transactionRecordTypes.get(objName) != null) {
				return transactionRecordTypes.get(objName);
			}

			// check platform cache
			output = (Map<Id, RecordType>)CacheManager.get('UTILITY_RECORD_TYPES', objName);
			if(output != null) {
				return output;
			}

			// fetch recordtype details from Schema method based on the object api name
			output = new Map<Id, RecordType>();
			for(Schema.RecordTypeInfo result : Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfos()) {
				output.put(result.getRecordTypeId(), new RecordType(Id = result.getRecordTypeId(), Name = result.getName(), DeveloperName = result.getDeveloperName()));
			}

			transactionRecordTypes.put(objName, output);

			CacheManager.put('UTILITY_RECORD_TYPES', objName, output);
		}
		return output;
	}

}