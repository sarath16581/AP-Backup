/**
* @author Dish Kariya
* @date 2020-05-12
* @group Selector
* @tag Selector
* @tag Asset SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-05-12 - Disha Kariya - Created
*/
public virtual inherited sharing class AssetsSelector extends ApplicationSelector {

    public enum Options {
        WITH_RECORDTYPE
    }

    public static AssetsSelector newInstance() {
        return (AssetsSelector)Application.Selectors.newInstance(AssetsSelector.class);
    }
    public static AssetsSelector newInstance(Integer recordLimit) {
        return (AssetsSelector)Application.Selectors.newInstance(AssetsSelector.class).setLimit(recordLimit);
    }

    public override SObjectType getSObjectType() {
        return Asset.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                Asset.Id, Asset.Name, Asset.Status, Asset.Product2Id, Asset.AccountId
        };
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Asset> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Asset> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Asset.Id + ' in :ids')).endConditions();
        return new Map<Id, Asset>((List<Asset>)Database.query(qb.toSoqlString()));
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
            builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
        }
        return builder;
    }
}