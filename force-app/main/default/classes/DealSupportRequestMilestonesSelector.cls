/* @author Dattaraj Deshmukh
 * @date 2022-06-02 
 * @group Tests
 * @test DealSupportRequstMilestoneSelector_Test
 * @tag Selector
 * @tag Deal Support Request Milestones
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-06-02 -dattaraj.deshmukh@slalom.com - Created  
 */
public with sharing class DealSupportRequestMilestonesSelector extends ApplicationSelector{
    
   

    public enum Options {
        WITH_RECORDTYPE, WITH_DEAL_SUPPORT_REQUEST
    }

    public static DealSupportRequestMilestonesSelector newInstance() {
        return (DealSupportRequestMilestonesSelector)Application.Selectors.newInstance(DealSupportRequestMilestonesSelector.class);
    }

    public static DealSupportRequestMilestonesSelector newInstance(Integer recordLimit) {
        return (DealSupportRequestMilestonesSelector)Application.Selectors.newInstance(DealSupportRequestMilestonesSelector.class).setLimit(recordLimit);
    }
  
    public virtual override SObjectType getSObjectType() {
        return DealSupportRequestMilestone__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            DealSupportRequestMilestone__c.Id, DealSupportRequestMilestone__c.DealSupportRequest__c, 
            DealSupportRequestMilestone__c.Stage__c, DealSupportRequestMilestone__c.Timeinminutes__c,DealSupportRequestMilestone__c.RecordTypeId
        };
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual List<DealSupportRequestMilestone__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on  Id's
     */
    public virtual List<DealSupportRequestMilestone__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(DealSupportRequestMilestone__c.Id + ' in :ids')).endConditions();
        return (List<DealSupportRequestMilestone__c>)Database.query(qb.toSoqlString());
    }

    /**
     * @description Run a simple query to get records based on DSR Ids
     */
    public virtual List<DealSupportRequestMilestone__c> selectByDSRId(Set<Id> ids, Set<Object> selectorOptions) {

        Id stageGatesRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('DealSupportRequestMilestone__c', new Set<String>{'StageGates'}).values()[0].Id;


        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
        .add(new QueryBuilder.SimpleCondition(DealSupportRequestMilestone__c.DealSupportRequest__c + ' in :ids'))
		.add(new QueryBuilder.CompareCondition(DealSupportRequestMilestone__c.RecordTypeId).eq(stageGatesRecordTypeId))
        .endConditions();
        return (List<DealSupportRequestMilestone__c>)Database.query(qb.toSoqlString());
    } 


    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
            builder.addRelatedFields(RecordTypesSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'RecordType');
        }

        if(selectorOptions.contains(Options.WITH_DEAL_SUPPORT_REQUEST)) {
            builder.addRelatedFields(DealSupportRequestsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'DealSupportRequest__r');
        }
       
        return builder;
    }
}