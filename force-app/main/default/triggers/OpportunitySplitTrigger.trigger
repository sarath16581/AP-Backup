/*
 * @date 2020-10-01
 * @group Opportunities
 * @tag OpportunitySplit
 * @domain Core
 * @description Utility Class for OpportunitySplit trigger events
 * @changelog
 * 2020-10-01 - arjun.singh@auspost.com.au - Created
 */
trigger OpportunitySplitTrigger on OpportunitySplit (before insert, before delete, before update,after insert, after update, after delete, after undelete) {
    
    
    OpportunitySplitTriggerHandler.execute();  // Split handler dispatches appropriate event
}