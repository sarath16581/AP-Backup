/* @author
	* @date 2021-05-12
	* @group Tests
	* @tag Selector
	* @tag BillingAccount
	* @domain Core
	* @description test class for CreateSubAccountsController
	* @changelog
	* 2021-05-12 - seth.heang@auspost.com.au - created
	* 2021-05-13 - dheeraj.mandavilli@auspost.com.au - Updated the test class to include test methods dealing with SubAccountRequest creation/edit,deletion and finalization.
	* 2022-08-04 - Nasir Jawed - added test method for validate lodgement point search
	* 2023-01-27 - Sarath Burra -Removed the method validateSearchLodgementZone in the main class as part of https://australiapost.jira.com/browse/CI-828 so removed the test menthod validateSearchLodgementZoneTest()
	* 								Lines Removed 554-632
	* 2023-03-23 - sarath burra CI-703 Added new test method to cover the check APPC contracts logic. This logic is added in the class to check for existing APPC contracts and display message to user
	* 2023-08-18 - Harry Wang - added test method for getBillingAccountDetails
	*/
	@IsTest
	public with sharing class CreateSubAccountsControllerTest {
	@TestSetup
	private static void setup() {
		AusPostSettings__c setting = new AusPostSettings__c(Name = 'CreateBillingAccountCredentials', ApplicationName__c = 'Camunda', URL2__c = 'callout:LAYER7_CERT/csp/customer/v1/billingaccounts');
		insert setting;
	}
	public static void setMetadata(String query, List<SObject> records){
		CreateSubAccountHelper.MetadataCoverageRecordsMap.put(query, records);
	}
	//CI-703 Added new test method to cover the check APPC contracts logic.
	@IsTest
	private static void checkAPPCContractsTest() {
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c contract = ApplicationTestDataFactory.getApttusContracts(1,contact.Id,opportunityRecord.id,true)[0];
		contract.Apttus__Account__c=account.Id;
		contract.Contract_Relationship__c='Billing Account';
		contract.Apttus__Status__c = 'Activated';
		contract.Apttus__Status_Category__c = 'In Effect';
		contract = (Apttus__APTS_Agreement__c)ApplicationTestDataFactory.setUnwritableFields(contract,
		new Map<String, Object>{
			'APT_APPC_Count__c' =>1.00
		});
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		ApttusContractsSelector conReqSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
		MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

		List<Apttus__APTS_Agreement__c> mockConList = new List<Apttus__APTS_Agreement__c>{contract};
		MockUtility.Mocks.when(conReqSelector.Search(new Map<String, Object>{'accountIds' => new Set<Id>{billingAcc.Organisation__c}},true)).thenReturn(mockConList);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		Boolean showMsg=CreateSubAccountsController.checkAPPCContracts(billingAcc.Id);
		System.assertEquals(true, showMsg, 'Message should not be displayed for the user');
		Test.stopTest();

	}
	@IsTest
	private static void generateExternalOnboardingRecordTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );

		Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
		MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );


		Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
		MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);
		CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		Test.stopTest();
	}

	@IsTest
	private static void generateExternalOnboardingRecordTestWithDummyConnection() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"No"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.Product__c = 'eParcel;APPC';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );

		Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
		MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );


		Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
		MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);
		CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());

		Test.stopTest();
	}
	@IsTest
	private static void subAccountCreationRequestSuccessScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );

		Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
		MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );


		Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
		MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.stopStubbing();
		String requestLabel;
		Test.startTest();
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);
		CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
		String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
		System.debug('---onboardingRecordJson>>' + onboardingRecordJson);
		Continuation con = (Continuation)CreateSubAccountsController.subAccountCreationRequest(onboardingRecordJson);
		requestLabel = new List<String>(con.getRequests().keySet())[0];
		Test.stopTest();
		String mockResponseBody = 'TestBodyResponse';
		// Verify that the continuation has the correct number of requests
		Map<String, HttpRequest> requests = con.getRequests();
		System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
		// Create a mock response
		HttpResponse response = new HttpResponse();
		response.setStatusCode(202);
		response.setBody(mockResponseBody);
		Test.setContinuationResponse(requestLabel, response);

		List<String> labels = new List<String>{requestLabel};
		Boolean result = CreateSubAccountsController.processResponse(labels, CreateSubAccountsController.stateInfoVar);
		System.assertEquals(true, result);
	}

	@IsTest
	private static void subAccountCreationRequestErrorScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );

		Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
		MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );


		Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
		MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":false,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.stopStubbing();
		String requestLabel;
		Test.startTest();
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);
		CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
		String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
		Continuation con = (Continuation)CreateSubAccountsController.subAccountCreationRequest(onboardingRecordJson);
		requestLabel = new List<String>(con.getRequests().keySet())[0];

		// Test setFailStatus() method which set the Sub Account Request passed in parameter, to 'Error' status
		List<APT_Sub_Account__c> failedSARList = CreateSubAccountsController.setFailStatus(sarList);

		Test.stopTest();

		// Verify that the Sub Account Request status = 'Error' after executing CreateSubAccountsController.setFailStatus() method
		System.assertEquals('Error', failedSARList[0].APT_Sub_Account_Request_Status__c);

		String mockResponseBody = '{"errors":[{"detail":"Error in billing account creation"}]}';
		// Verify that the continuation has the correct number of requests
		Map<String, HttpRequest> requests = con.getRequests();
		System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
		// Create a mock response
		HttpResponse response = new HttpResponse();
		response.setStatusCode(500);
		response.setBody(mockResponseBody);
		Test.setContinuationResponse(requestLabel, response);

		List<String> labels = new List<String>{requestLabel};
		Boolean result = CreateSubAccountsController.processResponse(labels, CreateSubAccountsController.stateInfoVar);
		System.assertEquals(false, result);
	}


	@IsTest
	private static void subAccountRequestFinalizeScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );

		Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
		MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );

		Test.startTest();
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);

		boolean finalizeSARList = CreateSubAccountsController.setPendingStatus(sarList);

		Test.stopTest();

		// Verify that the Sub Account Request status = 'Error' after executing CreateSubAccountsController.setFailStatus() method
		System.assertEquals('Pending Charge Account', sarList[0].APT_Sub_Account_Request_Status__c);
		System.assertEquals(true, finalizeSARList);

	}

	@IsTest
	private static void subAccountRequestDeleteScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		Test.startTest();

		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);

		boolean deleteRec = CreateSubAccountsController.deleteSubAccounts(sarList);

		Test.stopTest();

		// Verify that the Sub Account Requests got successfully deleted from CreateSubAccountsController.deleteSubAccounts method
		System.assertEquals(true, deleteRec);

	}

	@IsTest
	private static void getSubAccountRecordValuesfromProposalTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequest.APT_Quote_Proposal__c = proposalRec.Id;

		Test.startTest();

		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);

		List<APT_Sub_Account__c> subAccList = CreateSubAccountsController.getRelatedSubAccountRequestsforProposal(proposalRec.Id);

		Test.stopTest();

		System.assertNotEquals(null, subAccList);

	}


	@IsTest
	private static void getSubAccountRecordValuesfromBillingAccTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		//Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];
		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequest.APT_Billing_Account__c = billingAcc.Id;

		Test.startTest();

		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		sarList.add(subAccountRequest);

		List<APT_Sub_Account__c> subAccList = CreateSubAccountsController.getRelatedSubAccountRequests(billingAcc.Id);

		Test.stopTest();

		System.assertNotEquals(null, subAccList);

	}

	@IsTest
	private static void getSubAccountRequestUpsertTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test2',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'No';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 2';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequest.APT_Quote_Proposal__c = proposalRec.Id;

		string lodgementPoints = '[{"recId":"a2K1s0000002TMPEA2","recName":"St Kilda","recWCC":"297832","postCode":"3182"},{"recId":"a2K1s0000002TMAEA2","recName":"Flinder Station","recWCC":"879234","postCode":"3000"}]';

		Test.startTest();

		try
		{
			APT_Sub_Account__c subAccRec = CreateSubAccountsController.createSubAccounts(subAccountRequest,lodgementPoints);
		}
		catch(exception e)
		{
		}

		Test.stopTest();

		}

		/**
		 * Test:
		 *  Ensures that billing account details are retrieved
		 */
		@IsTest
		private static void testGetBillingAccountDetails() {
			// =====================================
			// Data Preparation
			// =====================================
			List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
			Map<Id, Billing_Account__c> billingAccounts = new Map<Id, Billing_Account__c>(ApplicationTestDataFactory.getBillingAccounts(1, accounts[0].Id, 'TEAM', true));

			// =====================================
			// Stubbing
			// =====================================
			BillingAccountsSelector selector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(selector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(billingAccounts);
			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			Billing_Account__c billingAccount = CreateSubAccountsController.getBillingAccountDetails(billingAccounts.values()[0].Id);
			Test.stopTest();
			System.assertEquals('TEAM', billingAccount.Source_System__c, 'TEAM expected');
		}
	}