/**
* @author avula.jansirani@auspost.com.au
* @date 2021-05-18
* @group Tests
* @tag Selector
* @tag Credit_Assessment_Network__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-05-18 - avula.jansirani@auspost.com.au - Created
*/
@IsTest
public class CreditsAssessmentNetworkSelector_Test {
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

        CreditsAssessmentNetworkSelector selector = CreditsAssessmentNetworkSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Credit_Assessment_Network__c\\b').matcher(soql).find(), 'Resulting query does not select from Credit_Assessment_Network__c');

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

        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, false);
        insert accountList;
        
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false)[0];
        insert chargeAccountRequest;
        
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, false)[0];
        insert apttusCreditAssessment ; 
        
        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
        insert networkFacility;
        
        Credit_Assessment_Network__c can = new Credit_Assessment_Network__c(Network__c=networkFacility.Id, Credit_Assessment__c=apttusCreditAssessment.Id);
        insert can;
        
         // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        CreditsAssessmentNetworkSelector selector = CreditsAssessmentNetworkSelector.newInstance();
        Map<Id, Credit_Assessment_Network__c> results = selector.selectById(new Set<Id>{can.Id});
        System.assertEquals(1, results.size(), 'Result count is correct');

 
        Test.stopTest();
    }
}