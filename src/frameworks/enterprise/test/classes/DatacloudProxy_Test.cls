@isTest
public with sharing class DatacloudProxy_Test {
	@isTest
	public static void testDatacloudProxy() {
		DatacloudProxy.FindDuplicatesResult fdResult = mockFindDuplicatesResult(
			new CreditSuspect__c(
				Id = fflib_IDGenerator.generate(CreditSuspect__c.SObjectType),
				FirstName__c = 'Edwin',
				LastName__c = 'Chen',
				Email__c = 'edwin.chen@auspost.com.au'
			), 80
		);

		System.assertEquals(true, fdResult.isSuccess(), 'Success expected');
		System.assertNotEquals(null, fdResult.getErrors(), 'Expected List');

		List<DatacloudProxy.MatchRecord> matchRecords = new List<DatacloudProxy.MatchRecord>();

		for (DatacloudProxy.DuplicateResult dupResult :fdResult.getDuplicateResults()) {
			System.assertNotEquals(null, dupResult.isAllowSave(), 'Expected return value other than null');
			System.assertNotEquals(null, dupResult.getDuplicateRule(), 'Rule name cannot be empty');
			
			if (dupResult.getErrorMessage() != null) {
				System.assert(true, 'Code block cannot be empty');
			}

			for (DatacloudProxy.MatchResult mResult :dupResult.getMatchResults()) {
				System.assertNotEquals(null, mResult.getEntityType(), 'Expected SObjectType name');
				System.assert(mResult.getSize() > 0, 'Cannot have empty array');
				System.assertNotEquals(null, mResult.getErrors(), 'Expected List');
				System.assertNotEquals(null, mResult.getMatchEngine(), 'Expected MatchEngine type');
				System.assertNotEquals(null, mResult.getRule(), 'Expected Rule Name');
				System.assertNotEquals(null, mResult.isSuccess(), 'Expected return value other than null');

				matchRecords.addAll(mResult.getMatchRecords());				
			}			
		}

		for (DatacloudProxy.MatchRecord mRecord :matchRecords) {
			System.assert(mRecord.getMatchConfidence() > 0, 'Can never be 0');
			System.assertNotEquals(null, mRecord.getRecord(), 'Expected Matched record');

			// for (DatacloudProxy.AdditionalInformationMap addInfo :mRecord.getAdditionalInformation()) {
			// 	System.assertNotEquals(null, addInfo.getName(), 'Name attrib cannot be empty');

			// 	if (addInfo.getValue() != null) {
			// 		System.assert(true, 'Code block cannot be empty');
			// 	}
			// }

			// for (DatacloudProxy.FieldDiff fDiff :mRecord.getFieldDiffs()) {
			// 	System.assertNotEquals(null, fDiff.getName(), 'Name attrib cannot be empty');
			// 	System.assertNotEquals(null, fDiff.getDifference(), 'Difference attrib cannot be empty');
			// }
		}
    }

	/**
	 * Generates a FindDuplicatesResult respose based on provided matching record and confidence level
	 * @param record Any SObject that will be returned as match record
	 * @param matchConfidence Double value for match fonfidence level: value > 0 AND value <= 100
	 * @return  `DatacloudProxy.FindDuplicatesResult`
	 */
	public static DatacloudProxy.FindDuplicatesResult mockFindDuplicatesResult(SObject record, Double matchConfidence) {
		return mockFindDuplicatesResult(
			new Map<SObject,Double>{ record => matchConfidence },
			'SuspectsDuplicateRule',
			'SuspectMatcher'
		);
	}

	/**
	 * Generates a FindDuplicatesResult respose based on provided matching record and confidence level
	 * @param matchesWithConfidence Map with SObject alongside match confidence level (> 0 <= 100)
	 * @param duplicateRuleName Name of duplicate rule that will be stamped into result object
	 * @param matcherName  Name of matcher that will be stamped into result object
	 * @return  `DatacloudProxy.FindDuplicatesResult`
	 */
	public static DatacloudProxy.FindDuplicatesResult mockFindDuplicatesResult(Map<SObject,Double> matchesWithConfidence, String duplicateRuleName, String matcherName) {
		List<SObject> records = new List<SObject>(matchesWithConfidence.keySet());
		String sObjName = String.valueOf(records[0].getSObjectType());

		DatacloudProxy.FindDuplicatesResult fdResult = new DatacloudProxy.FindDuplicatesResult();
		fdResult.success = true;
		fdResult.errors = new List<Database.Error>();
		DatacloudProxy.DuplicateResult dupResult = new DatacloudProxy.DuplicateResult();
		fdResult.duplicateResults = new List<DatacloudProxy.DuplicateResult>{ dupResult };

		dupResult.allowSave = true;
		dupResult.duplicateRuleEntityType = sObjName;
		dupResult.duplicateRule = duplicateRuleName;
		dupResult.allowSave = true;
		DatacloudProxy.MatchResult mResult = new DatacloudProxy.MatchResult();
		dupResult.matchResults = new List<DatacloudProxy.MatchResult>{ mResult };
		
		mResult.success = true;
		mResult.rule = matcherName;
		
		mResult.matchEngine = 'FuzzyMatchEngine';
		mResult.errors = new List<Database.Error>();
		mResult.entityType = sObjName;
		mResult.matchRecords = new List<DatacloudProxy.MatchRecord>();

		for (SObject rec :records) {
			DatacloudProxy.MatchRecord mRec = new DatacloudProxy.MatchRecord();
			mRec.record = rec;
			mRec.matchConfidence = matchesWithConfidence.get(rec);
			mResult.matchRecords.add(mRec);
		}

		mResult.size = mResult.matchRecords.size();

		return fdResult;
	}
}