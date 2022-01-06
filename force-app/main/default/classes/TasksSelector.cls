/**
* @author Steve W.
* @date 2021-03-03
* @group Selector
* @tag Selector
* @tag Task SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2010-03-03 - Steve W - Created
* 2021-06-24 - Raman Saxena(Salesforce) - Added Priority field in getSObjectFieldList method and created a new method selectByWhatId - PBRP
*/
public virtual inherited sharing class TasksSelector extends ApplicationSelector {

    public enum Options {
        WITH_OWNER, WITH_CONTACT
    }

    public static TasksSelector newInstance() {
        return (TasksSelector)Application.Selectors.newInstance(TasksSelector.class);
    }

    public static TasksSelector newInstance(Integer offsetLimit) {
        return (TasksSelector)Application.Selectors.newInstance(TasksSelector.class).setOffset(offsetLimit);
    }

    public override SObjectType getSObjectType() {
        return Task.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                Task.Id, Task.Subject, Task.Description, Task.ActivityDate, Task.OwnerId, Task.WhatId,
                Task.WhoId, Task.Status, Task.Category__c, Task.Type, Task.IsClosed, Task.Priority
        };
    }
     /**
     * Run a SOQL based on the search parameters passed in
     *
     * @param searchParams A map containing searchable values:
     *                          
     * @param selectorOptions Selector Options
     * @param matchAll If true will search based on AND, else search based on OR
     * @return Map<Id, Task>
     */
    public Map<Id, Task> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
        QueryBuilder builder = newQueryBuilder(selectorOptions);
        // add our tracking query
        QueryBuilder.ConditionsManager conditions = builder.addConditions();

        String referenceDate = searchParams.get('ActivityDate') == null ? null : String.valueOf(searchParams.get('ActivityDate'));
        Id recordId = (searchParams.get('WhatId') == null ? null : Id.valueOf(String.valueOf(searchParams.get('WhatId'))));
        Boolean isClosed = (Boolean) searchParams.get('IsClosed');
        
        Integer conditionCount = 0;
        if(searchParams.containsKey('ActivityDate')) {
            conditions.add(new QueryBuilder.SimpleCondition('ActivityDate >= ' + referenceDate));
            conditionCount++;
        }
        if(searchParams.containsKey('WhatId')) {
            conditions.add(new QueryBuilder.SimpleCondition('WhatId =: recordId'));
            conditionCount++;
        }
        if(searchParams.containsKey('IsClosed')) {
            conditions.add(new QueryBuilder.SimpleCondition('IsClosed =: isClosed'));
            conditionCount++;
        }
        
        // build our condition string which would end up being something liek the following:
        // 1 AND 2 AND 3
        // 1 OR 2 OR 3
        String conditionOrder = '';
        for(Integer i=0;i<conditionCount;i++) {
            conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
        }
        conditions.setConditionOrder(conditionOrder);
        String soql = conditions.endConditions().toSoqlString();

        return new Map<Id, Task>((List<Task>)Database.query(soql));
    }
    /**
     * @description Run a simple query to get records based on Ids
     */
    public Map<Id, Task> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Ids
     */
    public Map<Id, Task> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Task.Id + ' in :ids')).endConditions();
        return new Map<Id, Task>((List<Task>)Database.query(qb.toSoqlString()));
    }
   
   /**
     * @description Run a simple query to get records based on what Ids | PBRP
     */
    public Map<Id, Task> selectByWhatId(Set<Id> whatIds) {
        QueryBuilder qb = newQueryBuilder(new Set<Object>()).addConditions().add(new QueryBuilder.SimpleCondition(Task.WhatId + ' in :whatIds')).endConditions();
        return new Map<Id, Task>((List<Task>)Database.query(qb.toSoqlString()));
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_CONTACT)) {
            builder.addRelatedFields(ContactsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Who');
        }

        if(selectorOptions.contains(Options.WITH_OWNER)) {
            builder.addRelatedFields(UsersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Owner');
        }

        return builder;
    }

    public virtual override List<QueryBuilder.Order> getOrderBy() {
        return new List<QueryBuilder.Order>{new QueryBuilder.Order('ActivityDate', 'Desc NULLS First')};
    }
}