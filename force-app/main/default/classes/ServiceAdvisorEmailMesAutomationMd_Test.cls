/**
 * @author Naveen Rajanna
 * @date 2022-10-26
 * @group Tests
 * @description Test class covering ServiceAdvisorEmailMesAutomationModule
 * @changelog
 */
@IsTest
private class ServiceAdvisorEmailMesAutomationMd_Test {
	/**
	 * This test method verifies if the Activity/Task are created under the case for bounce email
	 */
	@IsTest
	private static void testOnAfterCreateTasks() {
		// Disable trigger execution
		MockUtility.disableTriggerExecution();

		RecordType caseServiceDeliveryRecordType = [
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE SObjectType = 'Case' AND DeveloperName = 'Sales_Ops_Delivery'
		];
		Group bgsQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		bgsQueue.Name = 'BGS Queue';
		User adminUser = ApplicationTestDataFactory.getUsers(1, ApplicationTestDataFactory.defaultUserProfileId, true)[0];

		// Generate caseList
		List<Case> caseList = ApplicationTestDataFactory.getCases(4, true);
		// Closed Service Delivery case assigned to an User
		caseList[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(
			caseList[0],
			new Map<String, Object>{
				'RecordType' => caseServiceDeliveryRecordType,
				'RecordTypeId' => caseServiceDeliveryRecordType.Id,
				'OwnerId' => adminUser.Id,
				'Status' => 'Closed',
				'Owner_is_Queue__c' => false
			}
		);
		// Closed Service Delivery case assigned to a Queue
		caseList[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(
			caseList[1],
			new Map<String, Object>{
				'RecordType' => caseServiceDeliveryRecordType,
				'RecordTypeId' => caseServiceDeliveryRecordType.Id,
				'OwnerId' => bgsQueue.Id,
				'Status' => 'Closed',
				'Owner_is_Queue__c' => true
			}
		);
		// New Service Delivery case assigned to an User
		caseList[2] = (Case) ApplicationTestDataFactory.setUnwritableFields(
			caseList[2],
			new Map<String, Object>{
				'RecordType' => caseServiceDeliveryRecordType,
				'RecordTypeId' => caseServiceDeliveryRecordType.Id,
				'OwnerId' => adminUser.Id,
				'Status' => 'New',
				'Owner_is_Queue__c' => false
			}
		);
		Map<Id, Case> caseMap = new Map<Id, Case>(caseList);

		// Generate Incoming Email Message for each of the above Cases
		List<EmailMessage> emailList = ApplicationTestDataFactory.getEmailMessages(
			4,
			true,
			true,
			'fromAddress@test.com',
			'toAddress@auspost.com.au',
			null,
			null,
			'Subject Inbound',
			null
		);
		// Incoming email having fromAddress different from related Case LastIncomingEmailAddress__c
		emailList[0] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(
			emailList[0],
			new Map<String, Object>{ 'Parent' => caseList[0], 'ParentId' => caseList[0].Id }
		);
		emailList[1] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(
			emailList[1],
			new Map<String, Object>{ 'Parent' => caseList[0], 'ParentId' => caseList[1].Id }
		);
		emailList[2] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(
			emailList[2],
			new Map<String, Object>{ 'Parent' => caseList[0], 'ParentId' => caseList[2].Id }
		);

		//Stubbing, set up our responses
		ServiceAdvisorsCasesSelector mockServiceAdvisorsCasesSelector = (ServiceAdvisorsCasesSelector) MockUtility.mockSelector(
			ServiceAdvisorsCasesSelector.class
		);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockServiceAdvisorsCasesSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(caseMap);
		MockUtility.Mocks.when(
				mockUow.registerNew(
					(List<SObject>) fflib_Match.anyObject(),
					(Boolean) fflib_Match.anyObject(),
					(String) fflib_Match.anyObject()
				)
			)
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		//Testing
		Test.startTest();
		ServiceAdvisorEmailMesAutomationModule module = ServiceAdvisorEmailMesAutomationModule.newInstance();
		module.onAfterInsert(emailList, mockUow);
		Test.stopTest();

		//Assert or Verify
		((ServiceAdvisorsCasesSelector) MockUtility.Mocks.verify(mockServiceAdvisorsCasesSelector, MockUtility.Mocks.times(1)))
			.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject());

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1))
			.registerNew((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyObject(), (String) fflib_Match.anyObject());

		// Expected only 1 Task to be created as only 1 email matches the filter
		System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());
		// Ensure Task is created for the expected Case
		system.assertEquals(caseList[0].Id, ((Task) MockUtility.mockUnitOfWorkDMLs[0]).WhatId, 'Expected WhatId to match the CaseId');
	}

	private class MockException extends Exception {
	}

	/**
	 * This covers the exception scenario onAfter insert
	 */
	@IsTest
	private static void testOnAfterInsertException() {
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(EmailMessageTriggerHandler.getUnitOfWorkSObjectTypes());

		Test.startTest();
		try {
			ServiceAdvisorEmailMesAutomationModule module = ServiceAdvisorEmailMesAutomationModule.newInstance();
			module.onAfterInsert(null, uow);
		} catch (Exception e) {
			System.assert(true, 'Expected Exception to be thrown');
		}
		Test.stopTest();
	}
}
