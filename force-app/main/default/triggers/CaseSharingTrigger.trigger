trigger CaseSharingTrigger on Case (after insert, after update) {
    if (trigger.isInsert) {
        //CaseSharingUtil.insertCaseShares(trigger.new);
        CaseSharingUtil.insertCaseTeamMembers(trigger.new);
    }
    if (trigger.isUpdate) {
        CaseSharingUtil.updateCaseShares(trigger.new, trigger.old);
    }
}