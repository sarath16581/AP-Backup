/**
 * @description
 * Test class for CustomerResCreditApprovalMatrixModule
 * @author Ranjeewa Silva
 * @date 2021-05-14
 * @group Tests
 * @domain CustomerResolutions
 * @changelog
 * 2021-05-14 - Ranjeewa Silva - Created
 */

@IsTest
private class CustomerResCreditAppMatrixModule_Test {

    /**
	 * Test:
	 *  When a credit approval matrix record is updated, the after update will ensure approvers and approver roles
	 *  on all open credit approvals are updated to match the new approvers configured in the matrix record.
	 */
    @IsTest
    private static void testEnsureAfterUpdatePopulatesApproversOnRelatedCreditApprovals() {

        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CreditApprovalMatrixTriggerHandler.getUnitOfWorkSObjectTypes());

        List<User> approvers = ApplicationTestDataFactory.getUsers(10, true);

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(2, true, 'Non-Discretionary', 'default', 'default');
        // set approvers and roles on matrix records
        creditApprovalMatrixRecords[0].Approver1Role__c = 'Customer Resolutions Manager';
        creditApprovalMatrixRecords[0].Approver_1__c = approvers[0].Id;
        creditApprovalMatrixRecords[0].Approver2Role__c = 'Sales Director';
        creditApprovalMatrixRecords[0].Approver_2__c = approvers[1].Id;
        creditApprovalMatrixRecords[0].Approver3Role__c = 'GM of Sales';
        creditApprovalMatrixRecords[0].Approver_3__c = approvers[2].Id;
        creditApprovalMatrixRecords[0].Approver4Role__c = 'EGM Sales';
        creditApprovalMatrixRecords[0].Approver_4__c = approvers[3].Id;

        creditApprovalMatrixRecords[1].Approver1Role__c = 'Customer Resolutions Manager';
        creditApprovalMatrixRecords[1].Approver_1__c = approvers[0].Id;

        List<CreditApprovalMatrix__c> oldCreditApprovalMatrixRecords = new List<CreditApprovalMatrix__c>{creditApprovalMatrixRecords[0].clone(true), creditApprovalMatrixRecords[1].clone(true)};

        // on creditApprovalMatrixRecords[0] Approver_1__c has been changed from approvers[0] to approvers[5].
        oldCreditApprovalMatrixRecords[0].Approver_1__c = approvers[0].Id;
        creditApprovalMatrixRecords[0].Approver_2__c = approvers[5].Id;
        // on creditApprovalMatrixRecords[0] Approver4Role__c has been changed from 'EGM Sales' to 'EGM'
        oldCreditApprovalMatrixRecords[0].Approver4Role__c = 'EGM Sales';
        creditApprovalMatrixRecords[0].Approver4Role__c = 'EGM';
        // on creditApprovalMatrixRecords[0] Approver_4__c has been changed from approvers[3] to approvers[6]..
        oldCreditApprovalMatrixRecords[0].Approver_4__c = approvers[3].Id;
        creditApprovalMatrixRecords[0].Approver_4__c = approvers[6].Id;

        // on creditApprovalMatrixRecords[1] Approver_1__c has been changed from approvers[0] to approvers[7].
        oldCreditApprovalMatrixRecords[1].Approver_1__c = approvers[0].Id;
        creditApprovalMatrixRecords[1].Approver_1__c = approvers[7].Id;

        List<Credit_Approval__c> creditApprovals = ApplicationTestDataFactory.getCreditApprovals(2, true);

        // creditApprovals[0] is linked to creditApprovalMatrixRecords[0]. so populate approvers based on the old values on approval matrix
        creditApprovals[0].CreditApprovalMatrix__c = creditApprovalMatrixRecords[0].Id;
        creditApprovals[0].Approver1Role__c = 'Customer Resolutions Manager';
        creditApprovals[0].Approver_1__c = approvers[0].Id;
        creditApprovals[0].Approver1Complete__c = 'Approved'; //approver1 has already approved
        creditApprovals[0].ActualApprover1User__c = approvers[0].Id;
        creditApprovals[0].Approver2Role__c = 'Sales Director';
        creditApprovals[0].Approver_2__c = approvers[1].Id;
        creditApprovals[0].Approver3Role__c = 'GM of Sales';
        creditApprovals[0].Approver_3__c = approvers[2].Id;
        creditApprovals[0].Approver4Role__c = 'EGM Sales';
        creditApprovals[0].Approver_4__c = approvers[3].Id;

        // creditApprovals[1] is linked to creditApprovalMatrixRecords[1]. so populate approvers based on the old values on approval matrix
        creditApprovals[1].CreditApprovalMatrix__c = creditApprovalMatrixRecords[1].Id;
        creditApprovals[1].Approver1Role__c = 'Customer Resolutions Manager';
        creditApprovals[1].Approver_1__c = approvers[0].Id;

        // =====================================
        // Stubbing
        // =====================================
        CreditApprovalsSelector mockSelector = (CreditApprovalsSelector)MockUtility.mockSelector(CreditApprovalsSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectOpenCreditApprovalsByApprovalMatrixId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Credit_Approval__c>(creditApprovals));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CustomerResCreditApprovalMatrixModule module = CustomerResCreditApprovalMatrixModule.newInstance();

        module.onAfterUpdate(creditApprovalMatrixRecords, new Map<Id, SObject>(oldCreditApprovalMatrixRecords), uow);

        // make sure the method behaved
        ((CreditApprovalsSelector)MockUtility.Mocks.verify(mockSelector, 1)).selectOpenCreditApprovalsByApprovalMatrixId((Set<Id>)fflib_Match.anyObject());

        // make sure creditApprovals[0] fields were updated correctly
        System.assertEquals(approvers[0].Id, creditApprovals[0].Approver_1__c, 'Expected no change to approvers for approvals already completed');
        System.assertEquals('Customer Resolutions Manager', creditApprovals[0].Approver1Role__c, 'Expected no change to approvers for approvals already completed');
        System.assertEquals(approvers[6].Id, creditApprovals[0].Approver_4__c, 'Expected approvers to be updated for approvals not yet complete');
        System.assertEquals('EGM', creditApprovals[0].Approver4Role__c, 'Expected approvers to be updated for approvals not yet complete');

        // make sure creditApprovals[1] fields were updated correctly
        System.assertEquals(approvers[7].Id, creditApprovals[1].Approver_1__c, 'Expected approvers to be updated for approvals not yet complete');
        System.assertEquals('Customer Resolutions Manager', creditApprovals[1].Approver1Role__c, 'Expected approvers to be updated for approvals not yet complete');

        Test.stopTest();
    }

}