/**
* @author Victor Cheng
* @date 2021-04-28
* @group Selector
* @tag Selector
* @tag Custom Settings
* @domain Core
* @description A polymorphic Selector Class for custom settings
* @changelog
* 2021-04-28 - Victor Cheng - Created
*/
public virtual inherited sharing class KnowledgeArticleVersionsSelector extends ApplicationSelector{

    public SObjectType settingsType = Business_Credit_Account__kav.SObjectType;
    public Set<SObjectField> fieldList {get; set;}

    public static KnowledgeArticleVersionsSelector newInstance(SObjectType sType, Set<SObjectField> fields){

        KnowledgeArticleVersionsSelector selector = (KnowledgeArticleVersionsSelector)Application.Selectors.newInstance(KnowledgeArticleVersionsSelector.class);
        selector.settingsType = sType;
        selector.fieldList = fields;

        return selector;
    }

    protected override SObjectType getSObjectType() {
        return settingsType;
    }

    protected override Set<SObjectField> getSObjectFieldList() {
        return fieldList;
    }

    public virtual List<SObject> selectByStatusLanguageType(String status, String language, String type)
    {
        // new query string
        QueryBuilder qb = newQueryBuilder();

        QueryBuilder.ConditionsManager cm = qb.conditionsManager;
        cm.add(new QueryBuilder.SimpleCondition('PublishStatus =: status'));
        cm.add(new QueryBuilder.SimpleCondition('Language =: language'));
        cm.add(new QueryBuilder.SimpleCondition('Type__c =: type'));
        cm.endConditions();
        List<SObject> queryResults = Database.query((qb.toSoqlString()));

        return queryResults;
    }
}