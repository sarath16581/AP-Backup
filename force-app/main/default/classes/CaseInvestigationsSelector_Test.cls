/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering CaseInvestigationsSelector
 */

@IsTest
public with sharing class CaseInvestigationsSelector_Test {
    
    /**
     * Test:
     * Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString() {

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
        Test.startTest();

        CaseInvestigationsSelector selector = CaseInvestigationsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom CaseInvestigation__c\\b').matcher(soql).find(), 'Resulting query does not select from CaseInvestigation__c');

        Test.stopTest();

    }

    /**
     * Test:
     * Executes a query to ensure it returns expected results
     */
    @IsTest
    private static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        //create test data
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
        insert articles;

        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
        cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		insert cases;

        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';
		insert networks;

        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0].Id, networks[0].Id, false);
        caseInvestigations[0].Status__c = 'Open';
        insert caseInvestigations;
        
        // =====================================
        // Stubbing
        // =====================================
        PUDBookingsSelector mockBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CaseInvestigationsSelector selector = CaseInvestigationsSelector.newInstance();
		Map<Id, CaseInvestigation__c> results = selector.selectById(new Set<Id> {caseInvestigations[0].Id});
		System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

        CaseInvestigationsSelector selectorLimit = CaseInvestigationsSelector.newInstance(1);
		Map<Id, CaseInvestigation__c> resultsLimit = selector.selectById(new Set<Id> {caseInvestigations[0].Id});
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

        CaseInvestigationsSelector selectorOpenCaseInvestion = CaseInvestigationsSelector.newInstance();
		Map<Id, CaseInvestigation__c> resultsOpenCaseInvestion = selectorOpenCaseInvestion.selectOpenCaseInvestigationsByCaseArticleNetworkId(new Set<Id> {cases[0].Id}, new Set<Id> {articles[0].Id}, new Set<Id> {networks[0].Id});
		System.assertEquals(1, resultsOpenCaseInvestion.size(), 'Expected result size of 1');

        Test.stopTest();

    }
}
