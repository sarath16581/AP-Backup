/**************************************************
Type:         Selector class for AccountRelationship__c
@test AccountRelationshipSelector_Test
History:
--------------------------------------------------
2023-10-02    Ken McGuire - Created
**************************************************/
public virtual inherited sharing class AccountRelationshipSelector extends ApplicationSelector {

    public enum Options {
        WITH_PARENT_ACCOUNT,
        WITH_RELATED_ACCOUNT
    }

    public static AccountRelationshipSelector newInstance() {
        return (AccountRelationshipSelector) Application.Selectors.newInstance(AccountRelationshipSelector.class);
    }

    public static AccountRelationshipSelector newInstance(Integer recordLimit) {
        return (AccountRelationshipSelector) Application.Selectors.newInstance(AccountRelationshipSelector.class).setLimit(recordLimit);
    }

    public override SObjectType getSObjectType() {
        return AccountRelationship__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                AccountRelationship__c.Id, 
                AccountRelationship__c.Connection__c,
                AccountRelationship__c.EndDate__c, 
                AccountRelationship__c.ParentAccount__c, 
                AccountRelationship__c.RelatedAccount__c,
                AccountRelationship__c.Relationship__c
        };
    }

    public Map<Id, AccountRelationship__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    public Map<Id, AccountRelationship__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(AccountRelationship__c.Id + ' in :ids')).endConditions();
        return new Map<Id, AccountRelationship__c>((List<AccountRelationship__c>) Database.query(qb.toSoqlString()));
    }
    
	public List<AccountRelationship__c> selectByParent(Set<Id> parentAccountsToInclude) {
		return selectByParent(parentAccountsToInclude, new Set<Object>());
	}

	public List<AccountRelationship__c> selectByParent(Set<Id> parentAccountsToInclude, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.InCondition(AccountRelationship__c.ParentAccount__c).inCollection(parentAccountsToInclude))
		.endConditions();
		return (List<AccountRelationship__c>) Database.query(qb.toSoqlString());
	}

	public List<AccountRelationship__c> selectByOPCParentEndDateInFuture(Set<Id> parentAccountsToInclude) {
		return selectByOPCParentEndDateInFuture(parentAccountsToInclude, new Set<Object>());
	}

	public List<AccountRelationship__c> selectByOPCParentEndDateInFuture(Set<Id> parentAccountsToInclude, Set<Object> selectorOptions) {
		Date todaysDate = System.today();
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.InCondition(AccountRelationship__c.ParentAccount__c).inCollection(parentAccountsToInclude))
				.add(new QueryBuilder.CompareCondition(AccountRelationship__c.Relationship__c).eq('OPC'))
				.add(new QueryBuilder.NullCondition(AccountRelationship__c.EndDate__c).isNull())
				.add(new QueryBuilder.SimpleCondition('EndDate__c > :todaysDate'))
				.setConditionOrder('1 AND 2 AND (3 OR 4)')
				.endConditions();
		return (List<AccountRelationship__c>) Database.query(qb.toSoqlString());
	}

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_PARENT_ACCOUNT)) {
            builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'ParentAccount__r');
        }

        if(selectorOptions.contains(Options.WITH_RELATED_ACCOUNT)) {
            builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'RelatedAccount__r');
        }

        return builder;
    }
}