/* @author
* @date 2020-11-18
* @group Tests
* @tag Selector
* @tag BillingAccount
* @domain Core
* @description test class for CreateBillingAccountController
* @changelog
* 2020-11-18 - arjun.singh@austpost.com.au - Created
* 2021-05-12 - seth.heang@auspost.com.com.au Updated test classes due to field mapping changes in main classes
* 2021-05-19 - avula.jansirani@auspost.com.au - added bca methods
* 2022-08-08 - Seth Heang - Added test method to cover Rating Plan Activation changes
* 2023-03-23 - Sarath.burra@auspost.com.au - CI-613 Added Contract Line Items to check for Service commencement date and Service expiry date as sent in i5 request
* 2023-11-03 - Ranjeewa Silva - Updated to fix test case where new sub account requests can only be created in 'Draft' status.
*/
	@IsTest
public with sharing class CreateBillingAccountController_Test {
	@TestSetup
	private static void setup() {
		AusPostSettings__c setting = new AusPostSettings__c(Name = 'CreateBillingAccountCredentials', ApplicationName__c = 'Camunda', URL2__c = 'callout:LAYER7_CERT/csp/customer/v1/billingaccounts');
		insert setting;
	}
	public static void setMetadata(String query, List<SObject> records){
		CreateBillingAccountHelper.MetadataCoverageRecordsMap.put(query, records);
	}
	@IsTest
	private static void BillingAccountCreationPreCheckTest() {
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Account chargeAccount = accountList[1];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = primaryContact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Method_of_Payment__c = 'Charge Account + Sub Account';
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		subAccountRequest.APT_Charge_Account__c = chargeAccountRequest.Id;
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id},
			new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_CONTRACT
			})).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c},
			new Set<object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION,
				ApttusContractsSelector.Options.WITH_CONTACT,
				ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL,
				ApttusContractsSelector.Options.WITH_OPPORTUNITY
			})).thenReturn(mockApttusContractMap);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CreateBillingAccountHelper.billingAccountWithEmptyfields bAccount = CreateBillingAccountController.BillingAccountCreationPreCheck(dealSupportRequest.Id);
		System.assert(!bAccount.emptyAttributesList.isEmpty()) ;
		Test.stopTest();
	}

	/**
	 * @description Test method on by simulating the mock Charge + Sub Account Request Payload to Camunda
	 *			  Due to limitation of the ApplicationTestDataFactory + Selector Framework, where we need to query two layers deep in a relationship based on fake ID,
	 *			  the selector query does not work. As such, I have used actual DML operation for this method.
	 *			  - Seth.Heang@auspost.com.au
	 */
	@IsTest
	private static void generateExternalOnboardingRecordTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Account chargeAccount = accountList[1];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.SubAccountContact__c = primaryContact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		apttusProposals.id = null;
		apttusContracts.id = null;
		primaryContact.id = null;
		account.id = null;
		opportunityRecord.id = null;
		apttusCreditAssessment.id = null;
		chargeAccountRequest.id = null;
		subAccountRequest.id = null;
		dealSupportRequest.id = null;
		insert account;

		opportunityRecord.AccountId = account.id;
		insert opportunityRecord;

		primaryContact.AccountId = account.id;
		insert primaryContact;

		apttusProposals.Apttus_Proposal__Primary_Contact__c = primaryContact.id;
		insert apttusProposals;

		apttusContracts.Apttus__Primary_Contact__c = primaryContact.id;
		apttusContracts.Apttus__Related_Opportunity__c = opportunityRecord.id;
		insert apttusContracts;

		insert chargeAccountRequest;

		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.id;
		insert apttusCreditAssessment;

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Method_of_Payment__c = 'Charge Account + Sub Account';
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusProposals.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
		update apttusProposals;

		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		update apttusContracts;
		// The mock framework does not work with below query, as such for this method we had to insert actual data in order to pass the code coverage
		apttusContracts = ApttusContractsSelector.newInstance().selectById(new set<Id>{apttusContracts.id},
			new Set<object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION,
				ApttusContractsSelector.Options.WITH_CONTACT,
				ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL,
				ApttusContractsSelector.Options.WITH_OPPORTUNITY
			}).values()[0];

		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		dealSupportRequest.Opportunity__c = opportunityRecord.Id;
		dealSupportRequest.Organisation__c = account.id;
		insert dealSupportRequest;
		subAccountRequest.APT_Charge_Account__c = chargeAccountRequest.Id;
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequest.SubAccountContact__c = primaryContact.id;
		insert subAccountRequest;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id},
			new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_CONTRACT
			})).thenReturn(mockDsrMap);
		Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
		MockUtility.Mocks.when(subAccReqSelector.selectByChargeAcountRequestIdAndStatus(new Set<Id>{chargeAccountRequest.Id},new Set<String>{'Pending Charge Account'}, new Set<Object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c},
			new Set<object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION,
				ApttusContractsSelector.Options.WITH_CONTACT,
				ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL,
				ApttusContractsSelector.Options.WITH_OPPORTUNITY
			})).thenReturn(mockApttusContractMap);
		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		// MockUtility.Mocks.when(mockDatabase.dmlInsert((onboardingRequest),(Boolean)fflib_Match.anyBoolean())).thenReturn(externalOnboardingRecord.Id);
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountController.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
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
		Account chargeAccount = accountList[1];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id},
		new Set<Object>{
			DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
			DealSupportRequestsSelector.Options.WITH_CONTRACT}
			)).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c},
			new Set<object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION,
				ApttusContractsSelector.Options.WITH_CONTACT,
				ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL,
				ApttusContractsSelector.Options.WITH_OPPORTUNITY
			})).thenReturn(mockApttusContractMap);
		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountController.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		Test.stopTest();
	}
	@IsTest
	private static void billingAccountCreationRequestTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Account chargeAccount = accountList[1];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id},
			new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_CONTRACT
		})).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c},
			new Set<object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION,
				ApttusContractsSelector.Options.WITH_CONTACT,
				ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL,
				ApttusContractsSelector.Options.WITH_OPPORTUNITY
			})).thenReturn(mockApttusContractMap);
		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		// MockUtility.Mocks.when(mockDatabase.dmlInsert((onboardingRequest),(Boolean)fflib_Match.anyBoolean())).thenReturn(externalOnboardingRecord.Id);
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		String requestLabel;
		Test.startTest();
		CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountController.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
		String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
		Continuation con = (Continuation)CreateBillingAccountController.billingAccountCreationRequest(onboardingRecordJson);
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
		Boolean result = CreateBillingAccountController.processResponse(labels, CreateBillingAccountController.stateInfoVar);
		System.assertEquals(true, result);
	}
	@IsTest
	private static void billingAccountCreationRequestErrorScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Account chargeAccount = accountList[1];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,DealSupportRequestsSelector.Options.WITH_CONTRACT})).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById(
			new Set<Id>{dealSupportRequest.APT_Contract__c},
			new Set<object>{
				ApttusContractsSelector.Options.WITH_ORGANISATION,
				ApttusContractsSelector.Options.WITH_CONTACT,
				ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL,
				ApttusContractsSelector.Options.WITH_OPPORTUNITY
			})).thenReturn(mockApttusContractMap);
		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		// MockUtility.Mocks.when(mockDatabase.dmlInsert((onboardingRequest),(Boolean)fflib_Match.anyBoolean())).thenReturn(externalOnboardingRecord.Id);
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		String requestLabel;
		Test.startTest();
		CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountController.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
		String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
		Continuation con = (Continuation)CreateBillingAccountController.billingAccountCreationRequest(onboardingRecordJson);
		requestLabel = new List<String>(con.getRequests().keySet())[0];
		Test.stopTest();
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
		Boolean result = CreateBillingAccountController.processResponse(labels, CreateBillingAccountController.stateInfoVar);
		System.assertEquals(false, result);
	}

	@IsTest
	private static void bcaBillingAccountCreationSuccessRequestTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);

			// account
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		//insert testAccount;

		String caJSONStr = '{"directors":[],"userOrgId":"ORGID","skipValidation":true,"lowerCreditLimitVal":1001,"abnDetails":{"ABN":"51824753556","ABNStatus":"ACT","ABNStatusFromDate":"1999-11-01","entities":[{"entityName":"AUSTRALIAN TAXATION OFFICE-SUPERANNUATION GROUP","entityType":"OTN"}],"EntityTypeGroup":"Government","EntityTypeMasterLabel":"GOVT","EntityTypeText":"Commonwealth Government Entity","LegalEntityName":"AUSTRALIAN TAXATION OFFICE","MatchName":"AUSTRALIAN TAXATION OFFICE","State":"ACT","TradingNameStr":"AUSTRALIAN TAXATION OFFICE","statusString":"Active","formattedABN":"51 824 753 556","tradingName":"AUSTRALIAN TAXATION OFFICE","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street, 22","countryCode":"AU","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"streetAddressString":"Finlayson street, 22,  15, LANE COVE ACT 2066 "},"businessTypeDetails":{"industryDivision":"A Agriculture, Forestry and Fishing","industryClass":"Apple & Pear Growing"},"businessContact":{"index":"_someoneElse","firstName":"xx","lastName":"yut","positionTitle":"Account Manger","email":"a@gmail.com"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":1200,"recommendedAmount":3000},"postalOutlets":[{"addressLine2":"SHOP 2 767-769 PACIFIC HIGHWAY","distance":6.62,"id":"a2K5D000001piuBUAQ","latitude":-33.755039,"longitude":151.152857,"name":"GORDON LPO","networkAddress":"SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","orgId":"288067","postcode":"2072","state":"NSW","suburb":"GORDON","addressFormatted":"shop 2 767-769 pacific highway, gordon, NSW, 2072","mapLink":"https://maps.google.com/?q=Australia Post - GORDON LPO SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","disabled":false,"selected":true},{"addressLine2":"SHOP 1 183 HARRIS STREET","distance":6.88,"id":"a2K5D000001piuIUAQ","latitude":-33.8709777,"longitude":151.1943996,"name":"PYRMONT LPO","networkAddress":"SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","orgId":"288171","postcode":"2009","state":"NSW","suburb":"PYRMONT","addressFormatted":"shop 1 183 harris street, pyrmont, NSW, 2009","mapLink":"https://maps.google.com/?q=Australia Post - PYRMONT LPO SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","disabled":false,"selected":true}]}';
		caJSONStr = caJSONStr.replace('ORGID', testAccount.Id);

		CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);

		APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();

		caRecord.L2C_Assessment_Type__c = 'Online';
		caRecord.APT_Credit_Assessment_Status__c = 'Approved';
		caRecord.Integration_Status__c = '';
		caRecord.Billing_Account__c = null;
		ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
			// =====================================
		// Stubbing
		// =====================================
		AccountsSelector accSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		//ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.stopStubbing();

		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new restSuccessMock());

		Test.startTest();
		BCABillingAccountCreationController.createBillingAccount(new Set<Id>{caRecord.Id});
		Test.stopTest();
	}

	public class restSuccessMock implements  HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('TestBodyResponse');
			response.setStatusCode(202);
			return response;
		}
	}

	@IsTest
	private static void bcaBillingAccountCreationErrorRequestTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);

			// account
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		//insert testAccount;

		String caJSONStr = '{"directors":[],"userOrgId":"ORGID","skipValidation":true,"lowerCreditLimitVal":1001,"abnDetails":{"ABN":"51824753556","ABNStatus":"ACT","ABNStatusFromDate":"1999-11-01","entities":[{"entityName":"AUSTRALIAN TAXATION OFFICE-SUPERANNUATION GROUP","entityType":"OTN"}],"EntityTypeGroup":"Government","EntityTypeMasterLabel":"GOVT","EntityTypeText":"Commonwealth Government Entity","LegalEntityName":"AUSTRALIAN TAXATION OFFICE","MatchName":"AUSTRALIAN TAXATION OFFICE","State":"ACT","TradingNameStr":"AUSTRALIAN TAXATION OFFICE","statusString":"Active","formattedABN":"51 824 753 556","tradingName":"AUSTRALIAN TAXATION OFFICE","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street, 22","countryCode":"AU","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"streetAddressString":"Finlayson street, 22,  15, LANE COVE ACT 2066 "},"businessTypeDetails":{"industryDivision":"A Agriculture, Forestry and Fishing","industryClass":"Apple & Pear Growing"},"businessContact":{"index":"_someoneElse","firstName":"xx","lastName":"yut","positionTitle":"Account Manger","email":"a@gmail.com"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":1200,"recommendedAmount":3000},"postalOutlets":[{"addressLine2":"SHOP 2 767-769 PACIFIC HIGHWAY","distance":6.62,"id":"a2K5D000001piuBUAQ","latitude":-33.755039,"longitude":151.152857,"name":"GORDON LPO","networkAddress":"SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","orgId":"288067","postcode":"2072","state":"NSW","suburb":"GORDON","addressFormatted":"shop 2 767-769 pacific highway, gordon, NSW, 2072","mapLink":"https://maps.google.com/?q=Australia Post - GORDON LPO SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","disabled":false,"selected":true},{"addressLine2":"SHOP 1 183 HARRIS STREET","distance":6.88,"id":"a2K5D000001piuIUAQ","latitude":-33.8709777,"longitude":151.1943996,"name":"PYRMONT LPO","networkAddress":"SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","orgId":"288171","postcode":"2009","state":"NSW","suburb":"PYRMONT","addressFormatted":"shop 1 183 harris street, pyrmont, NSW, 2009","mapLink":"https://maps.google.com/?q=Australia Post - PYRMONT LPO SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","disabled":false,"selected":true}]}';
		caJSONStr = caJSONStr.replace('ORGID', testAccount.Id);

		CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);

		APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();

		caRecord.L2C_Assessment_Type__c = 'Online';
		caRecord.APT_Credit_Assessment_Status__c = 'Approved';
		caRecord.Integration_Status__c = '';
		caRecord.Billing_Account__c = null;
		ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
			// =====================================
		// Stubbing
		// =====================================
		AccountsSelector accSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		//ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.stopStubbing();

		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new restErrorMock());

		Test.startTest();
		BCABillingAccountCreationController.createBillingAccount(new Set<Id>{caRecord.Id});
		Test.stopTest();
	}

	public class restErrorMock implements  HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{"errors":[{"detail":"Error in billing account creation"}]}');
			response.setStatusCode(500);
			return response;
		}
	}

		@IsTest
	private static void bcaBillingAccountCreationWithDummyConnectionTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"No"}]', List<SAP_Integration__mdt>.class)
		);

			// account
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		//insert testAccount;

		String caJSONStr = '{"directors":[],"userOrgId":"ORGID","skipValidation":true,"lowerCreditLimitVal":1001,"abnDetails":{"ABN":"51824753556","ABNStatus":"ACT","ABNStatusFromDate":"1999-11-01","entities":[{"entityName":"AUSTRALIAN TAXATION OFFICE-SUPERANNUATION GROUP","entityType":"OTN"}],"EntityTypeGroup":"Government","EntityTypeMasterLabel":"GOVT","EntityTypeText":"Commonwealth Government Entity","LegalEntityName":"AUSTRALIAN TAXATION OFFICE","MatchName":"AUSTRALIAN TAXATION OFFICE","State":"ACT","TradingNameStr":"AUSTRALIAN TAXATION OFFICE","statusString":"Active","formattedABN":"51 824 753 556","tradingName":"AUSTRALIAN TAXATION OFFICE","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street, 22","countryCode":"AU","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"streetAddressString":"Finlayson street, 22,  15, LANE COVE ACT 2066 "},"businessTypeDetails":{"industryDivision":"A Agriculture, Forestry and Fishing","industryClass":"Apple & Pear Growing"},"businessContact":{"index":"_someoneElse","firstName":"xx","lastName":"yut","positionTitle":"Account Manger","email":"a@gmail.com"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":1200,"recommendedAmount":3000},"postalOutlets":[{"addressLine2":"SHOP 2 767-769 PACIFIC HIGHWAY","distance":6.62,"id":"a2K5D000001piuBUAQ","latitude":-33.755039,"longitude":151.152857,"name":"GORDON LPO","networkAddress":"SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","orgId":"288067","postcode":"2072","state":"NSW","suburb":"GORDON","addressFormatted":"shop 2 767-769 pacific highway, gordon, NSW, 2072","mapLink":"https://maps.google.com/?q=Australia Post - GORDON LPO SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","disabled":false,"selected":true},{"addressLine2":"SHOP 1 183 HARRIS STREET","distance":6.88,"id":"a2K5D000001piuIUAQ","latitude":-33.8709777,"longitude":151.1943996,"name":"PYRMONT LPO","networkAddress":"SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","orgId":"288171","postcode":"2009","state":"NSW","suburb":"PYRMONT","addressFormatted":"shop 1 183 harris street, pyrmont, NSW, 2009","mapLink":"https://maps.google.com/?q=Australia Post - PYRMONT LPO SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","disabled":false,"selected":true}]}';
		caJSONStr = caJSONStr.replace('ORGID', testAccount.Id);

		CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);

		APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();

		caRecord.L2C_Assessment_Type__c = 'Online';
		caRecord.APT_Credit_Assessment_Status__c = 'Approved';
		caRecord.Integration_Status__c = '';
		caRecord.Billing_Account__c = null;
		ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,caRecord.Id, 'APT_Credit_Assessment__c', true)[0];

		Billing_Account__c billingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, testAccount.Id, 'SAP', true)[0];
		billingAccountRecord.LEGACY_ID__c = '7000001';
		// billingAccountRecord.Billing_Account_Number__c = '';
			// =====================================
		// Stubbing
		// =====================================
		AccountsSelector accSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.when(dsrSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Deal_Support_Request__c>{});
		MockUtility.Mocks.stopStubbing();

		// Set mock callout class
		//Test.setMock(HttpCalloutMock.class, new restErrorMock());

		Test.startTest();
		BCABillingAccountCreationController.isAllowTocreateBillingAccount(caRecord);
		BCABillingAccountCreationController.createBillingAccount(new Set<Id>{caRecord.Id});
		BillingAccountCreationEvent__e bae = new BillingAccountCreationEvent__e();
		bae.Status__c='Success';
		BillingAccountCreationEventTriggerHelper.updateCA( bae,billingAccountRecord.Id);
		Test.stopTest();
	}

	/**
	 * Test: When rating plan request payload is triggered for existing account scenario and the connection to Camunda is successful,
	 * 		validate that continuation method response expects a boolean true callout response, and DSR rating integration status updated to 'Requested'
	 */
	@IsTest
	private static void ratingPlanRequestSuccessScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

		// setup APPC product data
		List<Product2> prodList = ApplicationTestDataFactory.getPSRProducts(6, true);
		List<String> prodClassification = new List<String>{
			'APPC-Standard',
			'APPC-Premium',
			'APPC-Feature',
			'APPC-Surcharge',
			'APPC-Return',
			'APPC-FuelSurcharge'
		};
		for(Integer i=0; i<prodList.size();i++){
			prodList[i].APT_Apttus_Product_Classification__c = prodClassification[i];
		}
		// setup APPC agreement line item data
		List<Apttus__AgreementLineItem__c> aliList = APT_TestDataFactory.getAPTAgreementLineItem(6, true);
		for(Integer i=0; i<prodList.size();i++){
			aliList[i].Apttus_CMConfig__LineType__c = 'Option';
			aliList[i].Apttus_CMConfig__OptionId__c = prodList[i].Id;
			aliList[i] = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(aliList[i],
				new Map<String, Object>{
					'Apttus_CMConfig__OptionId__r' => prodList[i],
					'Apttus__AgreementId__c' => apttusContracts.Id,
					'APT_Option_Name_Without_Tier__c' => 'T04'
				});
		}
		//CI-613 Added Contract Line Items to check for Service commencement date and Service expiry date as sent in i5 request
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		Apttus__AgreementLineItem__c apttusContractLineItem = APT_TestDataFactory.getAPTAgreementLineItem(1, true)[0];
		apttusContractLineItem.Apttus__Description__c='Australia Post Parcel Contract';
		apttusContractLineItem.Apttus__ProductId__c=prod.Id;
		apttusContractLineItem.APT_Bundle_Name__c='Australia Post Parcel Contract';
		apttusContractLineItem.Apttus_CMConfig__ChargeType__c='Standard Price';
		apttusContractLineItem.Apttus_CMConfig__EffectiveDate__c=Date.newInstance(2023, 06, 01);
		apttusContractLineItem.Apttus_CMConfig__EndDate__c=Date.newInstance(2025, 06, 01);
		apttusContractLineItem.Apttus_CMConfig__BillToAccountId__c=account.ID;
		apttusContractLineItem.Apttus_CMConfig__LineType__c='Product/Service';
		apttusContractLineItem = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(apttusContractLineItem,
		new Map<String, Object>{
			'Apttus__AgreementId__c' => apttusContracts.id,
			'APT_Product_Name__c' =>'Australia Post Parcel Contract'
		});
		aliList.add(apttusContractLineItem);
		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'SAP ERP', true)[0];
		List<APT_Agreement_Lodgement_Point__c> alpList = ApplicationTestDataFactory.getAgreementLodgementPoints(2, net.id, apttusContracts.id, account.id, true);

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		APT_AgreementLineItemsSelector agreementLineItemSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(mockApttusContractMap);

		MockUtility.Mocks.when(agreementLineItemSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(alpList));

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		String requestLabel;
		Test.startTest();
		CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation onboardingRecord = CreateBillingAccountController.activateRatingPlan(dealSupportRequest.Id);
		String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
		Continuation con = (Continuation)CreateBillingAccountController.ratingPlanActivationCreationRequest(onboardingRecordJson, dealSupportRequest.Id);
		requestLabel = new List<String>(con.getRequests().keySet())[0];
		Boolean serviceDatesInPlace =CreateBillingAccountController.checkServiceDatesOnALI(dealSupportRequest.Id);
		System.assertEquals(false, serviceDatesInPlace, 'Expected success in Callout response');
		Test.stopTest();
		String mockResponseBody = '{"Status":"success"}';
		// Verify that the continuation has the correct number of requests
		Map<String, HttpRequest> requests = con.getRequests();
		System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
		// Create a mock response
		HttpResponse response = new HttpResponse();
		response.setStatusCode(202);
		response.setBody(mockResponseBody);
		Test.setContinuationResponse(requestLabel, response);
		// Expected Callout Success
		List<String> labels = new List<String>{requestLabel};
		Boolean result = CreateBillingAccountController.processResponse(labels, CreateBillingAccountController.stateInfoVar);
		System.assertEquals(true, result, 'Expected success in Callout response');
		// verify 1 dml insert for BAM external onboarding
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		// verify 3 dml update for related object records
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(3))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		// setup DSR captor
		fflib_ArgumentCaptor updatableDSRCaptor = fflib_ArgumentCaptor.forClass(List<Deal_Support_Request__c>.class);
		// verify dml insert and retrieve DSR test record from captor
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(3))).dmlUpdate((List<SObject>)updatableDSRCaptor.capture());
		Map<Id, Object> updatedDSR;
		String jsonDmlResponse = JSON.serialize(updatableDSRCaptor.getAllValues());
		System.assertEquals(true, Pattern.compile('Deal_Support_Request__c/'+dealSupportRequest.Id+'"([\\s\\S]*?)"Rating_Integration_Status__c":"Requested"').matcher(jsonDmlResponse).find(), 'Expected DSR Rating Integration Status changed to Requested');
	}

	/**
	 * Test: When rating plan request payload is triggered for existing account scenario and there is connection error with Camunda,
	 * 		validate that continuation method response expects a boolean false callout response, and DSR rating integration status updated to 'Error'
	 */
	@IsTest
	private static void ratingPlanRequestErrorScenarioTest() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
		);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

		// setup APPC product data
		List<Product2> prodList = ApplicationTestDataFactory.getPSRProducts(6, true);
		List<String> prodClassification = new List<String>{
			'APPC-Standard',
			'APPC-Premium',
			'APPC-Feature',
			'APPC-Surcharge',
			'APPC-Return',
			'APPC-FuelSurcharge'
		};
		for(Integer i=0; i<prodList.size();i++){
			prodList[i].APT_Apttus_Product_Classification__c = prodClassification[i];
		}
		// setup APPC agreement line item data
		List<Apttus__AgreementLineItem__c> aliList = APT_TestDataFactory.getAPTAgreementLineItem(6, true);
		for(Integer i=0; i<prodList.size();i++){
			aliList[i].Apttus_CMConfig__LineType__c = 'Option';
			aliList[i].Apttus_CMConfig__OptionId__c = prodList[i].Id;
			aliList[i] = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(aliList[i],
				new Map<String, Object>{
					'Apttus_CMConfig__OptionId__r' => prodList[i],
					'Apttus__AgreementId__c' => apttusContracts.Id,
					'APT_Option_Name_Without_Tier__c' => 'T04'
				});
		}

		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'SAP ERP', true)[0];
		List<APT_Agreement_Lodgement_Point__c> alpList = ApplicationTestDataFactory.getAgreementLodgementPoints(2, net.id, apttusContracts.id, account.id, true);

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		APT_AgreementLineItemsSelector agreementLineItemSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(mockApttusContractMap);

		MockUtility.Mocks.when(agreementLineItemSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(alpList));

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		String requestLabel;
		Test.startTest();
		CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation onboardingRecord = CreateBillingAccountController.activateRatingPlan(dealSupportRequest.Id);
		String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
		Continuation con = (Continuation)CreateBillingAccountController.ratingPlanActivationCreationRequest(onboardingRecordJson, dealSupportRequest.Id);
		requestLabel = new List<String>(con.getRequests().keySet())[0];
		Test.stopTest();
		String mockResponseBody = '{"errors":[{"detail":"Error in rating plan creation"}]}';
		// Verify that the continuation has the correct number of requests
		Map<String, HttpRequest> requests = con.getRequests();
		System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
		// Create a mock response
		HttpResponse response = new HttpResponse();
		response.setStatusCode(500);
		response.setBody(mockResponseBody);
		Test.setContinuationResponse(requestLabel, response);
		// Expected Callout Error
		List<String> labels = new List<String>{requestLabel};
		Boolean result = CreateBillingAccountController.processResponse(labels, CreateBillingAccountController.stateInfoVar);
		System.assertEquals(false, result, 'Expected failure in Callout response');
		// verify 1 dml insert for BAM external onboarding
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		// verify 3 dml update for related object records
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(3))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		// setup DSR captor
		fflib_ArgumentCaptor updatableDSRCaptor = fflib_ArgumentCaptor.forClass(List<Deal_Support_Request__c>.class);
		// verify dml insert and retrieve DSR test record from captor
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(3))).dmlUpdate((List<SObject>)updatableDSRCaptor.capture());
		Map<Id, Object> updatedDSR;
		String jsonDmlResponse = JSON.serialize(updatableDSRCaptor.getAllValues());
		System.assertEquals(true, Pattern.compile('Deal_Support_Request__c/'+dealSupportRequest.Id+'"([\\s\\S]*?)"Rating_Integration_Status__c":"Error"').matcher(jsonDmlResponse).find(), 'Resulting payload has failures');
	}

	/**
	 * Test: When rating plan request payload is triggered for existing account scenario with dummy connection,
	 * 		validate that DSR integration status related fields are still properly updated, and dummy response code coverage is covered
	 */
	@IsTest
	private static void validateRatingPlanRequestPayloadWithDummyConnection() {
		setMetadata(
		'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		(List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"No"}]', List<SAP_Integration__mdt>.class)
		);
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Account chargeAccount = accountList[1];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		externalOnboardingRecord.Request_Object_Id__c = dealSupportRequest.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		// setup APPC product data
		List<Product2> prodList = ApplicationTestDataFactory.getPSRProducts(6, true);
		List<String> prodClassification = new List<String>{
			'APPC-Standard',
			'APPC-Premium',
			'APPC-Feature',
			'APPC-Surcharge',
			'APPC-Return',
			'APPC-FuelSurcharge'
		};
		for(Integer i=0; i<prodList.size();i++){
			prodList[i].APT_Apttus_Product_Classification__c = prodClassification[i];
		}
		// setup APPC agreement line item data
		List<Apttus__AgreementLineItem__c> aliList = APT_TestDataFactory.getAPTAgreementLineItem(6, true);
		for(Integer i=0; i<prodList.size();i++){
			aliList[i].Apttus_CMConfig__LineType__c = 'Option';
			aliList[i].Apttus_CMConfig__OptionId__c = prodList[i].Id;
			aliList[i] = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(aliList[i],
				new Map<String, Object>{
					'Apttus_CMConfig__OptionId__r' => prodList[i],
					'Apttus__AgreementId__c' => apttusContracts.Id,
					'APT_Option_Name_Without_Tier__c' => 'T04'
				});
		}

		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'SAP ERP', true)[0];
		List<APT_Agreement_Lodgement_Point__c> alpList = ApplicationTestDataFactory.getAgreementLodgementPoints(2, net.id, apttusContracts.id, account.id, true);

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		APT_AgreementLineItemsSelector agreementLineItemSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(mockDsrMap);

		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(mockApttusContractMap);

		MockUtility.Mocks.when(agreementLineItemSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);


		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(alpList));

		List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
		String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation onboardingRecord = CreateBillingAccountController.activateRatingPlan(dealSupportRequest.Id);
		Test.stopTest();
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(3))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		// setup DSR captor
		fflib_ArgumentCaptor updatableDSRCaptor = fflib_ArgumentCaptor.forClass(List<Deal_Support_Request__c>.class);
		// verify dml insert and retrieve DSR test record from captor
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(3))).dmlUpdate((List<SObject>)updatableDSRCaptor.capture());
		Map<Id, Object> updatedDSR;
		String jsonDmlResponse = JSON.serialize(updatableDSRCaptor.getAllValues());
		System.assertEquals(true, Pattern.compile('Deal_Support_Request__c/'+dealSupportRequest.Id+'"([\\s\\S]*?)"Rating_Integration_Status__c":"Completed"').matcher(jsonDmlResponse).find(), 'Resulting payload is successful');
	}

	/**
	 * Test: When rating plan request payload is triggered and the contract is linked at charge and sub account request level for New Account scenario,
	 * 		validate that 'ChargeAccount' and 'SubAccount' objectType is present in the customer node within the payload
	 */
	@IsTest
	private static void validatePayloadContractIsLinkedAtChargeAndSubAccountLevel() {
		MockUtility.disableTriggerExecution();
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];

		// setup APPC Product data with Product Classification values
		List<Product2> prodList = ApplicationTestDataFactory.getPSRProducts(6, true);
		List<String> prodClassification = new List<String>{
			'APPC-Standard',
			'APPC-Premium',
			'APPC-Feature',
			'APPC-Surcharge',
			'APPC-FuelSurcharge',
			'APPC-Return'
		};
		// setup product code for APPC product
		List<String> prodCode = new List<String>{'SP00','SP01','FE00','SU00','SU01','RE00'};
		for(Integer i=0; i<prodList.size();i++){
			prodList[i].APT_Apttus_Product_Classification__c = prodClassification[i];
			prodList[i].SAP_Product_Code__c = prodCode[i];
		}
		// populate product classification to agreement line item
		List<Apttus__AgreementLineItem__c> aliList = APT_TestDataFactory.getAPTAgreementLineItem(6, true);
		for(Integer i=0; i<prodList.size();i++){
			aliList[i].Apttus_CMConfig__LineType__c = 'Option';
			aliList[i].Apttus_CMConfig__OptionId__c = prodList[i].Id;
			aliList[i] = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(aliList[i],
				new Map<String, Object>{
					'Apttus_CMConfig__OptionId__r' => prodList[i],
					'Apttus__AgreementId__c' => apttusContracts.Id,
					'APT_Option_Name_Without_Tier__c' => 'T04'
				});
		}

		List<APT_Agreement_Lodgement_Point__c> alpList = ApplicationTestDataFactory.getAgreementLodgementPoints(2, null, apttusContracts.id, account.id, true);
		// link charge account and sub account req to contract's junction obj
		alpList[0].APT_Charge_Account__c = chargeAccountRequest.Id;
		alpList[1].APT_Sub_Account__c = subAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================
		APT_AgreementLineItemsSelector agreementLineItemSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(agreementLineItemSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);
		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(alpList));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		// generate rating plan request payload
		BillingAccountWrapper.CompassContractActivation payload = CreateBillingAccountHelper.generateActivateRatePlanJSON(dealSupportRequest, true);
		String payloadJSON = JSON.serialize(payload);
		// Validate that "ChargeAccount" and "SubAccount" objectType is present in custom node within payload
		System.assertEquals(true, Pattern.compile('"customer"(.*)"requestObjId"(.*)"ratingPlanId"(.*)"objectType":"ChargeAccount"').matcher(payloadJSON).find(), 'Resulting payload contain charge account in customer node');
		System.assertEquals(true, Pattern.compile('"customer"(.*)"requestObjId"(.*)"ratingPlanId"(.*)"objectType":"SubAccount"').matcher(payloadJSON).find(), 'Resulting payload contain sub account in customer node');
		// Validate that all 6 product codes are present in payload
		System.assertEquals(true, Pattern.compile('"SP00"(.*)"SP01"(.*)"FE00"(.*)"SU00"(.*)"SU01"(.*)"RE00"').matcher(payloadJSON).find(), 'Resulting payload contain all 6 APPC product codes');
		Test.stopTest();
	}

	/**
	 * Test: When rating plan request payload is triggered and the contract is linked at organisation level,
	 * 		validate that 'Organisation' objectType is present in the customer node within the payload
	 */
	@IsTest
	private static void validatePayloadContractIsLinkedAtOrgLevel() {
		MockUtility.disableTriggerExecution();
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];

		// setup APPC Product data with Product Classification values
		List<Product2> prodList = ApplicationTestDataFactory.getPSRProducts(6, true);
		List<String> prodClassification = new List<String>{
			'APPC-Standard',
			'APPC-Premium',
			'APPC-Feature',
			'APPC-Surcharge',
			'APPC-FuelSurcharge',
			'APPC-Return'
		};
		// setup product code for APPC product
		List<String> prodCode = new List<String>{'SP00','SP01','FE00','SU00','SU01','RE00'};
		for(Integer i=0; i<prodList.size();i++){
			prodList[i].APT_Apttus_Product_Classification__c = prodClassification[i];
			prodList[i].SAP_Product_Code__c = prodCode[i];
		}
		// populate product classification to agreement line item
		List<Apttus__AgreementLineItem__c> aliList = APT_TestDataFactory.getAPTAgreementLineItem(6, true);
		for(Integer i=0; i<prodList.size();i++){
			aliList[i].Apttus_CMConfig__LineType__c = 'Option';
			aliList[i].Apttus_CMConfig__OptionId__c = prodList[i].Id;
			aliList[i] = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(aliList[i],
				new Map<String, Object>{
					'Apttus_CMConfig__OptionId__r' => prodList[i],
					'Apttus__AgreementId__c' => apttusContracts.Id,
					'APT_Option_Name_Without_Tier__c' => 'T04'
				});
		}

		List<APT_Agreement_Lodgement_Point__c> alpList = ApplicationTestDataFactory.getAgreementLodgementPoints(1, null, apttusContracts.id, account.id, true);
		// contract's junction obj is linked at Org Lv
		alpList[0].APT_Charge_Account__c = null;
		alpList[0].APT_Sub_Account__c = null;
		alpList[0].APT_Billing_Account__c = null;

		// =====================================
		// Stubbing
		// =====================================
		APT_AgreementLineItemsSelector agreementLineItemSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(agreementLineItemSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);
		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(alpList));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		// generate rating plan request payload
		BillingAccountWrapper.CompassContractActivation payload = CreateBillingAccountHelper.generateActivateRatePlanJSON(dealSupportRequest, true);
		String payloadJSON = JSON.serialize(payload);
		// Validate that "Organisation" objectType is present in custom node within payload
		System.assertEquals(true, Pattern.compile('"customer"(.*)"requestObjId"(.*)"ratingPlanId"(.*)"objectType":"Organisation"').matcher(payloadJSON).find(), 'Resulting payload contain organisation in customer node');
		System.assertEquals(true, Pattern.compile('"SP00"(.*)"SP01"(.*)"FE00"(.*)"SU00"(.*)"SU01"(.*)"RE00"').matcher(payloadJSON).find(), 'Resulting payload contain all 6 APPC product codes');
		Test.stopTest();
	}

	/**
	 * Test: When rating plan request payload is triggered and the contract is linked at billing account level for existing account scenario,
	 * 		validate that 'BillingAccount' objectType is present in the customer node within the payload
	 */
	@IsTest
	private static void validatePayloadContractIsLinkedAtBillingAccountLevel() {
		MockUtility.disableTriggerExecution();
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];

		// setup APPC Product data with Product Classification values
		List<Product2> prodList = ApplicationTestDataFactory.getPSRProducts(6, true);
		List<String> prodClassification = new List<String>{
			'APPC-Standard',
			'APPC-Premium',
			'APPC-Feature',
			'APPC-Surcharge',
			'APPC-FuelSurcharge',
			'APPC-Return'
		};
		// setup product code for APPC product
		List<String> prodCode = new List<String>{'SP00','SP01','FE00','SU00','SU01','RE00'};
		for(Integer i=0; i<prodList.size();i++){
			prodList[i].APT_Apttus_Product_Classification__c = prodClassification[i];
			prodList[i].SAP_Product_Code__c = prodCode[i];
		}
		// populate product classification to agreement line item
		List<Apttus__AgreementLineItem__c> aliList = APT_TestDataFactory.getAPTAgreementLineItem(6, true);
		for(Integer i=0; i<prodList.size();i++){
			aliList[i].Apttus_CMConfig__LineType__c = 'Option';
			aliList[i].Apttus_CMConfig__OptionId__c = prodList[i].Id;
			aliList[i] = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(aliList[i],
				new Map<String, Object>{
					'Apttus_CMConfig__OptionId__r' => prodList[i],
					'Apttus__AgreementId__c' => apttusContracts.Id,
					'APT_Option_Name_Without_Tier__c' => 'T04'
				});
		}
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'SAP ERP', true)[0];
		List<APT_Agreement_Lodgement_Point__c> alpList = ApplicationTestDataFactory.getAgreementLodgementPoints(2, null, apttusContracts.id, account.id, true);
		// contract's junction obj is linked at Org Lv
		alpList[0].APT_Billing_Account__c = billAccRec.Id;

		// =====================================
		// Stubbing
		// =====================================
		APT_AgreementLineItemsSelector agreementLineItemSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(agreementLineItemSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);
		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject()))
			.thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(alpList));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		// generate rating plan request payload
		BillingAccountWrapper.CompassContractActivation payload = CreateBillingAccountHelper.generateActivateRatePlanJSON(dealSupportRequest, false);
		String payloadJSON = JSON.serialize(payload);
		// Validate that "BillingAccount" objectType is present in custom node within payload
		System.assertEquals(true, Pattern.compile('"customer"(.*)"requestObjId"(.*)"ratingPlanId"(.*)"objectType":"BillingAccount"').matcher(payloadJSON).find(), 'Resulting payload contain billing account in customer node');
		System.assertEquals(true, Pattern.compile('"SP00"(.*)"SP01"(.*)"FE00"(.*)"SU00"(.*)"SU01"(.*)"RE00"').matcher(payloadJSON).find(), 'Resulting payload contain all 6 APPC product codes');
		Test.stopTest();
	}
}