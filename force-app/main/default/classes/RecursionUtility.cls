/**
 * @description Determines which records should be processed during a trigger iteration
 * @author Nathan Franklin
 * @date 2019-02-20
 * @changelog
 * 2023-05-04 - Nathan Franklin - Reimagine the method to get processable records
 */
public inherited sharing class RecursionUtility {

	/**
	 * Stores the context and a Map of Record Id and joined string values for hashing (if necessary)
	 */
	@TestVisible
	private static Map<String, Map<Id, Integer>> processedRecords = new Map<String, Map<Id, Integer>>();

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

	public static RecursionUtility getInstance() {
		return (RecursionUtility)Application.Utilities.getInstance(RecursionUtility.class);
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
	public Map<Id, RecordState> getProcessableRecords(String context, Map<Id, SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<SObjectField> comparisonFields) {
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
	 * @param allRecordsOld the Trigger.oldMap objects. NOTE: This is used to capture the initial state of a record's values where this is method is invoked for the first time within a transaction.... This parameter will be ignore in subsequent iterations of this method for the same context
	 * @param comparisonFields Any records where the values have changed in comparisonFields will cause the record to reappear in the processable records list.
	 */
	public Map<Id, RecordState> getProcessableRecords(String context, Map<Id, SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<String> comparisonFields) {
		Long t1 = System.currentTimeMillis();
		
		// check whether the records already processed should be reprocessed
		Map<Id, RecordState> processableRecords = new Map<Id, RecordState>();

		// see definition of stateStore for breakdown/reasons of variable structure
		Map<Id, Map<String, Object>> currentState = stateStore.get(context);
		if(currentState == null) {
			currentState = new Map<Id, Map<String, Object>>();
		}
	
		// iterate through the records passed in... if the record has not previously been processed previously, then we use the oldMap vallues to compare against
		// 	if the record has previously been processed then we use the previous values at the time the last method was called
		for(SObject sObjectRecord : allRecords.values()) {
			if(currentState.get(sObjectRecord.Id) == null && allRecordsOld.get(sObjectRecord.Id) == null) {
				// what the....
				continue;
			}

			if(currentState.get(sObjectRecord.Id) == null) {
				// this is the first time this specific record has been passed into the method (even though this method has been called previously with the same context)
				// we do a comparison on the oldMap records in this scenario 
				SObject oldRecord = allRecordsOld.get(sObjectRecord.Id);

				// grab the changed values between current state and previous state
				Set<String> changedFields = new Set<String>();
				for(String comparisonField : comparisonFields) {
					if(sObjectRecord.get(comparisonField) != oldRecord.get(comparisonField)) {
						changedFields.add(comparisonField);
					}
				}

				// grab the old state as a map so that the original values can be passed back to caller
				Map<String, Object> oldStateAsMap = new Map<String, Object>();
				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, oldRecord.get(comparisonField));
				}

				if(!changedFields.isEmpty()) {
					processableRecords.put(sObjectRecord.Id, new RecordState(sObjectRecord, oldStateAsMap, changedFields));
				}
			} else {
				// this record already exists in the state from a previous call
				// we compare the current values of the record against the values that were previously seen to determine whether the calling method should reprocess the record
				Map<String, Object> oldRecord = currentState.get(sObjectRecord.Id);

				// grab the changed values between current state and previous state
				Set<String> changedFields = new Set<String>();
				for(String comparisonField : comparisonFields) {
					if(sObjectRecord.get(comparisonField) != oldRecord.get(comparisonField)) {
						changedFields.add(comparisonField);
					}
				}

				if(!changedFields.isEmpty()) {
					processableRecords.put(sObjectRecord.Id, new RecordState(sObjectRecord, oldRecord, changedFields));
				}
			}

			Map<String, Object> newState = new Map<String, Object>();
			for(String comparisonField : comparisonFields) {
				newState.put(comparisonField, sObjectRecord.get(comparisonField));
			}

			currentState.put(sObjectRecord.Id, newState);
		}

		// remove all the processed entries
		System.debug('RecursionUtility: Found Unprocessed Records: ' + context + ' - ' + processableRecords.keySet());

		stateStore.put(context, currentState);

		System.debug('RecursionUtility: Time to retrieve processable records: ' + (System.currentTimeMillis() - t1));

		return processableRecords;
	}

	/**
	 * @deprecated DO NOT USE ANYMORE... Look at getProcessableRecords
	 */
	public static List<SObject> getUnprocessedRecords(String context, List<SObject> allRecords) {
		return getUnprocessedRecords(context, allRecords, null);
	}

	/**
	 * @deprecated DO NOT USE ANYMORE... Look at getProcessableRecords
	 */
	public static List<SObject> getUnprocessedRecords(String context, List<SObject> allRecords, Set<String> comparisonFields) {
		Long t1 = System.currentTimeMillis();
		if(processedRecords.get(context) == null)
			processedRecords.put(context, new Map<Id, Integer>());

		// check whether the records already processed should be reprocessed
		Map<Id, Integer> processedRecordsContext = processedRecords.get(context);
		Map<Id, SObject> processableRecords = new Map<Id, SObject>(allRecords);

		for(SObject record : allRecords) {
			if(comparisonFields != null) {

				// if comparisonFields are passed in, we need to keep track of these values....
				// the next time the method is called with the same context with the comparisonFields parameter set,
				//	  we will compare the original values against the new values and include the record for reprocessing if they are different.
				// This method is useful to ensure we are not needlessly reprocessing the same records over and agin with any reason to.

				// concatenate the tracked fields together so we can get a hashCode to compare it against the values passed in originally
				String joinedValues = '';
				for (String comparisonField : comparisonFields) {
					joinedValues += String.valueOf(record.get(comparisonField));
				}

				if (processedRecordsContext.containsKey(record.Id) && processedRecordsContext.get(record.Id) == joinedValues.hashCode()) {
					// the values passed into this method this time around are the same from the last time this record was processed....
					// we don't need to process this record again
					processableRecords.remove(record.Id);
				} else {
					// either this record has not been processed yet OR the fields we are tracking for the record/context combination have changed since the last time they were processed
					// because of this, this record will be reprocessed and we then mark this record as processed with the new hashCode
					processedRecordsContext.put(record.Id, joinedValues.hashCode());
				}
			} else {
				if(processedRecordsContext.containsKey(record.Id)) {
					// this record has already been processed and does not need to be processed again
					processableRecords.remove(record.Id);
				} else {
					// this record has not been processed yet so leave it in the processableRecords and mark it as processed so it won't process again the next time around.
					processedRecordsContext.put(record.Id, 0); // zero for hascode since it's not used}
				}
			}
		}

		// remove all the processed entries
		System.debug('>> Found Unprocessed Records: ' + context + ' - ' + processableRecords.keySet());

		Long t2 = System.currentTimeMillis();

		System.debug('| RecursionUtility: Time to retrieve unprocessed record: ' + (t2 - t1));

		return processableRecords.values();

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