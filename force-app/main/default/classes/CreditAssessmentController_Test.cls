/**
 * @author Harry Wang
 * @date 2023-02-08
 * @group Tests
 * @tag Controller
 * @tag CSP
 * @domain CreditAssessment
 * @description Test class for CreditAssessmentController
 * @changelog
 * 2023-02-08 - Harry Wang - Created
 */
@IsTest
private class CreditAssessmentController_Test {
	/**
	* Test:
	*  Ensures that the opportunity and credit assessment are retrieved correctly
	*/
	@IsTest
	public static void testGetOpportunityCreditAssessment() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(ApplicationTestDataFactory.getOpportunities(1, account.Id, true));

		List<Apttus_Proposal__Proposal__c> proposalList = ApplicationTestDataFactory.getApttusProposals(2, account.Id, true);
		proposalList[0].Apttus_Proposal__Opportunity__c = opportunityMap.values()[0].Id;

		List<APT_Credit_Assessment__c> caList = ApplicationTestDataFactory.getApttusCreditsAssessment(1, account.Id, true);
		caList[0].APT_Proposal__c = proposalList[0].Id;

		List<APT_Charge_Account__c> chargeAccounts = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true);

		// =====================================
		// Stubbing
		// =====================================
		OpportunitySelector oppSelector = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector) MockUtility.mockSelector(CreditsAssessmentSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(oppSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(opportunityMap);
		MockUtility.Mocks.when(caSelector.selectByProposalOpportunity((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(caList);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CreditAssessmentController.CreditAssessmentResultWrapper result = CreditAssessmentController.getOpportunityCreditAssessment(opportunityMap.values()[0].Id);

		List<SObject> caDetails = new List<SObject>{proposalList[0], proposalList[1], caList[0], chargeAccounts[0]};

		try {
			CreditAssessmentController.updateCreditAssessmentDetails(caDetails);
			System.assert(false, 'Expected an exception to be thrown - but was not thrown.');
		} catch (Exception ex) {
			//expected
		}

		System.assert(result.opportunity != null && !result.creditAssessments.isEmpty(), 'Non-empty results');

		Test.stopTest();
	}

	/**
	* Test:
	*  Ensures that the datatable columns are retrieved correctly
	*/
	@IsTest
	public static void testRetrieveOpportunityCreditAssessment() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<CreditAssessmentController.DataTableColumn> columns = CreditAssessmentController.retrieveDatatableColumns();
		System.assert(!columns.isEmpty(), 'Non-empty results');
	}

	private class MockException extends Exception {}
}