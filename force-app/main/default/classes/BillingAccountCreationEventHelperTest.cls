/* @author
* @date 2020-11-18
* @group Tests
* @tag Selector
* @tag BillingAccount
* @domain Core
* @description test class for BillingAccountCreationEventHelper
* @changelog
* 2020-11-18 - Shashwat.Nath@austpost.com.au - Created
* 2022-08-08 - Seth Heang - Added test method to cover Rating Plan Activation changes
* 2023-03-23 - Sarath.burra@auspost.com.au - CI-703 Added verifyAndCaptureInsertedDmlRecords/verifyAndCaptureUpdatedDmlRecords to verify captured Inserted and updated records
* 2023-03-23 - Sarath.burra@auspost.com.au - CI-613 Added Contract Line Items to populate SAP contract with  Service commencement date and Service expiry date as sent in i5 request
* 2023-11-24 - Ranjeewa Silva - Removed test method verifying the processing of StarTrack billing account creation event from TEAM.
*							   Processing StarTrack billing account creation event is covered in detail in CreateSTBillingAccEvtHandlerModule_Test.
*/
@IsTest
public with sharing class BillingAccountCreationEventHelperTest {
	@IsTest
	private static void testBillingAccountCreationSuccessScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];


		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_eParcel_Enabled__c='Yes';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c='Billing Account';
		subAccountRequest.Is_Parcel_Send_Login_Required__c ='No';
		subAccountRequest.Sub_Account_Number__c = 'SF-11224455';
		subAccountRequest.product__c='eParcel;APPC';
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		//apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, net.id, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;
		//Code start
		Apttus__AgreementLineItem__c apttusContractLineItem = APT_TestDataFactory.getAPTAgreementLineItem(1, true)[0];
		apttusContractLineItem.Apttus__Description__c='Australia Post Parcel Contract';
		apttusContractLineItem.Apttus__ProductId__c=prod.Id;
		apttusContractLineItem.APT_Bundle_Name__c='Australia Post Parcel Contract';
		apttusContractLineItem.Apttus_CMConfig__ChargeType__c='Standard Price';
		apttusContractLineItem.Apttus_CMConfig__EffectiveDate__c=Date.newInstance(2023, 06, 01);
		apttusContractLineItem.Apttus_CMConfig__EndDate__c=Date.newInstance(2025, 06, 01);

		apttusContractLineItem.Apttus_CMConfig__BillToAccountId__c=account.ID;

		apttusContractLineItem = (Apttus__AgreementLineItem__c)ApplicationTestDataFactory.setUnwritableFields(apttusContractLineItem,
				new Map<String, Object>{
					'Apttus__AgreementId__c' => apttusContracts.id
				});
		apttusProposals = (Apttus_Proposal__Proposal__c)ApplicationTestDataFactory.setUnwritableFields(apttusProposals,
				new Map<String, Object>{
					'APT_Credit_Assessment__r' =>apttusCreditAssessment
				});

		apttusContracts = (Apttus__APTS_Agreement__c)ApplicationTestDataFactory.setUnwritableFields(apttusContracts,
				new Map<String, Object>{
					'APT_APPC_Count__c' =>1.00,
						'Apttus_QPComply__RelatedProposalId__r'=> apttusProposals
				});

			dealSupportRequest = (Deal_Support_Request__c)ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest,
				new Map<String, Object>{
					'APT_Contract__r' =>apttusContracts
				});



		system.assertEquals(apttusContractLineItem.Apttus__Description__c,'Australia Post Parcel Contract');
		system.assertEquals(apttusContracts.APT_APPC_Count__c,1.00);

		APT_AgreementLodgementPointsSelector alpSelector = (APT_AgreementLodgementPointsSelector) MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}),(Set<Object>)fflib_Match.anyObject())).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
			BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Request_Object_Id__c=dealSupportRequest.Id,
			Billing_Account_Number__c = 'SF-11224455',
			Billing_Account_Name__c ='Test Billing account Name',
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Success',
			Parent_Account_Number__c='',
			Sub_Account_Request_Id__c= ''
			);
			EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Success'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();
		//CI-703 Added verifyAndCaptureInsertedDmlRecords/verifyAndCaptureUpdatedDmlRecords to verify captured Inserted and updated records
		List<List<sObject>> insertRecs=MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase,2);
		List<List<sObject>> updateRecs=MockUtility.verifyAndCaptureUpdatedDmlRecords(mockDatabase,2);
		for(List<SObject> obj :insertRecs){
			if (obj.size()==1){
				Deal_Support_Request__c dsr =(Deal_Support_Request__c)obj[0];
				System.assertEquals(billingAccount.Id, dsr.Billing_Account__c, 'Expected Success on DSR Record creation');
				System.assertEquals('Submitted', dsr.Status__c, 'Expected Success on DSR Record creation');
			}
		}
		for(List<SObject> obj :updateRecs){
			for(SObject sObj :obj){
				String objectName = String.valueOf(id.valueOf(sObj.Id)?.getsobjecttype());

				if(objectName.equalsIgnoreCase('APT_Sub_Account__c')){
					APT_Sub_Account__c sAcc =(APT_Sub_Account__c)sObj;
					System.assertEquals(newsEvent1.Status__c, sAcc.APT_Sub_Account_Request_Status__c, 'Expected Success on Sub Account Record Update');
				}
				if(objectName.equalsIgnoreCase('APT_Agreement_Lodgement_Point__c')){
					APT_Agreement_Lodgement_Point__c lp =(APT_Agreement_Lodgement_Point__c)sObj;
					System.assertEquals(apttusContracts.Id, lp.APT_Agreement__c, 'Expected Success on Lodgement Point Record Update');
				}
			}
		}
	}

	@IsTest
	private static void testBillingAccountCreationErrorScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, null, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);
		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Source_System__c = 'SAP',
				Status__c = 'Error'
		);
		EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Error'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();
		//CI-703 Added verifyAndCaptureInsertedDmlRecords/verifyAndCaptureUpdatedDmlRecords to verify captured Inserted and updated records
		List<List<SObject>> updateRecs=MockUtility.verifyAndCaptureUpdatedDmlRecords(mockDatabase,2);
		for(List<SObject> obj :updateRecs){
			for(SObject sObj :obj){
				String objectName = String.valueOf(id.valueOf(sObj.Id)?.getsobjecttype());
				if(objectName.equalsIgnoreCase('APT_Sub_Account__c')){
					APT_Sub_Account__c sAcc =(APT_Sub_Account__c)sObj;
					System.assertEquals(newsEvent1.Status__c, sAcc.APT_Sub_Account_Request_Status__c, 'Expected Failure on Sub Account Record Update');
				}
			}
		}
	}

	@IsTest
	private static void testBillingAccountCreationPartialSuccessScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];


		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, null, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;
		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);
		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Source_System__c = 'SAP',
				Status__c = 'Partial Success'
		);
		EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224454',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Success'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();
		//CI-703 Added verifyAndCaptureInsertedDmlRecords/verifyAndCaptureUpdatedDmlRecords to verify captured Inserted and updated records
		List<sObject> insertRecs=MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase);
		List<List<SObject>> updateRecs=MockUtility.verifyAndCaptureUpdatedDmlRecords(mockDatabase,2);
		Billing_Account__c ba =(Billing_Account__c)insertRecs[0];
		System.assertEquals(ba.LEGACY_ID__c, newsEvent.Billing_Account_Number__c, 'Expected Success on Billing Account Record creation');
		for(List<SObject> obj :updateRecs){
			for(SObject sObj :obj){
				String objectName = String.valueOf(id.valueOf(sObj.Id)?.getsobjecttype());
				if(objectName.equalsIgnoreCase('APT_Sub_Account__c')){
					APT_Sub_Account__c sAcc =(APT_Sub_Account__c)sObj;
					System.assertEquals(newsEvent1.Status__c, sAcc.APT_Sub_Account_Request_Status__c, 'Expected Success on Sub Account Record Update');
				}
				if(objectName.equalsIgnoreCase('APT_Agreement_Lodgement_Point__c')){
					APT_Agreement_Lodgement_Point__c lp =(APT_Agreement_Lodgement_Point__c)sObj;
					System.assertEquals(apttusContracts.Id, lp.APT_Agreement__c, 'Expected Success on Lodgement Point Record Update');
				}
			}
		}
	}

	@IsTest
	private static void testDSRCreationForAddContractRates() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Billing Account';
		subAccountRequest.Sub_Account_Number__c = 'SF-11224455'; // fix null reference issue and increase code coverage
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		//apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, null, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);
		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Source_System__c = 'SAP',
				Status__c = 'Success'
		);
		EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Success'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();

		//CI-703 Added verifyAndCaptureInsertedDmlRecords/verifyAndCaptureUpdatedDmlRecords to verify captured Inserted and updated records
		List<sObject> insertRecs=MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase);
		List<List<SObject>> updateRecs=MockUtility.verifyAndCaptureUpdatedDmlRecords(mockDatabase,2);
		Billing_Account__c ba =(Billing_Account__c)insertRecs[0];
		System.assertEquals(ba.LEGACY_ID__c, newsEvent.Billing_Account_Number__c, 'Expected Success on Billing Account Record creation');
		for(List<SObject> obj :updateRecs){
			for(SObject sObj :obj){
				String objectName = String.valueOf(id.valueOf(sObj.Id)?.getsobjecttype());
				if(objectName.equalsIgnoreCase('APT_Sub_Account__c')){
					APT_Sub_Account__c sAcc =(APT_Sub_Account__c)sObj;
					System.assertEquals(newsEvent1.Status__c, sAcc.APT_Sub_Account_Request_Status__c, 'Expected Success on Sub Account Record Update');
				}
				if(objectName.equalsIgnoreCase('APT_Agreement_Lodgement_Point__c')){
					APT_Agreement_Lodgement_Point__c lp =(APT_Agreement_Lodgement_Point__c)sObj;
					System.assertEquals(apttusContracts.Id, lp.APT_Agreement__c, 'Expected Success on Lodgement Point Record Update');
				}
			}
		}
	}

	@IsTest
	private static void testBillingAccountCreationPartialSuccessSubScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';

		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		//apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Source_System__c = 'SAP',
				Status__c = 'Success'
		);
		EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=dealSupportRequest.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Partial Success'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();

		//CI-703 Added verifyAndCaptureInsertedDmlRecords/verifyAndCaptureUpdatedDmlRecords to verify captured Inserted and updated records
		List<sObject> insertRecs=MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase);
		List<List<SObject>> updateRecs=MockUtility.verifyAndCaptureUpdatedDmlRecords(mockDatabase,2);
		Billing_Account__c ba =(Billing_Account__c)insertRecs[0];
		System.assertEquals(ba.LEGACY_ID__c, newsEvent.Billing_Account_Number__c, 'Expected Success on Billing Account Record creation');
		for(List<SObject> obj :updateRecs){
			for(SObject sObj :obj){
				String objectName = String.valueOf(id.valueOf(sObj.Id)?.getsobjecttype());
				if(objectName.equalsIgnoreCase('APT_Sub_Account__c')){
					APT_Sub_Account__c sAcc =(APT_Sub_Account__c)sObj;
					System.assertEquals(newsEvent1.Status__c, sAcc.APT_Sub_Account_Request_Status__c, 'Expected Success on Sub Account Record Update');
				}
				if(objectName.equalsIgnoreCase('APT_Agreement_Lodgement_Point__c')){
					APT_Agreement_Lodgement_Point__c lp =(APT_Agreement_Lodgement_Point__c)sObj;
					System.assertEquals(apttusContracts.Id, lp.APT_Agreement__c, 'Expected Success on Lodgement Point Record Update');
				}
			}
		}
	}

		@IsTest
		private static void testBillingAccountCreationSuccessScenarioBCAError() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];


		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';

		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';

		APT_Credit_Assessment__c CA = ApplicationTestDataFactory.getApttusCreditsAssessment(1,null,true)[0];
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		//apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		Account tempAccount = new Account();
		tempAccount.name = 'TempBillingaccount';
		tempAccount.Legacy_Id__c = '60000000';
		insert tempAccount;
		tempAccount.Legacy_Id__c = '60000000';
		update tempAccount;



		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
			BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Request_Object_Id__c=CA.Id,
			Billing_Account_Number__c = 'SF-11224455',
			Billing_Account_Name__c ='Test Billing account Name',
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Error'
			);
			EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=CA.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Success'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();
	}

	@IsTest
	private static void testBillingAccountCreationSuccessScenarioBCASuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';

		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';

		APT_Credit_Assessment__c CA = ApplicationTestDataFactory.getApttusCreditsAssessment(1,null,true)[0];
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		//apttusContracts.Apttus_QPComply__RelatedProposalId__c = new Apttus_Proposal__Proposal__c();
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;

		Account tempAccount = new Account();
		tempAccount.name = 'TempBillingaccount';
		tempAccount.Legacy_Id__c = '60000000';
		insert tempAccount;
		tempAccount.Legacy_Id__c = '60000000';
		update tempAccount;



		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_OWNER,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT ,
				DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		//MockUtility.Mocks.when(holdingRoleSelector.selectByName('New Accounts')).thenReturn(holdingRoleMap);
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		system.debug('Mock Billing Account Map' +billAccountMap);
		system.debug('Mock Billing Account ' +billingAccount);
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber((List<Billing_Account__c>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);


		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
			BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Request_Object_Id__c=CA.Id,
			Billing_Account_Number__c = 'SF-11224455',
			Billing_Account_Name__c ='Test Billing account Name',
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Success'
			);
			EventBus.publish(newsEvent);

		BillingAccountCreationEvent__e newsEvent1 = new BillingAccountCreationEvent__e(
				Request_Object_Id__c=CA.Id,
				Billing_Account_Number__c = 'SF-11224455',
				Billing_Account_Name__c ='Test Billing account Name',
				Organisation_Record_Id__c=account.Id,
				Transaction_Id__c = externalOnboardingRecord.Id,
				Parent_Account_Number__c = 'SF-11224455',
				Sub_Account_Request_Id__c = subAccountRequest.id,
				Source_System__c = 'SAP',
				Status__c = 'Error'
		);
		EventBus.publish(newsEvent1);

		Test.stopTest();

	}

	/**
	 * Test: when the rating plan creation callout is triggered and the callout is successful,
	 *	  validate that the agreement lodgement point's integration related fields are updated based on platform event fields
	 */
	@IsTest
	private static void testRatingPlanCreationSuccessScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		externalOnboardingRecord = (BAMExternalOnboardingRequest__c)ApplicationTestDataFactory.setUnwritableFields(externalOnboardingRecord,
				new Map<String, Object>{
					'CreatedDate' => System.TODAY()
				});
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		//CI-613 Added Contract Line Items to populate SAP contract with  Service commencement date and Service expiry date as sent in i5 request
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
			'Apttus__AgreementId__c' => apttusContracts.id
		});
		List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c> {apttusContractLineItem};
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, null, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);
		ExternalOnboardingRequestSelector exOnboardingSelector = (ExternalOnboardingRequestSelector)MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		APT_AgreementLineItemsSelector lineItemsSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, BAMExternalOnboardingRequest__c> externalOnboardingRecordMap = new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRecord.Id => externalOnboardingRecord};
		MockUtility.Mocks.when(exOnboardingSelector.selectById(new Set<id>{externalOnboardingRecord.Id})).thenReturn(externalOnboardingRecordMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		MockUtility.Mocks.when(billAccountSel.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));
		MockUtility.Mocks.when(lineItemsSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		Test.startTest();
			BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Additional_Info__c='RatingPlanActivation',
			Request_Object_Id__c=alpRec.Id,
			Billing_Account_Number__c = 'SF-11224455',
			Billing_Account_Name__c ='Test Billing account Name',
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Success',
			Status_Description__c = 'Rating plan(s) have been activated successfully.',
			Rating_Plan_Id__c = '444555677'
		);
		EventBus.publish(newsEvent);

		Test.stopTest();

		//define update DSR Captor
		fflib_ArgumentCaptor updateableALPCaptor = fflib_ArgumentCaptor.forClass(List<APT_Agreement_Lodgement_Point__c>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<APT_Agreement_Lodgement_Point__c>) updateableALPCaptor.capture());

		// setup sap contract captor
		fflib_ArgumentCaptor insertedSAPContract = fflib_ArgumentCaptor.forClass(List<APT_SAP_Contracts__c>.class);
		// verify dml insert has been made 1 times for SAP Contract record
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<APT_SAP_Contracts__c>)insertedSAPContract.capture());

		Map<Id, APT_Agreement_Lodgement_Point__c> updateableALPs = new Map<Id, APT_Agreement_Lodgement_Point__c>((List<APT_Agreement_Lodgement_Point__c>) updateableALPCaptor.getValue());
		System.assertEquals(newsEvent.Status__c, updateableALPs.get(alpRec.Id).Integration_Status__c, 'Expected Success on Agreement Lodgement Point Integration Status');
		System.assertEquals(newsEvent.Status_Description__c, updateableALPs.get(alpRec.Id).Integration_Status_Description__c, 'Expected matching status description on Agreement Lodgement Point Status Description');
		System.assertEquals(newsEvent.Rating_Plan_Id__c, updateableALPs.get(alpRec.Id).Rating_Plan_Id__c, 'Expected matching rating plan Id on Agreement Lodgement Point Status Description');
		}

		/**
		 * Test: when the rating plan creation callout is triggered and the callout has Error,
		 *	  validate that the agreement lodgement point's integration related fields are updated based on platform event fields
		 */
		@IsTest
		private static void testRatingPlanCreationErrorScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		//CI-613 Added Contract Line Items to populate SAP contract with  Service commencement date and Service expiry date as sent in i5 request
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
			'Apttus__AgreementId__c' => apttusContracts.id
		});
		List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c> {apttusContractLineItem};
		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, net.id, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);
		ExternalOnboardingRequestSelector exOnboardingSelector = (ExternalOnboardingRequestSelector)MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		APT_AgreementLineItemsSelector lineItemsSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, BAMExternalOnboardingRequest__c> externalOnboardingRecordMap = new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRecord.Id => externalOnboardingRecord};
		MockUtility.Mocks.when(exOnboardingSelector.selectById(new Set<id>{externalOnboardingRecord.Id})).thenReturn(externalOnboardingRecordMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		MockUtility.Mocks.when(billAccountSel.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

		MockUtility.Mocks.when(lineItemsSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Additional_Info__c='RatingPlanActivation',
			Request_Object_Id__c=alpRec.Id,
			Billing_Account_Number__c = 'SF-11224455',
			Billing_Account_Name__c ='Test Billing account Name',
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Error',
			Status_Description__c = 'Rating plan activation has failure.',
			Rating_Plan_Id__c = '444555677'
		);
		EventBus.publish(newsEvent);

		Test.stopTest();

		//define update dsr Captor
		fflib_ArgumentCaptor updateableALPCaptor = fflib_ArgumentCaptor.forClass(List<APT_Agreement_Lodgement_Point__c>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<APT_Agreement_Lodgement_Point__c>) updateableALPCaptor.capture());

		Map<Id, APT_Agreement_Lodgement_Point__c> updateableALPs = new Map<Id, APT_Agreement_Lodgement_Point__c>((List<APT_Agreement_Lodgement_Point__c>) updateableALPCaptor.getValue());
		System.assertEquals(newsEvent.Status__c, updateableALPs.get(alpRec.Id).Integration_Status__c, 'Expected Error on Agreement Lodgement Point Integration Status');
		System.assertEquals(newsEvent.Status_Description__c, updateableALPs.get(alpRec.Id).Integration_Status_Description__c, 'Expected matching status description on Agreement Lodgement Point Status Description');
	}

	/**
	 * Test: when the rating plan creation callout is triggered and the final rollup platform event has Completed status,
	 *	  validate that the DSR's integration related fields are updated based on platform event fields
	 */
	@IsTest
	private static void testRatingPlanCreationFinalPayloadCompletedScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		//CI-613 Added Contract Line Items to populate SAP contract with  Service commencement date and Service expiry date as sent in i5 request
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
			'Apttus__AgreementId__c' => apttusContracts.id
		});
		List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c> {apttusContractLineItem};

		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, net.id, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;
		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);
		ExternalOnboardingRequestSelector exOnboardingSelector = (ExternalOnboardingRequestSelector)MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		APT_AgreementLineItemsSelector lineItemsSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
			new Set<object>{
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
			})).thenReturn(mockDsrMap);

		Map<Id, BAMExternalOnboardingRequest__c> externalOnboardingRecordMap = new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRecord.Id => externalOnboardingRecord};
		MockUtility.Mocks.when(exOnboardingSelector.selectById(new Set<id>{externalOnboardingRecord.Id})).thenReturn(externalOnboardingRecordMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		//MockUtility.Mocks.when(billAccountSel.selectByIdorAccountNumber(billAccountMap.values(),new Set<String>{'SF-11224455'})).thenReturn(billAccountMap);
		MockUtility.Mocks.when(billAccountSel.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

		MockUtility.Mocks.when(lineItemsSelector.selectByContractIdsAndLineType(
				(Set<Id>)fflib_Match.anyObject(),
				(Set<String>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
			new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Additional_Info__c='RatingPlanActivation',
			Request_Object_Id__c=dealSupportRequest.Id,
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Completed',
			Status_Description__c = 'Rating plan(s) have been activated successfully.'
		);
		EventBus.publish(newsEvent);

		Test.stopTest();
		//define update dsr Captor
		fflib_ArgumentCaptor updateableDSRCaptor = fflib_ArgumentCaptor.forClass(List<Deal_Support_Request__c>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Deal_Support_Request__c>) updateableDSRCaptor.capture());

		Map<Id, Deal_Support_Request__c> updateableDSRs = new Map<Id, Deal_Support_Request__c>((List<Deal_Support_Request__c>) updateableDSRCaptor.getValue());
		System.assertEquals(newsEvent.Status__c, updateableDSRs.get(dealSupportRequest.Id).Rating_Integration_Status__c, 'Expected Completed on DSR Rating Plan Integration Status');
		System.assertEquals(newsEvent.Status_Description__c, updateableDSRs.get(dealSupportRequest.Id).Rating_Integration_Status_Description__c, 'Expected matching status description on DSR Rating Plan Integration Status Description');
	}

	/**
	 * Test: when the rating plan creation callout is triggered and final rollup platform event has Partial Success status,
	 *	  validate that the DSR's integration related fields are updated based on platform event fields
	 */
	@IsTest
	private static void testRatingPlanCreationFinalPayloadPartialSuccessScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		//CI-613 Added Contract Line Items to populate SAP contract with  Service commencement date and Service expiry date as sent in i5 request
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
			'Apttus__AgreementId__c' => apttusContracts.id
		});
		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, net.id, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);
		ExternalOnboardingRequestSelector exOnboardingSelector = (ExternalOnboardingRequestSelector)MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);
		APT_AgreementLineItemsSelector lineItemsSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c> {apttusContractLineItem};
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
		new Set<object>{
			DealSupportRequestsSelector.Options.WITH_ORGANISATION
		})).thenReturn(mockDsrMap);

		Map<Id, BAMExternalOnboardingRequest__c> externalOnboardingRecordMap = new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRecord.Id => externalOnboardingRecord};
		MockUtility.Mocks.when(exOnboardingSelector.selectById(new Set<id>{externalOnboardingRecord.Id})).thenReturn(externalOnboardingRecordMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		MockUtility.Mocks.when(billAccountSel.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);

		MockUtility.Mocks.when(lineItemsSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
		(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
		new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Additional_Info__c='RatingPlanActivation',
			Request_Object_Id__c=dealSupportRequest.Id,
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Partial Success',
			Status_Description__c = 'One or more rating plan(s) activation failed...'
		);
		EventBus.publish(newsEvent);

		Test.stopTest();

		//define update dsr Captor
		fflib_ArgumentCaptor updateableDSRCaptor = fflib_ArgumentCaptor.forClass(List<Deal_Support_Request__c>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Deal_Support_Request__c>) updateableDSRCaptor.capture());

		Map<Id, Deal_Support_Request__c> updateableDSRs = new Map<Id, Deal_Support_Request__c>((List<Deal_Support_Request__c>) updateableDSRCaptor.getValue());
		System.assertEquals(newsEvent.Status__c, updateableDSRs.get(dealSupportRequest.Id).Rating_Integration_Status__c, 'Expected Partial Success on DSR Rating Plan Integration Status');
		System.assertEquals(newsEvent.Status_Description__c, updateableDSRs.get(dealSupportRequest.Id).Rating_Integration_Status_Description__c, 'Expected matching status description on DSR Rating Plan Integration Status Description');
	}

	/**
	 * Test: when the rating plan creation callout is triggered and final rollup platform event has Error status,
	 *	  validate that the DSR's integration related fields are updated based on platform event fields
	 */
	@IsTest
	private static void testRatingPlanCreationFinalPayloadErrorScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
		Holding_Role_Reference__c getHoldingRoleRef = ApplicationTestDataFactory.getHoldingRoleRef(1, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];
		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test',true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1,account.id,'SAP',true)[0];
		product2 prod=APT_TestDataFactory.getAppcProduct(1,true)[0];
		billingAccount.LEGACY_ID__c = 'SF-11224455';
		subAccountRequest.APT_Source_of_Sub_Account_Request__c = 'Proposal';
		apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;
		//CI-613 Added Contract Line Items to populate SAP contract with  Service commencement date and Service expiry date as sent in i5 request
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
			'Apttus__AgreementId__c' => apttusContracts.id
		});
		List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c> {apttusContractLineItem};

		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, net.id, apttusContracts.id, account.id, true)[0];
		alpRec.APT_Charge_Account__c = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================

		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HoldingReferenceRoleSelector holdingRoleSelector = (HoldingReferenceRoleSelector)MockUtility.mockSelector(HoldingReferenceRoleSelector.class);
		SubAccountRequestsSelector subRequestSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		BillingAccountsSelector billAccountSel = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);
		APT_AgreementLodgementPointsSelector agreementLPSelector = (APT_AgreementLodgementPointsSelector)MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);
		ExternalOnboardingRequestSelector exOnboardingSelector = (ExternalOnboardingRequestSelector)MockUtility.mockSelector(ExternalOnboardingRequestSelector.class);

		APT_AgreementLineItemsSelector lineItemsSelector = (APT_AgreementLineItemsSelector)MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
		MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES,AccountsSelector.Options.WITH_HOLDINGROLE})).thenReturn(mockOrganisationMap );

		Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
		MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset(),
		new Set<object>{
			DealSupportRequestsSelector.Options.WITH_ORGANISATION
		})).thenReturn(mockDsrMap);

		Map<Id, BAMExternalOnboardingRequest__c> externalOnboardingRecordMap = new Map<Id, BAMExternalOnboardingRequest__c>{externalOnboardingRecord.Id => externalOnboardingRecord};
		MockUtility.Mocks.when(exOnboardingSelector.selectById(new Set<id>{externalOnboardingRecord.Id})).thenReturn(externalOnboardingRecordMap);

		Map<Id, Holding_Role_Reference__c> holdingRoleMap = new Map<Id, Holding_Role_Reference__c>{getHoldingRoleRef.Id => getHoldingRoleRef};
		MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);

		Map<Id, APT_Sub_Account__c> subAccountMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest};
		MockUtility.Mocks.when(subRequestSelector.selectById(subAccountMap.keySet())).thenReturn(subAccountMap);

		Map<Id, Billing_Account__c> billAccountMap = new Map<Id, Billing_Account__c>{billingAccount.Id => billingAccount};
		MockUtility.Mocks.when(billAccountSel.selectByAccountNumber((Set<String>)fflib_Match.anyObject())).thenReturn(billAccountMap);
		MockUtility.Mocks.when(lineItemsSelector.selectByContractIdsAndLineType(
				(Set<Id>)fflib_Match.anyObject(),
				(Set<String>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject())).thenReturn(aliList);

		MockUtility.Mocks.when(agreementLPSelector.selectByApttusContractId(
		(Set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.Id}))).thenReturn(
		new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		BillingAccountCreationEvent__e newsEvent = new BillingAccountCreationEvent__e(
			Additional_Info__c='RatingPlanActivation',
			Request_Object_Id__c=dealSupportRequest.Id,
			Organisation_Record_Id__c=account.Id,
			Transaction_Id__c = externalOnboardingRecord.Id,
			Source_System__c = 'SAP',
			Status__c = 'Error',
			Status_Description__c = 'All rating plan(s) activation failed...'
		);
		EventBus.publish(newsEvent);

		Test.stopTest();

		//define update dsr Captor
		fflib_ArgumentCaptor updateableDSRCaptor = fflib_ArgumentCaptor.forClass(List<Deal_Support_Request__c>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Deal_Support_Request__c>) updateableDSRCaptor.capture());

		Map<Id, Deal_Support_Request__c> updateableDSRs = new Map<Id, Deal_Support_Request__c>((List<Deal_Support_Request__c>) updateableDSRCaptor.getValue());
		System.assertEquals(newsEvent.Status__c, updateableDSRs.get(dealSupportRequest.Id).Rating_Integration_Status__c, 'Expected Error on DSR Rating Plan Integration Status');
		System.assertEquals(newsEvent.Status_Description__c, updateableDSRs.get(dealSupportRequest.Id).Rating_Integration_Status_Description__c, 'Expected matching status description on DSR Rating Plan Integration Status Description');
	}
}