/**
* @author Seth Heang
* @date 2020-11-06
* @group Tests
* @tag Selector
* @tag SSSWRouting__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-12-18 - Seth Heang - Created
* 2024-07-10 - Ranjeewa Silva - Added more tests for testing search method.
*/
@IsTest
private with sharing class SSSWRoutingSelector_Test {
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

        SSSWRoutingSelector selector = SSSWRoutingSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom SSSWRouting__c\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

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
        MockUtility.disableTriggerExecution();

        Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SSSWRouting__c', new Set<String>{'Credit_DSR_Routing'}).values()[0].Id;
        SSSWRouting__c ssswCreditDSR = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, 'M12', 'seth@test.com', 'Legal Recovery Team', 'Credit Person Code', false)[0];
        insert ssswCreditDSR;
        
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        SSSWRoutingSelector selector = SSSWRoutingSelector.newInstance(1);
        Map<Id, SSSWRouting__c> results = selector.selectByRecordTypeId(new Set<id>{recTypeId});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }

    /**
	 * Executes a query to ensure that the query actually runs. There will be no data returned, however this ensure that
	 * the query does not error
	 */
    @IsTest
    private static void testSelectorSearchAllIntegrationValidationOfQueryOnly() {

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

        SSSWRoutingSelector selector = SSSWRoutingSelector.newInstance();
        List<SSSWRouting__c> results = selector.search(new Map<String, Object>{'recordtypeDeveloperNames' => new Set<String>{'SSSW_Routing', 'UnifiedRouting'}}, true);
        Assert.areEqual(0, results.size());

        Test.stopTest();
    }

    /**
	 * Test to ensure that the selectors QueryBuilder is generating the correct output
	 */
    @IsTest
    public static void testEnsureSearchMethodProducesCorrectString() {

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

        Map<String, Object> searchParams;

        SSSWRoutingSelector selector = SSSWRoutingSelector.newInstance(1);

        searchParams = new Map<String, Object>{
                'recordtypeDeveloperNames' => new Set<String>{'SSSW_Routing'},
                'isActive' => true,
                'matchRulesOn' => new Set<String>{'ANY', 'ALL'}
        };

        String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
        Assert.isTrue(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bRecordType.DeveloperName\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter RecordType.DeveloperName.');
        Assert.isTrue(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bIsActive__c\\s+=\\B').matcher(soql).find(), 'Resulting query does not filter IsActive__c.');
        Assert.isTrue(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bMatch_Rules_On__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit bMatch_Rules_On__c');
        Assert.isTrue(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

        // make sure the query is valid (even though no records will be returned)
        // note if the query fails, an exception will be thrown
        selector.search(searchParams, true);

        searchParams = new Map<String, Object>{
                'recordtypeDeveloperNames' => new Set<String>{'SSSW_Routing', 'UnifiedRouting'}
        };

        soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
        Assert.isTrue(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bRecordType.DeveloperName\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter RecordType.DeveloperName.');
        Assert.isFalse(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bIsActive__c\\s+=\\B').matcher(soql).find(), 'Resulting query limits IsActive__c, it should not');
        Assert.isFalse(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bMatch_Rules_On__c\\s+In\\b').matcher(soql).find(), 'Resulting query limits Match_Rules_On__c, it should not');
        Assert.isFalse(Pattern.compile('(?ism)\\s+from SSSWRouting__c\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

        // make sure the query is valid (even though no records will be returned)
        // note if the query fails, an exception will be thrown
        selector.search(searchParams, true);

        // make sure an exception is thrown for invalid search parameters
        searchParams = new Map<String, Object>{
                'invalidParam' => new Set<String>{'somevalue'},
                'isActive' => true
        };

        try {
            soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
        } catch (Exception e) {
            // ensure correct type of exception thrown
            Assert.isInstanceOfType(e, ApplicationSelector.SelectorException.class);
        }

        Test.stopTest();

    }

}