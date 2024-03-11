/**
 * @description Utility class to help with easier mocking in text classes
 * @author Nathan Franklin
 * @date 2020-04-24
 * @group Tests
 * @tags mocking, apex mocks, tests
 * @changelog
 * 2020-08-02 - Nathan Franklin - Added new generic DML answers
 * 2021-10-15 - Nathan Franklin - Add new AnswerVoid class
 * 2022-07-28 - Sreenish Krishnan - Added DMLUpsert logic
 * 2023-03-21 - Nathan Franklin - Added some DML insert/update captor helper methods
 * 2023-05-16 - Sarath Burra - Added a method Method to typecast the List<Object> into List<List<SObject>> returned from the fflib_ArgumentCaptor.getAllValues()
 * 2024-03-07 - Mahesh Parvathaneni - Updated mockSelector to include setForUpdate
 */
@IsTest
public class MockUtility {

	/**
	 * Whenever the AnswerGenericDMLInserted/AnswerGenericDMLUpdated is used, these will store a reference to the record that was inserted
	 * This is used to verify the records that would be created
	 */
	public static List<SObject> mockDMLInsertedRecords = new List<SObject>();
	public static List<SObject> mockDMLUpdatedRecords = new List<SObject>();
	public static List<SObject> mockDMLUpsertedRecords = new List<SObject>();
	public static List<SObject> mockUnitOfWorkDMLs = new List<SObject>();

	public static fflib_ApexMocks Mocks {
		get {
			if(Mocks == null) {
				Mocks = new fflib_ApexMocks();
			}
			return Mocks;
		}
		private set;
	}

	/**
	 * Use this to mock Selector classes in unit tests
	 */
	public static ApplicationSelector mockSelector(Type selectorType) {
		ApplicationSelector selector = (ApplicationSelector)Mocks.mock(selectorType);

		// A little hack here to stub any chained methods
		// This ensures that chained methods will not unexpectedly return null
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(selector.setLimit(fflib_Match.anyInteger())).thenReturn(selector);
		MockUtility.Mocks.when(selector.setOffset(fflib_Match.anyInteger())).thenReturn(selector);
		MockUtility.Mocks.when(selector.setFieldOverrides((Set<SObjectField>)fflib_Match.anyObject())).thenReturn(selector);
		MockUtility.Mocks.when(selector.setFieldOverrides((Map<SObjectType, Set<SObjectField>>)fflib_Match.anyObject())).thenReturn(selector);
		MockUtility.Mocks.when(selector.setForUpdate(fflib_Match.anyBoolean())).thenReturn(selector);
		MockUtility.Mocks.stopStubbing();

		Application.Selectors.setMock(selectorType, selector);

		return selector;
	}

	/**
	 * Use this to mock Utility classes in unit tests
	 */
	public static Object mockUtility(Type utilityType) {
		Object utility = Mocks.mock(utilityType);
		Application.Utilities.setMock(utilityType, utility);
		return utility;
	}

	/**
	 * Use this to mock Domain classes in unit tests
	 */
	public static Object mockDomain(Type domainType) {
		ApplicationDomain domain = (ApplicationDomain)Mocks.mock(domainType);
		Application.Domains.setMock(domainType, domain);
		return domain;
	}

	/**
	 * Use this to mock Module classes in unit tests
	 */
	public static Object mockModule(Type moduleType) {
		ApplicationModule module = (ApplicationModule)Mocks.mock(moduleType);
		Application.Modules.setMock(moduleType, module);
		return module;
	}

	/**
	 * Use this to return a stubbed ApplicationDatabase instance
	 */
	public static ApplicationDatabase mockDatabase() {
		ApplicationDatabase utility = (ApplicationDatabase)Mocks.mock(ApplicationDatabase.class);
		Application.Utilities.setMock(ApplicationDatabase.class, utility);
		return utility;
	}

	/**
	 * Use this to return a stubbed ApplicationUnitOfWork instance - Added Mathew
	 */
	public static ApplicationUnitOfWork mockUnitOfWork() {
		ApplicationUnitOfWork utility = (ApplicationUnitOfWork)Mocks.mock(ApplicationUnitOfWork.class);
		Application.Utilities.setMock(ApplicationUnitOfWork.class, utility);
		return utility;
	}

	/**
	 * Stubs the Application domain to stop all trigger processing
	 * Useful to load records for integration style testing.
	 */
	public static void disableTriggerExecution() {
		SystemSettings__c settings = new SystemSettings__c(Disable_Triggers__c = true);
		insert settings;

//	  // redirect calls made to the domain to the stub class we generate
//	  fflib_ApexMocks mocks = new fflib_ApexMocks();
//	  ApplicationDomain mockDomain = (ApplicationDomain)mocks.mock(ApplicationDomain.class);
//	  Application.Domains.setMock(mockDomain);
//	  return mockDomain;
	}

	// ======================================================
	// DML Insert captor helpers
	public static List<SObject> verifyAndCaptureInsertedDmlRecords(ApplicationDatabase mockDatabase) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)recordCaptor.capture());
		return (List<SObject>)recordCaptor.getValue();
	}

	public static List<SObject> verifyAndCaptureInsertedDmlRecords(ApplicationDatabase mockDatabase, Boolean allOrNothing) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)recordCaptor.capture(), fflib_Match.eqBoolean(allOrNothing));
		return (List<SObject>)recordCaptor.getValue();
	}

	public static List<List<SObject>> verifyAndCaptureInsertedDmlRecords(ApplicationDatabase mockDatabase, Integer timesExecuted) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(timesExecuted))).dmlInsert((List<SObject>)recordCaptor.capture());
		return typeCastObject(recordCaptor.getAllValues());
	}

	public static List<List<SObject>> verifyAndCaptureInsertedDmlRecords(ApplicationDatabase mockDatabase, Boolean allOrNothing, Integer timesExecuted) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(timesExecuted))).dmlInsert((List<SObject>)recordCaptor.capture(), fflib_Match.eqBoolean(allOrNothing));
		return typeCastObject(recordCaptor.getAllValues());
	}
	// ======================================================

	// ======================================================
	// DML Update captor helpers
	public static List<SObject> verifyAndCaptureUpdatedDmlRecords(ApplicationDatabase mockDatabase) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)recordCaptor.capture());
		return (List<SObject>)recordCaptor.getValue();
	}

	public static List<SObject> verifyAndCaptureUpdatedDmlRecords(ApplicationDatabase mockDatabase, Boolean allOrNothing) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)recordCaptor.capture(), fflib_Match.eqBoolean(allOrNothing));
		return (List<SObject>)recordCaptor.getValue();
	}

	public static List<List<SObject>> verifyAndCaptureUpdatedDmlRecords(ApplicationDatabase mockDatabase, Integer timesExecuted) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(timesExecuted))).dmlUpdate((List<SObject>)recordCaptor.capture());
		return typeCastObject(recordCaptor.getAllValues());
	}

	public static List<List<SObject>> verifyAndCaptureUpdatedDmlRecords(ApplicationDatabase mockDatabase, Boolean allOrNothing, Integer timesExecuted) {
		fflib_ArgumentCaptor recordCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(timesExecuted))).dmlUpdate((List<SObject>)recordCaptor.capture(), fflib_Match.eqBoolean(allOrNothing));
		return typeCastObject(recordCaptor.getAllValues());
	}
	// ======================================================
	// Method to typecast the List<Object> into List<List<SObject>> returned from the fflib_ArgumentCaptor.getAllValues()
	public static List<List<SObject>> typeCastObject(List<Object> values){
		List<List<SObject>> retValues = new List<List<SObject>>();
		for(Object obj :values){
			retValues.add((List<SObject>)obj);
		}
		return retValues;
	}
	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLInserted implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				record.Id = fflib_IDGenerator.generate(record.getSObjectType());

				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}

			// store a list of the records that were updated when this answer is invoked.
			mockDMLInsertedRecords.addAll(records);

			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLFailed implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'message' => 'The request failed because of some random error'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLFailedLockError implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'statusCode' => 'UNABLE_TO_LOCK_ROW',
										'message' => 'unable to obtain exclusive access to this record or 1 records: 000000000000000'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML update operation
	 */
	public class AnswerGenericDMLUpdated implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}

			// store a list of the records that were updated when this answer is invoked.
			mockDMLUpdatedRecords.addAll(records);

			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML upsert operation
	 */
	public class AnswerGenericDMLUpserted implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> upsertResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				record.Id = fflib_IDGenerator.generate(record.getSObjectType());
				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				upsertResults.add(result);
			}

			// store a list of the records that were upserted when this answer is invoked.
			mockDMLUpsertedRecords.addAll(records);

			List<Database.UpsertResult> result = (List<Database.UpsertResult>)JSON.deserialize(JSON.serialize(upsertResults), List<Database.UpsertResult>.class);
			return result;
		}
	}



	/**
	 * A simple Answer class to set an Id on the record to simulate a DML delete operation
	 */
	public class AnswerGenericDMLDeleted implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}
			List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLDeleteFailed implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'message' => 'The request failed because of some random error'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLDeleteFailedLockError implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'statusCode' => 'UNABLE_TO_LOCK_ROW',
										'message' => 'unable to obtain exclusive access to this record or 1 records: 000000000000000'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericRegisterUnitOfWorkDML implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			Boolean isList = (invocation.getArgument(0) instanceof List<SObject>);
			List<SObject> records = (isList ? (List<SObject>)invocation.getArgument(0) : new List<SObject>{(SObject)invocation.getArgument(0)});
			// store a list of the records that were updated when this answer is invoked.
			mockUnitOfWorkDMLs.addAll(records);
			return  (isList ? (Object)records : (Object)records[0]);
		}
	}

	/**
	 * This Answer is used for methods requiring mocking that return VOID
	 * Example public void doThing() { }
	 */
	public class AnswerVoid implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			return null;
		}
	}

}