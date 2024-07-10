/**
* @description Impacted Articles Selector Test class
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
**/
@isTest
private class ImpactedArticlesSelector_Test {
    
    /**
* Test:
*  Ensures that the selectors QueryBuilder is generating the correct output
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
        
        ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        
        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select from ImpactedArticle__c: ' + soql);
        
        Test.stopTest();
        
    }
    
    /**
* Executes a query to ensure it returns expected results with actual inserted data
*/
    @IsTest
    private static void testSelectorIntegration() {
        
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        
        Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];        
        INSERT consignment;
       
        
        Article__c article = ApplicationTestDataFactory.getArticles(2, consignment.Id, false)[0];
        INSERT article;
        
        Case caserec = ApplicationTestDataFactory.getCases(1, false)[0];
        INSERT caserec;
        
        List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, caserec.Id, article.Id,false);
        INSERT impactedArticles;
        
        System.debug('impactedArticles ==>' + impactedArticles);
        
        // =====================================
        // Stubbing
        // =====================================
        // None!
        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();
        List<ImpactedArticle__c> results  = selector.selectByCaseId(new Set<Id>{caserec.Id}, new Set<Object>());
        System.assertEquals(1, results.size(), 'Expected result size of 1');           
        Test.stopTest();      
        
    }
    
}