/*
* Author: 		Angelo Rivera
* Name: 		CreditApprovalWorkflowBlueBarController
* Description: 	Controller for CreditApprovalWorkflowBlueBar Page
* Revision History
* 07-13-2017 	1.0		AP.Rivera		Created
* 12-05-2021 - Ranjeewa Silva - Refactored to use new fields on Credit_Approval__c in rendering approval workflow.
*/
public with sharing class CreditApprovalWorkflowBlueBarController {

	@TestVisible private static final String AUTO_APPROVAL_STEP_NAME = 'Auto Approved';

	// list of approval steps applicable to this Credit_Approval__c record
	public List<ApprovalStep> approvalSteps {get;set;}

	public CreditApprovalWorkflowBlueBarController(ApexPages.StandardController stdController) {

		// query all approval related fields on Credit Approval record
		Credit_Approval__c creditApproval = CreditApprovalsSelector.newInstance().selectById(new Set<Id>{stdController.getId()}, new Set<Object>{CreditApprovalsSelector.Options.WITH_APPROVERS, CreditApprovalsSelector.Options.WITH_ACTUAL_APPROVERS}).values()[0];

		approvalSteps = new List<ApprovalStep>();

		//TODO - Credit Approvals with status = INVALID ????

		if (creditApproval.AutoApprove__c) {
			// credit approval record is auto approved.
			approvalSteps.add(new ApprovalStep(AUTO_APPROVAL_STEP_NAME, (creditApproval.Status__c == 'Approved' ? 'Approved' : 'Pending'), null, null));
		} else if (String.isNotBlank(creditApproval.Approver1Role__c)) {

			// populate details of approval step 1
			approvalSteps.add(new ApprovalStep(creditApproval.Approver1Role__c, creditApproval.Approver1Complete__c, creditApproval.Approver_1__r, creditApproval.ActualApprover1User__r));

			if (String.isNotBlank(creditApproval.Approver2Role__c)) {
				// populate details of approval step 2
				approvalSteps.add(new ApprovalStep(creditApproval.Approver2Role__c, creditApproval.Approver2Complete__c, creditApproval.Approver_2__r, creditApproval.ActualApprover2User__r));
			}

			if (String.isNotBlank(creditApproval.Approver3Role__c)) {
				// populate details of approval step 3
				approvalSteps.add(new ApprovalStep(creditApproval.Approver3Role__c, creditApproval.Approver3Complete__c, creditApproval.Approver_3__r, creditApproval.ActualApprover3User__r));
			}

			if (String.isNotBlank(creditApproval.Approver4Role__c)) {
				// populate details of approval step 4
				approvalSteps.add(new ApprovalStep(creditApproval.Approver4Role__c, creditApproval.Approver4Complete__c, creditApproval.Approver_4__r, creditApproval.ActualApprover4User__r));
			}

			if (String.isNotBlank(creditApproval.Approver5Role__c)) {
				// populate details of approval step 5
				approvalSteps.add(new ApprovalStep(creditApproval.Approver5Role__c, creditApproval.Approver5Complete__c, creditApproval.Approver_5__r, creditApproval.ActualApprover5User__r));
			}

			if (String.isNotBlank(creditApproval.Approver6Role__c)) {
				// populate details of approval step 6
				approvalSteps.add(new ApprovalStep(creditApproval.Approver6Role__c, creditApproval.Approver6Complete__c, creditApproval.Approver_6__r, creditApproval.ActualApprover6User__r));
			}
		}
	}

	public class ApprovalStep {
		public String status {get;set;}
		public String stepName {get;set;}		
		public String approver {get;set;}

		public ApprovalStep(){
		}

		public ApprovalStep(String stepName, String approvalStatus, User approver, User actualApprover) {
			this.stepName = stepName;
			if (approvalStatus == 'Approved') {
				this.approver = (actualApprover != null ? actualApprover.FirstName + ' ' + actualApprover.LastName : '');
				this.status = 'APPROVED';
			} else if (approvalStatus == 'Rejected') {
				this.approver = (actualApprover != null ? actualApprover.FirstName + ' ' + actualApprover.LastName : '');
				this.status = 'REJECTED';
			} else {
				this.approver = (approver != null ? approver.FirstName + ' ' + approver.LastName : '');
				this.status = 'PENDING';
			}
		}
	}
}