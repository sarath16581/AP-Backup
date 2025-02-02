/**
 * @description Test class covering DealSupportRequestMilestonesSelector
 * @author Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date 2022-06-08
 * @group Tests
 * @tag Domain
 * @tag Deal_Support_Request__c
 * @domain Core
 * @changelog
 * 2022-06-08	Dattaraj Deshmukh - created
 */
@IsTest
public with sharing class DealSupportRequstMilestoneSelector_Test {
    
    @IsTest
    static void testEnsureQueryBuilderProducesCorrectString(){
        

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


         /**
         * Test:
         *  Ensures that the selectors QueryBuilder is generating the correct output
         */
        Test.startTest();

        DealSupportRequestMilestonesSelector selector = DealSupportRequestMilestonesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom DealSupportRequestMilestone__c\\b').matcher(soql).find(), 'Resulting query does not select from DealSupportRequestMilestones');

        Test.stopTest();
    }

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

        DealSupportRequestMilestonesSelector selector = DealSupportRequestMilestonesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestMilestonesSelector.Options.WITH_RECORDTYPE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom DealSupportRequestMilestone__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

          
        qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestMilestonesSelector.Options.WITH_DEAL_SUPPORT_REQUEST});
		soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)DealSupportRequest__r\\..*?\\bfrom DealSupportRequestMilestone__c\\b').matcher(soql).find(), 'Resulting query does not select deal support request fields');

        
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
        Id dsrMilestoneStageGateRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('DealSupportRequestMilestone__c', new Set<String>{'StageGates'}).values()[0].Id;


        List<Account> accountList = ApplicationTestDataFactory.getAccounts(1, false);
        insert accountList;

        
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, null, accountList[0].Id, false)[0];
        dealSupportRequest.Implementation_Stage__c = 'Idea - Sales';
        insert dealSupportRequest;

        List<DealSupportRequestMilestone__c> newDsrMilestones = ApplicationTestDataFactorySales.getDealSupportRequestMilestones(1, dealSupportRequest.Id, false);
        newDsrMilestones[0].RecordTypeId=dsrMilestoneStageGateRecordTypeId;
        insert newDsrMilestones;




        Map<Id, Deal_Support_Request__c> mappedDealSupports = new Map<Id, Deal_Support_Request__c>(new List<Deal_Support_Request__c>{dealSupportRequest});
        Set<Id> dsrMilestonesIds = new Set<Id>{newDsrMilestones[0].Id};


        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        DealSupportRequestMilestonesSelector selector = DealSupportRequestMilestonesSelector.newInstance(1);
        
        List<DealSupportRequestMilestone__c> results = selector.selectByDSRId(mappedDealSupports.keySet(), new Set<Object>{DealSupportRequestMilestonesSelector.Options.WITH_RECORDTYPE, DealSupportRequestMilestonesSelector.Options.WITH_DEAL_SUPPORT_REQUEST});
        

        System.assertNotEquals(null, results[0].RecordType, 'Expected RecordType object');

        List<DealSupportRequestMilestone__c>  queriedDsrMilestones = selector.selectById(dsrMilestonesIds);
        System.assertEquals(dsrMilestoneStageGateRecordTypeId, queriedDsrMilestones[0].RecordTypeId, 'Result count was wrong');


        Test.stopTest();

    }


}