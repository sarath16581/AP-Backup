/**
* @description Case Hand-off Mapping custom Metadata Test class
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
**/
@IsTest
private class CaseHandoffMappingSelector_Test {
    
    /**
* Test:
*  Ensures that the selectors QueryBuilder is generating the correct output
*/
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {
        
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
        
        CaseHandoffMappingSelector selector = CaseHandoffMappingSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        
        Assert.areEqual(true, Pattern.compile('(?ism)\\bfrom CaseHandoffMapping__mdt\\b').matcher(soql).find(), 'Resulting query does not select from CaseHandoffMapping__mdt');
        
       
        Test.stopTest();
        
    }
    
    /**
* Executes a query to ensure it returns expected results with actual data
*/
    @IsTest
    public static void testSelectorIntegration() {
        
        // =====================================
        // Data Preparation
        // =====================================
        CaseHandoffMapping__mdt mapping = [SELECT 	BusinessUnit__c, UnifiedRecordTypeDeveloperName__c FROM CaseHandoffMapping__mdt LIMIT 1];
        String businessUnit = mapping.BusinessUnit__c;
        String unifiedRecordType = mapping.UnifiedRecordTypeDeveloperName__c;
        
        // =====================================
        // Stubbing
        // =====================================
        // None!
        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        CaseHandoffMappingSelector selector = CaseHandoffMappingSelector.newInstance();		      
        List<CaseHandoffMapping__mdt> results = selector.selectByBusinesssUnitRecordType(new Set<String>{businessUnit}, new Set<String>{unifiedRecordType}, new Set<Object>());
        Assert.areEqual(1, results.size(), 'Result count was wrong');
        
        Test.stopTest();
        
    }
    
    
}