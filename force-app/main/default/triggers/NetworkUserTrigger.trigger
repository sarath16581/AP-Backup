trigger NetworkUserTrigger on Facility_User__c (after insert, after update, after delete, before insert, before update) {
    if (trigger.isAfter && trigger.isInsert) {
        NetworkUserSharingUtil.insertNetworkAndCaseShares(trigger.new);
    }
    if (trigger.isAfter && trigger.isUpdate) {
        NetworkUserSharingUtil.updateNetworkAndCaseShares(trigger.new, trigger.old);
    }
    if (trigger.isAfter && trigger.isDelete) {
        NetworkUserSharingUtil.deleteNetworkAndCaseShares(trigger.old);
    }
    if(trigger.isBefore && trigger.isInsert) {
        NetworkUserTriggerUtility.createNetworkUsers(trigger.new);
    }
}