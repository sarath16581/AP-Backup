/***
 * @author Ranjeewa Silva
 * @date 2021-03-01
 * @group Tests
 * @tag Selector
 * @tag Disputed_Item__c
 * @domain Core
 * @description Test Class covering DisputedItemsSelector
 * @changelog
 * 2021-03-01 - Ranjeewa Silva - Created
 */

@IsTest
private class DisputedItemsSelector_Test {

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

        DisputedItemsSelector selector = DisputedItemsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Disputed_Item__c\\b').matcher(soql).find(), 'Resulting query does not select from Disputed_Item__c: ' + soql);

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

        DisputedItemsSelector selector = DisputedItemsSelector.newInstance(0, new Set<SObjectField>{Disputed_Item__c.Case__c});
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();
        // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(false, Pattern.compile('(?ism)\\bStatus__c\\b.*?\\bfrom Disputed_Item__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\bCase__c\\b.*?\\bfrom Disputed_Item__c\\b').matcher(soql).find(), 'Resulting query does not select Case__c field: ' + soql);

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

        List<Case> cases = ApplicationTestDataFactory.getCases(2, false);
        Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'Enterprise_Credit_Dispute_Claim'}).values()[0].Id;
        cases[0].RecordTypeId = creditDisputeCaseRecordTypeId;
        cases[1].RecordTypeId = creditDisputeCaseRecordTypeId;
        insert(cases);

        List<Disputed_Item__c> disputedItemsForClaimOne = ApplicationTestDataFactory.getDisputedItems(3, cases[0].Id,false);
        insert(disputedItemsForClaimOne);

        List<Disputed_Item__c> disputedItemsForClaimTwo = ApplicationTestDataFactory.getDisputedItems(1, cases[1].Id,false);
        insert(disputedItemsForClaimTwo);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DisputedItemsSelector selector = DisputedItemsSelector.newInstance(0);
        Map<Id, Disputed_Item__c> results = selector.selectByCaseId(new Set<Id>{cases[0].Id});
        System.assertEquals(3, results.size(), 'Expected result size of 3');

        Test.stopTest();

    }
}