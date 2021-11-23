/**
 * @description
 * Domain Module to handle the approver configuration functionality on an Credit Approval in Customer Resolutions domain .
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Domain
 * @domain CustomerResolutions
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created.
 */

public inherited sharing class CustomerResCreditApprovalMatrixModule extends ApplicationDomain.Module {

    public static CustomerResCreditApprovalMatrixModule newInstance() {
        return (CustomerResCreditApprovalMatrixModule)Application.Utilities.newInstance(CustomerResCreditApprovalMatrixModule.class);
    }

    // Setup which trigger events this module should respond to
    public CustomerResCreditApprovalMatrixModule() {
        getTriggerEvents().enableAfterUpdate();
    }

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {

        Map<Id, CreditApprovalMatrix__c> approvalMatrixRecordsWithApproverChanges = new Map<Id, CreditApprovalMatrix__c>();

        // get the set of updated fields for each record
        // pass in the approver fields on Credit Approval Matrix to monitor for updates
        Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{
                CreditApprovalMatrix__c.Approver_1__c, CreditApprovalMatrix__c.Approver1Role__c,
                CreditApprovalMatrix__c.Approver_2__c, CreditApprovalMatrix__c.Approver2Role__c,
                CreditApprovalMatrix__c.Approver_3__c, CreditApprovalMatrix__c.Approver3Role__c,
                CreditApprovalMatrix__c.Approver_4__c, CreditApprovalMatrix__c.Approver4Role__c,
                CreditApprovalMatrix__c.Approver_5__c, CreditApprovalMatrix__c.Approver5Role__c,
                CreditApprovalMatrix__c.Approver_6__c, CreditApprovalMatrix__c.Approver6Role__c
        });

        for (CreditApprovalMatrix__c approvalMatrix: (List<CreditApprovalMatrix__c>) records) {

            Set<SObjectField> changed = changedRecords.get(approvalMatrix.Id);
            if (changed == null) changed = new Set<SObjectField>();

            if (!changed.isEmpty()) {
                // changes are detected in monitored fields for this credit approval matrix record.
                approvalMatrixRecordsWithApproverChanges.put(approvalMatrix.Id, approvalMatrix);
            }
        }

        if (!approvalMatrixRecordsWithApproverChanges.isEmpty()) {
            // approvers on credit approval matrix has changed.
            // populate approvers on credit approvals linked to approval matrix records
            populateApproversOnLinkedCreditApprovals(approvalMatrixRecordsWithApproverChanges, uow);
        }
    }

    /**
     * Populate credit approvers on related credit approval records for the Credit Approval Matrix records passed in
     * @param creditApprovalMatrixRecords  parent credit approval matrix records
     * @param uow unit of work instance
     */
    private void populateApproversOnLinkedCreditApprovals(Map<Id, CreditApprovalMatrix__c> creditApprovalMatrixRecords, ApplicationUnitOfWork uow) {

        // grab the active credit approvals related to Credit Approval Matrix records passed in.
        Map<Id, Credit_Approval__c> activeCreditApprovals = CreditApprovalsSelector.newInstance().selectOpenCreditApprovalsByApprovalMatrixId(creditApprovalMatrixRecords.keySet());

        for (Credit_Approval__c creditApproval: activeCreditApprovals.values()) {

            if (creditApprovalMatrixRecords.containsKey(creditApproval.CreditApprovalMatrix__c)) {
                CreditApprovalMatrix__c approvalMatrix = creditApprovalMatrixRecords.get(creditApproval.CreditApprovalMatrix__c);
                Boolean isUpdated = reassignApproverDetails(creditApproval, Credit_Approval__c.Approver_1__c, Credit_Approval__c.Approver1Role__c, Credit_Approval__c.Approver1Complete__c, approvalMatrix.Approver_1__c, approvalMatrix.Approver1Role__c);
                isUpdated = (reassignApproverDetails(creditApproval, Credit_Approval__c.Approver_2__c, Credit_Approval__c.Approver2Role__c, Credit_Approval__c.Approver2Complete__c, approvalMatrix.Approver_2__c, approvalMatrix.Approver2Role__c) || isUpdated);
                isUpdated = (reassignApproverDetails(creditApproval, Credit_Approval__c.Approver_3__c, Credit_Approval__c.Approver3Role__c, Credit_Approval__c.Approver3Complete__c, approvalMatrix.Approver_3__c, approvalMatrix.Approver3Role__c) || isUpdated);
                isUpdated = (reassignApproverDetails(creditApproval, Credit_Approval__c.Approver_4__c, Credit_Approval__c.Approver4Role__c, Credit_Approval__c.Approver4Complete__c, approvalMatrix.Approver_4__c, approvalMatrix.Approver4Role__c) || isUpdated);
                isUpdated = (reassignApproverDetails(creditApproval, Credit_Approval__c.Approver_5__c, Credit_Approval__c.Approver5Role__c, Credit_Approval__c.Approver5Complete__c, approvalMatrix.Approver_5__c, approvalMatrix.Approver5Role__c) || isUpdated);
                isUpdated = (reassignApproverDetails(creditApproval, Credit_Approval__c.Approver_6__c, Credit_Approval__c.Approver6Role__c, Credit_Approval__c.Approver6Complete__c, approvalMatrix.Approver_6__c, approvalMatrix.Approver6Role__c) || isUpdated);

                if (isUpdated) {
                    //TODO pass in field set to update

                    // approver details updated for this credit approval. mark the record as dirty.
                    uow.registerDirty(creditApproval, false, 'CustomerResCreditApprovalMatrixModule.populateApproversOnLinkedCreditApprovals');
                }
            }
        }
    }

    private Boolean reassignApproverDetails(Credit_Approval__c creditApproval, SObjectField approverField, SObjectField approverRoleField, SObjectField approvalCompletedField, Id newApproverId, String newApproverRole) {
        String approvalCompleted = (String) creditApproval.get(approvalCompletedField);
        if ((String.isBlank(approvalCompleted) || approvalCompleted.equalsIgnoreCase('Pending'))
                && (creditApproval.get(approverField) == null || creditApproval.get(approverField) != creditApproval.Current_Approver_Name__c)) {
            creditApproval.put(approverField, newApproverId);
            creditApproval.put(approverRoleField, newApproverRole);
            return true;
        }
        return false;
    }

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
    public class Constructor implements ApplicationDomain.IConstructableModule {
        public ApplicationDomain.Module construct() {
            return (ApplicationDomain.Module)CustomerResCreditApprovalMatrixModule.newInstance();
        }
    }

}