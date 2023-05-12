/**
 * @description Determines which records should be processed during a trigger iteration
 * @author Nathan Franklin
 * @date 2019-02-20
 * @deprecated Replaced with ApplicationRecursion
 * @changelog
 */
public inherited sharing class RecursionUtility {

	/**
	 * Stores the context and a Map of Record Id and joined string values for hashing (if necessary)
	 */
	@TestVisible
	private static Map<String, Map<Id, Integer>> processedRecords = new Map<String, Map<Id, Integer>>();

	/**
	 * @deprecated Replaced with ApplicationRecursion
	 */
	public static List<SObject> getUnprocessedRecords(String context, List<SObject> allRecords) {
		return getUnprocessedRecords(context, allRecords, null);
	}

	/**
	 * @deprecated Replaced with ApplicationRecursion
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
}