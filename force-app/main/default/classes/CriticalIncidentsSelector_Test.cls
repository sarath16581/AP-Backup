/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering CriticalIncidentsSelector
 */

@isTest
public with sharing class CriticalIncidentsSelector_Test {
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

        CriticalIncidentsSelector selector = CriticalIncidentsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Critical_Incident__kav\\b').matcher(soql).find(), 'Resulting query does not select from Critical_Incident__kav');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Critical_Incident__kav.KnowledgeArticleId) + '\\b').matcher(soql).find(), 'KnowledgeArticleId field does not exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Critical_Incident__kav.URLName) + '\\b').matcher(soql).find(), 'URLName field does not exists in query');

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

		List<Critical_Incident__kav> kavs = ApplicationTestDataFactory.getCriticalIncidents(1, false);
		insert kavs;

        //retrieve master article Id created on Critical_Incident__kav record insertion
		//in order to get the KnowledgeArticleId
		Critical_Incident__kav kav = [SELECT KnowledgeArticleId FROM Critical_Incident__kav WHERE Id = :kavs[0].Id];

		//publish it
		KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
        
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CriticalIncidentsSelector selector = CriticalIncidentsSelector.newInstance();
		Map<Id, Critical_Incident__kav> results = selector.selectCriticalIncidentsByPublishStatus('Online');
		System.assert(results.size() >= 1, 'Expected result size of more than 1');

        CriticalIncidentsSelector selectorLimit = CriticalIncidentsSelector.newInstance(1);
		Map<Id, Critical_Incident__kav> resultsLimit = selectorLimit.selectCriticalIncidentsByPublishStatus('Online');
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

        Test.stopTest();

    }
}