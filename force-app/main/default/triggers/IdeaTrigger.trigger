trigger IdeaTrigger on Idea (after insert, after delete, after update ) {
    try {
        IdeaTriggerHandler hndlr = new IdeaTriggerHandler();

        if (Trigger.isAfter && Trigger.isInsert) {
            hndlr.createSubscriptions(Trigger.new);
            hndlr.moderateIdeas(Trigger.new);
            hndlr.addReputationPointOnPostIdea(Trigger.new.size());
            hndlr.sendNewIdeaNotifications(Trigger.new);

        } else if (Trigger.isAfter && Trigger.isUpdate) {
            hndlr.sendStatusChangeNotifications(Trigger.new, Trigger.oldMap);

        } else if(Trigger.isAfter && Trigger.isDelete) {
            hndlr.deleteBannedItems(Trigger.old);

        }
    } catch(Exception ex) {
        System.debug('IdeaTrigger error: ' + ex.getMessage());
    }
}