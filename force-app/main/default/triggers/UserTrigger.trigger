trigger UserTrigger on Facility_User__c (after insert, after update, after delete) {
    if (trigger.isInsert) {
        UserSharingUtil.insertFacilityAndCaseShares(trigger.new);
    }
    if (trigger.isUpdate) {
        UserSharingUtil.updateFacilityAndCaseShares(trigger.new, trigger.old);
    }
    if (trigger.isDelete) {
        UserSharingUtil.deleteFacilityAndCaseShares(trigger.old);
    }
}