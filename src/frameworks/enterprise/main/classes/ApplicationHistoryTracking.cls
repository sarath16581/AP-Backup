// Purpose:		Framework for history tracking
// Author:		Paul Perry @ PERRYNET PTY LTD
// Created:		21/09/2020
// Description:
//	  This class can be used as is, or used as base class for extension in case there's
//	  more flexibility required (custom merging / field type conversion, etc.)
//
public without sharing class ApplicationHistoryTracking {
	// definition of static properties and methods

	// caching to minimise regex compilation
	private static Map<String, Pattern> regexPatternMap;

	// Instance related properties and methods
	private Map<String, SObjectField> fieldMap;

	// Map<"fieldName", Map<"matchingValue", List<HistoryTracking>>>
	private Map<String, Map<String, List<HistoryTracker>>> configByFieldAndValue;
	// set this to your custom merge field encapsulation
	public String regexDef = '\\{([A-z\\.0-9])*\\}';
	public Boolean resumeOnError = true;

	// This map can be added to for custom static merging situations (in here or programmatic in consuming method)
	public Map<String, Object> mergeValuesDefs = new Map<String, Object>{
		'TODAY' => System.today(),
		'NOW' => System.now(),
		'NULL' => null,
		'TRUE' => true,
		'FALSE' => false
	};

	// logic to find all regex occurrences within a string
	public static List<String> findAllOccurrences(String searchStr, String regexStr) {
		List<String> result = new List<String>();

		if (regexPatternMap == null) {
			regexPatternMap = new Map<String, Pattern>();
		}

		if (!regexPatternMap.containsKey(regexStr)) {
			// Compile each regex only once
			regexPatternMap.put(regexStr, Pattern.compile(regexStr));
		}

		Pattern p = regexPatternMap.get(regexStr);
		Matcher m = p.matcher(searchStr);

		if (m.find()) {
			do {
				result.add(m.group());
			} while (m.find());
		}

		return result;
	}

	// kick off the custom history tracking for given SObjectType using CustomMetadata Settings config
	//  Usages:run(Opportunity.SObjectType, Trigger.new, Trigger.oldMap)
	//	  *This process doesn't commit any records. Use it within before insert/update
	//	  trigger context or manually insert/update your List<SObject> newList
	public static void run(Schema.SObjectType sObjectType, List<SObject> newList, Map<Id, SObject> oldMap) {
		ApplicationHistoryTracking cht = new ApplicationHistoryTracking(sObjectType);
		/* Add your custom merge values in the consuming class to customise
		cht.mergeValuesDefs.putAll(new Map<String,Object>{
			'MERGEKEY1' => 1500,						// Integer
			'ISSUNDAY' => System.today().weekday() == 1 // Boolean
		});
		*/
		cht.process(newList, oldMap);
	}

	@SuppressWarnings('PMD.ExcessiveParameterList')
	public static void run(List<HistoryTracker> trackers, SObjectType sObjType, List<SObject> newList, Map<Id, SObject> oldMap) {
		if (!trackers.isEmpty() && !newList.isEmpty()) {
			ApplicationHistoryTracking cht = new ApplicationHistoryTracking(sObjType, trackers);
			cht.process(newList, oldMap);
		}
	}

	// constructor for system based config (Custom Metadata Setting)
	public ApplicationHistoryTracking(Schema.SObjectType sObjectType) {
		 // Fetch config for given sObjectType
		List<HistoryTracking__mdt> config = selectConfiguration(sObjectType);

		populateFieldIndex(convertHTList(config), sObjectType);
	}

	// constructor for list of HistoryTracker records
	public ApplicationHistoryTracking(SObjectType sObjType, List<HistoryTracker> htList) {
		populateFieldIndex(htList, sObjType);
	}

	private static Map<String,List<HistoryTracking__mdt>> selectorCacheMap;
	public static List<HistoryTracking__mdt> selectConfiguration(SObjectType sObjType) {
		if (selectorCacheMap == null) {
			selectorCacheMap = new Map<String,List<HistoryTracking__mdt>>();
		}

		String sObjTypeName = String.valueOf(sObjType);
		if (!selectorCacheMap.containsKey(sObjTypeName)) {
			HistoryTrackingSelector selector = HistoryTrackingSelector.newInstance();
			
			selectorCacheMap.put(
				sObjTypeName,
				selector.selectByObjectApiNames(
					new List<String>{ sObjTypeName }
				).values()
			);
		}

		return selectorCacheMap.get(sObjTypeName);
	}

	// constructor for custom config (on the fly Custom Metadata Setting)
	// public ApplicationHistoryTracking(Schema.SObjectType sObjType, List<HistoryTracker> trackingConfig) {
	//	 populateFieldIndex(convertHTList(tracingConfig), sObjType);
	// }

	// override this when using custom merge field encapsulation
	public String removeMergeFieldEncapsulation(String mergeKey) {
		if (mergeKey.startsWith('{') && mergeKey.endsWith('}')) {
			mergeKey = mergeKey.substringBetween('{', '}');
		}

		return mergeKey;
	}

	// override this if you need tailered processing
	public void process(List<SObject> newList, Map<Id,SObject> oldMap) {
		// Make sure oldMap is always initialised
		if (oldMap == null) {
			oldMap = new Map<Id,SObject>();
		}

		// loop through each of the tracked fields
		for (String changedField :configByFieldAndValue.keySet()) {
			// filter out the list of records that have this field changed
			List<SObject> fieldUpdates = hasChanged(
				new Set<String>{ changedField },
				oldMap,
				newList
			);

			// get the stamp field by value mappings for the tracked field
			Map<String,List<HistoryTracker>> configByValue = configByFieldAndValue.get(
				changedField
			);

			// process all filtered records
			for (SObject record :fieldUpdates) {
				// get the tracked fields' new value
				String newValue = String.valueOf(record.get(changedField));
				// see if there's a mapping for this value
				if (configByValue.containsKey(newValue)) {
					// for each related config
					for (HistoryTracker htlConfig :configByValue.get(newValue)) {
						// the target field to provide the stamp date
						String targetField = htlConfig.targetField;

						if (targetField != null) {
							// update if there's no value present or overwrite is allowed
							Object targetValue = record.get(targetField);
							Boolean updateTargetField =
								htlConfig.overwriteExistingValue ||
								targetValue == null ||
								targetValue == false ||
								(targetValue instanceOf String) && String.isBlank((String)targetValue);

							if (updateTargetField) {
								// get merged value
								Object mergedValue = getTargetValue(
									htlConfig.targetValue,
									record,
									oldMap.get(record.Id)
								);

								if (mergedValue instanceOf String && String.isBlank((String)mergedValue)) {
									mergedValue = null;
								}

								// put target value into target field
								try {
									record.put(targetField, mergedValue);
								} catch (System.SObjectException sObjEx) {
									if (!handleException(sObjEx)) {
										throw sObjEx;
									}
								}
							}
						}
					}
				}
			}
		}
	}

	// override this method in your custom class to add additional merge functionality
	public Object getTargetValue(String mergeKey, SObject newSObject, SObject oldSObject) {
		Map<String,Object> mergeValues = new Map<String,Object>(
			mergeValuesDefs
		);

		if (oldSObject != null) {
			mergeValues.put(
				String.valueOf(oldSObject.getSObjectType()),
				oldSObject.getPopulatedFieldsAsMap()
			);
		}

		// In case of static value
		Object result;

		// In case of merge value(s)
		List<String> mergeKeys = findAllOccurrences(mergeKey, regexDef);
		if (mergeKeys.size() == 1 && mergeKeys[0] == mergeKey) {
			// single value -> keep object type
			result = getMergeValue(mergeValues, mergeKey);
		} else if (mergeKeys.size() > 0) {
			// mixed text and/or merge values -> convert to string
			String textValue = mergeKey;

			for (String key :mergeKeys) {
				textValue = textValue.replace(
					key,
					String.valueOf(getMergeValue(mergeValues, key))
				);
			}

			result = textValue;
		} else {
			result = mergeKey;
		}

		return result;
	}

	// Override in case you need custom error handling
	public Boolean handleException(Exception ex) {
		final String messageTemplate = 'Verify configuration in HistoryTracker records';
		String errorMessage = String.format(
			'{0}\r\n{1}',
			new String[] { messageTemplate, ex.getMessage() }
		);

		System.debug(LoggingLevel.ERROR, errorMessage);

		if (!resumeOnError) {
			throw ex;
		}

		// return whether handled or not
		return resumeOnError;
	}

	// private methods
	// populate an index based on given CustomMetadata:History Tracking records for SObjectType
	private void populateFieldIndex(List<HistoryTracker> trackingConfig, Schema.SObjectType sObjectType) {
		configByFieldAndValue = new Map<String, Map<String,List<HistoryTracker>>>();

		if (!trackingConfig.isEmpty()) {
			// get SObjectFields
			for (HistoryTracker ht :trackingConfig) {
				String field = ht.fieldApiName;

				if (field != null) {
					if (!configByFieldAndValue.containsKey(field)) {
						configByFieldAndValue.put(
							field,
							new Map<String,List<HistoryTracker>>()
						);
					}

					if (!configByFieldAndValue.get(field).containsKey(ht.matchingValue)) {
						configByFieldAndValue.get(field).put(
							ht.matchingValue,
							new List<HistoryTracker>()
						);
					}

					configByFieldAndValue.get(field).get(ht.matchingValue).add(ht);
				}
			}
		}
	}

	// find merge values within the mergemap (recursive when Map in Map)
	private Object getMergeValue(Map<String,Object> mergeValues, String mergeKey) {
		mergeKey = removeMergeFieldEncapsulation(mergeKey);

		List<String> keys = mergeKey.split('\\.');
		String key = keys[0];
		Object mergeResult = '';

		if (mergeValues.containsKey(key)) {
			Object val = mergeValues.get(key);
			if (val != null) {
				if (keys.size() > 1) {
					if (val instanceof Map<String,Object>) {
						keys.remove(0);
						mergeResult = getMergeValue(
							(Map<String,Object>) val,
							String.join(keys, '.')
						);
					}
				} else {
					mergeResult = val;
				}
			}
		}

		return mergeResult;
	}

	@TestVisible
	private class HistoryTrackingException extends Exception { }

	public class HistoryTracker {
		public Id htRecordId;
		public String objectApiName;
		public String fieldApiName;
		public String matchingValue;
		public Boolean overwriteExistingValue = false;
		public String targetField;
		public String targetValue;

		/* BEGIN: test class purposes */
		public HistoryTracker setObjectApiName(String objectApiName) {
			this.objectApiName = objectApiName;
			return this;
		}

		public HistoryTracker setFieldApiName(String fieldApiName) {
			this.fieldApiName = fieldApiName;
			return this;
		}

		public HistoryTracker setMatchingValue(String matchingValue) {
			this.matchingValue = matchingValue;
			return this;
		}

		public HistoryTracker setOverwriteExistingValue(Boolean overwriteExistingValue) {
			this.overwriteExistingValue = overwriteExistingValue;
			return this;
		}

		public HistoryTracker setTargetField(String targetField) {
			this.targetField = targetField;
			return this;
		}

		public HistoryTracker setTargetValue(String targetValue) {
			this.targetValue = targetValue;
			return this;
		}
		/* END: for test class purposes only */	
	}

	private static HistoryTracker newInstance(HistoryTracking__mdt htRecord) {
		HistoryTracker result = new HistoryTracker();
		result.htRecordId = htRecord.Id;
		result.objectApiName = htRecord.ObjectName__c;
		result.fieldApiName = htRecord.TrackedFieldName__c;
		result.matchingValue = htRecord.MatchingValue__c;
		result.overwriteExistingValue = htRecord.OverwriteExistingValue__c;
		result.targetField = htRecord.TargetField__c;
		result.targetValue = htRecord.TargetValue__c;
		return result;
	}

	private static List<HistoryTracker> convertHTList(List<HistoryTracking__mdt> records) {
		List<HistoryTracker> result = new List<HistoryTracker>();

		for (HistoryTracking__mdt record :records) {
			result.add(newInstance(record));
		}

		return result;
	}

	/**
	 * Analyse provided list of SObjects passed in and compare these with the oldMap of SObjects
	 * Returns a list of records that have updates within provided fields.
	 *
	 * @param comparisonFields fields to compare
	 * @param oldMap List of SObjects for comparison
	 * @param newList Updated SObject list for comparison
	 *
	 * @return true if at least one field from the interested field set is different. false otherwise.
	 */
	private List<SObject> hasChanged(Set<String> comparisonFields, Map<Id,SObject> oldMap, List<SObject> newList) {
		List<SObject> result = new List<SObject>();
		for (SObject record :newList) {
			Boolean isDirty = true;
			isDirty = record.Id == null || !oldMap.containsKey(record.Id);

			if (!isDirty) {
				isDirty = hasChanged(record, oldMap.get(record.Id), comparisonFields);
			}

			if (isDirty) {
				result.add(record);
			}
		}

		return result;
	}

	/**
	 * Compare the two SObject instances passed in by doing a field by field comparison for the set of fields
	 * Returns true if at least one field is different.
	 *
	 * @param newRecord SObject for comparison
	 * @param existingRecord SObject for comparison
	 * @param comparisonFields fields to compare
	 *
	 * @return true if at least one field from the interested field set is different. false otherwise.
	 */
	private Boolean hasChanged(SObject newRecord, SObject existingRecord, Set<String> comparisonFields) {
		Boolean result = false;

		if (newRecord != null && existingRecord != null) {
			for (String field : comparisonFields) {
				if(newRecord.get(field) != existingRecord.get(field)) {
					result = true;
					break;
				}
			}
		}
		
		return result;
	}
}