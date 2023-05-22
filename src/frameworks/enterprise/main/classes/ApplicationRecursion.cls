/**
 * @description Determines which records should be processed during a trigger iteration
 * 				Usually when a record is inserted or updated, subsequent config based automation such as workflows, process builders etc... may trigger recursion which restarts the trigger iterations again
 * 				This class is responsible for only allowing calling methods to re-process records if their values have changed since the last time they were used in that calling method.
 * 				Other concepts like Boolean flags and only checking the oldMap are inadequate ways of limiting recursive processing.
 * 				See this page: https://australiapost.jira.com/wiki/spaces/SF/pages/2797764773/Triggers+and+Recursion
 * 
 * @author Nathan Franklin
 * @date 2023-05-05
 * @changelog
 */
public inherited sharing class ApplicationRecursion {

	/**
	 * Stores the context and a Map of Record Id and joined string values for hashing (if necessary)
	 * 
	 * Map<String> -- the context name
	 * Map<String, Map<Id>> -- the sobject record id
	 * Map<String, Map<Id, Map<String>>> -- the name of the field
	 * Map<String, Map<Id, Map<String, Object>>> -- the value of the field
	 * NOTE we store this in a basic MAP for 2 reasons:
	 * 1. We only want to store the comparison fields
	 * 2. Since we only want to store the comparison fields, we would need to create a sobject instance. If a comparison field is 'not writeable' then an error will occur while trying to add the value to the new sobject (I didn't want to use JSON hacks)
	 */
	@TestVisible
	private Map<String, Map<Id, Map<String, Object>>> stateStore = new Map<String, Map<Id, Map<String, Object>>>();

	/**
	 * Used to temporarily store sobject in the event a record is passed in without an id
	 * This sobject is used simply as a reference for the Salesforce to set the Id against after the on before insert iteration
	 * Salesforce does this as an internal process
	 * After this, the oldState will be transferred to 'stateStore' variable.
	 * NOTE: We do not reference any of the values on this sobject since the sobject is a reference and other parts of the code may modify this sobjects values unintentionally!
	 * 			We store any monitored values for this SObject in sobjectStateStoreStaticValuesMapStore variable to ensure nothing else can modify these values
	 * 
	 * Map<String> -- the context name
	 * Map<String, List<SObject>> -- the sobject instance
	 */
	@TestVisible
	private Map<String, List<SObject>> sobjectStateStore = new Map<String, List<SObject>>();

	/**
	 * This is used to capture the values passed in at the time getProcessableRecords is called.
	 * Since the temporary reference of the SOBject we are holding (see sobjectStateStore) is a reference,
	 * 	any changes made to that SObject through the code will be populated in this sobject value which will cause inconsistencies an unexpected behaviour
	 * To stop other code from unintentionally modifying the state of the temp stored SObject, we snapshot the values into a static map so they can't be overridden
	 */
	@TestVisible
	private Map<String, List<Map<String, Object>>> sobjectStateStoreStaticValuesMapStore = new Map<String, List<Map<String, Object>>>();

	public static ApplicationRecursion getInstance() {
		return (ApplicationRecursion)Application.Utilities.getInstance(ApplicationRecursion.class);
	}

	/**
	 * This will filter the records passed in and remove all the records that have already been processed for the current context
	 * This will track the current state of the record and on subsequent calls will only return records that have changed since last execution
	 * A combination of Trigger oldMap, and tracking the values in the sobject itself are all used to determine which records should be returned for reprocessing
	 * NOTE: comparisonFields must remain the same (per single context) for each call into this method to avoid unexpected results
	 *
	 * @param context Any name that is unique to where you are calling this from. The context is needed to store a snapshot of any values at the same point in the code where it was previously invoked
	 * @param allRecords the Trigger.new objects
	 * @param allRecordsOld the Trigger.oldMap objects. Used when necessary to determine if records are returned. Sometimes it's used, other times it's not.
	 * @param comparisonFields A list of fields the calling method is tracking. Keep this list short and consistent.
	 */
	public List<RecordState> getProcessableRecords(String context, List<SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<SObjectField> comparisonFields) {
		Long t1 = System.currentTimeMillis();

		Map<String, SObjectField> comparisonFieldsAsString = new Map<String, SObjectField>();
		for(SObjectField comparisonField : comparisonFields) {
			comparisonFieldsAsString.put(String.valueOf(comparisonField), comparisonField);
		}
		Set<String> comparisonFieldsKeySet = comparisonFieldsAsString.keySet();
		
		// check whether the records already processed should be reprocessed
		List<RecordState> processableRecords = new List<RecordState>();
		Set<Integer> sobjectIndexesToRemove = new Set<Integer>();

		// see definition of stateStore for breakdown/reasons of variable structure
		Map<Id, Map<String, Object>> currentContextStore = stateStore.get(context);
		if(currentContextStore == null) {
			currentContextStore = new Map<Id, Map<String, Object>>();
		}

		// stores sobjects temporarily when the record passed in has no Id yet (on before insert scenario)
		Map<Id, Integer> sobjectIdListPositionMappings = new Map<Id, Integer>();
		List<SObject> currentContextSObjectStore = sobjectStateStore.get(context);
		if(currentContextSObjectStore == null) {
			currentContextSObjectStore = new List<SObject>();
		}

		// stores the static values of any temporary sobject we are storing
		List<Map<String, Object>> currentContextSObjectStaticValuesMapStore = sobjectStateStoreStaticValuesMapStore.get(context);
		if(currentContextSObjectStaticValuesMapStore == null) {
			currentContextSObjectStaticValuesMapStore = new List<Map<String, Object>>();
		}
		
		// after the on before insert call any sObjects we are temporarily storing will have their Id populated by internal Salesforce
		// no other field is updated, just the objects Id which is what we need
		// in the event the temporary stored objects now have an Id we add them to a map for easy retrieval
		for(Integer i=0;i<currentContextSObjectStore.size();i++) {
			if(currentContextSObjectStore[i].Id != null) {
				sobjectIdListPositionMappings.put(currentContextSObjectStore[i].Id, i);
			}
		}

		// iterate through the records passed in to determine which records have been changed
		for(SObject sObjectRecord : allRecords) {

			// grab the index of the sobject which is used to grab the current record's position and also to remove the current record once it has an id (only relevant if it exists)
			Integer sobjectIndexPosition = sobjectIdListPositionMappings.get(sObjectRecord.Id);
			SObject currentRecordPreviousSObject = null;
			Map<String, Object> currentRecordPreviousSObjectStaticValuesMap = null;
			if(sobjectIndexPosition != null) {
				currentRecordPreviousSObject = currentContextSObjectStore[sobjectIndexPosition];
				currentRecordPreviousSObjectStaticValuesMap = currentContextSObjectStaticValuesMapStore[sobjectIndexPosition];
			}

			Map<String, Object> newState = new Map<String, Object>();
			Set<SObjectField> changedFields = new Set<SObjectField>();

			// determine the old values
			Map<String, Object> oldStateAsMap = new Map<String, Object>();
			if(sObjectRecord.Id != null && currentRecordPreviousSObject != null) {
				// this block should called subsequent to a call to this method in on before insert where a copy of the sobject record is stored without an id
				// Note that at the end of the on before insert call, salesforce copies the id to all the instances of the sobject we have created. No other fields are updated
				// NOTE: this block may be entered into in any scenario (on before/after insert/update if the previous call to this method did not clear the sobject from the sobject instance list)

				for(String comparisonField : comparisonFieldsKeySet) {
					// note currentRecordPreviousSObjectStaticValuesMap... we are pulling the static values rather than the reference value which could have been modified unintentionally in other code
					Object oldValue = currentRecordPreviousSObjectStaticValuesMap.get(comparisonField);
					Object newValue = sObjectRecord.get(comparisonField);

					if(newValue != oldValue) {
						changedFields.add(comparisonFieldsAsString.get(comparisonField));
					}
					newState.put(comparisonField, newValue);
					oldStateAsMap.put(comparisonField, oldValue);
				}

			} else if(sObjectRecord.Id == null) {
				// the record has no id yet, so we are in an on before insert scenario
				for(String comparisonField : comparisonFieldsKeySet) {
					Object newValue = sObjectRecord.get(comparisonField);

					if(newValue != null) { // the previous state is null since the previous record state was nothing since it didn't exist at all previously
						changedFields.add(comparisonFieldsAsString.get(comparisonField));
					}
					newState.put(comparisonField, newValue);
					oldStateAsMap.put(comparisonField, null);
				}

			} else if(currentContextStore.get(sObjectRecord.Id) == null && allRecordsOld == null) {
				// the record has an id, however, allRecordsOld is null which implies this is an on after insert scenario
				// NOTE: if the method was called in an on before insert scenario then subsequently on after insert, this block will only be hit after the sobject instance is removed from the list!
				for(String comparisonField : comparisonFieldsKeySet) {
					Object newValue = sObjectRecord.get(comparisonField);

					if(newValue != null) { // the previous state is null since the previous record state was nothing since it didn't exist at all previously
						changedFields.add(comparisonFieldsAsString.get(comparisonField));
					}
					newState.put(comparisonField, newValue);
					oldStateAsMap.put(comparisonField, null);
				}

			} else if(currentContextStore.get(sObjectRecord.Id) == null && allRecordsOld != null) {
				// since allRecordsOld is NOT null, this implies we are in either an on before update or on after update scenario
				// NOTE: if the method was called in an on before insert scenario then subsequently on before/after update next, this block will only be hit after the sobject instance is removed from the list!
				SObject oldSObject = allRecordsOld.get(sObjectRecord.Id);
				for(String comparisonField : comparisonFieldsKeySet) {
					Object oldValue = oldSObject.get(comparisonField);
					Object newValue = sObjectRecord.get(comparisonField);

					if(newValue != oldValue) {
						changedFields.add(comparisonFieldsAsString.get(comparisonField));
					}
					newState.put(comparisonField, newValue);
					oldStateAsMap.put(comparisonField, oldValue);

				}

			} else { // currentContextStore.get(sObjectRecord.Id) != null
				// currentContextStore has been populated from a previous call to this method
				// grab the old values from the currentContextStore
				Map<String, Object> currentValues = currentContextStore.get(sObjectRecord.Id);
				for(String comparisonField : comparisonFieldsKeySet) {
					Object oldValue = currentValues.get(comparisonField);
					Object newValue = sObjectRecord.get(comparisonField);

					if(newValue != oldValue) {
						changedFields.add(comparisonFieldsAsString.get(comparisonField));
					}
					newState.put(comparisonField, newValue);
					oldStateAsMap.put(comparisonField, oldValue);
				}
				
			}

			// confirm whether the old state duffers from the current values of the sobject
			if(!changedFields.isEmpty()) {
				processableRecords.add(new RecordState(sObjectRecord, oldStateAsMap, changedFields));
			}

			if(sObjectRecord.Id != null) {
				currentContextStore.put(sObjectRecord.Id, newState);

				if(currentRecordPreviousSObject != null) {
					sobjectIndexesToRemove.add(sobjectIndexPosition);
				}
			} else {
				currentContextSObjectStore.add(sObjectRecord);
				currentContextSObjectStaticValuesMapStore.add(newState);
			}
		}

		// remove all the processed entries
		System.debug('ApplicationRecursion: Found Unprocessed Records: ' + context + ' - Count: ' + processableRecords.size());

		// 'purge' the sobjects that we no longer need to track
		List<SObject> currentContextNewSObjectStateStore = new List<SObject>();
		List<Map<String, Object>> currentContextNewSObjectStaticValuesMapStore = new List<Map<String, Object>>();
		for(Integer i=0;i<currentContextSObjectStore.size();i++) {
			if(!sobjectIndexesToRemove.contains(i)) {
				currentContextNewSObjectStateStore.add(currentContextSObjectStore[i]);
				currentContextNewSObjectStaticValuesMapStore.add(currentContextSObjectStaticValuesMapStore[i]);
			}
		}

		stateStore.put(context, currentContextStore);
		sobjectStateStore.put(context, currentContextNewSObjectStateStore);
		sobjectStateStoreStaticValuesMapStore.put(context, currentContextNewSObjectStaticValuesMapStore);

		System.debug('ApplicationRecursion: Time to retrieve processable records: ' + (System.currentTimeMillis() - t1));

		return processableRecords;
	}

	/**
	 * Use this method to override the stored values for records within a particular context
	 * Use this method if your method has modifed values you are monitoring and you don't want reprocessing to occur because of those changes
	 * List<RecordState> param is just a convenience param... only .record will be used to reset the state 
	 * 
	 * Example: 
	 *  List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('MyCustomCaseArticlesModule', records, existingRecords, new Set<SObjectField>{Case.ReferenceID__c, Case.ArticleTest__c, Case.Subscribed__c});
	 *	// loop through our records to figure out what actions need to be taken
	 *	for(ApplicationRecursion.RecordState recordState : changedRecords) {
	 *		Case c = (Case)recordState.record;
	 *		Set<SObjectField> changed = recordState.changedFields;
	 *		if(changed == null) changed = new Set<SObjectField>();
	 *		
	 *		c.ReferenceID__c = 'value overridden, but I do not want this method to reprocess this change I just made'
	 * }
	 * ApplicationRecursion.getInstance().resetRecordState('MyCustomCaseArticlesModule', changedRecords);
	 */
	public void updateRecordState(String context, List<RecordState> modifedRecordsState, Set<SObjectField> fieldsToReset) {
		List<SObject> records = new List<SObject>();
		for(RecordState modifiedRecordState : modifedRecordsState) {
			records.add(modifiedRecordState.record);
		}
		updateRecordState(context, records, fieldsToReset);
	}

	/**
	 * Use this method to override the stored values for records within a particular context
	 * Use this method if your method has modifed values you are monitoring and you don't want reprocessing to occur because of those changes
	 * 
	 * Example: 
	 *  List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('MyCustomCaseArticlesModule', records, existingRecords, new Set<SObjectField>{Case.ReferenceID__c, Case.ArticleTest__c, Case.Subscribed__c});
	 *	// loop through our records to figure out what actions need to be taken
	 *	for(ApplicationRecursion.RecordState recordState : changedRecords) {
	 *		Case c = (Case)recordState.record;
	 *		Set<SObjectField> changed = recordState.changedFields;
	 *		if(changed == null) changed = new Set<SObjectField>();
	 *		
	 *		c.ReferenceID__c = 'value overridden, but I do not want this method to reprocess this change I just made'
	 * }
	 * ApplicationRecursion.getInstance().resetRecordState('MyCustomCaseArticlesModule', (List<SObject>)records);
	 */
	public void updateRecordState(String context, List<SObject> modifedRecords, Set<SObjectField> fieldsToReset) {
		Long t1 = System.currentTimeMillis();

		Map<String, SObjectField> resetFieldsAsString = new Map<String, SObjectField>();
		for(SObjectField resetField : fieldsToReset) {
			resetFieldsAsString.put(String.valueOf(resetField), resetField);
		}
		Set<String> resetFieldsKeySet = resetFieldsAsString.keySet();

		// see definition of stateStore for breakdown/reasons of variable structure
		Map<Id, Map<String, Object>> currentContextStore = stateStore.get(context);
		if(currentContextStore == null) {
			currentContextStore = new Map<Id, Map<String, Object>>();
		}

		// stores sobjects temporarily when the record passed in has no Id yet (on before insert scenario)
		Map<Id, Integer> sobjectIdListPositionMappings = new Map<Id, Integer>();
		List<SObject> curentContextSObjectStore = sobjectStateStore.get(context);
		if(curentContextSObjectStore == null) {
			curentContextSObjectStore = new List<SObject>();
		}

		// stores the static values of any temporary sobject we are storing
		List<Map<String, Object>> currentContextSObjectStaticValuesMapStore = sobjectStateStoreStaticValuesMapStore.get(context);
		if(currentContextSObjectStaticValuesMapStore == null) {
			currentContextSObjectStaticValuesMapStore = new List<Map<String, Object>>();
		}

		for(Sobject record : modifedRecords) {
			for(Integer i=0;i<curentContextSObjectStore.size();i++) {
				if(curentContextSObjectStore[i] === record || (record.Id != null && curentContextSObjectStore[i].Id == record.Id)) {
					for(String resetField : resetFieldsKeySet) {
						currentContextSObjectStaticValuesMapStore[i].put(resetField, record.get(resetField));
					}
					break;
				}
			}

			if(record.Id != null && currentContextStore.get(record.Id) != null) {
				for(String resetField : resetFieldsKeySet) {
					currentContextStore.get(record.Id).put(resetField, record.get(resetField));
				}
			}
		}

		System.debug('ApplicationRecursion: Reset state time: ' + (System.currentTimeMillis() - t1));
	}

	public class RecordState {
		public Set<SObjectField> changedFields = new Set<SObjectField>();
		public Map<String, Object> previousState = new Map<String, Object>();
		public SObject record;

		public RecordState(SObject record, Map<String, Object> previousState, Set<SObjectField> changedFields) {
			this.record = record;
			this.previousState = previousState;
			this.changedFields = changedFields;
		}
	}
}