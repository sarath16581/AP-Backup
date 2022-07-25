/**
* @author George Nguyen
* @group Selector
* @tag Selector
* @tag ContactPoints
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2022-06-07 - George Nguyen - Created
*/
public virtual inherited sharing class ContactPointAddressSelector extends ApplicationSelector {
    
    public static ContactPointAddressSelector newInstance() {
        return (ContactPointAddressSelector)Application.Selectors.newInstance(ContactPointAddressSelector.class);
    }

    public override SObjectType getSObjectType() {
        return ContactPointAddress.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            ContactPointAddress.Id, 
            ContactPointAddress.Name, 
            ContactPointAddress.ParentId,
            ContactPointAddress.Contact__c,
            ContactPointAddress.Street,
            ContactPointAddress.Street2__c,
            ContactPointAddress.City,
            ContactPointAddress.PostalCode,
            ContactPointAddress.State,
            ContactPointAddress.Country,
            ContactPointAddress.AddressType
        };
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        selectorOptions.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        return builder;
    }

    public List<ContactPointAddress> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    public List<ContactPointAddress> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ContactPointAddress.Id + ' in :ids')).endConditions();
        return (List<ContactPointAddress>)Database.query(qb.toSoqlString());
    }

    public List<ContactPointAddress> selectByContactWithOtherOrMailingAddressType(Set<Id> contactIds) {
        QueryBuilder qb = newQueryBuilder(new Set<Object>()).addConditions()
            .add(new QueryBuilder.SimpleCondition(ContactPointAddress.Contact__c + ' in :contactIds'))
            .add(new QueryBuilder.SimpleCondition(ContactPointAddress.AddressType + ' = \'Other\''))
            .add(new QueryBuilder.SimpleCondition(ContactPointAddress.AddressType + ' = \'Mailing\''))
            .setConditionOrder('1 AND (2 OR 3)')
            .endConditions();

        qb.addOrder(new QueryBuilder.Order(ContactPointAddress.Contact__c))
            .addOrder(new QueryBuilder.Order(ContactPointAddress.AddressType))
            .addOrder(
                new QueryBuilder.Order(ContactPointAddress.LastModifiedDate)
                .setSortingOrderDesc()
            );

        return (List<ContactPointAddress>)Database.query(qb.toSoqlString());
    }
}