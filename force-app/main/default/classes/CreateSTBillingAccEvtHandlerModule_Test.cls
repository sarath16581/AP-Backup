/***
 * @description Test class for CreateSTBillingAccountEventHandlerModule
 * @author Ranjeewa Silva
 * @date 2023-11-27
 * @changelog
 * 2023-11-07 - Ranjeewa Silva - created
 */
@IsTest
private class CreateSTBillingAccEvtHandlerModule_Test {

	/**
	 * Ensure new billing account created and relevant related records are updated on receiving successful leader account
	 * creation platform event from external system.
	 */
	@IsTest
	static void testHandlingLeaderAccountCreationSuccessfulEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		Customer_Scoping_Questionnaire__c csq = ApplicationTestDataFactorySales.getCustomerScopingQuestionnaires(1, opportunity.Id, true)[0];
		Pick_Up_Location__c pickupLocation = ApplicationTestDataFactorySales.getPickUpLocations(1, csq.Id, true)[0];
		opportunity.Primary_Pick_Up_Location__c = pickupLocation.Id;

		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => organisation,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'LeaderBillingAccountName',
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'L1000000',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345'
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatedSObjectListsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		// verify that dirty sobject lists are registered twice with the unit of work. once for deal support request and once for external onboarding requests,.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjectLists = (List<Object>) updatedSObjectListsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjectLists.size(), 'Expected sobject lists are registered twice with the unit of work');
		for (Object obj: updatedSObjectLists) {
			List<SObject> sobjectList = (List<SObject>) obj;
			if (sobjectList instanceof  List<Deal_Support_Request__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one deal support reques`t is expected to be updated, but updated ['+sobjectList.size() + '].');
				Deal_Support_Request__c updated = (Deal_Support_Request__c) sobjectList[0];
				Assert.areEqual(dealSupportRequest.Id, updated.Id, 'Only the deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Success', updated.Integration_Status__c, 'Deal support request integration status should have been updated on receiving successful event.');
			} else if (sobjectList instanceof List<BAMExternalOnboardingRequest__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one external onboarding request is expected to be updated, but updated ['+sobjectList.size() + '].');
				BAMExternalOnboardingRequest__c updated = (BAMExternalOnboardingRequest__c) sobjectList[0];
				Assert.areEqual(externalOnboardingRequest.Id, updated.Id, 'Only the external onboarding request that initiated the request should be updated on receiving plagtform event.');
				Assert.areEqual('Success', updated.Status__c, 'External Onboarding Request status should have been updated on receiving successful event.');
				Assert.isNotNull(updated.Response_Payload__c, 'External Onboarding Request must be updated with the platform event payload.');
			}
		}

		fflib_ArgumentCaptor insertedBillingAccountsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// verify that one new billing account is inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerNew((Billing_Account__c) insertedBillingAccountsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		Billing_Account__c insertedBillingAccount = (Billing_Account__c)insertedBillingAccountsCaptor.getValue();
		Assert.areEqual(events[0].Billing_Account_Number__c, insertedBillingAccount.LEGACY_ID__c, 'New billing account created with incorrect billing account number.');
		Assert.areEqual(events[0].Source_System__c, insertedBillingAccount.Source_System__c, 'New billing account source system must be set to the platform event\'s source system.');

		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);

		// verify that dirty individual sobject records are registered twice with the unit of work. once for charge account request and once for apttus contract.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjects = (List<Object>) updatedSObjectsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjects.size(), 'Expected two dirty sobject records registered with the unit of work');
		for (Object obj: updatedSObjects) {
			SObject record = (SObject) obj;
			if (record instanceof  APT_Charge_Account__c) {
				APT_Charge_Account__c updated = (APT_Charge_Account__c) record;
				Assert.areEqual(chargeAccountRequest.Id, updated.Id, 'Only the charge account request related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Completed', updated.Status__c, 'Charge Account Request status should have been updated on receiving successful event.');
			} else if (record instanceof Apttus__APTS_Agreement__c) {
				Apttus__APTS_Agreement__c updated = (Apttus__APTS_Agreement__c) record;
				Assert.areEqual(apttusContract.Id, updated.Id, 'Only the apttus contract related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
			}
		}

		// verify async operation registered to send success notification for leader account.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncStagingWorker = (ApplicationUnitOfWork.AsyncStagingWorker) asyncWorkerCaptor.getValue();

		Assert.areEqual(CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker.class, asyncStagingWorker.classType,
				'Expected AsyncWorker type that handle post commit actions for newly created billing accounts, but got something else');

		Assert.isNotNull(asyncStagingWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncStagingWorker.params, List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam> params = (List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>)asyncStagingWorker.params;
		Assert.areEqual(1, params.size(), 'Expected parameters not passed into async process');
		Assert.areEqual(events[0].Billing_Account_Number__c, params[0].billingAccountNumber, 'Expected billing account number not passed into async process');
		Assert.isNull(params[0].leaderBillingAccountNumber, 'Leader billing account is not expected to set \'leaderBillingAccountNumber\' on async worker parameters');
		Assert.isTrue(params[0].relatedBillingAccountNumbers.isEmpty(), 'Leader billing account should not have billing account self lookup fields populated.');
	}

	/**
	 * Ensure external onboarding request, deal support request and charge account request records are updated on receiving
	 * leader account creation failed platform event from external system.
	 */
	@IsTest
	static void testHandlingLeaderAccountCreationFailedEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => organisation,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		//MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Error',
				Status__c = 'Error',
				Transaction_Id__c = externalOnboardingRequest.Id
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatedSObjectListsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		// verify that dirty sobject lists are registered once with the unit of work. once for deal support request and once for external onboarding requests,.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjectLists = (List<Object>) updatedSObjectListsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjectLists.size(), 'Expected sobject lists are registered twice with the unit of work');
		for (Object obj: updatedSObjectLists) {
			List<SObject> sobjectList = (List<SObject>) obj;
			if (sobjectList instanceof  List<Deal_Support_Request__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one deal support request is expected to be updated, but updated ['+sobjectList.size() + '].');
				Deal_Support_Request__c updated = (Deal_Support_Request__c) sobjectList[0];
				Assert.areEqual(dealSupportRequest.Id, updated.Id, 'Only the deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Error', updated.Integration_Status__c, 'Deal support request integration status should have been updated on receiving platform event.');
			} else if (sobjectList instanceof List<BAMExternalOnboardingRequest__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one external onboarding request is expected to be updated, but updated ['+sobjectList.size() + '].');
				BAMExternalOnboardingRequest__c updated = (BAMExternalOnboardingRequest__c) sobjectList[0];
				Assert.areEqual(externalOnboardingRequest.Id, updated.Id, 'Only the external onboarding request that initiated the request should be updated on receiving plagtform event.');
				Assert.areEqual('Error', updated.Status__c, 'External Onboarding Request status should have been updated on receiving platform event.');
				Assert.isNotNull(updated.Response_Payload__c, 'External Onboarding Request must be updated with the platform event payload.');
			}
		}

		// verify that no new billing account is inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerNew((Billing_Account__c) fflib_Match.anySObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString());

		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// verify that dirty charge account request is registered once with the unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		Object obj = updatedSObjectsCaptor.getValue();
		APT_Charge_Account__c updated = (APT_Charge_Account__c) obj;
		Assert.areEqual(chargeAccountRequest.Id, updated.Id, 'Only the charge account request related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
		Assert.areEqual('Error', updated.Status__c, 'Charge Account Request status should have been updated on receiving platform event.');
	}

	/**
	 * Ensure new billing accounts created and relevant related records are updated on receiving successful billing accounts
	 * creation platform event from external system.
	 */
	@IsTest
	static void testHandlingLeaderAndSubAccountsCreationSuccessfulEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => organisation,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(1, 'test', true);

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		SubAccountRequestsSelector mockSubAccountRequestsSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'LeaderBillingAccountName',
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'L1000000',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345'
		));

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'FOBillingAccountName',
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'FO1000001',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345',
				LeaderAccountNumber__c = 'L1000000',
				Sub_Account_Request_Id__c = subAccountRequests[0].Id
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatedSObjectListsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		// verify that dirty sobject lists are registered twice with the unit of work. once for deal support request and once for external onboarding requests,.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjectLists = (List<Object>) updatedSObjectListsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjectLists.size(), 'Expected sobject lists are registered twice with the unit of work');
		for (Object obj: updatedSObjectLists) {
			List<SObject> sobjectList = (List<SObject>) obj;
			if (sobjectList instanceof  List<Deal_Support_Request__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one deal support reques`t is expected to be updated, but updated ['+sobjectList.size() + '].');
				Deal_Support_Request__c updated = (Deal_Support_Request__c) sobjectList[0];
				Assert.areEqual(dealSupportRequest.Id, updated.Id, 'Only the deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Success', updated.Integration_Status__c, 'Deal support request integration status should have been updated on receiving successful event.');
				Assert.areEqual(events[1].Billing_Account_Number__c, updated.Sub_Accounts__c, 'Deal support request should have been updated with sub account numbers on receiving successful event.');
			} else if (sobjectList instanceof List<BAMExternalOnboardingRequest__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one external onboarding request is expected to be updated, but updated ['+sobjectList.size() + '].');
				BAMExternalOnboardingRequest__c updated = (BAMExternalOnboardingRequest__c) sobjectList[0];
				Assert.areEqual(externalOnboardingRequest.Id, updated.Id, 'Only the external onboarding request that initiated the request should be updated on receiving platform event.');
				Assert.areEqual('Success', updated.Status__c, 'External Onboarding Request status should have been updated on receiving successful event.');
				Assert.isNotNull(updated.Response_Payload__c, 'External Onboarding Request must be updated with the platform event payload.');
			}
		}

		fflib_ArgumentCaptor insertedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// verify that two new billing accounts and a deal support request are inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(3))).registerNew((SObject) insertedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> insertedSObjects = insertedSObjectsCaptor.getAllValues();
		Assert.areEqual(3, insertedSObjects.size(), 'Expected 2 new billing accounts and one new DSR are registered with the unit of work');
		for (Object obj: insertedSObjects) {
			if (obj instanceof Billing_Account__c) {
				Billing_Account__c inserted = (Billing_Account__c) obj;
				Assert.isTrue(new List<String>{events[0].Billing_Account_Number__c, events[1].Billing_Account_Number__c}.contains(inserted.LEGACY_ID__c), 'Expected two new billing accounts with the numbers specified in platform event.');
			} else if (obj instanceof  Deal_Support_Request__c) {
				Deal_Support_Request__c inserted = (Deal_Support_Request__c) obj;
				Assert.areEqual('Add Contract Rates', inserted.Work_Type__c, 'New DSR must be created for surcharge setup and activation');
			}
		}

		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);

		// verify that dirty individual sobject records are registered three times with the unit of work: (1) charge account request (2) apttus contract (3) sub account request
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(3))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjects = (List<Object>) updatedSObjectsCaptor.getAllValues();
		Assert.areEqual(3, updatedSObjects.size(), 'Expected three dirty sobject records registered with the unit of work');
		for (Object obj: updatedSObjects) {
			SObject record = (SObject) obj;
			if (record instanceof  APT_Charge_Account__c) {
				APT_Charge_Account__c updated = (APT_Charge_Account__c) record;
				Assert.areEqual(chargeAccountRequest.Id, updated.Id, 'Only the charge account request related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Completed', updated.Status__c, 'Charge Account Request status should have been updated on receiving successful event.');
			} else if (record instanceof Apttus__APTS_Agreement__c) {
				Apttus__APTS_Agreement__c updated = (Apttus__APTS_Agreement__c) record;
				Assert.areEqual(apttusContract.Id, updated.Id, 'Only the apttus contract related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
			} else if (record instanceof  APT_Sub_Account__c) {
				APT_Sub_Account__c updated = (APT_Sub_Account__c) record;
				Assert.areEqual(subAccountRequests[0].Id, updated.Id, 'Only the sub account request referenced in the platform event should be updated. Updated some other record.');
				Assert.areEqual('Success', updated.APT_Sub_Account_Request_Status__c, 'Sub Account Request status should have been updated on receiving successful event.');
				Assert.areEqual(events[1].Billing_Account_Number__c, updated.Sub_Account_Number__c, 'Sub Account number should have been updated on receiving successful event.');
			}
		}

		// verify async operation registered to populate leader account lookup relationship and to send notifications.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncStagingWorker = (ApplicationUnitOfWork.AsyncStagingWorker) asyncWorkerCaptor.getValue();

		Assert.areEqual(CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker.class, asyncStagingWorker.classType,
				'Expected AsyncWorker type that handle post commit actions required on new billing accounts, but got something else');

		Assert.isNotNull(asyncStagingWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncStagingWorker.params, List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam> params = (List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>)asyncStagingWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		for (Integer i=0; i<params.size(); i++) {
			Assert.areEqual(events[i].Billing_Account_Number__c, params[i].billingAccountNumber, 'Expected billing account number not passed into async process');
			Assert.areEqual(events[i].LeaderAccountNumber__c, params[i].leaderBillingAccountNumber, 'Sub accounts should have leader billing account number passed into async process');
			if (String.isNotBlank(events[i].LeaderAccountNumber__c)) {
				Assert.areEqual(events[i].LeaderAccountNumber__c, params[i].relatedBillingAccountNumbers.get('LeaderAccount__c'), 'Expected related billing account number not passed into async process');
			}
		}

	}

	/**
	 * Ensure new billing accounts created and relevant related records are updated on receiving successful billing accounts
	 * creation platform event from external system.
	 */
	@IsTest
	static void testHandlingLeaderAndSubAccountsCreationFailedEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => organisation,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(1, 'test', true);

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		SubAccountRequestsSelector mockSubAccountRequestsSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Error',
				Status__c = 'Error',
				Transaction_Id__c = externalOnboardingRequest.Id
		));

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Error',
				Status__c = 'Error',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Sub_Account_Request_Id__c = subAccountRequests[0].Id
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatedSObjectListsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		// verify that dirty sobject lists are registered twice with the unit of work. once for deal support request and once for external onboarding requests,.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjectLists = (List<Object>) updatedSObjectListsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjectLists.size(), 'Expected sobject lists are registered twice with the unit of work');
		for (Object obj: updatedSObjectLists) {
			List<SObject> sobjectList = (List<SObject>) obj;
			if (sobjectList instanceof  List<Deal_Support_Request__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one deal support request is expected to be updated, but updated ['+sobjectList.size() + '].');
				Deal_Support_Request__c updated = (Deal_Support_Request__c) sobjectList[0];
				Assert.areEqual(dealSupportRequest.Id, updated.Id, 'Only the deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Error', updated.Integration_Status__c, 'Deal support request integration status should have been updated on receiving platform event.');
			} else if (sobjectList instanceof List<BAMExternalOnboardingRequest__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one external onboarding request is expected to be updated, but updated ['+sobjectList.size() + '].');
				BAMExternalOnboardingRequest__c updated = (BAMExternalOnboardingRequest__c) sobjectList[0];
				Assert.areEqual(externalOnboardingRequest.Id, updated.Id, 'Only the external onboarding request that initiated the request should be updated on receiving plagtform event.');
				Assert.areEqual('Error', updated.Status__c, 'External Onboarding Request status should have been updated on receiving platform event.');
				Assert.isNotNull(updated.Response_Payload__c, 'External Onboarding Request must be updated with the platform event payload.');
			}
		}

		// verify that no new billing account is inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerNew((Billing_Account__c) fflib_Match.anySObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString());

		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);

		// verify that dirty individual sobject records are registered two times with the unit of work: (1) charge account request (2) sub account request
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjects = (List<Object>) updatedSObjectsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjects.size(), 'Expected two dirty sobject records registered with the unit of work');
		for (Object obj: updatedSObjects) {
			SObject record = (SObject) obj;
			if (record instanceof  APT_Charge_Account__c) {
				APT_Charge_Account__c updated = (APT_Charge_Account__c) record;
				Assert.areEqual(chargeAccountRequest.Id, updated.Id, 'Only the charge account request related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Error', updated.Status__c, 'Charge Account Request status should have been updated on receiving platform event.');
			} else if (record instanceof  APT_Sub_Account__c) {
				APT_Sub_Account__c updated = (APT_Sub_Account__c) record;
				Assert.areEqual(subAccountRequests[0].Id, updated.Id, 'Only the sub account request referenced in the platform event should be updated. Updated some other record.');
				Assert.areEqual('Error', updated.APT_Sub_Account_Request_Status__c, 'Sub Account Request status should have been updated on receiving platform event.');
				Assert.isNull(updated.Sub_Account_Number__c, 'Sub Account number should not have been updated on receiving creation failed event.');
			}
		}
	}

	/**
	 * Ensure new leader billing account is created and relevant related records are updated on receiving successful leader
	 * billing accounts creation platform event from external system irrespective of sub account failure.
	 */
	@IsTest
	static void testHandlingSuccessfulLeaderEventFollowedBySubAccountErrorEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => organisation,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(1, 'test', true);

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		SubAccountRequestsSelector mockSubAccountRequestsSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'LeaderBillingAccountName',
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'L1000000',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345'
		));

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Error',
				Status__c = 'Error',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Sub_Account_Request_Id__c = subAccountRequests[0].Id
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatedSObjectListsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		// verify that dirty sobject lists are registered twice with the unit of work. once for deal support request and once for external onboarding requests,.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).registerDirty((List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjectLists = (List<Object>) updatedSObjectListsCaptor.getAllValues();
		Assert.areEqual(2, updatedSObjectLists.size(), 'Expected sobject lists are registered twice with the unit of work');
		for (Object obj: updatedSObjectLists) {
			List<SObject> sobjectList = (List<SObject>) obj;
			if (sobjectList instanceof  List<Deal_Support_Request__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one deal support reques`t is expected to be updated, but updated ['+sobjectList.size() + '].');
				Deal_Support_Request__c updated = (Deal_Support_Request__c) sobjectList[0];
				Assert.areEqual(dealSupportRequest.Id, updated.Id, 'Only the deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Success', updated.Integration_Status__c, 'Deal support request integration status should be set based on leader event.');
				Assert.isNull(updated.Sub_Accounts__c, 'Sub account number on deal support request should be null as sub account has failed.');
			} else if (sobjectList instanceof List<BAMExternalOnboardingRequest__c>) {
				Assert.areEqual(1, sobjectList.size(), 'Only one external onboarding request is expected to be updated, but updated ['+sobjectList.size() + '].');
				BAMExternalOnboardingRequest__c updated = (BAMExternalOnboardingRequest__c) sobjectList[0];
				Assert.areEqual(externalOnboardingRequest.Id, updated.Id, 'Only the external onboarding request that initiated the request should be updated on receiving plagtform event.');
				Assert.areEqual('Partial Success', updated.Status__c, 'External Onboarding Request status should have been updated on receiving successful leader and failed sub account events.');
				Assert.isNotNull(updated.Response_Payload__c, 'External Onboarding Request must be updated with the platform event payloads.');
			}
		}

		fflib_ArgumentCaptor insertedBillingAccountsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// verify that only one new billing accounts are inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerNew((Billing_Account__c) insertedBillingAccountsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> insertedBillingAccounts = insertedBillingAccountsCaptor.getAllValues();
		Assert.areEqual(1, insertedBillingAccounts.size(), 'Expected only one new billing account registered with the unit of work');

		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);

		// verify that dirty individual sobject records are registered three times with the unit of work: (1) charge account request (2) apttus contract (3) sub account request
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(3))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjects = (List<Object>) updatedSObjectsCaptor.getAllValues();
		Assert.areEqual(3, updatedSObjects.size(), 'Expected three dirty sobject records registered with the unit of work');
		for (Object obj: updatedSObjects) {
			SObject record = (SObject) obj;
			if (record instanceof  APT_Charge_Account__c) {
				APT_Charge_Account__c updated = (APT_Charge_Account__c) record;
				Assert.areEqual(chargeAccountRequest.Id, updated.Id, 'Only the charge account request related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Completed', updated.Status__c, 'Charge Account Request status should have been updated on receiving successful leader event.');
			} else if (record instanceof Apttus__APTS_Agreement__c) {
				Apttus__APTS_Agreement__c updated = (Apttus__APTS_Agreement__c) record;
				Assert.areEqual(apttusContract.Id, updated.Id, 'Only the apttus contract related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
			} else if (record instanceof  APT_Sub_Account__c) {
				APT_Sub_Account__c updated = (APT_Sub_Account__c) record;
				Assert.areEqual(subAccountRequests[0].Id, updated.Id, 'Only the sub account request referenced in the platform event should be updated. Updated some other record.');
				Assert.areEqual('Error', updated.APT_Sub_Account_Request_Status__c, 'Sub Account Request status should have been updated on receiving sub account creation error.');
				Assert.isNull(updated.Sub_Account_Number__c, 'Sub Account number should not have been updated on receiving sub account creation error.');
			}
		}

		// verify async operation is registered for post commit actions (success notification on leader).
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) fflib_Match.anyObject());
	}

	/**
	 * Ensure any existing sub account requests in 'Draft' and 'Error' status are updated to populate the leader account
	 * lookup on receiving successful leader account creation platform event from external system.
	 */
	@IsTest
	static void testUpdatingDraftSubAccountRequestsOnReceivingLeaderSuccessfulEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => organisation,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		// setup sub account requests in 'Draft' status
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'test', true);
		subAccountRequests[0].APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequests[1].APT_Sub_Account_Request_Status__c = 'Error';

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector mockSubAccountRequestsSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'LeaderBillingAccountName',
				Request_Object_Id__c = dealSupportRequest.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'L1000000',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345'
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor insertedBillingAccountsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// verify that one new billing account is inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerNew((Billing_Account__c) insertedBillingAccountsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		Billing_Account__c insertedBillingAccount = (Billing_Account__c)insertedBillingAccountsCaptor.getValue();
		Assert.areEqual(events[0].Billing_Account_Number__c, insertedBillingAccount.LEGACY_ID__c, 'New billing account created with incorrect billing account number.');
		Assert.areEqual(events[0].Source_System__c, insertedBillingAccount.Source_System__c, 'New billing account source system must be set to the platform event\'s source system.');

		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);

		// verify that dirty individual sobject records are registered four times with the unit of work.
		// - charge account request (1 record), apttus contract (1 record), existing sub account requests (2 records)
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(4))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjects = (List<Object>) updatedSObjectsCaptor.getAllValues();
		Assert.areEqual(4, updatedSObjects.size(), 'Expected four dirty sobject records registered with the unit of work');
		for (Object obj: updatedSObjects) {
			SObject record = (SObject) obj;
			if (record instanceof  APT_Charge_Account__c) {
				APT_Charge_Account__c updated = (APT_Charge_Account__c) record;
				Assert.areEqual(chargeAccountRequest.Id, updated.Id, 'Only the charge account request related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
				Assert.areEqual('Completed', updated.Status__c, 'Charge Account Request status should have been updated on receiving successful event.');
			} else if (record instanceof Apttus__APTS_Agreement__c) {
				Apttus__APTS_Agreement__c updated = (Apttus__APTS_Agreement__c) record;
				Assert.areEqual(apttusContract.Id, updated.Id, 'Only the apttus contract related to deal support request that initiated the billing account provisioning request should be updated. Updated some other record.');
			} else if (record instanceof APT_Sub_Account__c) {
				APT_Sub_Account__c updated = (APT_Sub_Account__c) record;
				Assert.isTrue(new Map<Id, APT_Sub_Account__c>(subAccountRequests).containsKey(updated.Id), 'Existing Sub account requests in \'Draft\' and \'Error\' status should be updated.');
			}
		}
	}

	/**
	 * Ensure new billing accounts created and relevant related records are updated on receiving successful billing accounts
	 * creation platform event from external system.
	 */
	@IsTest
	static void testHandlingSubAccountsCreationEvent() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c leaderBillingAccount = ApplicationTestDataFactory.getBillingAccounts(1, organisation.Id, 'TEAM', true)[0];

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(3, 'test', true);

		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, leaderBillingAccount.Id, String.valueOf(Billing_Account__c.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		//DealSupportRequestsSelector mockDealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ExternalOnboardingRequestSelector mockExternalOnboardingRequestSelector = (ExternalOnboardingRequestSelector) MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		SubAccountRequestsSelector mockSubAccountRequestsSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockExternalOnboardingRequestSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRequest.Id => externalOnboardingRequest});
		//MockUtility.Mocks.when(mockDealSupportRequestsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{organisation.Id => organisation});
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));
		MockUtility.Mocks.when(mockSubAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BillingAccountCreationEvent__e> events = new List<BillingAccountCreationEvent__e>();

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'FOBillingAccountName1',
				Request_Object_Id__c = leaderBillingAccount.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'FO1000001',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345',
				LeaderAccountNumber__c = 'L1000000',
				Sub_Account_Request_Id__c = subAccountRequests[0].Id
		));

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Request_Object_Id__c = leaderBillingAccount.Id,
				Status_Description__c = 'Error',
				Status__c = 'Error',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Sub_Account_Request_Id__c = subAccountRequests[1].Id
		));

		events.add(new BillingAccountCreationEvent__e(
				Source_System__c = 'TEAM',
				Organisation_Record_Id__c = organisation.Id,
				Billing_Account_Name__c = 'FOBillingAccountName2',
				Request_Object_Id__c = leaderBillingAccount.Id,
				Status_Description__c = 'Success',
				Status__c = 'Success',
				Transaction_Id__c = externalOnboardingRequest.Id,
				Credit_Person_Code__c = 'A11',
				Billing_Account_Number__c = 'FO1000002',
				Credit_Person__c = 'TEST OFFICER',
				Credit_Officer_Phone__c = '1234512345',
				LeaderAccountNumber__c = 'L1000000',
				Parent_Account_Number__c = 'FOBillingAccountName1', //off spring of follower
				Sub_Account_Request_Id__c = subAccountRequests[2].Id
		));

		new CreateSTBillingAccountEventHandlerModule().onAfterInsert(events, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatedSObjectListsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		// verify that dirty sobject lists are registered with the unit of work containing external onboarding requests,.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<BAMExternalOnboardingRequest__c> updatedExternalOnboardingRequests = (List<BAMExternalOnboardingRequest__c>) updatedSObjectListsCaptor.getValue();
		Assert.areEqual(1, updatedExternalOnboardingRequests.size(), 'Only one external onboarding request is expected to be updated.');
		Assert.areEqual(externalOnboardingRequest.Id, updatedExternalOnboardingRequests[0].Id, 'Only the external onboarding request that initiated the request should be updated on receiving platform event.');
		Assert.areEqual('Partial Success', updatedExternalOnboardingRequests[0].Status__c, 'External Onboarding Request status should have been updated on receiving platform events.');
		Assert.isNotNull(updatedExternalOnboardingRequests[0].Response_Payload__c, 'External Onboarding Request must be updated with the platform event payload.');

		fflib_ArgumentCaptor insertedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// verify that two new billing accounts and a deal support request are inserted.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(4))).registerNew((SObject) insertedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> insertedSObjects = insertedSObjectsCaptor.getAllValues();
		Assert.areEqual(4, insertedSObjects.size(), 'Expected 2 new billing accounts and two new DSR are registered with the unit of work');
		for (Object obj: insertedSObjects) {
			if (obj instanceof Billing_Account__c) {
				Billing_Account__c inserted = (Billing_Account__c) obj;
				Assert.isTrue(new List<String>{events[0].Billing_Account_Number__c, events[2].Billing_Account_Number__c}.contains(inserted.LEGACY_ID__c), 'Expected two new billing accounts with the numbers specified in platform event.');
			} else if (obj instanceof  Deal_Support_Request__c) {
				Deal_Support_Request__c inserted = (Deal_Support_Request__c) obj;
				Assert.areEqual('Add Contract Rates', inserted.Work_Type__c, 'New DSR must be created for surcharge setup and activation');
			}
		}


		fflib_ArgumentCaptor updatedSObjectsCaptor = fflib_ArgumentCaptor.forClass(SObject.class);

		// verify that dirty sub account request records are registered three times with the unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(3))).registerDirty((SObject) updatedSObjectsCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedSObjects = (List<Object>) updatedSObjectsCaptor.getAllValues();
		Assert.areEqual(3, updatedSObjects.size(), 'Expected three dirty sobject records registered with the unit of work');

		// verify async operation registered to send notifications for two new billing accounts.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncStagingWorker = (ApplicationUnitOfWork.AsyncStagingWorker) asyncWorkerCaptor.getValue();

		Assert.areEqual(CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker.class, asyncStagingWorker.classType,
				'Expected AsyncWorker type that handle post commit actions required on new billing accounts, but got something else');

		Assert.isNotNull(asyncStagingWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncStagingWorker.params, List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam> params = (List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>)asyncStagingWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		for (CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam param: params) {
			Assert.isTrue(new Set<String>{events[0].Billing_Account_Number__c, events[2].Billing_Account_Number__c}.contains(param.billingAccountNumber), 'All new billing accounts must be passed into async worker to post commit actions.');
			Assert.areEqual('L1000000', param.leaderBillingAccountNumber, 'Leader billing account number must be passed into async worker for notifications.');
			Assert.isTrue(param.relatedBillingAccountNumbers.isEmpty(), 'Leader account was already existing, leader account self lookup population must not be done as a post commit action.');
		}
	}

	/**
	 * Test to ensure related billing accounts passed in are linked by the async worker.
	 */
	@IsTest
	static void testLinkRelatedAccountsAsyncWorker() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Billing_Account__c> billingAccounts = ApplicationTestDataFactory.getBillingAccounts(4, organisation.Id, 'TEAM', true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBillingAccountsSelector.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, Billing_Account__c>(billingAccounts));
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam> params = new List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>();
		// billingAccounts[1] has billingAccounts[0] as the leader. Pays invoices.
		params.add(getBillingAccountPostCommitAsyncWorkerParam(billingAccounts[1].LEGACY_ID__c, billingAccounts[0].LEGACY_ID__c, null));
		// billingAccounts[2] has billingAccounts[0] as the leader. Leader pays invoices.
		params.add(getBillingAccountPostCommitAsyncWorkerParam(billingAccounts[2].LEGACY_ID__c, billingAccounts[0].LEGACY_ID__c, billingAccounts[0].LEGACY_ID__c));
		// billingAccounts[3] has billingAccounts[0] as the leader. billingAccounts[1] as the parent.
		params.add(getBillingAccountPostCommitAsyncWorkerParam(billingAccounts[3].LEGACY_ID__c, billingAccounts[0].LEGACY_ID__c, billingAccounts[1].LEGACY_ID__c));

		CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker worker = new CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker();
		worker.deserialiseParams(Json.serialize(params));
		worker.execute(mockUow);
		Test.stopTest();

		Assert.areEqual(Billing_Account__c.SObjectType, worker.getSObjectTypeGroup(), 'Async worker is expected to update Billing_Account__c sobject type');

		fflib_ArgumentCaptor updatedSObjectCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 3)).registerDirty((SObject) updatedSObjectCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Object> updatedRecords = updatedSObjectCaptor.getAllValues();

		Assert.areEqual(3, updatedRecords.size(), 'Expected to update billing accounts with leader and parent lookups');
		for (Object obj: updatedRecords) {
			Billing_Account__c updated = (Billing_Account__c) obj;
			Assert.areEqual(billingAccounts[0].Id, updated.LeaderAccount__c, 'Async worker is expected to updated leader account relationship');
		}
	}

	/**
	 * Test to ensure async worker logs errors if it cannot locate billing accounts for billing account numbers supplied
	 * to it. This could happen in an unlikely scenario where some of the new billing accounts failed to insert.
	 */
	@IsTest
	static void testLinkRelatedAccountsAsyncWorkerLogsErrorsWhenBillingAccountsToLinkDoesNotExist() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Billing_Account__c> billingAccounts = ApplicationTestDataFactory.getBillingAccounts(3, organisation.Id, 'TEAM', true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
		ApplicationLogger mockApplicationLogger = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBillingAccountsSelector.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, Billing_Account__c>(billingAccounts));
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam> params = new List<CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam>();
		// billingAccounts[1] has billingAccounts[0] as the leader. Pays invoices.
		params.add(getBillingAccountPostCommitAsyncWorkerParam(billingAccounts[1].LEGACY_ID__c, billingAccounts[0].LEGACY_ID__c, null));
		// billingAccounts[2] has a leader who also pays invoices. However the leader account doesn't exist in Salesforce,
		params.add(getBillingAccountPostCommitAsyncWorkerParam(billingAccounts[2].LEGACY_ID__c, 'doesnotexistinsf', 'doesnotexistinsf'));
		// setup a offspring who failed to insert in salesforce. It has billingAccounts[0] as the leader. billingAccounts[1] as the parent.
		params.add(getBillingAccountPostCommitAsyncWorkerParam('offspringnotinsf', billingAccounts[0].LEGACY_ID__c, billingAccounts[1].LEGACY_ID__c));

		CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker worker = new CreateSTBillingAccountEventHandlerModule.CreateStarTrackBillingAccountPostCommitAsyncWorker();
		worker.deserialiseParams(Json.serialize(params));
		worker.execute(mockUow);
		Test.stopTest();

		Assert.areEqual(Billing_Account__c.SObjectType, worker.getSObjectTypeGroup(), 'Async worker is expected to update Billing_Account__c sobject type');

		fflib_ArgumentCaptor updatedSObjectCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		// only billingAccounts[1] should be updated. other billing accounts either failed to insert or has relationships with other accounts that failed to insert.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((SObject) updatedSObjectCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		Billing_Account__c updated = (Billing_Account__c) updatedSObjectCaptor.getValue();
		Assert.areEqual(billingAccounts[1].Id, updated.Id, 'Async worker is expected to update existing account with relationships');
		Assert.areEqual(billingAccounts[0].Id, updated.LeaderAccount__c, 'Async worker is expected to update leader account relationship');

		// ensure messages are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockApplicationLogger, 1)).logMessage((List<String>)fflib_Match.anyList(), (List<String>)fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.eq(ApplicationLogger.LoggingLevel.ERROR));
	}

	private static CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam getBillingAccountPostCommitAsyncWorkerParam(String accountNumber, String leaderAccountNumber, String parentAccountNumber) {
		CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam param = new CreateSTBillingAccountEventHandlerModule.StarTrackBillingAccountPostCommitWorkerParam();
		param.billingAccountNumber = accountNumber;
		if (String.isNotBlank(leaderAccountNumber)) {
			param.relatedBillingAccountNumbers.put('LeaderAccount__c', leaderAccountNumber);
		}
		if (String.isNotBlank(parentAccountNumber)) {
			param.relatedBillingAccountNumbers.put('PAYER_ACCOUNT_ID__c', parentAccountNumber);
		}
		return param;
	}

	private static Apttus__APTS_Agreement__c getApttusContractWithRelatedContactAndProposal(Contact primaryContact, Id opportunityId, Id chargeAccountRequestId) {
		APT_Credit_Assessment__c creditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequestId, true)[0];
		creditAssessment.StarTrack_Proposed_for_New_Account__c = 25000;
		creditAssessment.APT_Credit_Assessment_Status__c = ProvisionSTBillingAccountsController.VALID_CREDIT_ASSESSMENT_STATUS.iterator().next();

		Apttus_Proposal__Proposal__c apttusProposal = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		apttusProposal.APT_Minimum_Monthly_Spend__c = 2000;

		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityId, true)[0];
		apttusContract.Apttus_QPComply__RelatedProposalId__c = apttusProposal.Id;
		apttusContract.Term__c = 'Open Ended';

		apttusProposal = (Apttus_Proposal__Proposal__c) ApplicationTestDataFactory.setUnwritableFields(apttusProposal, new Map<String, Object>{
				'APT_Credit_Assessment__r' => creditAssessment
		});

		apttusContract = (Apttus__APTS_Agreement__c) ApplicationTestDataFactory.setUnwritableFields(apttusContract, new Map<String, Object>{
				'Apttus__Primary_Contact__r' => primaryContact,
				'Apttus_QPComply__RelatedProposalId__r' => apttusProposal
		});

		return apttusContract;
	}
}