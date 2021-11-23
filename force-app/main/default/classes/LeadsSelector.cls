/* @author Seth Heang
 * @date 2021-08-12
 * @group Selector
 * @tag Selector
 * @tag Lead
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 */
public virtual inherited sharing class LeadsSelector extends ApplicationSelector {

    public enum Options {
    }

    public static LeadsSelector newInstance() {
        return (LeadsSelector)Application.Selectors.newInstance(LeadsSelector.class);
    }
    public static LeadsSelector newInstance(Integer recordLimit) {
        return (LeadsSelector)Application.Selectors.newInstance(LeadsSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Lead.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Lead.Id, Lead.Name, Lead.Email
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Lead> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Lead> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Lead.Id + ' in :ids')).endConditions();
        return new Map<Id, Lead>((List<Lead>)Database.query(qb.toSoqlString()));
    }
}