/**
* @author Nasir Jawed
* @date 2022-12-06
* @description APT_RelatedAgreementsSelector helps to get record for the objects.
* @changelog 
*/

public virtual inherited sharing class APT_RelatedAgreementsSelector extends ApplicationSelector {
	public enum Options {
        WITH_AGREEMENT
    }
    
    public static APT_RelatedAgreementsSelector newInstance() {
        return (APT_RelatedAgreementsSelector)Application.Selectors.newInstance(APT_RelatedAgreementsSelector.class);
    }
    public static APT_RelatedAgreementsSelector newInstance(Integer recordLimit) {
        return (APT_RelatedAgreementsSelector)Application.Selectors.newInstance(APT_RelatedAgreementsSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus__APTS_Related_Agreement__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus__APTS_Related_Agreement__c.Id,Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_From__c,Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_To__c,
            Apttus__APTS_Related_Agreement__c.LastModifiedDate
		};
    }
    
    /**
    * @description Run a simple query to get records based on Apttus shopping cart config Id's
    */
    public virtual List<Apttus__APTS_Related_Agreement__c> selectByAgreementId(Set<ID> agreementIds) {
        return selectByAgreementId(agreementIds, new Set<Object>());
    }
    
    /**
    * @description Run a simple query to get records based on Apttus shopping cart config Id's
    */
    public virtual List<Apttus__APTS_Related_Agreement__c> selectByAgreementId(Set<ID> agreementIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_To__c + ' = :agreementIds'))
            .endConditions();
            qb.addOrderDesc(Apttus__APTS_Related_Agreement__c.LastModifiedDate );
        return new List<Apttus__APTS_Related_Agreement__c>((List<Apttus__APTS_Related_Agreement__c>)Database.query(qb.toSoqlString()));
    }
    
     public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);        
        if(selectorOptions.contains(Options.WITH_AGREEMENT)) {
            builder.addRelatedFields(APT_AgreementObjectsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus__APTS_Contract_From__r');
        }
        return builder;
    }
}