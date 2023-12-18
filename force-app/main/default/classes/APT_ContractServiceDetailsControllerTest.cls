/**
* @author Yatika bansal
* @date 2023-25-04
* @group Tests
* @tag ApexController
* @domain Apttus
* @description A test class for APT_ContractServiceDetailsController
*Modifications Log
 *1.0 : 07-06-2023 : Yatika bansal : Added test method for createAmendContract method, made some changes to increase coverage
* 27-07-2023 : Yatika bansal : Added test method for createRenewalContract method
* 08-04-2023 : Yatika bansal : Added test method for updateAlis method
 */
@IsTest
public class APT_ContractServiceDetailsControllerTest {
	
	
	 /**
	*Test: when the method createContractRecord is called, validate that the method successfully finalizes the config
	*/
	@IsTest
	public static void createContractRecordTest() { 
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account = (Account)ApplicationTestDataFactory.setUnwritableFields(account, 
				new Map<String, Object>{
					'Role_Type_Roll_Up__c' => 'Prospect'
				});
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c agg = ApplicationTestDataFactory.getApttusContracts(1, con.id, opp.id, true)[0];
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
		APT_Credit_Assessment__c cred = APT_TestDataFactory.getApttusCreditAssessment(1, quote.id, true)[0];
		
		APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProposal.selectByConfigId((set<Id>)fflib_Match.eq(new Set<Id>{quote.id}),
								(set<Object>)fflib_Match.eq(new Set<Object> {APT_ProposalObjectsSelector.Options.WITH_ACCOUNT}))).thenReturn(
			new Map<Id, Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote}));
		MockUtility.Mocks.stopStubbing(); 
		
		APT_CreditAssessmentSelector mockSelector1 = (APT_CreditAssessmentSelector) MockUtility.mockSelector(APT_CreditAssessmentSelector.class);
		ApplicationDatabase mockDatabase1 = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector1.selectByProposalAndAssessStatus((set<Id>)fflib_Match.eq(new Set<Id>{(ID)quote.Id}),
										(set<String>)fflib_Match.eq(new Set<String> {APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED, APT_Constants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED}))).thenReturn(
			new List<APT_Credit_Assessment__c>(new List<APT_Credit_Assessment__c>{cred}));
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseAgreement = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseAgreement.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		APT_ContractServiceDetailsController.createContractRecord(quote.Id);
			
		Test.startTest();
			String output = APT_ContractServiceDetailsController.createContract(quote);
		Test.stoptest();
		System.assert(output.contains('a7G'), 'Contract Record should be created');
	}
	
	/**
	*Test: when the method updateCollectionAddress is called, validate that the method returns error
	*/
	@IsTest
	public static void updateCollectionAddressTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
		
		APT_ContractServiceDetailsController.getCurrentAddress(apttusContracts.id);
		Test.startTest();
			String output = APT_ContractServiceDetailsController.updateCollectionAddress(apttusContracts.id, 'Test');
		Test.stoptest();
		
		System.assert(output.contains(APT_Constants.ERROR_PREFIX));
	}
	
	/**
	*Test: when the method updateCollectionAddress is called, validate that the method successfully works
	*/
	@IsTest
	public static void updateCollectionAddressTest_Pos() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
		APT_Operational_Schedule__c os = APT_TestDataFactory.getOperationalSchedule(1, apttusContracts.Id, true)[0];
		
		APT_OperationalScheduleSelector mockSelectorOS = (APT_OperationalScheduleSelector) MockUtility.mockSelector(APT_OperationalScheduleSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOS.selectByContractId((set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.id}))).thenReturn(
			new List<APT_Operational_Schedule__c>(new List<APT_Operational_Schedule__c>{os}));
		MockUtility.Mocks.stopStubbing(); 
		
		APT_ContractServiceDetailsController.getCurrentAddress(apttusContracts.id);
		Test.startTest();
			String output = APT_ContractServiceDetailsController.updateCollectionAddress(apttusContracts.id, 'Test');
		Test.stoptest();
		
		System.assert(output.contains(APT_Constants.ERROR_PREFIX));
	}
	
	 
	/**
	*Test: when the method getServiceDetail is called with no option alis validate that the method returns empty list
	*/
	@IsTest
	public static void getServiceDetailTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
		
		Test.startTest();
			List<APT_ContractServiceDetailsController.ServiceDetailRecord> recs = APT_ContractServiceDetailsController.getServiceDetail(apttusContracts.id);
		Test.stoptest();
		
		System.assert(recs.size() == 0, 'Output returned should be correct');
	}
							
	/**
	*Test: when the method createContractRecord is called, validate that the method successfully creates amend contract
 	* Inserting records was needed to cover Apttus.AgreementWebService.amendAgreement() Conga API during the execution flow
	*/
	@IsTest
	public static void createAmendContractTest() { 
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert con;
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		insert opp;
		Apttus__APTS_Agreement__c agg = ApplicationTestDataFactory.getApttusContracts(1, con.id, opp.id, false)[0];
		insert agg;
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, false)[0];
		Apttus__APTS_Agreement__c agg1 = [select Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Id =:agg.id limit 1];
		quote.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
		quote.APT_Contract_Number__c = agg1.Apttus__FF_Agreement_Number__c;
		insert quote;
			
		Test.startTest();
			String output = APT_ContractServiceDetailsController.createContractRecord(quote.Id);
		Test.stoptest();
		System.assert(output.contains('a7G'), 'Contract Record should be created');
	}

	/**
	*Test: when the method createContractRecord is called, validate that the method successfully creates Renewal contract
 	* Inserting records was needed to cover Apttus.AgreementWebService.renewAgreement() Conga API during the execution flow
	*/
	@IsTest
	public static void createRenewalContractTest() { 
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert con;
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		insert opp;
		Apttus__APTS_Agreement__c agg = ApplicationTestDataFactory.getApttusContracts(1, con.id, opp.id, false)[0];
		insert agg;
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, false)[0];
		Apttus__APTS_Agreement__c agg1 = [select Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Id =:agg.id limit 1];
		quote.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE).getRecordTypeId();
		quote.APT_Contract_Number__c = agg1.Apttus__FF_Agreement_Number__c;
		insert quote;
			
		Test.startTest();
			String output = APT_ContractServiceDetailsController.createContractRecord(quote.Id);
		Test.stoptest();
		System.assert(output.contains('a7G'), 'Contract Record should be created');
	}    
    
    /**
	*Test: when the method updateAlis is called method runs successfully
	*/
	@IsTest
	public static void updateAlisTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
        Apttus__AgreementLineItem__c ali = APT_TestDataFactory.getAPTAgreementLineItem(1, true)[0];
        ali.Apttus_CMConfig__ChargeType__c = APT_Constants.CHARGE_TYPE_STANDARD_PRICE;
            
        APT_AgreementLineItemsSelector mockSelectorOS = (APT_AgreementLineItemsSelector) MockUtility.mockSelector(APT_AgreementLineItemsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOS.selectByContractIdsAndLineType((set<Id>)fflib_Match.eq(new Set<Id>{apttusContracts.id}),
                                                                            (set<String>)fflib_Match.eq(new Set<String>{APT_Constants.PARAM_PRODUCT_Type, APT_Constants.PARAM_PRODUCT_Type_Misc}),
                                                                            (set<Object>)fflib_Match.eq(new Set<Object>{APT_AgreementLineItemsSelector.Options.WITH_PRODUCT}))).thenReturn(
			new List<Apttus__AgreementLineItem__c>(new List<Apttus__AgreementLineItem__c>{ali}));
		MockUtility.Mocks.stopStubbing(); 
		
		Test.startTest();
        String output = APT_ContractServiceDetailsController.updateAlis(apttusContracts.id, new List<Id>{ali.Id});
		Test.stoptest();
		
		System.assert(output.contains(APT_Constants.SUCCESS_LABEL_SMALL), 'Output returned should be correct');
	}
}