/***
 * @author Ranjeewa Silva
 * @date 2021-03-01
 * @group Tests
 * @tag Selector
 * @tag BulkLoadRequestLineItem
 * @domain Core
 * @description Test Class covering BulkLoadRequestLineItemsSelector
 * @changelog
 * 2021-03-01 - Ranjeewa Silva - Created
 */

@IsTest
private class BulkLoadRequestLineItemsSelector_Test {

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

        BulkLoadRequestLineItemsSelector selector = BulkLoadRequestLineItemsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select from BulkLoadRequestLineItem__c: ' + soql);

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

        BulkLoadRequestLineItemsSelector selector = BulkLoadRequestLineItemsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{BulkLoadRequestLineItemsSelector.Options.WITH_BULKLOADREQUEST});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)BulkLoadRequest__r\\..*?\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select Bulk Load Request fields: ' + soql);

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

        BulkLoadRequestLineItemsSelector selector = BulkLoadRequestLineItemsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                BulkLoadRequest__c.SObjectType => new Set<SObjectField>{BulkLoadRequest__c.FileName__c},
                BulkLoadRequestLineItem__c.SObjectType => new Set<SObjectField>{BulkLoadRequestLineItem__c.LineNumber__c}
        });
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{BulkLoadRequestLineItemsSelector.Options.WITH_BULKLOADREQUEST});
        String soql = qb.toSoqlString();
        // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(true, Pattern.compile('(?ism)BulkLoadRequest__r\\..*?\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select BulkLoadRequest__r fields: ' + soql);
        System.assertEquals(false, Pattern.compile('(?ism)BulkLoadRequest__r\\.Id.*?\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting query select BulkLoadRequest__r.Id field, but it shouldn\'t \': ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)BulkLoadRequest__r\\.FileName__c.*?\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select BulkLoadRequest__r.FileName__c field: ' + soql);
        System.assertEquals(false, Pattern.compile('(?ism)\\bStatus__c\\b.*?\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\bLineNumber__c\\b.*?\\bfrom BulkLoadRequestLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select LineNumber__c field: ' + soql);

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

        List<BulkLoadRequest__c> bulkLoadRequests = ApplicationTestDataFactory.getBulkLoadRequests(2, false);
        bulkLoadRequests[0].Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequests[1].Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        insert(bulkLoadRequests);

        List<BulkLoadRequestLineItem__c> request1LineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(3, bulkLoadRequests[0].Id,false);
        insert(request1LineItems);

        List<BulkLoadRequestLineItem__c> request2LineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(2, bulkLoadRequests[1].Id,false);
        insert(request2LineItems);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkLoadRequestLineItemsSelector selector = BulkLoadRequestLineItemsSelector.newInstance(0);
        Map<Id, BulkLoadRequestLineItem__c> results = selector.selectByBulkLoadRequestAndStatus(bulkLoadRequests[0].Id, new Set<String>{BulkUploadService.LINEITEM_STATUS_NEW});
        System.assertEquals(3, results.size(), 'Expected result size of 3');

        results = selector.selectByBulkLoadRequestAndStatus(bulkLoadRequests[0].Id, new Set<String>{BulkUploadService.LINEITEM_STATUS_SUCCESS});
        System.assertEquals(0, results.size(), 'Expected result size of 0');

        Test.stopTest();

    }
}