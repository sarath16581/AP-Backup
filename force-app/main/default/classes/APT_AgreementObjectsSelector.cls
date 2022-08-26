/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Apttus__APTS_Agreement__c
* @domain Apttus
* @description A very simple selector class for Apttus__APTS_Agreement__c to check expiration date
* @changelog:
* 2022-04-22 - Sri Harsha - Created
* 2022-05-30 - Seth Heang - updated getSObjectFieldList
* 2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
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
	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*						  This approach removes data consistency and prevents possible caching of results
	*/
	public static APT_AgreementObjectsSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		APT_AgreementObjectsSelector selector = (APT_AgreementObjectsSelector)Application.Selectors.newInstance(APT_AgreementObjectsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
    
    public virtual override SObjectType getSObjectType() {
        return Apttus__APTS_Agreement__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus__APTS_Agreement__c.Id,Apttus__APTS_Agreement__c.Contract_Expiration_Date__c, Apttus__APTS_Agreement__c.Apttus__Account__c
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