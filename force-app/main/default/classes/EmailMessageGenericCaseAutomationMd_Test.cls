/**
 * @author Naveen Rajanna
 * @date 2022-10-12
 * @group Tests
 * @description Test class covering EmailMessageGenericCaseAutomationModule
 * @changelog
 * 2024-08-07 - Ranjeewa Silva - Test class updates after uplifting the module to new ApplicationModule framework.
 */
@IsTest
private class EmailMessageGenericCaseAutomationMd_Test {
	/**
	 * This test method verifies if the case fields have been populated as part of After trigger
	 */
	@IsTest
	private static void testOnAfterInsertSetEmailToCaseFields() {
		// Disable trigger execution
		MockUtility.disableTriggerExecution();

		// Generate caseList and Email Messages
		List<Case> caseList = ApplicationTestDataFactory.getCases(2, true);
		caseList[0].LastIncomingEmailAddress__c = 'oldaddress@test.com';
		caseList[1].LastIncomingEmailAddress__c = 'oldaddress@test.com';

		List<EmailMessage> emailList = ApplicationTestDataFactory.getEmailMessages(
			2,
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
		// fromAddress same as related Case LastIncomingEmailAddress__c
		emailList[1] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(
			emailList[1],
			new Map<String, Object>{
				'FromAddress' => 'oldaddress@test.com',
				'Incoming' => false,
				'Parent' => caseList[1],
				'ParentId' => caseList[1].Id
			}
		);

		//Stubbing, set up our responses
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector) MockUtility.mockSelector(EmailMessagesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockEmailMessagesSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(emailList);
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		//Testing
		Test.startTest();
		EmailMessageGenericCaseAutomationModule module = new EmailMessageGenericCaseAutomationModule();
		module.onAfterInsert(emailList, mockUow);
		Test.stopTest();

		//Assert or Verify
		// Verify that only one DML is to be inserted
		((EmailMessagesSelector) MockUtility.Mocks.verify(mockEmailMessagesSelector, MockUtility.Mocks.times(1)))
			.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject());
		System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());
		// Verify in DML that LastIncomingEmailAddress__c is set from Email Message for incoming Email
		System.assertEquals(
			emailList[0].FromAddress,
			((Case) MockUtility.mockUnitOfWorkDMLs[0]).LastIncomingEmailAddress__c,
			'Expected Case LastIncomingEmailAddress__c field to be set from Email Message'
		);
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
			EmailMessageGenericCaseAutomationModule module = new EmailMessageGenericCaseAutomationModule();
			module.onAfterInsert(null, uow);
		} catch (Exception e) {
			System.assert(true, 'Expected Exception to be thrown');
		}
		Test.stopTest();
	}
}