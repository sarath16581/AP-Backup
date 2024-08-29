/**
 * @author Seth Heang
 * @group Tests
 * @tag Case, ImpactedArticle__c
 * @domain Core
 * @description Test class for UnifiedCaseCreationController
 * @changelog
 * 2024-08-29 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
public with sharing class UnifiedCaseCreationControllerTest {

	/**
	 *	Test getCaseRecordTypeInfos() with valid record type names
	 *	And verify that the record types return successfully
	 */
	@IsTest
	static void testGetCaseRecordTypeInfosWithValidNames() {
		// =====================================
		// Data Preparation
		// =====================================
		// Test with valid developer names
		List<String> developerNames = new List<String>{'UnifiedInvestigation', 'UnifiedGeneralEnquiry'};

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> result = UnifiedCaseCreationController.getCaseRecordTypeInfos(developerNames);
		Test.stopTest();

		// Verify the results
		Assert.areEqual(2, result.size());
		for (String recordTypeId : result.keySet()) {
			Map<String, Object> recordTypeInfo = (Map<String, Object>) result.get(recordTypeId);
			Assert.isTrue(developerNames.contains((String)recordTypeInfo.get('developerName')), 'Expected developerName to exists but was not found');
			Assert.isNotNull(recordTypeInfo.get('recordTypeId'), 'Expected recordTypeId to exists but was not found');
			Assert.isNotNull((recordTypeInfo.get('name')), 'Expected name to exists but was not found');
			Assert.isTrue(recordTypeInfo.containsKey('available'), 'Expected available key to exists but was not found');
			Assert.isTrue(recordTypeInfo.containsKey('defaultRecordTypeMapping'), 'Expected defaultRecordTypeMapping key to exists but was not found');
			Assert.isTrue(recordTypeInfo.containsKey('master'), 'Expected master key to exists but was not found');
		}
	}

	/**
	 *	Test getCaseRecordTypeInfos() with invalid record type names
	 *	And verify that the record types return blank result
	 */
	@IsTest
	static void testGetCaseRecordTypeInfosWithInvalidNames() {
		// =====================================
		// Data Preparation
		// =====================================
		// Test with invalid developer names
		List<String> developerNames = new List<String>{'Business_Account', 'Consumer', 'InvalidName'};

		// =====================================
		// Testing
		// =====================================
		Map<String, Object> resultWithInvalidNames = UnifiedCaseCreationController.getCaseRecordTypeInfos(developerNames);

		// Verify the results should be empty
		Assert.areEqual(0, resultWithInvalidNames.size());
	}

	/**
	 *	Test getCaseRecordTypeInfos() with invalid input
	 *	And verify that exception is thrown with pre-defined generic message
	 */
	@IsTest
	static void testGetCaseRecordTypeInfosExceptionHandling() {
		// =====================================
		// Testing
		// =====================================
		try {
			Test.startTest();
			UnifiedCaseCreationController.getCaseRecordTypeInfos(null);
			Test.stopTest();
		}
		catch(AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Expected error message to match but instead got: ' + ex.getMessage());
		}

		try {
			Test.startTest();
			UnifiedCaseCreationController.getCaseRecordTypeInfos(new List<String>());
			Test.stopTest();
		}
		catch(AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Expected error message to match but instead got: ' + ex.getMessage());
		}
	}
}