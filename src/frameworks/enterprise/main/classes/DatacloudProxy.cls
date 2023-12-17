public inherited sharing class DatacloudProxy {

    public class FindDuplicatesResult { 
		public List<DuplicateResult> duplicateResults;
		public List<Database.Error> errors;
		public Boolean success;

		/**
		 * @return  Returns a list of DuplicateResult objects representing the results of calling FindDuplicates.findDuplicates(sObjects) 
		 * or FindDuplicatesByIds.findDuplicatesByIds(ids). Elements in the list correspond to sObjects or IDs in the input list.
		 */
		public List<DuplicateResult> getDuplicateResults() {
			return duplicateResults;
		}
		
		/**
		 * @return  Returns a list of DatabaseError objects containing errors resulting from calling FindDuplicates.findDuplicates(sObjects)
		 * or FindDuplicatesByIds.findDuplicatesByIds(ids), if errors were encountered.
		 */		
		public List<Database.Error> getErrors() {
			return errors;
		}

		/**
		 * @return  Returns a Boolean signifying whether the call to FindDuplicates.findDuplicates(sObjects)
		 * or FindDuplicatesByIds.findDuplicatesByIds(ids) was successful.
		 */
		public Boolean isSuccess() {
			return success;
		}
	}

	public class DuplicateResult {
		public List<MatchResult> matchResults;
		public String errorMessage;
		public String duplicateRule;
		public Boolean allowSave;
		public String duplicateRuleEntityType;

		public List<MatchResult> getMatchResults() {
			return matchResults;
		}

		/**
		 * @return Returns the error message configured by the administrator to warn users they may be creating duplicate records. This message is associated with a duplicate rule.
		 */
		public String getErrorMessage() {
			return errorMessage;
		}

		/**
		 * @return Returns the developer name of the executed duplicate rule that returned duplicate records.
		 */
		public String getDuplicateRule() {
			return duplicateRule;
		}

		/**
		 * @return Indicates whether the duplicate rule will allow a record that’s identified as a duplicate to be saved. Set to true if duplicate rule should allow save; otherwise, false.
		 */
		public Boolean isAllowSave() {
			return allowSave;
		}
	}

	public class MatchResult {
		public String entityType;
		public List<MatchRecord> matchRecords;
		public List<Database.Error> errors;
		public String matchEngine;
		public String rule;
		public Integer size;
		public Boolean success;

		/**
		 * @return the entity type of the matching rule.
		 */
		public String getEntityType() {
			return entityType;
		}

		/**
		 * @return errors that occurred during matching for the matching rule.
		 */
		public List<Database.Error> getErrors() {
			return errors;
		}

		/**
		 * @return the match engine for the matching rule.
		 */
		public String getMatchEngine() {
			return matchEngine;
		}

		/**
		 * @return information about the duplicates for the matching rule.
		 */
		public List<DatacloudProxy.MatchRecord> getMatchRecords() {
			return matchRecords;
		}

		/**
		 * @return the developer name of the matching rule.
		 */
		public String getRule() {
			return rule;
		}

		/**
		 * @return the number of duplicates detected by the matching rule.
		 */
		public Integer getSize() {
			return size;
		}

		/**
		 * @return false if there’s an error with the matching rule, and true if the matching rule successfully ran.
		 */
		public Boolean isSuccess() {
			return success;
		}
	}

	public class MatchRecord {
		// public List<AdditionalInformationMap> additionalInformation;
		// public List<FieldDiff> fieldDiffs;
		public Double matchConfidence;
		public SObject record;

		// /**
		//  * @returns other information about a matched record. For example, a matchGrade represents the quality of the data for the D&B fields in the matched record.
		//  */
		// public List<AdditionalInformationMap> getAdditionalInformation() {
		// 	return additionalInformation;
		// }

		// /**
		//  * @returns all matching rule fields and how each field value compares for the duplicate and its matching record.
		//  */
		// public List<FieldDiff> getFieldDiffs() {
		// 	return fieldDiffs;
		// }

		/**
		 * @returns the ranking of how similar a matched record’s data is to the data in your request. Must be equal to or greater than the value of the minMatchConfidence specified in your request. Returns -1 if unused.
		 */
		public Double getMatchConfidence() {
			return matchConfidence;
		}

		/**
		 * @returns the fields and field values for the duplicate.
		 */
		public SObject getRecord() {
			return record;
		}
	}

	// public class AdditionalInformationMap {
	// 	public String name;
	// 	public String value;

	// 	public String getName() {
	// 		return name;
	// 	}

	// 	public String getValue() {
	// 		return value;
	// 	}
	// }

	// public class FieldDiff {
	// 	public String difference;
	// 	public String name;

	// 	/**
	// 	 * @returns how the field values compare for the duplicate and its matching record.
	// 	 */
	// 	public String getDifference() {
	// 		return difference;
	// 	}
	// 	/**
	// 	 * @returns the name of a field on a matching rule that detected duplicates.
	// 	 */
	// 	public String getName() {
	// 		return name;
	// 	}
	// }
}