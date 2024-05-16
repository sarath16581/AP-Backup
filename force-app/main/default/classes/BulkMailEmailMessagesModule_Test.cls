/**
 * @description Test class for BulkMaiEmailMessagesModule
 * @author Boris Bachovski
 * @date 14/05/2024
 * @changelog
*/

@IsTest
private class BulkMailEmailMessagesModule_Test {
	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the related cases have been updated with the correct email to address and other mappings based on the CMDT, when a new case is created via email-to-case
	*/
	@IsTest
	static void testAfterInsertUpdateRelatedCases() {
		final String productType = 'Reply Paid';
		final String casePurpose = 'Other';

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Id bulkMailRecordTypeId = BulkMailCaseService.getInstance().getBulkMailRecordTypeId();

		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
		caseRecord.RecordTypeId = bulkMailRecordTypeId;
		caseRecord.Priority = 'Low';
		caseRecord.Origin = 'Email';
		caseRecord.Permanent_Close__c = false;
		
		EmailMessage emailMessageRecord = ApplicationTestDataFactory.getEmailMessages(1, true, true, 'test@test.com', 'replypaid@auspost.com.au', 'Test Subject', caseRecord.Id)[0];
		emailMessageRecord.Headers = 'Return-Path: caseroutingtesting+caf_=caseroutingtesting=5-1iz5gu7n9ir9bqev6o9wspvpigsnywv2e31uhnp8iy8rfd9fq6.0k-edoeeag.cs57.case.sandbox.salesforce.com@gmail.com\nX-SFDC-Binding: coremailprocessor\nX-SFDC-DOMAINKEYS: None\nX-SFDC-TLS-VERIFIED: no\nX-SFDC-TLS-CIPHER: AES256-SHA\nX-SFDC-TLS-STATUS: true\nX-SFDC-SENDERID-PRA: Pass\nX-SFDC-SENDERID: None\nX-SFDC-SPF: None\nSFDC-Interface: external\nReceived: from [182.50.78.79] ([182.50.78.79:39388] helo=smtp16-tyo.mta.salesforce.com) by mx4-sjl.mta.salesforce.com (envelope-from <>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=AES256-SHA)  id 83/4F-23732-69D72A35; Thu, 19 May 2023 06:05:10 +0000\nMessage-ID: <0D.1F.12049.19D72A35@mx2-tyo.mta.salesforce.com>\nFrom: Mail Delivery System <mailer-daemon@salesforce.com>\nTo: someone.someone@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.com\nX-MS-Exchange-ForwardingLoop: replypaid@auspost.com.au;5195231b-cd74-45a4-b576-9bc88ae35b48\nDate: Thu, 19 May 2023 06:05:05 +0000';
		emailMessageRecord = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(emailMessageRecord, new Map <String, Object>{'ParentId' => caseRecord.Id});
		
		caseRecord = (Case)ApplicationTestDataFactory.setChildRelationships(caseRecord,new Map <String, List <SObject>> {'EmailMessages' => new List <EmailMessage>{ emailMessageRecord }});

		EmailToCaseMapping__mdt emailToCaseMapping = ApplicationTestDataFactory.getEmailToCaseMappings(1, 'replypaid@auspost.com.au', true)[0];
		emailToCaseMapping.EmailToCaseAddress__c = 'replypaid@auspost.com.au';
		emailToCaseMapping.IsActive__c = true;
		emailToCaseMapping.ProductType__c = productType;
		emailToCaseMapping.CasePurpose__c = casePurpose;

		// =====================================
		// Stubbing
		// =====================================
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		EmailToCaseMappingsSelector mockEmailToCaseMappingsSelector = (EmailToCaseMappingsSelector)MockUtility.mockSelector(EmailToCaseMappingsSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// Set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsAndParentRecordTypeId(new Set <Id>{ emailMessageRecord.Id }, new Set <Id> { bulkMailRecordTypeId }, new Set <Object> { EmailMessagesSelector.Options.WITH_CASE, CasesSelector.Options.WITH_RECORDTYPE})).thenReturn(new List <EmailMessage> { emailMessageRecord });
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set <Id> { caseRecord.Id}, new Set <Object> {CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER})).thenReturn(new Map <Id, Case> { caseRecord.Id => caseRecord});
		MockUtility.Mocks.when(mockEmailToCaseMappingsSelector.selectAll(new Set <Object>{ EmailToCaseMappingsSelector.Options.FILTER_ACTIVE })).thenReturn(new List <EmailToCaseMapping__mdt> { emailToCaseMapping });
		MockUtility.Mocks.when(mockUow.registerDirty((List <SObject>) fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(BulkMailEmailMessagesModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BulkMailEmailMessagesModule.newInstance().onAfterInsert(new List <EmailMessage> { emailMessageRecord }, mockUow);

		Test.stopTest();

		// Assert case records updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List <Case>) fflib_Match.eq(new List <Case>{
				new Case(Id = caseRecord.Id, Enquiry_Type__c = BulkMailCaseService.CASE_TYPE, Source__c = BulkMailCaseService.CUSTOMER_SOURCE, Call_Purpose__c = casePurpose,  EmailToCaseAddress__c = 'replypaid@auspost.com.au', Product_Type__c = productType)
			}),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(BulkMailEmailMessagesModule.class.getName()));

		Assert.areEqual(1, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 1 case record to be updated');
		Assert.areEqual('replypaid@auspost.com.au', ((Case)MockUtility.mockUnitOfWorkDMLs[0]).EmailToCaseAddress__c, 'Expected email to case address field to be updated');
	}

	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the closed cases are successfully reopened and relevant fields are updated with appropraite values
	*/
	@IsTest
	static void testAfterInsertReopenRelatedCases() {

		final Id queueId = BulkMailEmailMessagesModule.bulkMailQueueId; 

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Id bulkMailRecordTypeId = BulkMailCaseService.getInstance().getBulkMailRecordTypeId();

		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
		caseRecord.RecordTypeId = bulkMailRecordTypeId;
		caseRecord.Priority = 'Low';
		caseRecord.Origin = 'Other';
		caseRecord.Permanent_Close__c = false;
		caseRecord.Status = BulkMailCaseService.CLOSED_STATUS;
		
		EmailMessage emailMessageRecord = ApplicationTestDataFactory.getEmailMessages(1, true, true, 'test@test.com', 'replypaid@auspost.com.au', 'Test Subject', caseRecord.Id)[0];
		emailMessageRecord = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(emailMessageRecord, new Map <String, Object>{'ParentId' => caseRecord.Id});
		
		caseRecord = (Case)ApplicationTestDataFactory.setChildRelationships(caseRecord,new Map <String, List <SObject>> {'EmailMessages' => new List <EmailMessage>{ emailMessageRecord }});

		// =====================================
		// Stubbing
		// =====================================
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// Set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsAndParentRecordTypeId(new Set <Id>{ emailMessageRecord.Id }, new Set <Id> { bulkMailRecordTypeId }, new Set <Object> { EmailMessagesSelector.Options.WITH_CASE, CasesSelector.Options.WITH_RECORDTYPE})).thenReturn(new List <EmailMessage> { emailMessageRecord });
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set <Id> { caseRecord.Id}, new Set <Object> {CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER})).thenReturn(new Map <Id, Case> { caseRecord.Id => caseRecord});
		MockUtility.Mocks.when(mockUow.registerDirty((List <SObject>) fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(BulkMailEmailMessagesModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BulkMailEmailMessagesModule module = BulkMailEmailMessagesModule.newInstance();
		module.onAfterInsert(new List <EmailMessage> { emailMessageRecord }, mockUow);
		Datetime dt = module.currentTime;

		Test.stopTest();

		// Assert case records updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List <Case>) fflib_Match.eq(new List <Case>{
				new Case(Id = caseRecord.Id, Status = BulkMailCaseService.REOPENNED_STATUS, OwnerId = queueId, Case_Update__c = BulkMailCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = dt)
			}),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(BulkMailEmailMessagesModule.class.getName())
		);

		Assert.areEqual(1, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 1 case record to be updated');
		Assert.areEqual(BulkMailCaseService.REOPENNED_STATUS, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected case status to be ' + BulkMailCaseService.REOPENNED_STATUS);
	}
	
	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the relevant milestone record is created
	*/
	@IsTest
	static void testAfterInsertUpdateMilestone() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Id bulkMailRecordTypeId = BulkMailCaseService.getInstance().getBulkMailRecordTypeId();

		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
		caseRecord.RecordTypeId = bulkMailRecordTypeId;
		caseRecord.Priority = 'Low';
		caseRecord.Origin = 'Other';
		caseRecord.Permanent_Close__c = false;
		caseRecord.First_Email_Response__c = null;
		
		EmailMessage emailMessageRecord = ApplicationTestDataFactory.getEmailMessages(1, true, false, 'test@test.com', 'replypaid@auspost.com.au', 'Test Subject', caseRecord.Id)[0];
		emailMessageRecord = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(emailMessageRecord, new Map <String, Object>{'ParentId' => caseRecord.Id});
		emailMessageRecord.Status = EmailMessageUtil.STATUS_REPLIED;
		
		caseRecord = (Case)ApplicationTestDataFactory.setChildRelationships(caseRecord,new Map <String, List <SObject>> {'EmailMessages' => new List <EmailMessage>{ emailMessageRecord }});

		MilestoneType milestoneType = ApplicationTestDataFactory.getMilestoneTypes(1, true)[0];
		CaseMilestone milestone = ApplicationTestDataFactory.getCaseMilestones(1, true, false, false, milestoneType.Id, caseRecord.Id)[0];

		// =====================================
		// Stubbing
		// =====================================
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		CaseMilestonesSelector mockCaseMilestonesSelector = (CaseMilestonesSelector)MockUtility.mockSelector(CaseMilestonesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// Set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsAndParentRecordTypeId(new Set <Id>{ emailMessageRecord.Id }, new Set <Id> { bulkMailRecordTypeId }, new Set <Object> { EmailMessagesSelector.Options.WITH_CASE, CasesSelector.Options.WITH_RECORDTYPE})).thenReturn(new List <EmailMessage> { emailMessageRecord });
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set <Id> { caseRecord.Id}, new Set <Object> {CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER})).thenReturn(new Map <Id, Case> { caseRecord.Id => caseRecord});
		MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCaseAndMilestoneNames(new Set <Id> { caseRecord.Id }, new Set <String> { BulkMailCaseService.BULK_MAIL_FIRST_RESPONSE_MILESTONE }, new Set <Object>())).thenReturn(new List <CaseMilestone> { milestone });
		MockUtility.Mocks.when(mockUow.registerDirty((List <SObject>) fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(BulkMailEmailMessagesModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List <SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BulkMailEmailMessagesModule module = BulkMailEmailMessagesModule.newInstance();
		module.onAfterInsert(new List <EmailMessage> { emailMessageRecord }, mockUow);

		Test.stopTest();

		// Assert case new List <EmailMessage> { emailMessageRecord } updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List <Case>) fflib_Match.eq(new List <Case>{
				new Case(Id = caseRecord.Id, First_Email_Response__c = true, Status = BulkMailCaseService.IN_PROGRESS_STATUS)
			}),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(BulkMailEmailMessagesModule.class.getName())
		);

		Assert.areEqual(1, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 1 case record to be updated');
		Assert.areEqual(BulkMailCaseService.IN_PROGRESS_STATUS, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected case status to be ' + BulkMailCaseService.IN_PROGRESS_STATUS);
	
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
		
		// Assert Milestone update
		fflib_ArgumentCaptor updateCaptor = fflib_ArgumentCaptor.forClass(List <SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List <SObject>) updateCaptor.capture());
		List <CaseMilestone> caseMilestones = (List <CaseMilestone>) updateCaptor.getValue();
		System.assertEquals(1, caseMilestones.size(), 'Expected 1 case milestone record to be updated');
		System.assertNotEquals(null, caseMilestones[0].CompletionDate, 'Expected Mileston Completion date to be populated');
	}
}