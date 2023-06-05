/**
 * @description			: This is a test class for the CaseInvestigationTrigger
 * @author				: George Nguyen
 * @domain				: Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2023-05-22 - Mahesh Parvathaneni - SF-961 - Added filter for the network lookup field
**/
@IsTest
class CaseInvestigationTrigger_Test {
	
	@IsTest
	static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
		CaseInvestigationDomainTriggerHandler mock = (CaseInvestigationDomainTriggerHandler)MockUtility.mockUtility(CaseInvestigationDomainTriggerHandler.class);

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Contact_Facility__c = 'MyNetwork';
		networks[0].Org_ID__c = '1234';
		networks[0].Status__c = 'NULL';
		networks[0].Parcel__c = true;
		insert networks;

		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		insert cases;

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		insert caseInvestigations;


		((CaseInvestigationDomainTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();

		// PMD Warning
		System.assert(true);
	}
}