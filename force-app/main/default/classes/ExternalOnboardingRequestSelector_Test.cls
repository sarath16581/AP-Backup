/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag External Object SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-05-12 - Shashwat.Nath@auspost.com.au - Created
*/
@IsTest
public with sharing class ExternalOnboardingRequestSelector_Test{
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

        ExternalOnboardingRequestSelector selector = ExternalOnboardingRequestSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom BAMExternalOnboardingRequest__c\\b').matcher(soql).find(), 'Resulting query does not select from External Onboarding Object');

        Test.stopTest();

    }

    
    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,null, null, false)[0];
        insert externalOnboardingRecord; 
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        ExternalOnboardingRequestSelector selector = ExternalOnboardingRequestSelector.newInstance(1);
        Map<Id, BAMExternalOnboardingRequest__c > results = selector.selectById(new Set<Id>{externalOnboardingRecord.id});
        System.assertEquals(1, results.size(), 'Result count was wrong');

        Test.stopTest();

    }
    
      /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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
        ExternalOnboardingRequestSelector selector1 = ExternalOnboardingRequestSelector.newInstance(0, new Set<SObjectField>{BAMExternalOnboardingRequest__c.Response_Payload__c});

        ExternalOnboardingRequestSelector   selector = ExternalOnboardingRequestSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                BAMExternalOnboardingRequest__c.SObjectType => new Set<SObjectField>{BAMExternalOnboardingRequest__c.Response_Payload__c}
        });
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Response_Payload__c.*?\\bfrom BAMExternalOnboardingRequest__c\\b').matcher(soql).find(), 'Resulting query does not select payload field: ' + soql);

        Test.stopTest();

    }
}