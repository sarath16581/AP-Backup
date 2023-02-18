/**
 * @description
 * Test class for SalesRecordSharingModule
 * @author Ken McGuire
 * @group Tests
 * @domain Sales
 * @changelog
 * 2022-11-28 - Ken McGuire - Created.
 * 2023-02-13 - Ranjeewa Silva - Added tests to verify behaviour in undelete scenario.
 */
@isTest
private class SalesRecordSharingModule_Test {

	/**
	 * Test to ensure sharing service is called for newly inserted records where account lookup field is populated.
	 */
	@isTest
	private static void testEnsureAfterInsertShareRecordsWithSalesTeam() {
		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(2, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccount.Id;
		aprs[1].Legal_Entity_Name_LookUp__c = null;

		SalesRecordSharingService.SalesSharingObjectMapping objectMapping = new SalesRecordSharingService.SalesSharingObjectMapping(
				APR__c.SObjectType,
				APR__c.Legal_Entity_Name_LookUp__c,
				'mockrelname',
				'mocksharingreason'
		);

		// =====================================
		// Stubbing
		// =====================================s

		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationUnitOfWork mockUow =  (ApplicationUnitOfWork) MockUtility.mockUtility(ApplicationUnitOfWork.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType))).thenReturn(objectMapping);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================s
		Test.startTest();

		// pass in the aprs. note a new list instance is created passing in the objects returned from ApplicationTestDataFactory.
		// this is to ensure aprs.getSObjectType() when called from the method under test functions as expected.
		SalesRecordSharingModule.newInstance().onAfterInsert(new List<APR__c>(aprs), mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor shareRecordsCapture = fflib_ArgumentCaptor.forClass(Map<Id, SObject>.class);
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).shareRecords((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType), (Map<Id, SObject>)shareRecordsCapture.capture(), fflib_Match.eqBoolean(false), (ApplicationUnitOfWork)fflib_Match.anyObject());
		Map<Id, SObject> shareRecordsCaptureParams = (Map<Id, SObject>)shareRecordsCapture.getValue();
		System.assertEquals(1, shareRecordsCaptureParams.size(),'Only the APR__c record with account lookup populated should be submitted for sharing.');
		System.assert(shareRecordsCaptureParams.containsKey(aprs[0].Id),'Only the APR__c record with account lookup populated should be submitted for sharing.');
	}

	/**
	 * Test to ensure any sharing exceptions encountered while inserting new records are logged.
	 */
	@isTest
	private static void testEnsureAfterInsertLogsExceptionsThrownFromSharingService() {
		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(2, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccount.Id;
		aprs[1].Legal_Entity_Name_LookUp__c = parentAccount.Id;

		// =====================================
		// Stubbing
		// =====================================s

		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationUnitOfWork mockUow =  (ApplicationUnitOfWork) MockUtility.mockUtility(ApplicationUnitOfWork.class);
		ApplicationLogger mockLogger = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType))).thenThrow(new SalesRecordSharingService.SalesRecordSharingException('test'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================s
		Test.startTest();

		// pass in the aprs. note a new list instance is created passing in the objects returned from ApplicationTestDataFactory.
		// this is to ensure aprs.getSObjectType() when called from the method under test functions as expected.
		SalesRecordSharingModule.newInstance().onAfterInsert(new List<APR__c>(aprs), mockUow);

		Test.stopTest();

		// verify the sharing configuration is requested from service for APR__c
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType));

		// verify an exception is logged
		((ApplicationLogger) MockUtility.Mocks.verify(mockLogger, MockUtility.Mocks.times(1))).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.eq(ApplicationLogger.LoggingLevel.ERROR));
	}

	/**
	 * Test to ensure sharing service is called for updated records only when account lookup field is changed.
	 */
	@isTest
	private static void testEnsureAfterUpdateShareRecordsWithSalesTeam() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, true);

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(2, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;
		aprs[1].Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;

		List<APR__c> aprsUpdated = new List<APR__c>{aprs[0].clone(true), aprs[1].clone(true)};
		// update account lookup field on aprs[0]
		aprsUpdated[0].Legal_Entity_Name_LookUp__c = parentAccounts[1].Id;
		// update an unrelated field on aprs[1]
		aprsUpdated[1].Type__c = 'StarTrack APR';

		SalesRecordSharingService.SalesSharingObjectMapping objectMapping = new SalesRecordSharingService.SalesSharingObjectMapping(
				APR__c.SObjectType,
				APR__c.Legal_Entity_Name_LookUp__c,
				'mockrelname',
				'mocksharingreason'
		);

		// =====================================
		// Stubbing
		// =====================================s

		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationUnitOfWork mockUow =  (ApplicationUnitOfWork) MockUtility.mockUtility(ApplicationUnitOfWork.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType))).thenReturn(objectMapping);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================s
		Test.startTest();

		SalesRecordSharingModule.newInstance().onAfterUpdate(aprsUpdated, new Map<Id, APR__c>(aprs), mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor shareRecordsCapture = fflib_ArgumentCaptor.forClass(Map<Id, SObject>.class);
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).shareRecords((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType), (Map<Id, SObject>)shareRecordsCapture.capture(), fflib_Match.eqBoolean(true), (ApplicationUnitOfWork)fflib_Match.anyObject());
		Map<Id, SObject> shareRecordsCaptureParams = (Map<Id, SObject>)shareRecordsCapture.getValue();
		System.assertEquals(1, shareRecordsCaptureParams.size(),'Only the APR__c record where account lookup is changing should be submitted for sharing.');
		System.assert(shareRecordsCaptureParams.containsKey(aprs[0].Id),'Only the APR__c record where account lookup is changing should be submitted for sharing.');
	}

	/**
	 * Test to ensure any sharing exceptions encountered while updating records are logged.
	 */
	@isTest
	private static void testEnsureAfterUpdateLogsExceptionsThrownFromSharingService() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, true);

		APR__c apr = ApplicationTestDataFactory.getAPRs(1, null, null, true)[0];
		apr.Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;

		APR__c aprUpdated = apr.clone(true);
		// update account lookup field on apr
		aprUpdated.Legal_Entity_Name_LookUp__c = parentAccounts[1].Id;


		// =====================================
		// Stubbing
		// =====================================s

		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationUnitOfWork mockUow =  (ApplicationUnitOfWork) MockUtility.mockUtility(ApplicationUnitOfWork.class);
		ApplicationLogger mockLogger = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType))).thenThrow(new SalesRecordSharingService.SalesRecordSharingException('test'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================s
		Test.startTest();

		SalesRecordSharingModule.newInstance().onAfterUpdate(new List<APR__c>{aprUpdated}, new Map<Id,APR__c>{apr.Id => apr}, mockUow);

		Test.stopTest();

		// verify the sharing configuration is requested from service for APR__c
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType));

		// verify an exception is logged
		((ApplicationLogger) MockUtility.Mocks.verify(mockLogger, MockUtility.Mocks.times(1))).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.eq(ApplicationLogger.LoggingLevel.ERROR));
	}

	/**
	 * Test to ensure sharing service is called for undeleted records where account lookup field is populated.
	 */
	@isTest
	private static void testEnsureAfterUndeleteShareRecordsWithSalesTeam() {
		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(2, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccount.Id;
		aprs[1].Legal_Entity_Name_LookUp__c = null;

		SalesRecordSharingService.SalesSharingObjectMapping objectMapping = new SalesRecordSharingService.SalesSharingObjectMapping(
				APR__c.SObjectType,
				APR__c.Legal_Entity_Name_LookUp__c,
				'mockrelname',
				'mocksharingreason'
		);

		// =====================================
		// Stubbing
		// =====================================s

		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationUnitOfWork mockUow =  (ApplicationUnitOfWork) MockUtility.mockUtility(ApplicationUnitOfWork.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType))).thenReturn(objectMapping);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================s
		Test.startTest();

		SalesRecordSharingModule.newInstance().onAfterUndelete(new List<APR__c>(aprs), mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor shareRecordsCapture = fflib_ArgumentCaptor.forClass(Map<Id, SObject>.class);
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).shareRecords((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType), (Map<Id, SObject>)shareRecordsCapture.capture(), fflib_Match.eqBoolean(true), (ApplicationUnitOfWork)fflib_Match.anyObject());
		Map<Id, SObject> shareRecordsCaptureParams = (Map<Id, SObject>)shareRecordsCapture.getValue();
		System.assertEquals(1, shareRecordsCaptureParams.size(),'Only the APR__c record with account lookup populated should be submitted for sharing.');
		System.assert(shareRecordsCaptureParams.containsKey(aprs[0].Id),'Only the APR__c record with account lookup populated should be submitted for sharing.');
	}

	/**
	 * Test to ensure any sharing exceptions encountered while undeleting records are logged.
	 */
	@isTest
	private static void testEnsureAfterUndeleteLogsExceptionsThrownFromSharingService() {
		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(2, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccount.Id;
		aprs[1].Legal_Entity_Name_LookUp__c = parentAccount.Id;

		// =====================================
		// Stubbing
		// =====================================s

		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationUnitOfWork mockUow =  (ApplicationUnitOfWork) MockUtility.mockUtility(ApplicationUnitOfWork.class);
		ApplicationLogger mockLogger = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType))).thenThrow(new SalesRecordSharingService.SalesRecordSharingException('test'));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================s
		Test.startTest();

		SalesRecordSharingModule.newInstance().onAfterUndelete(new List<APR__c>(aprs), mockUow);

		Test.stopTest();

		// verify the sharing configuration is requested from service for APR__c
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getSharingConfiguration((SObjectType)fflib_Match.eqSObjectType(APR__c.SObjectType));

		// verify an exception is logged
		((ApplicationLogger) MockUtility.Mocks.verify(mockLogger, MockUtility.Mocks.times(1))).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.eq(ApplicationLogger.LoggingLevel.ERROR));
	}
}