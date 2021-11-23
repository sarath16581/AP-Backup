trigger IdeaCommentTrigger on IdeaComment (after insert, after delete) {
    try {
        IdeaCommentTriggerHandler hndlr = new IdeaCommentTriggerHandler();

        if (Trigger.isAfter && Trigger.isInsert) {
            // Updated to retrieve CreatorName to use Nicknames in notifications to external users - Communities
            List<IdeaComment> comments = [SELECT IdeaId, CreatedById, CommentBody, Idea.Categories, Idea.Title, Idea.CommunityId, CreatorName FROM IdeaComment WHERE Id IN :Trigger.new];

            hndlr.moderateIdeaComments(comments);
            hndlr.addReputationPointOnPostComment(Trigger.new.size());
            hndlr.sendNotificationsToSubscribers(comments);
            hndlr.sendNotificationsToAssignedUsers(comments);

        } else if (Trigger.isAfter && Trigger.isDelete) {
            hndlr.deleteBannedItems(Trigger.old);
        }
    } catch(Exception ex) {
        System.debug('IdeaCommentTrigger error: ' + ex.getMessage());
    }
}