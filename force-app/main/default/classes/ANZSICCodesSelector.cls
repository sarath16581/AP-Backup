/**
* @description       : Selector class for ANZSIC Code object
* @author            : Victor Cheng
* @group             :
* @last modified on  : 30-03-2021
* @last modified by  : victor.cheng@auspost.com.au
* Modifications Log
* Ver   Date         Author                               Modification
* -------------------------------------------------------------------------
* 1.0   30-03-2021  Victor Cheng   Initial Version
**/

public virtual inherited sharing class ANZSICCodesSelector extends ApplicationSelector {

    public static ANZSICCodesSelector newInstance() {
        return (ANZSICCodesSelector)Application.Selectors.newInstance(ANZSICCodesSelector.class);
    }

    public virtual override SObjectType getSObjectType() {
        return ANZSIC_Code__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                ANZSIC_Code__c.Id, ANZSIC_Code__c.Name,ANZSIC_Code__c.ANZSIC_Division__c, ANZSIC_Code__c.Code_Description__c
        };
    }

    public virtual List<ANZSIC_Code__c> selectByTypeAndClass(String industryType, String industryClass) {
        QueryBuilder qb = newQueryBuilder();
        QueryBuilder.ConditionsManager cm = qb.conditionsManager;
        //cm.add(new QueryBuilder.SimpleCondition(ANZSIC_Code__c.ANZSIC_Division__c + ' = :industryType'));
        cm.add(new QueryBuilder.SimpleCondition('ANZSIC_Division__c LIKE \'' + industryType + '%\''));
        cm.add(new QueryBuilder.SimpleCondition(ANZSIC_Code__c.Code_Description__c + ' = :industryClass'));
        cm.endConditions();

        System.debug(qb.toSoqlString());
        return (List<ANZSIC_Code__c>)Database.query(qb.toSoqlString());
    }
}