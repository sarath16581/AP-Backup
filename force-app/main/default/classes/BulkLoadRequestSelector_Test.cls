/***
 * @author Ranjeewa Silva
 * @date 2021-03-01
 * @group Tests
 * @tag Selector
 * @tag BulkLoadRequest
 * @domain Core
 * @description Test Class covering BulkLoadRequestsSelector
 * @changelog
 * 2021-03-01 - Ranjeewa Silva - Created
 */

@IsTest
private class BulkLoadRequestSelector_Test {

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

        BulkLoadRequestSelector selector = BulkLoadRequestSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting query does not select from BulkLoadRequest__c: ' + soql);

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

        BulkLoadRequestSelector selector = BulkLoadRequestSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{BulkLoadRequestSelector.Options.WITH_OWNER});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields: ' + soql);

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

        BulkLoadRequestSelector selector = BulkLoadRequestSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                BulkLoadRequest__c.SObjectType => new Set<SObjectField>{BulkLoadRequest__c.FileName__c}
        });
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{BulkLoadRequestSelector.Options.WITH_OWNER});
        String soql = qb.toSoqlString();
        // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting query does not select User fields: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\.Id.*?\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting query does not select User.Id field \': ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Owner\\.Name.*?\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting query does not select User.Name field: ' + soql);
        System.assertEquals(false, Pattern.compile('(?ism)\\bStatus__c\\b.*?\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\bFileName__c\\b.*?\\bfrom BulkLoadRequest__c\\b').matcher(soql).find(), 'Resulting query does not select FileName__c field: ' + soql);

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

        List<BulkLoadRequest__c> bulkLoadRequests = ApplicationTestDataFactory.getBulkLoadRequests(3, false);
        bulkLoadRequests[0].Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequests[0].UploadTimestamp__c = Date.today().addDays(-3);

        bulkLoadRequests[1].Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequests[1].UploadTimestamp__c = Date.today().addDays(-120);

        bulkLoadRequests[2].Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequests[2].FileName__c = 'someother.csv';
        bulkLoadRequests[2].UploadTimestamp__c = Date.today().addDays(-3);

        insert(bulkLoadRequests);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkLoadRequestSelector selector = BulkLoadRequestSelector.newInstance();
        Map<Id, BulkLoadRequest__c> results = selector.selectById(new Set<Id>{bulkLoadRequests[0].Id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        results = selector.selectById(new Set<Id>{bulkLoadRequests[0].Id, bulkLoadRequests[1].Id}, new Set<Object>{BulkLoadRequestSelector.Options.WITH_OWNER});
        System.assertEquals(2, results.size(), 'Expected result size of 2');

        //https://success.salesforce.com/issues_view?id=a1p30000000SwHDAA0
        // Owner field is empty in this scenario
        // The owner fields are included in the query as per above tests, it's just the integration test does not produce the actual values
        //System.assertNotEquals(null, results.values()[0].Owner, 'Expected Owner to be populated');
        //System.assertNotEquals(null, results.values()[1].Owner, 'Expected Owner to be populated');

        results = selector.selectByTypeAndUploadDate(60, new Set<String>{BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name()});
        System.assertEquals(2, results.size(), 'Expected results size of 2');
        System.assert(!results.containsKey(bulkLoadRequests[1].Id), 'Expected requests uploaded more than 60 days ago to be not included in results returned.');
        System.assert(results.containsKey(bulkLoadRequests[0].Id), 'Expected requests uploaded less than 60 days ago to be returned.');
        System.assert(results.containsKey(bulkLoadRequests[2].Id), 'Expected requests uploaded less than 60 days ago to be returned.');

        results = selector.selectByTypeAndUploadDate(60, new Set<String>{'Unknown'});
        System.assertEquals(0, results.size(), 'Expected results size of 0');

        results = selector.selectByTypeAndFileName(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name(), new Set<String>{'someother.csv'});
        System.assertEquals(1, results.size(), 'Expected results size of 1');

        results = selector.selectByTypeAndFileName('Unknown', new Set<String>{'someother.csv'});
        System.assertEquals(0, results.size(), 'Expected results size of 0');


        Test.stopTest();

    }

}