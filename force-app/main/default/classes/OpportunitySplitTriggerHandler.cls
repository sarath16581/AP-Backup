/*
 * @date 2020-10-01
 * @group Opportunities
 * @tag OpportunitySplit
 * @domain Core
 * @description Utility Class for OpportunitySplit trigger events
 * @changelog
 * 2020-10-01 - arjun.singh@auspost.com.au - Created
 * 2021-24-02 - dheeraj.mandavilli@auspost.com.au - Added method in before Insert to Populate "Split Member Role at Opportunity Closure" Field when
 *                                                  when a split member is added on Closed Opportunity.
 */
public with sharing class OpportunitySplitTriggerHandler {
    // class Variables
    private static OpportunitySplitUtility opportunitySplitUtil;    // Helper class variable to call methods based on scenario

     public static void execute(){
        
        opportunitySplitUtil = new OpportunitySplitUtility();
        
        // Check for event type of trigger
        if(Trigger.isBefore){
            beforeHandler();        // invoke of before handler
        }
        if(Trigger.isAfter){
            afterHandler();        // invoke of before handler
        }
    }

    private static void beforeHandler(){
         if(Trigger.isInsert){
                System.debug('Trigger.new>>>'+Trigger.new);
                opportunitySplitUtil.populateOpportunityOwnerRole(Trigger.new);
                opportunitySplitUtil.populateSplitMemberRoleAtOpportunityClosure(Trigger.new);
         }
    }
    private static void afterHandler(){
        if(Trigger.isInsert){
                System.debug('Calling>>>Insert');
                System.debug('Trigger.new>>>'+Trigger.new);
                opportunitySplitUtil.opportunitySplitValidations(Trigger.new, null);
                opportunitySplitUtil.updateTeamMemberRole(Trigger.new, null); 
                opportunitySplitUtil.createOpportunitySplitHistory(Trigger.new);             
        }else if(Trigger.isUpdate){
                System.debug('Calling>>>Update');
                System.debug('Trigger.new>>>'+Trigger.new);
                opportunitySplitUtil.opportunitySplitValidations(Trigger.new, (Map<Id,OpportunitySplit>)Trigger.oldMap);
                opportunitySplitUtil.updateTeamMemberRole(Trigger.new, (Map<Id,OpportunitySplit>)Trigger.oldMap);                
                opportunitySplitUtil.createOpportunitySplitHistory(Trigger.new);
                
         }else if(Trigger.isDelete){
            System.debug('Calling>>>Delete');
            opportunitySplitUtil.createOpportunitySplitHistoryOnDelete(Trigger.old);
        }
    }
}