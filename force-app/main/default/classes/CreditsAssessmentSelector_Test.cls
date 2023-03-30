/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Credit Assessment SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - arjun.singh@auspost.com.au - Created
* 2023-02-08 - Harry Wang - Added test method for selectByOpportunityIds and field overrides
*/
@IsTest
public with sharing class CreditsAssessmentSelector_Test {
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

        CreditsAssessmentSelector selector = CreditsAssessmentSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom APT_Credit_Assessment__c\\b').matcher(soql).find(), 'Resulting query does not select from credit assessment');

        Test.stopTest();

    }
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

        CreditsAssessmentSelector selector = CreditsAssessmentSelector.newInstance();       
        
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CreditsAssessmentSelector.Options.WITH_OWNER});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom APT_Credit_Assessment__c\\b').matcher(soql).find(), 'Resulting query does not select Owner field');
                
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
        Account account = accountList[0];

        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
        insert primaryContact;

        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert opportunityRecord;


        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false)[0];
        insert chargeAccountRequest;

        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, false)[0];
        insert apttusCreditAssessment ;        
        
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, false)[0];
        insert dealSupportRequest;

        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', false)[0];
        insert externalOnboardingRecord;       
       

        Map<Id, APT_Credit_Assessment__c> mappedRecord = new Map<Id, APT_Credit_Assessment__c>(new List<APT_Credit_Assessment__c>{apttusCreditAssessment});

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        CreditsAssessmentSelector selector = CreditsAssessmentSelector.newInstance(1);
        Map<Id, APT_Credit_Assessment__c> results = selector.selectById(mappedRecord.keySet());
        System.assertEquals(1, results.size(), 'Result count was wrong');

        results = selector.selectById(mappedRecord.keySet(), new Set<Object>{CreditsAssessmentSelector.Options.WITH_OWNER});
        System.assertEquals(1, results.size(), 'Result count was wrong');
        System.assertNotEquals(null, results.values()[0].OwnerId, 'Expected Owner object');

        List<APT_Credit_Assessment__c> resultList = selector.selectByOpportunityIds(new Set<Id>{opportunityRecord.Id});
        System.assertEquals(0, resultList.size(), 'Result count was wrong');

        Test.stopTest();
    }

    /**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
        Test.startTest();
        CreditsAssessmentSelector selector = CreditsAssessmentSelector.newInstance(new Set<SObjectField>{
                APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.Name
        });
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b.*?\\bfrom APT_Credit_Assessment__c\\b').matcher(soql).find(), 'Resulting query does not select name from APT_Credit_Assessment__c');

        selector = CreditsAssessmentSelector.newInstance(1, new Set<SObjectField>{
                APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.Name
        });
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b.*?\\bfrom APT_Credit_Assessment__c\\b.*?\\blimit 1\\b').matcher(soql).find(), 'Resulting query does not select name from APT_Credit_Assessment__c limit 1');

        selector = CreditsAssessmentSelector.newInstance('Name', 'Desc', 1);
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_Credit_Assessment__c\\b.*?\\border by Name DESC\\b.*?\\blimit 1\\b').matcher(soql).find(), 'Resulting query does not select from APT_Credit_Assessment__c order by name limit 1');

        Test.stopTest();
    }
}