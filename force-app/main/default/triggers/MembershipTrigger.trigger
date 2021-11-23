/*------------------------------------------------------------
Author:        Adrian Recio (adrian.recio@auspost.com.au)
Description:   Main handler trigger for Membership Object
Test Class:    MembershipTriggerHandler_Test
History
15/5/2018     Adrian Recio (adrian.recio@auspost.com.au)         Created trigger methods for before and after insert and udpate

------------------------------------------------------------*/

trigger MembershipTrigger on Membership__c (before insert, before update, 
                                            after insert, after update) {
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if (Trigger.IsBefore) {
            if (Trigger.IsInsert) {
                MembershipTriggerHandler.beforeInsertTriggerHandler(Trigger.new);
            }
            if (Trigger.IsUpdate) {
                MembershipTriggerHandler.beforeUpdateTriggerHandler(Trigger.new, Trigger.oldMap);
            }
        }

        if (Trigger.IsAfter) {
            if (Trigger.IsInsert) {
                MembershipTriggerHandler.afterInsertTriggerHandler(Trigger.new);
            }
            if (Trigger.IsUpdate) {
                MembershipTriggerHandler.afterUpdateTriggerHandler(Trigger.new);
            }
        }
    }
}