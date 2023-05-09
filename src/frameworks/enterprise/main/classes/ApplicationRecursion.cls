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
	@TestVisible
	private Map<String, Map<Id, Map<String, Object>>> stateStore = new Map<String, Map<Id, Map<String, Object>>>();

	public static ApplicationRecursion getInstance() {
		return (ApplicationRecursion)Application.Utilities.getInstance(ApplicationRecursion.class);
	}

	/**
	 * This will filter the records passed in and remove all the records that have already been processed for the current context
	 * An initial call to this method (per single context) will compare the oldMap records vs the newMap records.
	 * Subsequent calls to this method (per single context) will only compare the previous state (the comparison of when this method was last called) vs the newMap.
	 * The reason why this method exists is the prevent unnecessary reexecution of code when key field values have not been changed between the different stages of recursion execution throughout a single transaction
	 * NOTE: the oldMap values are ignored in subsequent iterations after the initial call
	 * NOTE: onBeforeInsert is NOT supported!
	 * NOTE: For consistency ApplicationRecursion class can still be used in an after insert context, however take special note that all records will be returned and all monitored fields will be flagged as changed
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
	public Map<Id, RecordState> getProcessableRecords(String context, List<SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<SObjectField> comparisonFields) {
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
	 * NOTE: onBeforeInsert is NOT supported!
	 * NOTE: For consistency ApplicationRecursion class can still be used in an after insert context, however take special note that all records will be returned and all monitored fields will be flagged as changed
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
	private Map<Id, RecordState> getProcessableRecords(String context, List<SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<String> comparisonFields) {
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
		for(SObject sObjectRecord : allRecords) {
			if(sObjectRecord.Id == null) {
				// records without an id are not support (on onBeforeInsert)
				continue;
			}

			if(currentState.get(sObjectRecord.Id) == null && allRecordsOld == null) {
				// this implies that we are calling this method onAfterInsert
				// the unique behaviour of onAfterInsert is to prime the state and return all the records flagging each monitored field as changed
				// this is so this method can be used consistently rather than having separate logic for insert vs update

				// grab the old state as a map so that the original values can be passed back to caller
				Map<String, Object> oldStateAsMap = new Map<String, Object>();
				for(String comparisonField : comparisonFields) {
					oldStateAsMap.put(comparisonField, null); // these values technically went from null to having a value
				}

				processableRecords.put(sObjectRecord.Id, new RecordState(sObjectRecord, oldStateAsMap, comparisonFields));

			} else if(currentState.get(sObjectRecord.Id) == null) {
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
		System.debug('ApplicationRecursion: Found Unprocessed Records: ' + context + ' - ' + processableRecords.keySet());

		stateStore.put(context, currentState);

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