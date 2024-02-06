/**************************************************
Type:         Provides test converage  for OpportunityProductRevForecastSelector
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
**************************************************/
@IsTest
public with sharing class OppProductRevForecastSelector_Test {

    /**
     * Test:
     * Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString() {

        // Testing
        Test.startTest();

        OpportunityProductRevForecastSelector selector = OpportunityProductRevForecastSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom OpportunityProductRevenueForecast__c\\b').matcher(soql).find(), 'Resulting query does not select from OpportunityProductRevenueForecast__c');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(OpportunityProductRevenueForecast__c.Rev1__c) + '\\b').matcher(soql).find(), 'Rev1__c field does not exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(OpportunityProductRevenueForecast__c.OpportunityProduct__c) + '\\b').matcher(soql).find(), 'OpportunityProduct__c field does not exists in query');

        Test.stopTest();

    }

    /**
     * Test:
     * Executes a query to ensure it returns expected results
     */
    @IsTest
    private static void testSelectorIntegration() {

        // Data Preparation
        // MockUtility.disableTriggerExecution(); // Uncomment if you have this utility

        // Create test data
        
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;
        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert oppRec;
            
        //Create product
        Product2 prod1 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod1;
                
        //Create your pricebook entry
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntry1 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry1;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry1.Id,
                TotalPrice = 5 * pbEntry1.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli1;
        

        List<OpportunityProductRevenueForecast__c> opRevForecastRecs = ApplicationTestDataFactory.getOpportunityProductRevenueForecasts(1, oli1.id, false);
        insert opRevForecastRecs;

        // Testing
        Test.startTest();

        OpportunityProductRevForecastSelector selector = OpportunityProductRevForecastSelector.newInstance();
        Map<Id, OpportunityProductRevenueForecast__c> results = selector.selectById(new Set<Id> {opRevForecastRecs[0].Id});
        System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

        OpportunityProductRevForecastSelector selectorLimit = OpportunityProductRevForecastSelector.newInstance(1);
        Map<Id, OpportunityProductRevenueForecast__c> resultsLimit = selectorLimit.selectById(new Set<Id> {opRevForecastRecs[0].Id});
        System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

        Test.stopTest();

    }
}