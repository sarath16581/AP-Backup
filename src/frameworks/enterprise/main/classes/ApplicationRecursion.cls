/**
 * @description Determines which records should be processed during a trigger iteration
 * @author Nathan Franklin
 * @date 2023-05-05
 * @changelog
 */
public inherited sharing class ApplicationRecursion {

	/**
	 * Usually when a record is inserted, subsequent config based automation such as workflows, process builders etc... will fire an iteration of the update trigger cycles
	 * This will usually mean that the insert triggers and the update triggers will fire in the same transaction.
	 * For consistency ApplicationRecursion class can still be used in an after insert context, however we need to 
	 */

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
	private Map<String, Map<Id, Map<String, Object>>> stateStore = new Map<String, Map<Id, Map<String, Object>>>();

	/**
	 * Used to temporarily store sobject in the event a record is passed in without an id
	 * This sobject is used as the 'oldState' up until the same record is passed back in with an id.
	 * After this, the oldState will be transferred to 'stateStore' variable.
	 * This is used in on before insert scenarios
	 * NOTE: after the on before insert call any sObjects we are temporarily storing will have their Id populated by internal Salesforce functionality. By the time on after insert is called on a trigger these temporary SObjects stored here will have an Id
				no other field is updated, just the objects Id which is what we need
	 * 
	 * Map<String> -- the context name
	 * Map<String, List<SObject>> -- the sobject instance
	 */
	private Map<String, List<SObject>> sobjectStateStore = new Map<String, List<SObject>>();

	public static ApplicationRecursion getInstance() {
		return (ApplicationRecursion)Application.Utilities.getInstance(ApplicationRecursion.class);
	}

	/**
	 * This will filter the records passed in and remove all the records that have already been processed for the current context
	 * An initial call to this method (per single context) will compare the oldMap records vs the newMap records.
	 * Subsequent calls to this method (per single context) will only compare the previous state (the comparison of when this method was last called) vs the newMap.
	 * The reason why this method exists is the prevent unnecessary reexecution of code when key field values have not been changed between the different stages of recursion execution throughout a single transaction
	 * NOTE: the oldMap values are ignored in subsequent iterations after the initial call
	 *  
	 * Example... 
	 * 1. An update trigger is fired, your method is called. You compare oldMap vs newMap and find out you have work to do
	 * 2. At the end of the update cycle, workflow, flow, etc... are processed and then another iteration of update fires
	 * 3. The second iteration of your method is fired, You compare oldMap vs newMap again and realised oldMap holds the same values as they were right at the start of the transaction and your method then proceeds to do the same work again as it did in the initial update iteration
	 * Applying a call to this method will prevent a subsequent iteration
	 * 
	 * NOTE: comparisonFields must remain the same (per single context) for each call into this method to avoid unexpected results
	 *
	 * @param context Any name that is unique to where you are calling this from. The context is needed to store a snapshot of any values at the same point in the code where it was previously invoked
	 * @param allRecords the Trigger.newMap objects
	 * @param allRecordsOld the Trigger.oldMap objects. NOTE: This is used to capture the initial state of a record's values where this is method is invoked for the first time within a transaction.... This parameter will be ignore in subsequent iterations of this method for the same context
	 * @param comparisonFields Any records where the values have changed in comparisonFields will cause the record to reappear in the processable records list.
	 */
	public List<RecordState> getProcessableRecords(String context, List<SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<SObjectField> comparisonFields) {
		Set<String> comparisonFieldsAsString = new Set<String>();
		for(SObjectField comparisonField : comparisonFields) {
			comparisonFieldsAsString.add(String.valueOf(comparisonField));
		}
		return getProcessableRecords(context, allRecords, allRecordsOld, comparisonFieldsAsString);
	}

	/**
	 * This will filter the records passed in and remove all the records that have already been processed for the current context
	 * An initial call to this method (per single context) will compare the oldMap records vs the newMap records.
	 * Subsequent calls to this method (per single context) will only compare the previous state (the comparison of when this method was last called) vs the newMap.
	 * The reason why this method exists is the prevent unnecessary reexecution of code when key field values have not been changed between the different stages of recursion execution throughout a single transaction
	 * NOTE: the oldMap values are ignored in subsequent iterations after the initial call
	 *  
	 * Example... 
	 * 1. An update trigger is fired, your method is called. You compare oldMap vs newMap and find out you have work to do
	 * 2. At the end of the update cycle, workflow, flow, etc... are processed and then another iteration of update fires
	 * 3. The second iteration of your method is fired, You compare oldMap vs newMap again and realised oldMap holds the same values as they were right at the start of the transaction and your method then proceeds to do the same work again as it did in the initial update iteration
	 * Applying a call to this method will prevent a subsequent iteration
	 * 
	 * NOTE: comparisonFields must remain the same (per single context) for each call into this method to avoid unexpected results
	 *
	 * @param context Any name that is unique to where you are calling this from. The context is needed to store a snapshot of any values at the same point in the code where it was previously invoked
	 * @param allRecords the Trigger.newMap objects
	 * @param allRecordsOld the Trigger.oldMap objects. NOTE: This is used to capture the initial state of a record's values where this is method is invoked for the first time within a transaction....
	 * @param comparisonFields Any records where the values have changed in comparisonFields will cause the record to reappear in the processable records list.
	 */
	private List<RecordState> getProcessableRecords(String context, List<SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<String> comparisonFields) {
		Long t1 = System.currentTimeMillis();
		
		// check whether the records already processed should be reprocessed
		List<RecordState> processableRecords = new List<RecordState>();
		Set<Id> processableIds = new Set<Id>();

		// see definition of stateStore for breakdown/reasons of variable structure
		Map<Id, Map<String, Object>> currentState = stateStore.get(context);
		if(currentState == null) {
			currentState = new Map<Id, Map<String, Object>>();
		}

		// stores sobjects temporarily when the record passed in has no Id yet (on before insert scenario)
		Map<Id, Integer> sobjectIdListPositionMappings = new Map<Id, Integer>();
		List<SObject> sobjectCurrentState = sobjectStateStore.get(context);
		if(sobjectCurrentState == null) {
			sobjectCurrentState = new List<SObject>();
		}
		
		// after the on before insert call any sObjects we are temporarily storing will have their Id populated by internal Salesforce
		// no other field is updated, just the objects Id which is what we need
		// in the event the temporary stored objects now have an Id we add them to a map for easy retrieval
		for(Integer i=0;i<sobjectCurrentState.size();i++) {
			if(sobjectCurrentState[i].Id != null) {
				sobjectIdListPositionMappings.put(sobjectCurrentState[i].Id, i);
			}
		}

		// iterate through the records passed in to determine which records have been changed
		for(SObject sObjectRecord : allRecords) {

			// grab the index of the sobject which is used to grab the current record's position and also to remove the current record once it has an id (only relevant if it exists)
			Integer sobjectIndexPosition = sobjectIdListPositionMappings.get(sObjectRecord.Id);
			SObject previousSObjectState = null;
			if(sobjectIndexPosition != null) {
				previousSObjectState = sobjectCurrentState[sobjectIndexPosition];
			}

			// determine the old values
			Map<String, Object> oldStateAsMap = new Map<String, Object>();
			if(sObjectRecord.Id != null && previousSObjectState != null) {
				// this block should called subsequent to a call to this method in on before insert where a copy of the sobject record is stored without an id
				// Note that at the end of the on before insert call, salesforce copies the id to all the instances of the sobject we have created. No other fields are updated
				// NOTE: this block may be entered into in any scenario (on before/after insert/update if the previous call to this method did not clear the sobject from the sobject instance list)

				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, previousSObjectState.get(comparisonField));
				}

			} else if(sObjectRecord.Id == null) {
				// the record has no id yet, so we are in an on before insert scenario
				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, null); // the previous state is null since the previous record state was nothing since it didn't exist at all previously
				}

			} else if(currentState.get(sObjectRecord.Id) == null && allRecordsOld == null) {
				// the record has an id, however, allRecordsOld is null which implies this is an on after insert scenario
				// NOTE: if the method was called in an on before insert scenario then subsequently on after insert, this block will only be hit after the sobject instance is removed from the list!
				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, null); // the previous state is null since the previous record state was nothing since it didn't exist at all previously
				}

			} else if(currentState.get(sObjectRecord.Id) == null && allRecordsOld != null) {
				// since allRecordsOld is NOT null, this implies we are in either an on before update or on after update scenario
				// NOTE: if the method was called in an on before insert scenario then subsequently on before/after update next, this block will only be hit after the sobject instance is removed from the list!
				SObject previousSObject = allRecordsOld.get(sObjectRecord.Id);
				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, previousSObject.get(comparisonField)); // the previous state is null since the previous record state was nothing since it didn't exist at all previously
				}

			} else { // currentState.get(sObjectRecord.Id) != null
				// currentState has been populated from a previous call to this method
				// grab the old values from the currentState
				Map<String, Object> currentValues = currentState.get(sObjectRecord.Id);
				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, currentValues.get(comparisonField));
				}
				
			}

			Map<String, Object> newState = new Map<String, Object>();
			Set<String> changedFields = new Set<String>();

			for(String comparisonField : comparisonFields) {
				if(sObjectRecord.get(comparisonField) != oldStateAsMap.get(comparisonField)) {
					changedFields.add(comparisonField);
				}
				newState.put(comparisonField, sObjectRecord.get(comparisonField));
			}

			// confirm whether the old state duffers from the current values of the sobject
			if(!changedFields.isEmpty()) {
				processableRecords.add(new RecordState(sObjectRecord, oldStateAsMap, changedFields));
			}

			if(sObjectRecord.Id != null) {
				currentState.put(sObjectRecord.Id, newState);

				if(previousSObjectState != null) {
					sobjectCurrentState.remove(sobjectIndexPosition);
				}
			} else {
				sobjectCurrentState.add(sObjectRecord);
			}
		}

		// remove all the processed entries
		System.debug('ApplicationRecursion: Found Unprocessed Records: ' + context + ' - Count: ' + processableRecords.size());

		stateStore.put(context, currentState);
		sobjectStateStore.put(context, sobjectCurrentState);

		System.debug('ApplicationRecursion: Time to retrieve processable records: ' + (System.currentTimeMillis() - t1));

		return processableRecords;
	}

	public class RecordState {
		public Set<String> changedFields = new Set<String>();
		public Map<String, Object> previousState = new Map<String, Object>();
		public SObject record;

		public RecordState(SObject record, Map<String, Object> previousState, Set<String> changedFields) {
			this.record = record;
			this.previousState = previousState;
			this.changedFields = changedFields;
		}
	}
}