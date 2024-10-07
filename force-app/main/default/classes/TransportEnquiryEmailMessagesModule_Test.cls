/**
 * @description Test class for TransportEnquiryEmailMessagesModule
 * @author Mahesh Parvathaneni
 * @date 2023-05-30
 * @changelog
 * 2024-08-07 - Ranjeewa Silva - Test class updates after uplifting the module to new ApplicationModule framework.
*/

@IsTest
private class TransportEnquiryEmailMessagesModule_Test {

	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the related cases have been updated with the correct email to address, network etc as per the metadata when a new case is created via email-to-case
	*/
	@IsTest
	static void testAfterInsertUpdateRelatedCases() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		RecordType transportEnquiryRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'Transport_Enquiry').values()[0];

		//insert case and emailmessages
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].RecordTypeId = transportEnquiryRecordType.Id;
		cases[0].Priority = 'Low';
		cases[0].Origin = 'Email';
		cases[1].RecordTypeId = transportEnquiryRecordType.Id;
		cases[1].Priority = 'Low';
		cases[1].Origin = 'Email';
		cases[2].RecordTypeId = transportEnquiryRecordType.Id;
		cases[2].Origin = 'Email';
		List<EmailMessage> records = ApplicationTestDataFactory.getEmailMessages(1, true, true, 'test@test.com', 'melbournevanoperations@test.com.au', 'Test Subject', cases[0].Id);
		records.addAll(ApplicationTestDataFactory.getEmailMessages(1, true, true, 'test@test.com', 'sydneyvanoperations@test.com.au', 'Test Subject', cases[1].Id));
		records.addAll(ApplicationTestDataFactory.getEmailMessages(1, true, true, 'test@test.com', 'perthvanoperations@test.com.au', 'Test Subject', cases[1].Id));
		records[0].Headers = 'Return-Path: caseroutingtesting+caf_=caseroutingtesting=5-1iz5gu7n9ir9bqev6o9wspvpigsnywv2e31uhnp8iy8rfd9fq6.0k-edoeeag.cs57.case.sandbox.salesforce.com@gmail.com\nX-SFDC-Binding: coremailprocessor\nX-SFDC-DOMAINKEYS: None\nX-SFDC-TLS-VERIFIED: no\nX-SFDC-TLS-CIPHER: AES256-SHA\nX-SFDC-TLS-STATUS: true\nX-SFDC-SENDERID-PRA: Pass\nX-SFDC-SENDERID: None\nX-SFDC-SPF: None\nSFDC-Interface: external\nReceived: from [182.50.78.79] ([182.50.78.79:39388] helo=smtp16-tyo.mta.salesforce.com) by mx4-sjl.mta.salesforce.com (envelope-from <>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=AES256-SHA)  id 83/4F-23732-69D72A35; Thu, 19 May 2023 06:05:10 +0000\nMessage-ID: <0D.1F.12049.19D72A35@mx2-tyo.mta.salesforce.com>\nFrom: Mail Delivery System <mailer-daemon@salesforce.com>\nTo: mohamed.atheek@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.com\nX-MS-Exchange-ForwardingLoop: melbournevanoperations@test.com.au;5195231b-cd74-45a4-b576-9bc88ae35b48\nDate: Thu, 19 May 2023 06:05:05 +0000';
		records[1].Headers = 'Return-Path: caseroutingtesting+caf_=caseroutingtesting=5-1iz5gu7n9ir9bqev6o9wspvpigsnywv2e31uhnp8iy8rfd9fq6.0k-edoeeag.cs57.case.sandbox.salesforce.com@gmail.com\nX-SFDC-Binding: coremailprocessor\nX-SFDC-DOMAINKEYS: None\nX-SFDC-TLS-VERIFIED: no\nX-SFDC-TLS-CIPHER: AES256-SHA\nX-SFDC-TLS-STATUS: true\nX-SFDC-SENDERID-PRA: Pass\nX-SFDC-SENDERID: None\nX-SFDC-SPF: None\nSFDC-Interface: external\nReceived: from [182.50.78.79] ([182.50.78.79:39388] helo=smtp16-tyo.mta.salesforce.com) by mx4-sjl.mta.salesforce.com (envelope-from <>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=AES256-SHA)  id 83/4F-23732-69D72A35; Thu, 19 May 2023 06:05:10 +0000\nMessage-ID: <0D.1F.12049.19D72A35@mx2-tyo.mta.salesforce.com>\nFrom: Mail Delivery System <mailer-daemon@salesforce.com>\nTo: mohamed.atheek@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.com\nX-MS-Exchange-ForwardingLoop: adelaidevanoperations@test.com.au\nDate: Thu, 19 May 2023 06:05:05 +0000\nX-MS-Exchange-ForwardingLoop: SydneyVanOperations@test.com.au';
		records[2].Headers = 'Return-Path: caseroutingtesting+caf_=caseroutingtesting=5-1iz5gu7n9ir9bqev6o9wspvpigsnywv2e31uhnp8iy8rfd9fq6.0k-edoeeag.cs57.case.sandbox.salesforce.com@gmail.com\nX-SFDC-Binding: coremailprocessor\nX-SFDC-DOMAINKEYS: None\nX-SFDC-TLS-VERIFIED: no\nX-SFDC-TLS-CIPHER: AES256-SHA\nX-SFDC-TLS-STATUS: true\nX-SFDC-SENDERID-PRA: Pass\nX-SFDC-SENDERID: None\nX-SFDC-SPF: None\nSFDC-Interface: external\nReceived: from [182.50.78.79] ([182.50.78.79:39388] helo=smtp16-tyo.mta.salesforce.com) by mx4-sjl.mta.salesforce.com (envelope-from <>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=AES256-SHA)  id 83/4F-23732-69D72A35; Thu, 19 May 2023 06:05:10 +0000\nMessage-ID: <0D.1F.12049.19D72A35@mx2-tyo.mta.salesforce.com>\nFrom: Mail Delivery System <mailer-daemon@salesforce.com>\nTo: mohamed.atheek@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.com\nX-MS-Exchange-ForwardingLoop: perthvanoperations@test.com.au;5195231b-cd74-45a4-b576-9bc88ae35b48\nDate: Thu, 19 May 2023 06:05:05 +0000';
		records[0] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'ParentId' => cases[0].Id});
		records[1] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'ParentId' => cases[1].Id});
		records[2] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[2], new Map<String, Object>{'ParentId' => cases[2].Id});
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[0]}});
		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[1]}});
		cases[2] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[2],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[2]}});

		//get networks
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = '1234';
		networks[1].Org_ID__c = '3456';

		//get EmailToCase Mapping custom metadata
		List<EmailToCaseMapping__mdt> emailToCaseMappings = ApplicationTestDataFactory.getEmailToCaseMappings(1, 'melbournevanoperations@test.com.au', true);
		emailToCaseMappings.addAll(ApplicationTestDataFactory.getEmailToCaseMappings(1, 'sydneyvanoperations@test.com.au', true));
		emailToCaseMappings[0].AssignNetworkWCIS__c = networks[0].Org_ID__c;
		emailToCaseMappings[1].AssignNetworkWCIS__c = networks[1].Org_ID__c;

		// =====================================
		// Stubbing
		// =====================================
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		EmailToCaseMappingsSelector mockEmailToCaseMappingsSelector = (EmailToCaseMappingsSelector)MockUtility.mockSelector(EmailToCaseMappingsSelector.class);
		NetworksSelector mockNetworksSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsAndParentRecordTypeId(new Set<Id>{records[0].Id, records[1].Id, records[2].Id}, new Set<Id>{transportEnquiryRecordType.Id}, 
			new Set<Object>{EmailMessagesSelector.Options.FILTER_INCOMING, EmailMessagesSelector.Options.WITH_CASE})).thenReturn(records);
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{cases[0].Id, cases[1].Id, cases[2].Id}, new Set<Object>{CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER}))
			.thenReturn(new Map<Id, Case>{cases[0].Id => cases[0], cases[1].Id => cases[1], cases[2].Id => cases[2]});
		MockUtility.Mocks.when(mockEmailToCaseMappingsSelector.selectAll(new Set<Object>{ EmailToCaseMappingsSelector.Options.FILTER_ACTIVE })).thenReturn(emailToCaseMappings);
		MockUtility.Mocks.when(mockNetworksSelector.selectByOrgId((Set<String>) fflib_Match.anyObject())).thenReturn(new Map<Id, Network__c>{networks[0].Id => networks[0], networks[1].Id => networks[1]});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(TransportEnquiryEmailMessagesModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new TransportEnquiryEmailMessagesModule().onAfterInsert(records, mockUow);

		Test.stopTest();

		//asserting case records updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = cases[0].Id, Network__c = networks[0].Id, EmailToCaseAddress__c = 'melbournevanoperations@test.com.au', Call_Purpose__c = null),
				new Case(Id = cases[1].Id, Network__c = networks[1].Id, EmailToCaseAddress__c = 'sydneyvanoperations@test.com.au', Call_Purpose__c = null)
			}),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(TransportEnquiryEmailMessagesModule.class.getName())
		);

		Assert.areEqual(2, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 2 case records to be updated');
		Assert.areEqual(networks[0].Id, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Network__c, 'Expected network field to be updated');
		Assert.areEqual(networks[1].Id, ((Case)MockUtility.mockUnitOfWorkDMLs[1]).Network__c, 'Expected network field to be updated');
		Assert.areEqual('melbournevanoperations@test.com.au', ((Case)MockUtility.mockUnitOfWorkDMLs[0]).EmailToCaseAddress__c, 'Expected email to case address field to be updated');
		Assert.areEqual('sydneyvanoperations@test.com.au', ((Case)MockUtility.mockUnitOfWorkDMLs[1]).EmailToCaseAddress__c, 'Expected email to case address field to be updated');
	}

	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the closed cases have been reopened and case update fields are updated when there is an incoming email
	*/
	@IsTest
	static void testAfterInsertReopenClosedCases() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		RecordType transportEnquiryRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'Transport_Enquiry').values()[0];

		//insert case and emailmessages
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].RecordTypeId = transportEnquiryRecordType.Id;
		cases[0].Status = 'Closed';
		cases[0].Permanent_Close__c = false;
		cases[0].EmailToCaseAddress__c = 'melbournevanoperations@test.com';
		cases[1].RecordTypeId = transportEnquiryRecordType.Id;
		cases[1].Status = 'Closed';
		cases[1].Permanent_Close__c = false;
		cases[1].EmailToCaseAddress__c = 'sydneyvanoperations@test.com';
		List<EmailMessage> records = ApplicationTestDataFactory.getEmailMessages(2, true, true, 'test@test.com', 'melbournevanoperations@test.com', 'Test Subject', cases[0].Id);
		records.addAll(ApplicationTestDataFactory.getEmailMessages(2, true, true, 'test@test.com', 'sydneyvanoperations@test.com', 'Test Subject', cases[1].Id));
		records[0] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'ParentId' => cases[0].Id});
		records[1] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'ParentId' => cases[0].Id});
		records[2] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[2], new Map<String, Object>{'ParentId' => cases[1].Id});
		records[3] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[3], new Map<String, Object>{'ParentId' => cases[1].Id});
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[0], records[1]}});
		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[2], records[3]}});

		// =====================================
		// Stubbing
		// =====================================
		TransportEnquiryCaseService mockService = (TransportEnquiryCaseService)MockUtility.mockUtility(TransportEnquiryCaseService.class);
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getTransportEnquiryRecordTypeId()).thenReturn(transportEnquiryRecordType.Id);
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsAndParentRecordTypeId(new Set<Id>{records[1].Id, records[3].Id}, new Set<Id>{transportEnquiryRecordType.Id}, 
			new Set<Object>{EmailMessagesSelector.Options.FILTER_INCOMING, EmailMessagesSelector.Options.WITH_CASE})).thenReturn(new List<EmailMessage>{records[1], records[3]});
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{cases[0].Id, cases[1].Id}, new Set<Object>{CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER}))
			.thenReturn(new Map<Id, Case>{cases[0].Id => cases[0], cases[1].Id => cases[1]});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(TransportEnquiryEmailMessagesModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TransportEnquiryEmailMessagesModule module = new TransportEnquiryEmailMessagesModule();
		module.onAfterInsert(new List<EmailMessage>{records[1], records[3]}, mockUow);
		Datetime dt = module.currentTime;

		Test.stopTest();

		//asserting case records updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = cases[0].Id, Status = TransportEnquiryCaseService.NEW_STATUS, Case_Update__c = TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = dt),
				new Case(Id = cases[1].Id, Status = TransportEnquiryCaseService.NEW_STATUS, Case_Update__c = TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = dt)
			}),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(TransportEnquiryEmailMessagesModule.class.getName())
		);

		((TransportEnquiryCaseService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getTransportEnquiryRecordTypeId();

		Assert.areEqual(2, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 2 case records to be updated');
		Assert.areEqual(TransportEnquiryCaseService.NEW_STATUS, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected case status to be New');
		Assert.areEqual(TransportEnquiryCaseService.NEW_STATUS, ((Case)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected case status to be New');
		Assert.areEqual(TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Case_Update__c, 'Expected case update field to be updated with New Email Received');
		Assert.areEqual(TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, ((Case)MockUtility.mockUnitOfWorkDMLs[1]).Case_Update__c, 'Expected case update field to be updated with New Email Received');
	}

	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the open cases have been updated with New Email Received when there is an incoming email
	*/
	@IsTest
	static void testAfterInsertUpdateOpenCases() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		RecordType transportEnquiryRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'Transport_Enquiry').values()[0];

		//insert case and emailmessages
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].RecordTypeId = transportEnquiryRecordType.Id;
		cases[0].Status = 'In Progress';
		cases[0].Permanent_Close__c = false;
		cases[0].EmailToCaseAddress__c = 'melbournevanoperations@test.com';
		cases[1].RecordTypeId = transportEnquiryRecordType.Id;
		cases[1].Status = 'In Progress';
		cases[1].Permanent_Close__c = false;
		cases[1].EmailToCaseAddress__c = 'sydneyvanoperations@test.com';
		List<EmailMessage> records = ApplicationTestDataFactory.getEmailMessages(2, true, true, 'test@test.com', 'melbournevanoperations@test.com', 'Test Subject', cases[0].Id);
		records.addAll(ApplicationTestDataFactory.getEmailMessages(2, true, true, 'test@test.com', 'sydneyvanoperations@test.com', 'Test Subject', cases[1].Id));
		records[0] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'ParentId' => cases[0].Id});
		records[1] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'ParentId' => cases[0].Id});
		records[2] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[2], new Map<String, Object>{'ParentId' => cases[1].Id});
		records[3] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[3], new Map<String, Object>{'ParentId' => cases[1].Id});
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[0], records[1]}});
		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[2], records[3]}});

		// =====================================
		// Stubbing
		// =====================================
		TransportEnquiryCaseService mockService = (TransportEnquiryCaseService)MockUtility.mockUtility(TransportEnquiryCaseService.class);
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getTransportEnquiryRecordTypeId()).thenReturn(transportEnquiryRecordType.Id);
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsAndParentRecordTypeId(new Set<Id>{records[1].Id, records[3].Id}, new Set<Id>{transportEnquiryRecordType.Id}, 
			new Set<Object>{EmailMessagesSelector.Options.FILTER_INCOMING, EmailMessagesSelector.Options.WITH_CASE})).thenReturn(new List<EmailMessage>{records[1], records[3]});
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{cases[0].Id, cases[1].Id}, new Set<Object>{CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER}))
			.thenReturn(new Map<Id, Case>{cases[0].Id => cases[0], cases[1].Id => cases[1]});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq(TransportEnquiryEmailMessagesModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TransportEnquiryEmailMessagesModule module = new TransportEnquiryEmailMessagesModule();
		module.onAfterInsert(new List<EmailMessage>{records[1], records[3]}, mockUow);
		Datetime dt = module.currentTime;

		Test.stopTest();

		//asserting case records updated with correct data
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = cases[0].Id, Case_Update__c = TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = dt),
				new Case(Id = cases[1].Id, Case_Update__c = TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = dt)
			}),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(TransportEnquiryEmailMessagesModule.class.getName())
		);

		((TransportEnquiryCaseService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getTransportEnquiryRecordTypeId();

		Assert.areEqual(2, MockUtility.mockUnitOfWorkDMLs.size(), 'Expected 2 case records to be updated');
		Assert.isNull(((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected case status not to be updated');
		Assert.isNull(((Case)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected case status not to be updated');
		Assert.areEqual(TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Case_Update__c, 'Expected case update field to be updated with New Email Received');
		Assert.areEqual(TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, ((Case)MockUtility.mockUnitOfWorkDMLs[1]).Case_Update__c, 'Expected case update field to be updated with New Email Received');
	}
	
}