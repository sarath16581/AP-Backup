/**
 * @description 
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
     */
    @TestVisible
    private Map<String, Map<Id, String>> stateStore = new Map<String, Map<Id, String>>();

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
	public Map<Id, SObject> getProcessableRecords(String context, Map<Id, SObject> allRecords, Map<Id, SObject> allRecordsOld, Set<SObjectField> comparisonFields) {
		Long t1 = System.currentTimeMillis();
        
        // check whether the records already processed should be reprocessed
        Map<Id, SObject> processableRecords = new Map<Id, SObject>(allRecords);
		Map<Id, String> currentState = stateStore.get(context);

		if(currentState == null) {
			// this is the first time this context has been passed in for this transaction
			currentState = new Map<Id, String>();

			for(SObject record : allRecords.values()) {
				if(allRecordsOld.get(record.Id) == null) {
					// what the actual....
					continue;
				}

				// concatenate the tracked fields together so we can get a hashCode to compare it against the values passed in originally
				String newJoinedValues = '';
				for (SObjectField comparisonField : comparisonFields) {
					newJoinedValues += String.valueOf(record.get(comparisonField));
				}

				// concatenate the tracked fields together so we can get a hashCode to compare it against the values passed in originally
				String oldJoinedValues = '';
				for (SObjectField comparisonField : comparisonFields) {
					oldJoinedValues += String.valueOf(allRecordsOld.get(record.Id).get(comparisonField));
				}

				if(!newJoinedValues.equals(oldJoinedValues)) {
					processableRecords.put(record.Id, record);
				}

				currentState.put(record.Id, newJoinedValues);
			}
		} else {
			// this context has been passed in previously for this transaction
			// we ignore allRecordsOld values here and only compare the current state with the last state derived from the previous call to this method (for the same context)
			for(SObject record : allRecords.values()) {
				if(currentState.get(record.Id) == null && allRecordsOld.get(record.Id) == null) {
					// what the actual....
					continue;
				}

				// concatenate the tracked fields together so we can get a hashCode to compare it against the values passed in originally
				String newJoinedValues = '';
				for (SObjectField comparisonField : comparisonFields) {
					newJoinedValues += String.valueOf(record.get(comparisonField));
				}

				if(currentState.get(record.Id) == null) {
					// this is the first time this record has been passed into the method (even though this method has been called previously with the same context)
					// we do a comparison on the oldMap records in this scenario 

					// concatenate the tracked fields together so we can get a hashCode to compare it against the values passed in originally
					String oldJoinedValues = '';
					for (SObjectField comparisonField : comparisonFields) {
						oldJoinedValues += String.valueOf(allRecordsOld.get(record.Id).get(comparisonField));
					}

					if(!newJoinedValues.equals(oldJoinedValues)) {
						processableRecords.put(record.Id, record);
					}
				} else {
					// this record already exists in the state from a previous call
					// we compare the current values of the record against the values that were previously seen to determine whether the calling method should reprocess the record

					if(!newJoinedValues.equals(currentState.get(record.Id))) {
						processableRecords.put(record.Id, record);
					}

				}

				currentState.put(record.Id, newJoinedValues);
			}
		}

		// remove all the processed entries
        System.debug('>> Found Unprocessed Records: ' + context + ' - ' + processableRecords.keySet());

        Long t2 = System.currentTimeMillis();

        System.debug('| RecursionUtility: Time to retrieve unprocessed record: ' + (t2 - t1));

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
                //      we will compare the original values against the new values and include the record for reprocessing if they are different.
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

}