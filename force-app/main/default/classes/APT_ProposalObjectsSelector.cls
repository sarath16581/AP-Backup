/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Apttus_Proposal__Proposal__c
* @domain Apttus
* @description A very simple selector class for Apttus_Proposal__Proposal__c to get createddate
* @changelog:
* 2022-05-30 - Seth Heang - updated getSObjectFieldList
* 2022-05-30 - Nasir JAwed Added method selectByConfigIds
* 2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
*/
public virtual inherited sharing class APT_ProposalObjectsSelector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_ProposalObjectsSelector newInstance() {
        return (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class);
    }
    public static APT_ProposalObjectsSelector newInstance(Integer recordLimit) {
        return (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class).setLimit(recordLimit);
    }
    
	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*						  This approach removes data consistency and prevents possible caching of results
	*/
	public static APT_ProposalObjectsSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		APT_ProposalObjectsSelector selector = (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
    
    public virtual override SObjectType getSObjectType() {
        return Apttus_Proposal__Proposal__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_Proposal__Proposal__c.Id,Apttus_Proposal__Proposal__c.createddate,Apttus_Proposal__Proposal__c.Apttus_Proposal__Proposal_Expiration_Date__c,Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c
                };
                    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Apttus_Proposal__Proposal__c> selectByConfigId(Set<Id> configIds) {
        return selectByConfigId(configIds, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Apttus_Proposal__Proposal__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.ID + ' = :configIds'))
            .endConditions();
        return new Map<Id, Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
    }
    /**
     * @description Run a simple query to get records based on Proposal id
     */
    public virtual List<Apttus_Proposal__Proposal__c> selectByConfigIds(Set<Id> ProposalIds) {
        return selectByConfigIds(ProposalIds, new Set<Object>());
    }
  
    public virtual List<Apttus_Proposal__Proposal__c> selectByConfigIds(Set<Id> ProposalIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.ID + ' = :ProposalIds'))
            .endConditions();
        return new List<Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
    } 
    
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        return builder;
    }
    
}