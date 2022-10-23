/* @author Seth Heang
* @date 2022-04-08
* @group Selector
* @tag Selector
* @tag Apttus_Config2__ProductAttributeValue__c
* @domain Apttus
* @description A very simple selector class for Apttus_Config2__ProductAttributeValue__c that sits in the Apttus domain
* 2022-05-20 - nasir.jawed@auspost.com.au - added the method to get the PAV record
*/
public virtual inherited sharing class APT_ProductAttributeValuesSelector extends ApplicationSelector {
    public enum Options {
        
    }

    public static APT_ProductAttributeValuesSelector newInstance() {
        return (APT_ProductAttributeValuesSelector)Application.Selectors.newInstance(APT_ProductAttributeValuesSelector.class);
    }
    
    public static APT_ProductAttributeValuesSelector newInstance(Integer recordLimit) {
        return (APT_ProductAttributeValuesSelector)Application.Selectors.newInstance(APT_ProductAttributeValuesSelector.class).setLimit(recordLimit);
    }

    public virtual override SObjectType getSObjectType() {
        return Apttus_Config2__ProductAttributeValue__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_Config2__ProductAttributeValue__c.Id,  Apttus_Config2__ProductAttributeValue__c.APT_Selected_Lodgement_Zone__c, Apttus_Config2__ProductAttributeValue__c.APT_Additional_Lodgement_Zone_1__c, 
            Apttus_Config2__ProductAttributeValue__c.APT_Additional_Lodgement_Zone_2__c, Apttus_Config2__ProductAttributeValue__c.Apttus_Config2__LineItemId__c,Apttus_Config2__ProductAttributeValue__c.APT_Customer_Tier__c,
            Apttus_Config2__ProductAttributeValue__c.APTS_Price_Structure__c ,Apttus_Config2__ProductAttributeValue__c.Applied_PSR__c,Apttus_Config2__ProductAttributeValue__c.SAP_Weight_Rounding__c,
            Apttus_Config2__ProductAttributeValue__c.SAP_Rating_Plan_DWT_Conversion_Factor__c,Apttus_Config2__ProductAttributeValue__c.SAP_Cubic_Conversion_Factor__c
            
        };
    }

    /**
     * @description Run a simple query to get records based on line item id
     */
    public virtual List<Apttus_Config2__ProductAttributeValue__c> selectByLineItemId(Set<Id> lineItemIds) {
        return selectByLineItemId(lineItemIds, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on line item id
     */
    public virtual List<Apttus_Config2__ProductAttributeValue__c> selectByLineItemId(Set<Id> lineItemIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductAttributeValue__c.Apttus_Config2__LineItemId__c + ' = :lineItemIds'))
            .endConditions();
        return new List<Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(qb.toSoqlString()));
    }

    public virtual List<Apttus_Config2__ProductAttributeValue__c> selectByPavID(List<Id> pavIds) {
        return selectByPavID( pavIds , new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Product attribute value id
     */
    public virtual List<Apttus_Config2__ProductAttributeValue__c> selectByPavID(List<Id> pavIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductAttributeValue__c.ID + ' = :pavIds'))
            .endConditions();
        return new List<Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(qb.toSoqlString()));
    }
    
    public virtual Map<Id, Apttus_Config2__ProductAttributeValue__c> selectByconfigIDAndLineType(List<Id> configIDs) {
        List<string> linetypes = new List<string>{'Product/Service'}; 
        return selectByconfigIDAndLineType( configIDs , lineTypes , new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on line item id
     */
    public virtual Map<Id, Apttus_Config2__ProductAttributeValue__c> selectByconfigIDAndLineType(List<Id> configIDs, List<String> lineTypes, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);        
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition('Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c = :configIDs'))
            //.add(new QueryBuilder.SimpleCondition('Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c  = :lineTypes'))
            .endConditions();
    
        return new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(qb.toSoqlString()));
    }
    
    

}