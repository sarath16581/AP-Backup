/**
 * @author Ken McGuire
 * @date 2022-04-22
 * @description Test class to cover Entry Conditions functionality
 * @changelog
 */
@IsTest
private class EntryConditions_Test {

	@IsTest
	private static void testEntryConditionMetForAllValues() {

		//Given
		string testSurveyName = 'Test Survey';
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
		Map<String,Object> entryConditionsFieldValueMap = new Map<String,Object> {
			'Status' => new List<String>{'New','Open'}, 
			'Subject' => 'Case Subject 1',
			'Description' => 'Case Description 1'
		};
		EntryConditions entryConditions = EntryConditions.getInstance();

		// When
		entryConditions.createEntryConditions(testSurveyName, entryConditionsFieldValueMap,'All');

		// Then
		Boolean meetsEntryConditions = entryConditions.meetsEntryConditions(testSurveyName,caseRecord);
		System.assert(meetsEntryConditions,'Entry Condition should be met for All values');
	}

	@IsTest
	static void testEntryConditionMetForAnyValues() {

		// Given
		string testSurveyName = 'Test Survey';
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
		Map<String,Object> entryConditionsFieldValueMap = new Map<String,Object> {
			'Status' => new List<String>{'New','Open'}, 
			'Subject' => 'Case Subject NA',
			'Description' => 'Case Description NA'
		};
		EntryConditions entryConditions = EntryConditions.getInstance();

		// When
		entryConditions.createEntryConditions(testSurveyName,entryConditionsFieldValueMap,'Any');

		// Then
		Boolean meetsEntryConditions = entryConditions.meetsEntryConditions(testSurveyName,caseRecord);
		System.assert(meetsEntryConditions,'Entry Condition should be met for Any value');
		
	}

  	@IsTest
	private static void testEntryConditionNotMetForAllValues() {

		//Given
		string testSurveyName = 'Test Survey';
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
		Map<String,Object> entryConditionsFieldValueMap = new Map<String,Object> {
			'Status' => new List<String>{'Closed'},
			'Subject' => 'Case Subject 1',
			'Description' => 'Case Description 1'
		};
		EntryConditions entryConditions = EntryConditions.getInstance();

		// When
		entryConditions.createEntryConditions(testSurveyName,entryConditionsFieldValueMap,'All');

		// Then
		Boolean meetsEntryConditions = entryConditions.meetsEntryConditions(testSurveyName,caseRecord);
		System.assert(meetsEntryConditions==false,'Entry Condition should not be met for All values');

	}

	@IsTest
	private static void testEntryConditionNotMetForAnyValues() {

		// Given
		string testSurveyName = 'Test Survey';
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
		Map<String,Object> entryConditionsFieldValueMap = new Map<String,Object> {
			'Status' => 'Closed',
			'Subject' => 'Case Subject NA',
			'Description' => 'Case Description NA'
		};
		EntryConditions entryConditions = EntryConditions.getInstance();

		// When
		entryConditions.createEntryConditions(testSurveyName,entryConditionsFieldValueMap,'Any');

		// Then
		Boolean meetsEntryConditions = entryConditions.meetsEntryConditions(testSurveyName,caseRecord);
		System.assert(meetsEntryConditions==false,'Entry Condition should be met for Any value');

	}
    
    @IsTest
	private static void testEntryConditionContainsMetForAllValues() {

		//Given
		string testSurveyName = 'Test Survey';
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
        caseRecord.Contact_Email__c = 'test@strattrack.com.au';
        caseRecord.Origin = 'Internal - Other';
		Map<String,Object> entryConditionsFieldValueMap = new Map<String,Object> {
			'Status' => new List<String>{'New','Open'}, 
			'Subject' => 'Case Subject 1',
			'Description' => 'Case Description 1',
            'contains' => new Map<String,Object> {
				'Contact_Email__c' => new List<String>{'@auspost.com.au','@strattrack.com.au'},
                'Origin' => 'Internal -'
			}
		};
		EntryConditions entryConditions = EntryConditions.getInstance();

		// When
		entryConditions.createEntryConditions(testSurveyName, entryConditionsFieldValueMap,'All');

		// Then
		Boolean meetsEntryConditions = entryConditions.meetsEntryConditions(testSurveyName,caseRecord);
		System.assert(meetsEntryConditions,'Entry Condition should be met for All values');
	}
    
    @IsTest
	private static void testEntryConditionNotContainsMetForAllValues() {

		//Given
		string testSurveyName = 'Test Survey';
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
        caseRecord.Contact_Email__c = 'test@strattrack.com.au';
        caseRecord.Origin = 'Internal - Other';
		Map<String,Object> entryConditionsFieldValueMap = new Map<String,Object> {
			'Status' => new List<String>{'New','Open'}, 
			'Subject' => 'Case Subject 1',
			'Description' => 'Case Description 1',
            'notContains' => new Map<String,Object> {
				'Contact_Email__c' => new List<String>{'@auspost.com.au','@strattrack.com.au'},
                'Origin' => 'Internal -'
			}
		};
		EntryConditions entryConditions = EntryConditions.getInstance();

		// When
		entryConditions.createEntryConditions(testSurveyName, entryConditionsFieldValueMap,'All');

		// Then
		Boolean meetsEntryConditions = entryConditions.meetsEntryConditions(testSurveyName,caseRecord);
		System.assertEquals(false,meetsEntryConditions,'Entry Condition should not be met for All values');
	}
    
}