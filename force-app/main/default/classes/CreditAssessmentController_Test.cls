/**
 * @author Harry Wang
 * @date 2023-02-08
 * @group Tests
 * @tag Controller
 * @tag CSP
 * @domain CSP
 * @description Test class for CreditAssessmentController
 * @changelog
 * 2023-02-08 - Harry Wang - Created
 */
@IsTest
private class CreditAssessmentController_Test {
	@IsTest
	public static void testGetOpportunityCreditAssessment() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(ApplicationTestDataFactory.getOpportunities(1, account.Id, true));

		List<Apttus_Proposal__Proposal__c> proposalList = ApplicationTestDataFactory.getApttusProposals(1, account.Id, true);
		proposalList[0].Apttus_Proposal__Opportunity__c = opportunityMap.values()[0].Id;

		Map<Id, APT_Credit_Assessment__c> caMap = new Map<Id, APT_Credit_Assessment__c>(ApplicationTestDataFactory.getApttusCreditsAssessment(1, account.Id, true));
		caMap.values()[0].APT_Proposal__c = proposalList[0].Id;

		// =====================================
		// Stubbing
		// =====================================
		OpportunitySelector oppSelector = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector) MockUtility.mockSelector(CreditsAssessmentSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(oppSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(opportunityMap);
		MockUtility.Mocks.when(caSelector.selectByOpportunityIds((Set<Id>) fflib_Match.anyObject())).thenReturn(caMap);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CreditAssessmentController.CreditAssessmentResultWrapper result = CreditAssessmentController.getOpportunityCreditAssessment(opportunityMap.values()[0].Id);
		System.assert(result.opportunity != null && !result.creditAssessments.isEmpty(), 'Non-empty results');

		Test.stopTest();
	}

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
}