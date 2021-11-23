/***
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Tests
 * @tag Selector
 * @tag CreditApprovalMatrix__c
 * @domain Core
 * @description Test Class covering CreditApprovalMatrixSelector
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created
 */

@IsTest
private class CreditApprovalMatrixSelector_Test {

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

        CreditApprovalMatrixSelector selector = CreditApprovalMatrixSelector.newInstance(5);
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select from CreditApprovalMatrix__c: ' + soql);

        qb = selector.newQueryBuilder(new Set<Object>{CreditApprovalMatrixSelector.Options.WITH_APPROVERS});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Approver_1__r\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select Approver_1__r fields: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Approver_2__r\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select Approver_2__r fields: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Approver_3__r\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select Approver_3__r fields: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Approver_4__r\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select Approver_4__r fields: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Approver_5__r\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select Approver_5__r fields: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Approver_6__r\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select Approver_6__r fields: ' + soql);

        selector = CreditApprovalMatrixSelector.newInstance(0, new Set<SObjectField>{CreditApprovalMatrix__c.AutoApprove__c, CreditApprovalMatrix__c.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)AutoApprove__c.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select AutoApprove__c field: ' + soql);

        selector = CreditApprovalMatrixSelector.newInstance(0, new Set<SObjectField>{CreditApprovalMatrix__c.AutoApprove__c, CreditApprovalMatrix__c.Id});
        qb = selector.newQueryBuilder(new Set<Object>{CreditApprovalMatrixSelector.Options.WITH_LASTMODIFIEDBYUSER});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)AutoApprove__c.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select AutoApprove__c field: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)LastModifiedBy\\.Id.*?\\bfrom CreditApprovalMatrix__c\\b').matcher(soql).find(), 'Resulting query does not select LastModifiedBy user fields: ' + soql);

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

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords_NonDiscretionary = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(2, false, 'Non-Discretionary', null, null);
        creditApprovalMatrixRecords_NonDiscretionary[0].AutoApprove__c = true;
        creditApprovalMatrixRecords_NonDiscretionary[0].Product_Family__c = 'default';
        creditApprovalMatrixRecords_NonDiscretionary[0].Product_Sub_Category__c = 'default';
        creditApprovalMatrixRecords_NonDiscretionary[0].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords_NonDiscretionary[0].ToCreditAmount__c = 1000000;

        creditApprovalMatrixRecords_NonDiscretionary[1].AutoApprove__c = true;
        creditApprovalMatrixRecords_NonDiscretionary[1].Product_Family__c = 'Parcels';
        creditApprovalMatrixRecords_NonDiscretionary[1].Product_Sub_Category__c = 'Local marketplaces';
        creditApprovalMatrixRecords_NonDiscretionary[1].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords_NonDiscretionary[1].ToCreditAmount__c = 1000000;

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords_Discretionary = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(3, false, 'Discretionary Credit', null, null);
        creditApprovalMatrixRecords_Discretionary[0].AutoApprove__c = true;
        creditApprovalMatrixRecords_Discretionary[0].Product_Family__c = 'default';
        creditApprovalMatrixRecords_Discretionary[0].Product_Sub_Category__c = 'default';
        creditApprovalMatrixRecords_Discretionary[0].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords_Discretionary[0].ToCreditAmount__c = 1000000;

        creditApprovalMatrixRecords_Discretionary[1].AutoApprove__c = true;
        creditApprovalMatrixRecords_Discretionary[1].Product_Family__c = 'Parcels';
        creditApprovalMatrixRecords_Discretionary[1].Product_Sub_Category__c = 'Local marketplaces';
        creditApprovalMatrixRecords_Discretionary[1].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords_Discretionary[1].ToCreditAmount__c = 500000;

        creditApprovalMatrixRecords_Discretionary[2].AutoApprove__c = true;
        creditApprovalMatrixRecords_Discretionary[2].Product_Family__c = 'Parcels';
        creditApprovalMatrixRecords_Discretionary[2].Product_Sub_Category__c = 'Local marketplaces';
        creditApprovalMatrixRecords_Discretionary[2].FromCreditAmount__c = 500001;
        creditApprovalMatrixRecords_Discretionary[2].ToCreditAmount__c = 1000000;

        List<CreditApprovalMatrix__c> newApprovalMatrixRecords = new List<CreditApprovalMatrix__c>(creditApprovalMatrixRecords_NonDiscretionary);
        newApprovalMatrixRecords.addAll(creditApprovalMatrixRecords_Discretionary);
        insert newApprovalMatrixRecords;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CreditApprovalMatrixSelector selector = CreditApprovalMatrixSelector.newInstance();
        Map<Id, CreditApprovalMatrix__c> results = selector.selectByCreditTypeAndProduct(new Set<String>{'Discretionary Credit'}, new Set<String> {'default'}, new Set<String>{'default'});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        results = selector.selectByCreditTypeAndProduct(new Set<String>{'Discretionary Credit'}, new Set<String> {'Parcels'}, new Set<String>{'Local marketplaces'});
        System.assertEquals(2, results.size(), 'Expected result size of 2');

        results = selector.selectByCreditTypeAndProduct(new Set<String>{'Non-Discretionary'}, new Set<String> {'default', 'Parcels'}, new Set<String>{'default', 'Local marketplaces'});
        System.assertEquals(2, results.size(), 'Expected result size of 2');

        selector = CreditApprovalMatrixSelector.newInstance();
        results = selector.selectByLastModifiedDate(0, new Set<Object>());
        System.assertEquals(5, results.size(), 'Expected result size of 5');

        selector = CreditApprovalMatrixSelector.newInstance();
        Database.QueryLocator queryLocator = selector.selectByLastModifiedDateQueryLocator(0, new Set<Object>());
        System.assert(queryLocator != null, 'Expected a valid query locator');
        System.assert(queryLocator.iterator().hasNext(), 'Expected a valid query locator');

        Test.stopTest();
    }

    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
    @IsTest
    private static void testEnsureSelectorReturnRescordsInExpectedOrder() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords_NonDiscretionary = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(4, false, 'Non-Discretionary', 'default', 'default');
        creditApprovalMatrixRecords_NonDiscretionary[0].AutoApprove__c = true;
        creditApprovalMatrixRecords_NonDiscretionary[0].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords_NonDiscretionary[0].ToCreditAmount__c = 100;

        creditApprovalMatrixRecords_NonDiscretionary[1].AutoApprove__c = true;
        creditApprovalMatrixRecords_NonDiscretionary[1].FromCreditAmount__c = 100;
        creditApprovalMatrixRecords_NonDiscretionary[1].ToCreditAmount__c = 1000;

        creditApprovalMatrixRecords_NonDiscretionary[2].AutoApprove__c = true;
        creditApprovalMatrixRecords_NonDiscretionary[2].FromCreditAmount__c = 1000;
        creditApprovalMatrixRecords_NonDiscretionary[2].ToCreditAmount__c = 10000;

        creditApprovalMatrixRecords_NonDiscretionary[3].AutoApprove__c = true;
        creditApprovalMatrixRecords_NonDiscretionary[3].FromCreditAmount__c = 10000;
        creditApprovalMatrixRecords_NonDiscretionary[3].ToCreditAmount__c = 100000;

        insert creditApprovalMatrixRecords_NonDiscretionary;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        //update the bands on one credit approval matrix so there are multiple bands with the same from credit amount

        creditApprovalMatrixRecords_NonDiscretionary[2].FromCreditAmount__c = 100;
        creditApprovalMatrixRecords_NonDiscretionary[2].ToCreditAmount__c = 999;
        update(creditApprovalMatrixRecords_NonDiscretionary[2]);

        CreditApprovalMatrixSelector selector = CreditApprovalMatrixSelector.newInstance();
        List<CreditApprovalMatrix__c> results = selector.selectByCreditTypeAndProductInOrder(new Set<String>{'Non-Discretionary'}, new Set<String> {'default'}, new Set<String>{'default'}, new Set<Object>{});
        System.assertEquals(4, results.size(), 'Expected result size of 4');

        System.assertEquals(creditApprovalMatrixRecords_NonDiscretionary[0].Id, results[0].Id, 'Results not returned in expected order');
        System.assertEquals(creditApprovalMatrixRecords_NonDiscretionary[2].Id, results[1].Id, 'Results not returned in expected order');
        System.assertEquals(creditApprovalMatrixRecords_NonDiscretionary[1].Id, results[2].Id, 'Results not returned in expected order');
        System.assertEquals(creditApprovalMatrixRecords_NonDiscretionary[3].Id, results[3].Id, 'Results not returned in expected order');

        Test.stopTest();
    }
}