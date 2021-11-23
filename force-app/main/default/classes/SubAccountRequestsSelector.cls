/* @author Seth Heang
 * @date 2021-04-05
 * @group Tests
 * @tag Selector
 * @tag Sub Account Requests, APT_Sub_Account__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-04-05 - seth.heang@auspost.com.au - Created
 */
public with sharing class SubAccountRequestsSelector extends ApplicationSelector{
    public enum Options {
        WITH_SUB_ACCOUNT_CONTACT
    }
    public static SubAccountRequestsSelector newInstance() {
        return (SubAccountRequestsSelector)Application.Selectors.newInstance(SubAccountRequestsSelector.class);
    }
    public static SubAccountRequestsSelector newInstance(Integer recordLimit) {
        return (SubAccountRequestsSelector)Application.Selectors.newInstance(SubAccountRequestsSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return APT_Sub_Account__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            APT_Sub_Account__c.Id, APT_Sub_Account__c.Name, APT_Sub_Account__c.APT_Account_Name_2__c,
            APT_Sub_Account__c.APT_Charge_Account__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Name__c,
            APT_Sub_Account__c.APT_Sub_Account_Contact_Telephone__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Email_Address__c,
            APT_Sub_Account__c.APT_Source_of_Sub_Account_Request__c, APT_Sub_Account__c.APT_Billing_Account_Number__c,
            APT_Sub_Account__c.Sub_Account_Name__c, APT_Sub_Account__c.Sub_Account_Number__c, APT_Sub_Account__c.Transaction_Id__c,
            APT_Sub_Account__c.APT_Sub_Account_Request_Status__c, APT_Sub_Account__c.Sub_Account_Request_Status_Description__c,
            APT_Sub_Account__c.Lodgement_Point_to_Work_Centre_Code__c,APT_Sub_Account__c.APT_eLMS_Enabled__c, APT_Sub_Account__c.APT_eParcel_Enabled__c,
            APT_Sub_Account__c.APT_Postal_Address_Street_Name__c, APT_Sub_Account__c.APT_Postal_Address_Suburb__c, 
            APT_Sub_Account__c.APT_Postal_Address_State__c, APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c,
            APT_Sub_Account__c.APT_Billing_Account__c, APT_Sub_Account__c.APT_Postal_Address_Country_Code__c, APT_Sub_Account__c.OwnerId, 
                APT_Sub_Account__c.Product__c, APT_Sub_Account__c.SubAccountContact__c
        };
    }

    /**
    * @description Run a simple query to get records based on Id's
    */
    public virtual Map<Id, APT_Sub_Account__c> selectById(Set<Id> ids) {
        return selectByIds(ids, new Set<Object>());
    }

    
    /**
    * @description Run a simple query to get records based on Id's
    */

    public virtual Map<Id, APT_Sub_Account__c> selectByIds(Set<Id> ids , Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.ID + ' in :ids')).endConditions();
        return new Map<Id, APT_Sub_Account__c>((List<APT_Sub_Account__c>)Database.query(qb.toSoqlString()));
    }
    
    /**
     * @description Run a simple query to get records based on charge Account request Id and status
     */
    public virtual Map<Id, APT_Sub_Account__c> selectByChargeAcountRequestIdAndStatus(Set<Id> ids, Set<String> status) {
        return selectByChargeAcountRequestIdAndStatus(ids, status, new Set<Object>());
    }
    
    /**
     * @description Run a simple query to get records based on charge Account request Id and status
     */

    public virtual Map<Id, APT_Sub_Account__c> selectByChargeAcountRequestIdAndStatus(Set<Id> ids, Set<String> status, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions)
            .addConditions()
            .add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Charge_Account__c + ' in :ids'))
            .add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Sub_Account_Request_Status__c + ' = :status'))
            .endConditions();
        return new Map<Id, APT_Sub_Account__c>((List<APT_Sub_Account__c>)Database.query(qb.toSoqlString()));
    }

    

    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }
    
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        
        if(selectorOptions.contains(Options.WITH_SUB_ACCOUNT_CONTACT)) {
            builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'SubAccountContact__r');
        }
        
        return builder;
    }
}