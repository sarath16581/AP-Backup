/**
* Author: 		Angelo Rivera
* Name: 		CreditApprovalWorkflowControllerTest
* Description: 	Test Class for CreditApprovalWorkflowBlueBarController
* Revision History
* 07-26-2017 	1.0		AP.Rivera		Created
* 13-05-2021 - Ranjeewa Silva - Updated with test methods after refactoring the controller.
**/

@isTest
private class CreditApprovalWorkflowControllerTest {

	@IsTest
	static void testApprovalWorkflowOnNewCreditApprovalSetForAutoApproval() {

		// =====================================
		// Data Preparation
		// =====================================
		Credit_Approval__c creditApproval = ApplicationTestDataFactory.getCreditApprovals(1, true)[0];
		creditApproval.AutoApprove__c = true;


		// =====================================
		// Stubbing
		// =====================================
		CreditApprovalsSelector mockCreditApprovalsSelector = (CreditApprovalsSelector)MockUtility.mockSelector(CreditApprovalsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCreditApprovalsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Credit_Approval__c>{creditApproval.Id => creditApproval});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CreditApprovalWorkflowBlueBarController controller = new CreditApprovalWorkflowBlueBarController(new ApexPages.StandardController(creditApproval));
		Test.stopTest();

		System.assertNotEquals(null, controller.approvalSteps, 'Expected one approval step rendered for auto approvals, but got null');
		System.assertEquals(1, controller.approvalSteps.size(), 'Expected only one approval step rendered for auto approvals');
		System.assertEquals(CreditApprovalWorkflowBlueBarController.AUTO_APPROVAL_STEP_NAME, controller.approvalSteps[0].stepName, 'Expected step name not returned for auto approved step');
		System.assertEquals('PENDING', controller.approvalSteps[0].status, 'Expected approval status not returned for new approval set for auto approval');
		System.assertEquals('', controller.approvalSteps[0].approver, 'Expected approver details to be blank for auto approval');
	}

	@IsTest
	static void testApprovalWorkflowOnCompletedAutoApproval() {

		// =====================================
		// Data Preparation
		// =====================================
		Credit_Approval__c creditApproval = ApplicationTestDataFactory.getCreditApprovals(1, true)[0];
		creditApproval.AutoApprove__c = true;
		creditApproval.Status__c = 'Approved';


		// =====================================
		// Stubbing
		// =====================================
		CreditApprovalsSelector mockCreditApprovalsSelector = (CreditApprovalsSelector)MockUtility.mockSelector(CreditApprovalsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCreditApprovalsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Credit_Approval__c>{creditApproval.Id => creditApproval});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CreditApprovalWorkflowBlueBarController controller = new CreditApprovalWorkflowBlueBarController(new ApexPages.StandardController(creditApproval));
		Test.stopTest();

		System.assertNotEquals(null, controller.approvalSteps, 'Expected one approval step rendered for auto approvals, but got null');
		System.assertEquals(1, controller.approvalSteps.size(), 'Expected only one approval step rendered for auto approvals');
		System.assertEquals(CreditApprovalWorkflowBlueBarController.AUTO_APPROVAL_STEP_NAME, controller.approvalSteps[0].stepName, 'Expected step name not returned for auto approved step');
		System.assertEquals('APPROVED', controller.approvalSteps[0].status, 'Expected approval status not returned for completed auto approval');
		System.assertEquals('', controller.approvalSteps[0].approver, 'Expected approver details must be blank for auto approval');
	}

	@IsTest
	static void testApprovalWorkflowMultipleApprovers() {

		// =====================================
		// Data Preparation
		// =====================================
		Credit_Approval__c creditApproval = ApplicationTestDataFactory.getCreditApprovals(1, true)[0];
		creditApproval.AutoApprove__c = false;
		creditApproval.Approver1Role__c = 'Customer Resolutions Manager';
		creditApproval.Approver_1__c = UserInfo.getUserId();
		creditApproval.Approver1Complete__c = 'Approved';
		creditApproval.ActualApprover1User__c = UserInfo.getUserId();

		creditApproval.Approver2Role__c = 'Sales Director';
		creditApproval.Approver_2__c = UserInfo.getUserId();
		creditApproval.Approver2Complete__c = 'Rejected';
		creditApproval.ActualApprover2User__c = UserInfo.getUserId();

		creditApproval.Approver3Role__c = 'GM of Sales';
		creditApproval.Approver_3__c = UserInfo.getUserId();

		creditApproval.Approver4Role__c = 'EGM Sales';
		creditApproval.Approver_4__c = UserInfo.getUserId();

		creditApproval.Approver5Role__c = 'GCFO';
		creditApproval.Approver_5__c = UserInfo.getUserId();

		creditApproval.Approver6Role__c = 'CEO';
		creditApproval.Approver_6__c = UserInfo.getUserId();

		creditApproval.Status__c = 'Rejected';


		// =====================================
		// Stubbing
		// =====================================
		CreditApprovalsSelector mockCreditApprovalsSelector = (CreditApprovalsSelector)MockUtility.mockSelector(CreditApprovalsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCreditApprovalsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Credit_Approval__c>{creditApproval.Id => creditApproval});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CreditApprovalWorkflowBlueBarController controller = new CreditApprovalWorkflowBlueBarController(new ApexPages.StandardController(creditApproval));
		Test.stopTest();

		System.assertNotEquals(null, controller.approvalSteps, 'Expected approval steps rendered, but got null');
		System.assertEquals(6, controller.approvalSteps.size(), 'Expected number of approval steps not returned');

		System.assertEquals(creditApproval.Approver1Role__c, controller.approvalSteps[0].stepName, 'Expected step name not returned');
		System.assertEquals('APPROVED', controller.approvalSteps[0].status, 'Expected approval status not returned for completed approval');

		System.assertEquals(creditApproval.Approver2Role__c, controller.approvalSteps[1].stepName, 'Expected step name not returned');
		System.assertEquals('REJECTED', controller.approvalSteps[1].status, 'Expected approval status not returned for completed approval');

		System.assertEquals(creditApproval.Approver3Role__c, controller.approvalSteps[2].stepName, 'Expected step name not returned');
		System.assertEquals('PENDING', controller.approvalSteps[2].status, 'Expected approval status not returned for pending approval');

		System.assertEquals(creditApproval.Approver4Role__c, controller.approvalSteps[3].stepName, 'Expected step name not returned');
		System.assertEquals('PENDING', controller.approvalSteps[3].status, 'Expected approval status not returned for pending approval');

		System.assertEquals(creditApproval.Approver5Role__c, controller.approvalSteps[4].stepName, 'Expected step name not returned');
		System.assertEquals('PENDING', controller.approvalSteps[4].status, 'Expected approval status not returned for pending approval');

		System.assertEquals(creditApproval.Approver6Role__c, controller.approvalSteps[5].stepName, 'Expected step name not returned');
		System.assertEquals('PENDING', controller.approvalSteps[5].status, 'Expected approval status not returned for pending approval');

	}
}