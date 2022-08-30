/**
* @author Seth Heang
* @date 2022-06-01
* @group Tests
* @tag ApexController
* @domain Apttus
* @description A test class for APT_LinkingBillAccContractController
* @changelog
* 2022-06-01 - seth.heang@auspost.com.au - Created
*/
@IsTest
public with sharing class APT_LinkingBillAccContractControllerTest {

	/**
	 * Test: when the method retrieveAgreementLodgementPoints() is called, 
	 * 		validate that the method successfully queries the agreement lodgement point based on contract Id
	 */
	@IsTest
	public static void testSuccessfulRetrievingAgreementLPs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Network__c net = ApplicationTestDataFactory.getNetworks(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, acc.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		Apttus__APTS_Agreement__c contract = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.id, true)[0];
		String contractId = (String)contract.Id;
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'SAP ERP', true)[0];
		APT_Charge_Account__c carRec = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		APT_Sub_Account__c sarRec = ApplicationTestDataFactory.getSubAccountRequest(1, 'Sub Test 1', true)[0];
		APT_Agreement_Lodgement_Point__c alpRec = ApplicationTestDataFactory.getAgreementLodgementPoints(1, net.id, contract.id, acc.id, true)[0];
		alpRec.APT_Billing_Account__c = billAccRec.Id;
		alpRec.APT_Charge_Account__c = carRec.Id;
		alpRec.APT_Sub_Account__c = sarRec.Id;

		// =====================================
		// Stubbing
		// =====================================
		APT_AgreementLodgementPointsSelector mockSelector = (APT_AgreementLodgementPointsSelector) MockUtility.mockSelector(APT_AgreementLodgementPointsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByApttusContractId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{contractId}),
			(Set<object>)fflib_Match.eq(new Set<object>{
				APT_AgreementLodgementPointsSelector.Options.WITH_BILLING_ACCOUNT,
				APT_AgreementLodgementPointsSelector.Options.WITH_CHARGE_ACCOUNT_REQ,
				APT_AgreementLodgementPointsSelector.Options.WITH_SUB_ACCOUNT_REQ
			}))).thenReturn(new Map<Id,APT_Agreement_Lodgement_Point__c>(new List<APT_Agreement_Lodgement_Point__c>{alpRec}));
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<APT_Agreement_Lodgement_Point__c> alpList = APT_LinkingBillAccToContractController.retrieveAgreementLodgementPoints(contractId);
		Test.stopTest();

		System.assertEquals(alpList[0].Id, alpRec.Id, 'Expected agreement lodgement point Id does not match');
	}

	/**
	 * Test: when the method retrieveProductsFromCLI() is called, 
	 *      validate that the method successfully queries the agreement line item based on contract Id
	 */
	@IsTest
	public static void testSuccessfulRetrievingCLIs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, acc.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		Apttus__APTS_Agreement__c contract = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.id, true)[0];
		String contractId = (String)contract.Id;
		Apttus__AgreementLineItem__c cliRec = APT_TestDataFactory.getAPTAgreementLineItem(1, true)[0];
		cliRec.Apttus_CMConfig__LineType__c = 'Product/Service';
		// =====================================
		// Stubbing
		// =====================================
		APT_AgreementLineItemsSelector mockSelector = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByContractIdsAndLineType(
			(Set<Id>)fflib_Match.eq(new Set<Id>{contractId}),
			(Set<String>)fflib_Match.eq(new Set<String>{'Product/Service'}),
			(Set<object>)fflib_Match.eq(new Set<object>{
				APT_AgreementLineItemsSelector.Options.WITH_CONTRACT, 
				APT_AgreementLineItemsSelector.Options.WITH_PROPOSAL
			}))).thenReturn(new List<Apttus__AgreementLineItem__c>{cliRec});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<Apttus__AgreementLineItem__c> cliList = APT_LinkingBillAccToContractController.retrieveProductsFromCLI(contractId);
		Test.stopTest();

		System.assertEquals(cliList[0].Id, cliRec.Id, 'Expected agreement line item Id does not match');
	}

	/**
	 * Test: when the method retrieveChargeAccountRequests() is called, 
	 *      validate that the method successfully queries the charge account requests based on proposal Id
	 */
	@IsTest
	public static void testSuccessfulRetrievingChargeAccReqs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		String propId = (String)ApplicationTestDataFactory.getApttusProposals(1, con.Id, true)[0].Id;
		APT_Charge_Account__c carRec = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		carRec.APT_Quote_Proposal__c = propId;
		carRec.APT_Organisation__c = acc.id;
		// =====================================
		// Stubbing
		// =====================================
		ChargeAccountRequestSelector mockSelector = (ChargeAccountRequestSelector) MockUtility.mockSelector(ChargeAccountRequestSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByProposalId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{propId}),
			(Set<object>)fflib_Match.eq(new Set<object>{ChargeAccountRequestSelector.Options.WITH_ORGANISATION})
			)).thenReturn(new List<APT_Charge_Account__c>{carRec});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<APT_Charge_Account__c> carList = APT_LinkingBillAccToContractController.retrieveChargeAccountRequests(propId);
		Test.stopTest();

		System.assertEquals(carList[0].Id, carRec.Id, 'Expected charge account request Id does not match');
	}

	/**
	 * Test: when the method retrieveChargeAccountRequests() is called, 
	 *      validate that the method is failling to query the charge account requests based on proposal Id
	 */
	@IsTest
	public static void testFailingToRetrievingChargeAccReqs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		String propId = (String)ApplicationTestDataFactory.getApttusProposals(1, con.Id, true)[0].Id;
		APT_Charge_Account__c carRec = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		carRec.APT_Quote_Proposal__c = propId;
		carRec.APT_Organisation__c = acc.id;
		// =====================================
		// Stubbing
		// =====================================
		ChargeAccountRequestSelector mockSelector = (ChargeAccountRequestSelector) MockUtility.mockSelector(ChargeAccountRequestSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByProposalId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{propId}),
			(Set<object>)fflib_Match.eq(new Set<object>{ChargeAccountRequestSelector.Options.WITH_ORGANISATION})
			)).thenReturn(new Map<Id, APT_Charge_Account__c>(new List<APT_Charge_Account__c>{carRec})); // set incorrect return type
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try{
			List<APT_Charge_Account__c> carList = APT_LinkingBillAccToContractController.retrieveChargeAccountRequests(propId);
			System.assert(false, 'An exception is expected'); // incorrect return type to trigger exception
		}catch(Exception e){
			// expected
		}
		Test.stopTest();
	}


	/**
	 * Test: when the method retrieveSubAccountRequests() is called, 
	 *      validate that the method successfully queries the sub account requests based on proposal Id
	 */
	@IsTest
	public static void testSuccessfulRetrievingSubAccReqs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		String propId = (String)ApplicationTestDataFactory.getApttusProposals(1, con.Id, true)[0].Id;
		APT_Sub_Account__c sarRec = ApplicationTestDataFactory.getSubAccountRequest(1, 'Sub Test 1', true)[0];
		sarRec.APT_Quote_Proposal__c = propId;
		sarRec.APT_Organisation__c = acc.id;
		// =====================================
		// Stubbing
		// =====================================
		SubAccountRequestsSelector mockSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByProposalId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{propId}),
			(Set<object>)fflib_Match.eq(new Set<object>{SubAccountRequestsSelector.Options.WITH_ORGANISATION})
			)).thenReturn(new List<APT_Sub_Account__c>{sarRec});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<APT_Sub_Account__c> sarList = APT_LinkingBillAccToContractController.retrieveSubAccountRequests(propId);
		Test.stopTest();

		System.assertEquals(sarList[0].Id, sarRec.Id, 'Expected sub account request Id does not match');
	}

	/**
	 * Test: when the method retrieveSubAccountRequests() is called, 
	 *      validate that the method is failing to query the sub account requests based on proposal Id
	 */
	@IsTest
	public static void testFailingtoRetrievingSubAccReqs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		String propId = (String)ApplicationTestDataFactory.getApttusProposals(1, con.Id, true)[0].Id;
		APT_Sub_Account__c sarRec = ApplicationTestDataFactory.getSubAccountRequest(1, 'Sub Test 1', true)[0];
		sarRec.APT_Quote_Proposal__c = propId;
		sarRec.APT_Organisation__c = acc.id;
		// =====================================
		// Stubbing
		// =====================================
		SubAccountRequestsSelector mockSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByProposalId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{propId}),
			(Set<object>)fflib_Match.eq(new Set<object>{SubAccountRequestsSelector.Options.WITH_ORGANISATION})
			)).thenReturn(new Map<Id, APT_Sub_Account__c>(new List<APT_Sub_Account__c>{sarRec})); // set incorrect return type
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try{
			List<APT_Sub_Account__c> sarList = APT_LinkingBillAccToContractController.retrieveSubAccountRequests(propId);
			System.assert(false, 'An exception is expected'); // incorrect return type to trigger exception
		}catch(Exception e){
			// expected
		}
		Test.stopTest();
	}

	/**
	 * Test: when the method retrieveBillingAcc() is called, 
	 *      validate that the method successfully queries the billing accounts on organisation Id
	 */
	@IsTest
	public static void testSuccessfulRetrievingBillingAccs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		String accId = (String)acc.Id;
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'SAP ERP', true)[0];
		Billing_Account__c parentBARec = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id,'SAP ERP', true)[0];
		billAccRec.PAYER_ACCOUNT_ID__c = parentBARec.Id;
		billAccRec.Type__c = 'CUST';
		billAccRec.SAP_marked_for_deletion__c = false;
		// =====================================
		// Stubbing
		// =====================================
		BillingAccountsSelector mockSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByOrgId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{accId}),
			(Set<object>)fflib_Match.eq(new Set<object>{
				BillingAccountsSelector.Options.FILTER_ACTIVE,
				BillingAccountsSelector.Options.FILTER_CUST_TYPE,
				BillingAccountsSelector.Options.WITH_PAYER_ACCOUNT_ID
			}))).thenReturn(
			new Map<Id,Billing_Account__c>(new List<Billing_Account__c>{billAccRec}));
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<Billing_Account__c> baList = APT_LinkingBillAccToContractController.retrieveBillingAcc(accId);
		Test.stopTest();

		System.assertEquals(baList[0].Id, billAccRec.Id, 'Expected billing account Id does not match');
	}

	/**
	 * Test: when the method retrieveBillingAcc() is called, 
	 *      validate that the method is failing to query the billing accounts on organisation Id
	 */
	@IsTest
	public static void testFailingToRetrievingBillingAccs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		String accId = (String)acc.Id;
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'SAP ERP', true)[0];
		Billing_Account__c parentBARec = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id,'SAP ERP', true)[0];
		billAccRec.PAYER_ACCOUNT_ID__c = parentBARec.Id;
		billAccRec.Type__c = 'CUST';
		billAccRec.SAP_marked_for_deletion__c = false;
		// =====================================
		// Stubbing
		// =====================================
		BillingAccountsSelector mockSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByOrgId(
			(Set<Id>)fflib_Match.eq(new Set<Id>{acc.Id}),
			(Set<object>)fflib_Match.eq(new Set<object>{
			BillingAccountsSelector.Options.FILTER_ACTIVE // cause null-pointer exception by providing unmatched Set<object> param
		}))).thenReturn(
		new Map<Id,Billing_Account__c>(new List<Billing_Account__c>{billAccRec}));
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try{
			List<Billing_Account__c> baList = APT_LinkingBillAccToContractController.retrieveBillingAcc(accId);
			System.assert(false, 'An exception is expected');
		}catch(Exception e){
			//Expected
		}
		Test.stopTest();
	}

	/**
	 * Test: when the method insertAgreementLodgementPoints() is called, 
	 *      validate that the method successfully insert the agreement lodgment points with appropriate field mapping
	 */
	@IsTest
	public static void testSuccessfulInsertAgreementLPs(){
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		String orgId = (String)acc.Id;
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, acc.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, con.Id, true)[0];
		string prop=string.valueOf(apttusProposals.id);

		Product2 prod = ApplicationTestDataFactory.getPSRProducts(1, true)[0];
		prod.Name='Australia Post Parcel Contract';
		prod.ProductCode='APPC';
		prod.Family='APPC';
		prod.APT_Apttus_Product_Classification__c='APPC';
		prod.IsActive=true;
		prod.Apttus_Config2__ConfigurationType__c='Bundle';

		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, true)[0];
		prodConfig.Apttus_QPConfig__Proposald__c =apttusProposals.id;
		prodConfig.Apttus_Config2__Status__c ='Finalized';
		prodConfig = (Apttus_Config2__ProductConfiguration__c)ApplicationTestDataFactory.setUnwritableFields(prodConfig,new Map<String, Object>{
			'APT_APPC_Count_in_Cart__c' => 1
		});

		APT_Lodgement_Zone__c lodgementZone= APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
		lodgementZone.APT_Zone_Structure__c ='APPC';
		lodgementZone.APT_Postcode__c='3000';
		lodgementZone.Name='Capital';

		Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];  
		lineItem.Apttus_Config2__LineType__c = 'Product/Service'; 
		lineItem.Apttus_Config2__ProductId__c= prod.id;
		lineItem.Apttus_Config2__Description__c='Australia Post Parcel Contract';
		lineItem.Apttus_Config2__ConfigurationId__c=prodConfig.id;

		Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
		pav.APT_Lodgement_Zone__c = lodgementZone.Id;             
		pav.APT_Customer_Tier__c = 'T04';
		pav.Apttus_Config2__LineItemId__c=lineItem.id;        
		pav.APT_Additional_Lodgement_Zone_1__c= 'Capital';
		pav.APT_Additional_Lodgement_Zone_2__c= 'Metro';
		lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
		lineItem = (Apttus_Config2__LineItem__c)ApplicationTestDataFactory.setUnwritableFields(lineItem,new Map<String, Object>{
					'Apttus_Config2__AttributeValueId__r' => pav
				});
		   
		List<CreateSubAccountsController.SObjectResult> lodgementWrapperList = new List<CreateSubAccountsController.SObjectResult>();
		CreateSubAccountsController.SObjectResult lPWrapper = new CreateSubAccountsController.SObjectResult('St Kilda','297832','','a2K0p000001NqVE','3000');
		lodgementWrapperList.add(lPWrapper);
		String lodgementWrapperJSON = System.JSON.serialize(lodgementWrapperList);

		Apttus__APTS_Agreement__c contract = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.id, true)[0];
		String contractId = (String)contract.Id;

		Billing_Account__c billAccRec = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'SAP ERP', true)[0];
		APT_Charge_Account__c carRec = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		APT_Sub_Account__c sarRec = ApplicationTestDataFactory.getSubAccountRequest(1, 'Sub Test 1', true)[0];

		String prodName = 'Apttus Test Product';
		// Build wrapper list for billing account, charge account req, sub account req
		List<APT_LinkingBillAccToContractController.LinkingAccountWrapper> wrappList = new List<APT_LinkingBillAccToContractController.LinkingAccountWrapper>();

		APT_LinkingBillAccToContractController.LinkingAccountWrapper wrapperBA = new APT_LinkingBillAccToContractController.LinkingAccountWrapper();
		wrapperBA.id = (String)billAccRec.Id;
		wrapperBA.objType = 'APT_Billing_Account__c';
		wrapperBA.proposalId =prop;

		APT_LinkingBillAccToContractController.LinkingAccountWrapper wrapperCAR = new APT_LinkingBillAccToContractController.LinkingAccountWrapper();
		wrapperCAR.id = (String)carRec.Id;
		wrapperCAR.objType = 'APT_Charge_Account__c';
		wrapperCAR.proposalId =prop;

		APT_LinkingBillAccToContractController.LinkingAccountWrapper wrapperSAR = new APT_LinkingBillAccToContractController.LinkingAccountWrapper();
		wrapperSAR.id = (String)sarRec.Id;
		wrapperSAR.objType = 'APT_Sub_Account__c';
		wrapperSAR.proposalId = prop;

		wrappList.add(wrapperBA);
		wrappList.add(wrapperCAR);
		wrappList.add(wrapperSAR);

		// =====================================
		// Stubbing
		// =====================================
		List<APT_Agreement_Lodgement_Point__c> alpList = new List<APT_Agreement_Lodgement_Point__c>();
		ProductConfigurationSelector prodConfigSelector = (ProductConfigurationSelector)MockUtility.mockSelector(ProductConfigurationSelector.class);
		APT_LodgementZonesSelector lpZoneSelector = (APT_LodgementZonesSelector) MockUtility.mockSelector(APT_LodgementZonesSelector.class);
		LineItemsSelector lineItemSelector = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(prodConfigSelector.selectByProposalId((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}); 
		MockUtility.Mocks.when(lpZoneSelector.selectByZoneStructure(
			(Set<String>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject())).thenReturn(new List<APT_Lodgement_Zone__c>{lodgementZone}); 
		MockUtility.Mocks.when(lineItemSelector.selectByProdConfigAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject()
			)).thenReturn(new List<Apttus_Config2__LineItem__c>{lineItem});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		String successMsg = APT_LinkingBillAccToContractController.insertAgreementLodgementPoints(wrappList,contractId,orgId,prodName,prop,lodgementWrapperJSON);
		Test.stopTest();
		// validate the success message
		System.assertEquals(successMsg, APT_Constants.SUCCESS_LABEL, 'Link Billing Acc to Contract is not successful');
		fflib_ArgumentCaptor insertedAgreementLP = fflib_ArgumentCaptor.forClass(List<APT_Agreement_Lodgement_Point__c>.class);
		// verify dml insert has been made 1 times
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<APT_Agreement_Lodgement_Point__c>)insertedAgreementLP.capture());
		// verify that Billing Account, Charge account and sub account request lookup are populated on agreement lodgment point after DML insert
		for(APT_Agreement_Lodgement_Point__c alp: (List<APT_Agreement_Lodgement_Point__c>) insertedAgreementLP.getValue()){
			if(alp.APT_Billing_Account__c != null){
				System.assertEquals(billAccRec.Id, alp.APT_Billing_Account__c, 'Billing Account does not match or is empty');
			}else if(alp.APT_Charge_Account__c != null){
				System.assertEquals(carRec.Id, alp.APT_Charge_Account__c, 'Charge Account does not match or is empty');
			}else if(alp.APT_Sub_Account__c != null){
				System.assertEquals(sarRec.Id, alp.APT_Sub_Account__c, 'Sub Account does not match or is empty');
			}
		}
	}
}