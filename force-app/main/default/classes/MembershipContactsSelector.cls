/**
*@author Ken McGuire
* @date 2022-10-18
* @group Selector
* @tag Selector
* @tag MembershipContact__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @test MembershipContactsSelector_Test
* @changelog
* 2022-10-18 - Ken McGuire - Created
 */
public virtual inherited sharing class MembershipContactsSelector extends ApplicationSelector {
    
    public static final String MEMBERSHIP_CONTACT_STATUS_COMPLETED = 'Completed';
    
    public enum Options {
    }
    
    public static MembershipContactsSelector newInstance() {
        return (MembershipContactsSelector)Application.Selectors.newInstance(MembershipContactsSelector.class);
    }

    public static MembershipContactsSelector newInstance(Integer recordLimit) {
        return (MembershipContactsSelector)Application.Selectors.newInstance(MembershipContactsSelector.class).setLimit(recordLimit);
    }

    public override SObjectType getSObjectType() {
        return MembershipContact__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            MembershipContact__c.Id, MembershipContact__c.Status__c, MembershipContact__c.LastStatusChangedDate__c
        };
    }

    /**
	 * @description Run a simple query to get records based on Id's
	 */
    public Map<Id, MembershipContact__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
	 * @description Run a simple query to get records based on Id's
	 */
    public Map<Id, MembershipContact__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(MembershipContact__c.Id + ' in :ids')).endConditions();
        return new Map<Id, MembershipContact__c>((List<MembershipContact__c>)Database.query(qb.toSoqlString()));
    }
    

    public List<AggregateResult> selectIncompleteMembershipsByMembershipIds(Set<Id> membershipIds, Set<Object> selectorOptions, Set<SObjectField> groupByFields) {
		setFieldOverrides(groupByFields); // need to reset the selected fields to only those that are grouped by. 
        selectorOptions.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
            .add(new QueryBuilder.SimpleCondition(MembershipContact__c.Membership__c + ' IN :membershipIds'))
            .add(new QueryBuilder.SimpleCondition(MembershipContact__c.CompletionDate__c + ' = NULL'))
            .add(new QueryBuilder.SimpleCondition(MembershipContact__c.Status__c + ' != :MEMBERSHIP_CONTACT_STATUS_COMPLETED'))
            .setConditionOrder('1 AND 2 AND 3')
            .endConditions();

        qb.addGroupBy(groupByFields);

        return (List<AggregateResult>)Database.query(qb.toSoqlString());
    }
    
}