/**
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Selector
 * @tag Selector
 * @tag Credit_Approval__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created
 */

public inherited sharing class CreditApprovalsSelector extends ApplicationSelector {

    public enum Options {
        WITH_APPROVERS, WITH_ACTUAL_APPROVERS
    }

    public static CreditApprovalsSelector newInstance() {
        return (CreditApprovalsSelector)Application.Selectors.newInstance(CreditApprovalsSelector.class);
    }
    public static CreditApprovalsSelector newInstance(Integer recordLimit) {
        return (CreditApprovalsSelector)Application.Selectors.newInstance(CreditApprovalsSelector.class).setLimit(recordLimit);
    }

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
    public static CreditApprovalsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        CreditApprovalsSelector selector = (CreditApprovalsSelector)Application.Selectors.newInstance(CreditApprovalsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * Run a simple query to get records based on Id's
     * @param ids record ids
     *
     * @return Credit Approval records
     */
    public virtual Map<Id, Credit_Approval__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * Run a simple query to get records based on Id's
     * @param ids record ids
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return Credit Approval records
     */
    public virtual Map<Id, Credit_Approval__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Case.Id + ' in :ids')).endConditions();
        return new Map<Id, Credit_Approval__c>((List<Credit_Approval__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * Run a simple query to get open credit approval requests based on credit approval matrix record Ids. Credit approval
     * record is still open when it hasn't reached a final state (i.e. in 'New' or 'Pending Approval Decision' status.
     *
     * @param creditApprovalMatrixIds parent Credit Approval Matrix ids
     *
     * @return collection of Credit_Approval__c records
     */
    public virtual Map<Id, Credit_Approval__c> selectOpenCreditApprovalsByApprovalMatrixId(Set<Id> creditApprovalMatrixIds) {
        return selectOpenCreditApprovalsByApprovalMatrixId(creditApprovalMatrixIds, new Set<Object>());
    }

    /**
     * Run a simple query to get open credit approval requests based on credit approval matrix record Ids. Credit approval
     * record is still open when it hasn't reached a final state (i.e. in 'New' or 'Pending Approval Decision' status.
     * Also supports passing in selector options to augment the result set returned.
     *
     * @param creditApprovalMatrixIds parent Credit Approval Matrix ids
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return collection of Credit_Approval__c records
     */
    public virtual Map<Id, Credit_Approval__c> selectOpenCreditApprovalsByApprovalMatrixId(Set<Id> creditApprovalMatrixIds, Set<Object> selectorOptions) {

        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
                .add(new QueryBuilder.SimpleCondition(Credit_Approval__c.CreditApprovalMatrix__c + ' in :creditApprovalMatrixIds'))
                .add(new QueryBuilder.InCondition(Credit_Approval__c.Status__c).inCollection(new List<String>{'New', 'Pending Approval Decision'}))
                .endConditions();

        return new Map<Id, Credit_Approval__c>((List<Credit_Approval__c>)Database.query(qb.toSoqlString()));
    }

    protected override SObjectType getSObjectType() {
        return Credit_Approval__c.getSObjectType();
    }

    protected override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                Credit_Approval__c.Id, Credit_Approval__c.Approver_1__c, Credit_Approval__c.Approver1Role__c, Credit_Approval__c.Approver1Complete__c, Credit_Approval__c.ActualApprover1User__c,
                Credit_Approval__c.Approver_2__c, Credit_Approval__c.Approver2Role__c, Credit_Approval__c.Approver2Complete__c, Credit_Approval__c.ActualApprover2User__c,
                Credit_Approval__c.Approver_3__c, Credit_Approval__c.Approver3Role__c, Credit_Approval__c.Approver3Complete__c, Credit_Approval__c.ActualApprover3User__c,
                Credit_Approval__c.Approver_4__c, Credit_Approval__c.Approver4Role__c, Credit_Approval__c.Approver4Complete__c, Credit_Approval__c.ActualApprover4User__c,
                Credit_Approval__c.Approver_5__c, Credit_Approval__c.Approver5Role__c, Credit_Approval__c.Approver5Complete__c, Credit_Approval__c.ActualApprover5User__c,
                Credit_Approval__c.Approver_6__c, Credit_Approval__c.Approver6Role__c, Credit_Approval__c.Approver6Complete__c, Credit_Approval__c.ActualApprover6User__c,
                Credit_Approval__c.AutoApprove__c, Credit_Approval__c.Credit_Amount__c, Credit_Approval__c.CreditAmountExclusiveGST__c, Credit_Approval__c.CreditAmountInclusiveGST__c,
                Credit_Approval__c.Status__c, Credit_Approval__c.CreditApprovalMatrix__c, Credit_Approval__c.Current_Approver_Name__c
        };
    }

    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if (selectorOptions.contains(Options.WITH_APPROVERS)) {
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'Approver_1__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'Approver_2__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'Approver_3__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'Approver_4__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'Approver_5__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'Approver_6__r');
        }

        if (selectorOptions.contains(Options.WITH_ACTUAL_APPROVERS)) {
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'ActualApprover1User__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'ActualApprover2User__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'ActualApprover3User__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'ActualApprover4User__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'ActualApprover5User__r');
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'ActualApprover6User__r');
        }

        return builder;
    }

}