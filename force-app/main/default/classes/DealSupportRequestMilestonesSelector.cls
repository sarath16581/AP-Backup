/* @author Dattaraj Deshmukh
 * @date 2022-06-02 
 * @group Tests
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
        return DealSupportRequestMilestones__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            DealSupportRequestMilestones__c.Id, DealSupportRequestMilestones__c.Deal_Support_Request__c, 
            DealSupportRequestMilestones__c.Stage__c, DealSupportRequestMilestones__c.Time_in_minutes__c,DealSupportRequestMilestones__c.RecordTypeId
        };
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, DealSupportRequestMilestones__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on  Id's
     */
    public virtual Map<Id, DealSupportRequestMilestones__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(DealSupportRequestMilestones__c.Id + ' in :ids')).endConditions();
        return new Map<Id, DealSupportRequestMilestones__c>((List<DealSupportRequestMilestones__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * @description Run a simple query to get records based on DSR Ids
     */
    public virtual Map<Id, DealSupportRequestMilestones__c> selectByDSRId(Set<Id> ids, Set<Object> selectorOptions) {

        Id stageGatesRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('DealSupportRequestMilestones__c', new Set<String>{'Stage_Gates'}).values()[0].Id;


        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
        .add(new QueryBuilder.SimpleCondition(DealSupportRequestMilestones__c.Deal_Support_Request__c + ' in :ids'))
		.add(new QueryBuilder.CompareCondition(DealSupportRequestMilestones__c.RecordTypeId).eq(stageGatesRecordTypeId))
        .endConditions();
        System.debug('Query for DSR Milestone Selector: '+qb.toSoqlString());
        return new Map<Id, DealSupportRequestMilestones__c>((List<DealSupportRequestMilestones__c>)Database.query(qb.toSoqlString()));
    } 


    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
            builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
        }

        if(selectorOptions.contains(Options.WITH_DEAL_SUPPORT_REQUEST)) {
            builder.addRelatedFields(DealSupportRequestsSelector.newInstance().newQueryBuilder(), 'Deal_Support_Request__r');
        }
       
        return builder;
    }
}