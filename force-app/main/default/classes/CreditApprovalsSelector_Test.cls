/***
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Tests
 * @tag Selector
 * @tag Credit_Approval__c
 * @domain Core
 * @description Test Class covering CreditApprovalsSelector
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created
 */

@IsTest
private class CreditApprovalsSelector_Test {

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

        CreditApprovalsSelector selector = CreditApprovalsSelector.newInstance(5);
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Credit_Approval__c\\b').matcher(soql).find(), 'Resulting query does not select from Credit_Approval__c: ' + soql);

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

        CreditApprovalsSelector selector = CreditApprovalsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CreditApprovalsSelector.Options.WITH_APPROVERS});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Approver_1__r\\..*?\\bfrom Credit_Approval__c\\b').matcher(soql).find(), 'Resulting query does not select Approver fields: ' + soql);

        qb = selector.newQueryBuilder(new Set<Object>{CreditApprovalsSelector.Options.WITH_ACTUAL_APPROVERS});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)ActualApprover1User__r\\..*?\\bfrom Credit_Approval__c\\b').matcher(soql).find(), 'Resulting query does not select Approver fields: ' + soql);

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

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(2, false,'Non-Discretionary', 'default', 'default');

        creditApprovalMatrixRecords[0].AutoApprove__c = true;
        creditApprovalMatrixRecords[0].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords[0].ToCreditAmount__c = 100000;

        creditApprovalMatrixRecords[1].AutoApprove__c = true;
        creditApprovalMatrixRecords[1].FromCreditAmount__c = 0.01;
        creditApprovalMatrixRecords[1].ToCreditAmount__c = 100000;

        insert(creditApprovalMatrixRecords);

        List<Credit_Approval__c> creditApprovals = ApplicationTestDataFactory.getCreditApprovals(6, false);

        creditApprovals[0].CreditApprovalMatrix__c = creditApprovalMatrixRecords[0].Id;
        creditApprovals[0].Status__c = 'New';

        creditApprovals[1].CreditApprovalMatrix__c = creditApprovalMatrixRecords[0].Id;
        creditApprovals[1].Status__c = 'Pending Approval Decision';

        creditApprovals[2].CreditApprovalMatrix__c = creditApprovalMatrixRecords[0].Id;
        creditApprovals[2].Status__c = 'Approved';

        creditApprovals[3].CreditApprovalMatrix__c = creditApprovalMatrixRecords[0].Id;
        creditApprovals[3].Status__c = 'Rejected';

        creditApprovals[4].CreditApprovalMatrix__c = creditApprovalMatrixRecords[0].Id;
        creditApprovals[4].Status__c = 'Invalid';

        creditApprovals[5].CreditApprovalMatrix__c = creditApprovalMatrixRecords[1].Id;
        creditApprovals[5].Status__c = 'New';

        insert(creditApprovals);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CreditApprovalsSelector selector = CreditApprovalsSelector.newInstance();
        Map<Id, Credit_Approval__c> results = selector.selectById(new Set<Id>{creditApprovals[0].Id, creditApprovals[3].Id});
        System.assertEquals(2, results.size(), 'Expected result size of 2');
        System.assert(results.keySet().contains(creditApprovals[0].Id), 'Expected credit approval record not returned');
        System.assert(results.keySet().contains(creditApprovals[3].Id), 'Expected credit approval record not returned');

        results = selector.selectOpenCreditApprovalsByApprovalMatrixId(new Set<Id>{creditApprovalMatrixRecords[0].Id});
        System.assertEquals(2, results.size(), 'Expected result size of 2');
        System.assert(results.keySet().contains(creditApprovals[0].Id), 'Expected credit approval record not returned');
        System.assert(results.keySet().contains(creditApprovals[1].Id), 'Expected credit approval record not returned');

        Test.stopTest();
    }
}