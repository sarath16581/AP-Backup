/**
 * @author Harry Wang
 * @date 2024-07-22
 * @tag CSP
 * @description Test class for ABNChangeDSRGenerator
 * @changelog
 * 2024-07-22 - Harry Wang - Created
 */
@IsTest
public with sharing class ABNChangeDSRGenerator_Test {
	/**
	 * Test:
	 *  Ensures that the DSR are created without issues
	 */
	@IsTest
	private static void testDSRGeneration() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accs = ApplicationTestDataFactory.getAccounts(1, true);
		List<Billing_Account__c> bas = ApplicationTestDataFactory.getBillingAccounts(6, accs[0].Id, 'SAP ERP', false);
		List<Opportunity> opps = ApplicationTestDataFactory.getOpportunities(1, accs[0].Id, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accs[0].Id, true);
		List<At_Risk_Business__c> atRiskBusinesses = ApplicationTestDataFactory.getAtRiskBusiness(1, accs[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		ABNChangeDSRGenerator.allProductTypes = new List<String>{'StarTrack', 'AP'};
		Deal_Support_Request__c dsr = new ABNChangeDSRGenerator.ProposalContractDSR(true, accs[0].Id, opps[0].Id, 'ABN Change - Same Owners', 'AP', contacts[0].Id, atRiskBusinesses[0].Id, 'Yes', null).toDsrRecord();
		System.assertEquals('New Proposal', dsr.Work_Type__c, 'Expected proposal work type');

		dsr = new ABNChangeDSRGenerator.ProposalContractDSR(false, accs[0].Id, opps[0].Id, 'ABN Change - Same Owners', 'ST', contacts[0].Id, atRiskBusinesses[0].Id, 'No', new List<String>{'One, Two'}).toDsrRecord();
		System.assertEquals('New Agreement', dsr.Work_Type__c, 'Expected agreement work type');
		System.assert(dsr.Description__c.contains('One, Two'), 'Expected pricing names');

		dsr = new ABNChangeDSRGenerator.TerminateDSR(accs[0].Id, 'ABN Change - Same Owners', 'AP', atRiskBusinesses[0].Id, '88888888').toDsrRecord();
		System.assertEquals('Termination of all AP Contract(s) - ABN Change', dsr.Work_Type__c, 'Expected AP termination work type');

		dsr = new ABNChangeDSRGenerator.TerminateSTBAs(accs[0].Id, atRiskBusinesses[0].Id, opps[0].Id, '88888888', 'ABN Change - Same Owners').toDsrRecord();
		System.assertEquals('Close all ST Billing Account(s) - ABN Change', dsr.Work_Type__c, 'Expected close ST BA work type');

		dsr = new ABNChangeDSRGenerator.CloseAllBAs(accs[0].Id, atRiskBusinesses[0].Id, 'ABN Change - Same Owners', bas, System.today() + 1).toDsrRecord();
		System.assertEquals('Close All Billing Accounts - ABN Change', dsr.Credit_Work_Type__c, 'Expected close all BA credit work type');

		ContentVersion cv = new ABNChangeDSRGenerator.CloseAllBAs(accs[0].Id, atRiskBusinesses[0].Id, 'ABN Change - Same Owners', bas, System.today() + 1).generateCloseAllBACsv();
		System.assertEquals('close_all_ba.csv', cv.PathOnClient);
		System.assertEquals('close_all_ba', cv.Title);
	}
}