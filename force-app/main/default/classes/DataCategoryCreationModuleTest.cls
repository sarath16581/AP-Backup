@isTest
public with sharing class DataCategoryCreationModuleTest {
	@TestSetup
	static void testData() {
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getOrgDefaults();
		logLevel.LoggingLevel__c = 'ERROR';
		logLevel.SetupOwnerId = UserInfo.getOrganizationId();

		upsert logLevel;
	}

	@isTest
	public static void testKnowledgeModleAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		insert criticalIncidents;
		List<Sobject> sobjects = [SELECT Id, RecordTypeId FROM Knowledge__kav];
		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		DataCategoryCreationModule module = DataCategoryCreationModule.newInstance();
		module.onAfterInsert(sobjects, mockUow);
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());
		module.onAfterInsert(sobjects, null);
		Test.stopTest();
		List<ExceptionLog__c> elList = new List<ExceptionLog__c>([SELECT Id, ClassName__C, MethodName__c, ExceptionCode__c, ExceptionDetails__c FROM ExceptionLog__c LIMIT 1]);
		System.assertEquals(1, elList.Size(), 'Error created');
	}

	@isTest
	public static void testKnowledgeModleAfterUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		insert criticalIncidents;
		Map<Id, Sobject> sobjects = new Map<Id, Sobject>();
		for (Sobject obj : [SELECT Id, RecordTypeId FROM Knowledge__kav]) {
			sobjects.put(obj.Id, obj);
		}
		List<Sobject> updateSobjects = new List<Sobject>();
		for (Sobject obj : [SELECT Id, RecordTypeId FROM Knowledge__kav]) {
			obj.put('Title', 'Title');
			updateSobjects.add(obj);
		}
		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		DataCategoryCreationModule module = DataCategoryCreationModule.newInstance();
		module.onAfterUpdate(updateSobjects, sobjects, mockUow);
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		module.onAfterUpdate(updateSobjects, sobjects, null);
		Test.stopTest();

		List<ExceptionLog__c> elList = new List<ExceptionLog__c>([SELECT Id, ClassName__C, MethodName__c, ExceptionCode__c, ExceptionDetails__c FROM ExceptionLog__c LIMIT 1]);
		System.assertEquals(1, elList.Size(), 'Error created');
	}
}