/***
 * A very simple selector class that sits in the base domain
 *
 * @author Disha Kariya
 * @date 2020-05-19
 * @group Selector
 * @tag Selector
 * @tag Assets
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-05-19 - Disha Kariya - Created
 */
public virtual inherited sharing class MyPostBusinessAssetsSelector  extends AssetsSelector {
    public enum Options {

    }

    /**
     * Return PSR record type Id
    */
    public Id psrRecordTypeId {
        get{
            if(psrRecordTypeId == null){
                for(RecordType pseRecordType : allMPBAssetRecordTypeIds.values()){
                    if(pseRecordType.DeveloperName.equalsIgnoreCase('PSR')){
                        psrRecordTypeId = pseRecordType.Id;
                    }
                }
            }
            return psrRecordTypeId;
        }set;
    }

    /**
     * Return All MPB record type Id
    */
    public Map<Id, RecordType> allMPBAssetRecordTypeIds {
        get{
            if(allMPBAssetRecordTypeIds == null){
                allMPBAssetRecordTypeIds = RecordTypesSelector.newInstance().selectByDeveloperName('Asset', new Set<String>{'PSR','TandC'});
            }
            return allMPBAssetRecordTypeIds;
        }set;
    }

    public static MyPostBusinessAssetsSelector newInstance() {
        return (MyPostBusinessAssetsSelector)Application.Selectors.newInstance(MyPostBusinessAssetsSelector.class);
    }
    public static MyPostBusinessAssetsSelector newInstance(Integer recordLimit) {
        return (MyPostBusinessAssetsSelector)Application.Selectors.newInstance(MyPostBusinessAssetsSelector.class).setLimit(recordLimit);
    }

    /**
     * Grab the base fields and extend by adding new fields specific to the domain of this selector
     */
    public virtual override Set<SObjectField> getSObjectFieldList() {
        Set<SObjectField> fields = super.getSObjectFieldList();
        fields.addAll(new Set<SObjectField>{
                Asset.Product_Hierarchy_Value__c, Asset.Tier_Type__c, Asset.Freeze_Period_Start_Date__c, Asset.Freeze_Period_End_Date__c, Asset.To_Be_Processed__c, Asset.Account_Legacy_Id__c, Asset.Product_Name__c
        });
        return fields;
    }

    /**
     * @description Run a query to get unprocessed PSR Assets based on accountIds
     */
    public Map<Id, Asset> selectPSRUnprocessedByAccounts(Set<Id> accountIds) {
        return selectPSRUnprocessedByAccounts(accountIds, new Set<Object>());
    }

    /**
     * @description Run a query to get unprocessed PSR Assets based on accountId
     */
    public Map<Id, Asset> selectPSRUnprocessedByAccounts(Set<Id> accountIds, Set<Object> selectorOptions) {
//        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Asset.AccountId + ' in :accountIds')).endConditions();
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
                .add(new QueryBuilder.SimpleCondition(Asset.AccountId + ' in :accountIds'))
                .add(new QueryBuilder.SimpleCondition(Asset.AccountId + ' != NULL'))
                .add(new QueryBuilder.SimpleCondition(Asset.To_Be_Processed__c + ' = false'))
                .add(new QueryBuilder.SimpleCondition(Asset.RecordTypeId + ' = :psrRecordTypeId'))
                .endConditions();
        return new Map<Id, Asset>((List<Asset>)Database.query(qb.toSoqlString()));
    }

    /**
     * @description Grabs a new QueryBuilder based on the selector options passed in
     */
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        builder.addConditions().add(new QueryBuilder.InCondition(Asset.RecordTypeId).inCollection(allMPBAssetRecordTypeIds.keySet())).endConditions();

        return builder;
    }
}