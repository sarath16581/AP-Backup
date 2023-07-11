/**
*@author Yatika bansal
*@date 2023-25-04
*@group Tests
*@tag ApexController
*@domain Apttus
*@description A test class for APT_ContractServiceDetailsController
*/
@IsTest
public class APT_ContractServiceDetailsControllerTest {

	/**
	*Test: when the method createContractRecord is called, validate that the method successfully finalizes the config
	*/
	@IsTest
	public static void createContractRecordTest() {
		//Inserted Records as AgreementTrigger updates related opp and it was erroring out otherwise
		User u = ApplicationTestDataFactory.getUsers(1, true)[0];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		APT_TestDataFactory.getOrganisationRole(1, account.Id, true);
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
		quote.OwnerId = u.Id;
		APT_Credit_Assessment__c credAssess = APT_TestDataFactory.getApttusCreditAssessment(1, quote.id, true)[0];

		APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProposal.selectByConfigId((set<Id>)fflib_Match.eq(new Set<Id>{quote.id}),
								  (set<Object>)fflib_Match.eq(new Set<Object> {APT_ProposalObjectsSelector.Options.WITH_ACCOUNT}))).thenReturn(
			new Map<Id, Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote}));
		MockUtility.Mocks.stopStubbing();

		APT_CreditAssessmentSelector mockSelectorCA = (APT_CreditAssessmentSelector) MockUtility.mockSelector(APT_CreditAssessmentSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorCA.selectByProposalAndAssessStatus((set<Id>)fflib_Match.eq(new Set<Id>{quote.id}),
								  (set<String>)fflib_Match.eq(new Set<String>{APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED, APT_Constants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED}))).thenReturn(
			new List<APT_Credit_Assessment__c>(new List<APT_Credit_Assessment__c>{credAssess}));
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
	*Test: when the method updateCollectionAddress is called, validate that the method successfully works
	*/
	@IsTest
	public static void updateCollectionAddressTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		//Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
		//APT_Operational_Schedule__c os = APT_TestDataFactory.getOperationalSchedule(1, apttusContracts.Id, true)[0];
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
		//Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
		//Apttus__AgreementLineItem__c ali = APT_TestDataFactory.getAPTAgreementLineItem(1, true)[0];

		Test.startTest();
			List<Id> ids = APT_ContractServiceDetailsController.getServiceDetail(apttusContracts.id);
		Test.stoptest();

		System.assert(ids.size() == 0, 'Output returned should be correct');
	}
}