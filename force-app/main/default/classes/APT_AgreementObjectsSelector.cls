/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Apttus__APTS_Agreement__c
* @domain Apttus
* @description A very simple selector class for Apttus__APTS_Agreement__c to check expiration date
*/
public virtual inherited sharing class APT_AgreementObjectsSelector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_AgreementObjectsSelector newInstance() {
        return (APT_AgreementObjectsSelector)Application.Selectors.newInstance(APT_AgreementObjectsSelector.class);
    }
    public static APT_AgreementObjectsSelector newInstance(Integer recordLimit) {
        return (APT_AgreementObjectsSelector)Application.Selectors.newInstance(APT_AgreementObjectsSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus__APTS_Agreement__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus__APTS_Agreement__c.Id,Apttus__APTS_Agreement__c.Contract_Expiration_Date__c
                };
           }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual List<Apttus__APTS_Agreement__c> selectByConfigId(Set<Id> configIds) {
        return selectByConfigId(configIds, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual List<Apttus__APTS_Agreement__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.ID + ' = :configIds'))
            .endConditions();
        return new List<Apttus__APTS_Agreement__c>((List<Apttus__APTS_Agreement__c>)Database.query(qb.toSoqlString()));
    }
    
}