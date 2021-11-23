/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Deal Support Request SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - arjun.singh@auspost.com.au - Created
*/
@IsTest
public with sharing class DealSupportRequestsSelector_Test {
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

        DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Deal Support Request');

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

        DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

        qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

        qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE, DealSupportRequestsSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');
        
        qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT});
		soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)APT_Contract__r.Apttus__Primary_Contact__r\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Primary Contact fields');

        qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST});
		soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r.APT_Charge_Account__r\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Charge Request fields');

        qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Credit Assessement  fields');

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
        Account chargeAccount = accountList[1];

        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
        insert primaryContact;

        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert opportunityRecord;


        /*APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false)[0];
        insert chargeAccountRequest;

        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, false)[0];
        insert apttusCreditAssessment ;

        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, false)[0];
        insert apttusProposals;

        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, false)[0];
        insert apttusContracts;*/
        
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, false)[0];
        insert dealSupportRequest;

        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', false)[0];
        insert externalOnboardingRecord;
        
       /* apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;*/

        Map<Id, Deal_Support_Request__c> mappedDealSupports = new Map<Id, Deal_Support_Request__c>(new List<Deal_Support_Request__c>{dealSupportRequest});

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance(1);
        Map<Id, Deal_Support_Request__c> results = selector.selectById(mappedDealSupports.keySet());
        System.assertEquals(1, results.size(), 'Result count was wrong');
        results = selector.selectById(mappedDealSupports.keySet(), new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE, DealSupportRequestsSelector.Options.WITH_OWNER});
        
        System.assertEquals(1, results.size(), 'Result count was wrong');
        System.assertNotEquals(null, results.values()[0].RecordType, 'Expected RecordType object');
        System.assertNotEquals(null, results.values()[0].OwnerId, 'Expected Owner object');

        Map<Id, Deal_Support_Request__c> resultsforMultipleDSR = selector.selectByRecordList(new List<Deal_Support_Request__c>{dealSupportRequest});
        System.assertEquals(1, resultsforMultipleDSR.size(), 'Result count was wrong');

        Test.stopTest();

    }
}