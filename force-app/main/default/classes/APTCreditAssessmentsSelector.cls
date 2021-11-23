/**
* @description       : A very simple selector class that sits in the Core domain
* @author            : Victor Cheng
* @group             : 
* @last modified on  : 30/11/2020
* @last modified by  : Victor Cheng
* Modifications Log 
* Ver   Date         Author                               Modification
* -------------------------------------------------------------------------
* 1.0   30-11-2020  Victor Cheng   Initial Version
**/

public virtual inherited sharing class APTCreditAssessmentsSelector extends ApplicationSelector {
    public enum Options {
        WITH_RECORDTYPE, WITH_OWNER, WITH_ACTIVE_MEMBERSHIPS
    }

    public static APTCreditAssessmentsSelector newInstance() {
        return (APTCreditAssessmentsSelector)Application.Selectors.newInstance(APTCreditAssessmentsSelector.class);
    }
    public static APTCreditAssessmentsSelector newInstance(Integer recordLimit) {
        return (APTCreditAssessmentsSelector)Application.Selectors.newInstance(APTCreditAssessmentsSelector.class).setLimit(recordLimit);
    }

    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static APTCreditAssessmentsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        APTCreditAssessmentsSelector selector = (APTCreditAssessmentsSelector)Application.Selectors.newInstance(APTCreditAssessmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     *                          This approach removes data consistency and prevents possible caching of results
     */
    public static APTCreditAssessmentsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        APTCreditAssessmentsSelector selector = (APTCreditAssessmentsSelector)Application.Selectors.newInstance(APTCreditAssessmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    public override SObjectType getSObjectType() {
        return APT_Credit_Assessment__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                APT_Credit_Assessment__c.Id,
                APT_Credit_Assessment__c.Name,
                APT_Credit_Assessment__c.L2C_Assessment_Type__c,
                APT_Credit_Assessment__c.APT_ABN__c,
                APT_Credit_Assessment__c.APT_ACN__c,
                APT_Credit_Assessment__c.APT_Date_Commenced__c,
                APT_Credit_Assessment__c.APT_Entity_Type__c,
                APT_Credit_Assessment__c.APT_Legal_Entity_Name__c,
                APT_Credit_Assessment__c.APT_Business_Name__c,

                // address
                APT_Credit_Assessment__c.APT_Unit_Number__c,
                APT_Credit_Assessment__c.APT_Street_Type__c,
                APT_Credit_Assessment__c.APT_Street_Number__c,
                APT_Credit_Assessment__c.APT_Street_Name__c,
                APT_Credit_Assessment__c.APT_Suburb__c,
                APT_Credit_Assessment__c.APT_City__c,
                APT_Credit_Assessment__c.APT_State__c,
                APT_Credit_Assessment__c.APT_Country__c,
                APT_Credit_Assessment__c.APT_Postcode__c,
                APT_Credit_Assessment__c.APT_Telephone__c,
                APT_Credit_Assessment__c.APT_Fax__c,

                // Contact
                APT_Credit_Assessment__c.APT_Position_Title__c,
                APT_Credit_Assessment__c.APT_Contact_Name__c,
                APT_Credit_Assessment__c.APT_Email_Address__c,

                // Type of Business
                APT_Credit_Assessment__c.APT_Nature_of_Business__c,
                APT_Credit_Assessment__c.APT_Industry_Type__c,

                // lodgement - TODO

                // Business Reference
                APT_Credit_Assessment__c.APT_Reference_Business_Name_1__c,
                APT_Credit_Assessment__c.APT_Reference_Business_Name_2__c,
                APT_Credit_Assessment__c.APT_Reference_Business_Name_3__c,
                APT_Credit_Assessment__c.APT_Reference_Contact_Name_1__c,
                APT_Credit_Assessment__c.APT_Reference_Contact_Name_2__c,
                APT_Credit_Assessment__c.APT_Reference_Contact_Name_3__c,
                APT_Credit_Assessment__c.APT_Reference_Job_Title_1__c,
                APT_Credit_Assessment__c.APT_Reference_Job_Title_2__c,
                APT_Credit_Assessment__c.APT_Reference_Job_Title_3__c,
                APT_Credit_Assessment__c.APT_Reference_Phone_Number_1__c,
                APT_Credit_Assessment__c.APT_Reference_Phone_Number_2__c,
                APT_Credit_Assessment__c.APT_Reference_Phone_Number_3__c,

                // applicant
                APT_Credit_Assessment__c.APT_Applicant_1_Title__c,
                APT_Credit_Assessment__c.APT_Applicant_1_First_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Middle_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Last_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Title__c,
                APT_Credit_Assessment__c.APT_Applicant_2_First_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Middle_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Last_Name__c,

                APT_Credit_Assessment__c.APT_Applicant_1_Unit_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Street_Type__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Street_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Street_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Suburb__c,
                APT_Credit_Assessment__c.APT_Applicant_1_City__c,
                APT_Credit_Assessment__c.APT_Applicant_1_State__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Postcode__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Country__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Unit_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Street_Type__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Street_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Street_Name__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Suburb__c,
                APT_Credit_Assessment__c.APT_Applicant_2_City__c,
                APT_Credit_Assessment__c.APT_Applicant_2_State__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Postcode__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Country__c,

                APT_Credit_Assessment__c.APT_Applicant_1_Business_Premises__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Business_Premises__c,

                APT_Credit_Assessment__c.APT_Applicant_1_Telephone__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Telephone__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Drivers_Licence_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Drivers_Licence_Number__c,
                APT_Credit_Assessment__c.APT_Applicant_1_Date_of_Birth__c,
                APT_Credit_Assessment__c.APT_Applicant_2_Date_of_Birth__c,


                // credit limit
                APT_Credit_Assessment__c.L2C_AP_Proposed_Credit_Limit__c,

                // Ts&Cs

                // background data
                APT_Credit_Assessment__c.APT_Assessment_Type__c,
                APT_Credit_Assessment__c.APT_Holding_Company__c,
                APT_Credit_Assessment__c.APT_Holding_Company_Name__c,
                APT_Credit_Assessment__c.APT_Holding_Company_ACN__c,
                APT_Credit_Assessment__c.APT_Number_of_Employees__c,
                APT_Credit_Assessment__c.APT_Business_Premises__c,
                APT_Credit_Assessment__c.APT_Business_Type__c,
                APT_Credit_Assessment__c.APT_ABR_Report__c,
                APT_Credit_Assessment__c.APT_ASIC_Report__c,
                APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c,
                APT_Credit_Assessment__c.APT_Credit_Assessment_Complete__c,
                APT_Credit_Assessment__c.APT_Account_Type__c,

                // status
                APT_Credit_Assessment__c.APT_Status__c

        };
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, APT_Credit_Assessment__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, APT_Credit_Assessment__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Credit_Assessment__c.Id + ' in :ids')).endConditions();
        return new Map<Id, APT_Credit_Assessment__c>((List<APT_Credit_Assessment__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * @description Run a simple query to get records based on Legacy Id's
     */
    /*
    public Map<Id, APT_Credit_Assessment__c> selectByAPT_Credit_Assessment__cNumber(Set<String> APT_Credit_Assessment__cNumbers) {
        return selectByAPT_Credit_Assessment__cNumber(APT_Credit_Assessment__cNumbers, new Set<Object>());
    }

     */

    /**
     * @description Run a simple query to get records based on Legacy Id's
     */
    /*
    public Map<Id, APT_Credit_Assessment__c> selectByAPT_Credit_Assessment__cNumber(Set<String> APT_Credit_Assessment__cNumbers, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Credit_Assessment__c.LEGACY_ID__c + ' in :APT_Credit_Assessment__cNumbers')).endConditions();
        return new Map<Id, APT_Credit_Assessment__c>((List<APT_Credit_Assessment__c>)Database.query(qb.toSoqlString()));
    }

     */

    /**
     * @description Grabs a new QueryBuilder based on the selector options passed in
     */
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
            builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
        }

        if(selectorOptions.contains(Options.WITH_OWNER)) {
            builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
        }

        if(selectorOptions.contains(Options.WITH_ACTIVE_MEMBERSHIPS)) {
            builder.addSubQuery(MembershipsSelector.newInstance().newQueryBuilder(new Set<Object>{MembershipsSelector.Options.FILTER_ACTIVE_STATUS}), 'Memberships__r');
        }

        return builder;
    }

}