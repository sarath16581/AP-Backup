/**
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Selector
 * @tag Selector
 * @tag CreditApprovalMatrix__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created
 */

public inherited sharing class CreditApprovalMatrixSelector extends ApplicationSelector {

    public enum Options {
        WITH_APPROVERS, WITH_LASTMODIFIEDBYUSER
    }

    public static CreditApprovalMatrixSelector newInstance() {
        return (CreditApprovalMatrixSelector)Application.Selectors.newInstance(CreditApprovalMatrixSelector.class);
    }
    public static CreditApprovalMatrixSelector newInstance(Integer recordLimit) {
        return (CreditApprovalMatrixSelector)Application.Selectors.newInstance(CreditApprovalMatrixSelector.class).setLimit(recordLimit);
    }

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
    public static CreditApprovalMatrixSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        CreditApprovalMatrixSelector selector = (CreditApprovalMatrixSelector)Application.Selectors.newInstance(CreditApprovalMatrixSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * Select Credit Approval Matrix records by credit type, product family and product sub category.
     *
     * @param creditTypes type of credit
     * @param productFamilies  collection of product families to filter
     * @param productSubCategories collection of product sub categories to filter
     *
     * @return matching CreditApprovalMatrix__c records
     */
    public virtual Map<Id, CreditApprovalMatrix__c> selectByCreditTypeAndProduct(Set<String> creditTypes, Set<String> productFamilies, Set<String> productSubCategories) {
        return selectByCreditTypeAndProduct(creditTypes, productFamilies, productSubCategories, new Set<Object>());
    }

    /**
     * Run a simple query to get records based on credit type, product family and product sub category. Also supports
     * passing in selector options to augment the result set returned.
     * @param creditTypes type of credit
     * @param productFamilies collection of product families to filter
     * @param productSubCategories collection of product sub categories to filter
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching CreditApprovalMatrix__c records
     */
    public virtual Map<Id, CreditApprovalMatrix__c> selectByCreditTypeAndProduct(Set<String> creditTypes, Set<String> productFamilies, Set<String> productSubCategories, Set<Object> selectorOptions) {
        return new Map<Id, CreditApprovalMatrix__c>(selectByCreditTypeAndProductInOrder(creditTypes, productFamilies, productSubCategories, selectorOptions));
    }

    /**
     * Run a simple query to get records based on credit type, product family and product sub category. Also supports
     * passing in selector options to augment the result set returned.
     * @param creditTypes type of credit
     * @param productFamilies collection of product families to filter
     * @param productSubCategories collection of product sub categories to filter
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching CreditApprovalMatrix__c records
     */
    public virtual List<CreditApprovalMatrix__c> selectByCreditTypeAndProductInOrder(Set<String> creditTypes, Set<String> productFamilies, Set<String> productSubCategories, Set<Object> selectorOptions) {

        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
                .add(new QueryBuilder.SimpleCondition(CreditApprovalMatrix__c.CreditType__c + ' in :creditTypes'))
                .add(new QueryBuilder.SimpleCondition(CreditApprovalMatrix__c.Product_Family__c + ' in :productFamilies'))
                .add(new QueryBuilder.SimpleCondition(CreditApprovalMatrix__c.Product_Sub_Category__c + ' in :productSubCategories'))
                .endConditions();
        System.debug('***** query = ' + qb.toSoqlString());
        return (List<CreditApprovalMatrix__c>)Database.query(qb.toSoqlString());
    }

    public virtual Map<Id, CreditApprovalMatrix__c> selectByLastModifiedDate(Integer numberOfDays, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
                .add(new QueryBuilder.SimpleCondition(CreditApprovalMatrix__c.LastModifiedDate + ' >= LAST_N_DAYS:' + numberOfDays))
                .endConditions();
        return new Map<Id, CreditApprovalMatrix__c>((List<CreditApprovalMatrix__c>)Database.query(qb.toSoqlString()));
    }

    public virtual Database.QueryLocator selectByLastModifiedDateQueryLocator(Integer numberOfDays, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
                .add(new QueryBuilder.SimpleCondition(CreditApprovalMatrix__c.LastModifiedDate + ' >= LAST_N_DAYS:' + numberOfDays))
                .endConditions();
        return Database.getQueryLocator(qb.toSoqlString());
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

        if (selectorOptions.contains(Options.WITH_LASTMODIFIEDBYUSER)) {
            builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'LastModifiedBy');
        }

        return builder;
    }

    public override List<QueryBuilder.Order> getOrderBy() {
        return new List<QueryBuilder.Order>{new QueryBuilder.Order('ToCreditAmount__c', 'Asc'), new QueryBuilder.Order('LastModifiedDate', 'Desc')};
    }


    protected override SObjectType getSObjectType() {
        return CreditApprovalMatrix__c.getSObjectType();
    }

    protected override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                CreditApprovalMatrix__c.Id, CreditApprovalMatrix__c.CreditType__c, CreditApprovalMatrix__c.Product_Family__c,
                CreditApprovalMatrix__c.Product_Sub_Category__c, CreditApprovalMatrix__c.FromCreditAmount__c, CreditApprovalMatrix__c.ToCreditAmount__c,
                CreditApprovalMatrix__c.AutoApprove__c, CreditApprovalMatrix__c.Approver_1__c, CreditApprovalMatrix__c.Approver_2__c,
                CreditApprovalMatrix__c.Approver_3__c, CreditApprovalMatrix__c.Approver_4__c, CreditApprovalMatrix__c.Approver_5__c,
                CreditApprovalMatrix__c.Approver_6__c, CreditApprovalMatrix__c.Approver1Role__c, CreditApprovalMatrix__c.Approver2Role__c,
                CreditApprovalMatrix__c.Approver3Role__c, CreditApprovalMatrix__c.Approver4Role__c, CreditApprovalMatrix__c.Approver5Role__c,
                CreditApprovalMatrix__c.Approver6Role__c, CreditApprovalMatrix__c.LastModifiedDate
        };
    }
}