public without sharing class IdeaCommentTriggerHandler {

    public IdeaCommentTriggerHandler(){
        if (!Trigger.isExecuting) throw new brideas_SecurityException('This code must run in trigger context only');
    }

    public void moderateIdeaComments(List<IdeaComment> ideaCommentsList) {
        List<brideas_Banned_Idea_Item__c> bannedIdeaItems = new List<brideas_Banned_Idea_Item__c>();
        brideas_EmailNotification emailNotification = new brideas_EmailNotification();

        for (IdeaComment ideaComment : ideaCommentsList) {
            if (brideas_Helper.isItemContainsForbiddenWords(ideaComment.CommentBody)) {
                bannedIdeaItems.add(new brideas_Banned_Idea_Item__c(
                        Item_Id__c = String.valueOf(ideaComment.Id),
                        Type__c = 'Idea comment'
                ));

                emailNotification.addIdeaCommentModeratedNotification(ideaComment);
            }
        }

        insert bannedIdeaItems;
        emailNotification.sendEmails();
    }

    public void addReputationPointOnPostComment( Integer countComments) {
        brideas_Helper.updateMemberReputation('postCommentPoints', countComments);
    }

    public void deleteBannedItems(List<IdeaComment> ideaCommentsList) {
        List<String> ideaCommentIds = new List<String>();

        for(IdeaComment ic: ideaCommentsList) {
            ideaCommentIds.add(String.valueOf(ic.Id));
        }


        List<brideas_Banned_Idea_Item__c> bannedItems = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c IN :ideaCommentIds AND Type__c = 'Idea comment'];

        try {
            delete bannedItems;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            return ;
        }
    }

    public void sendNotificationsToSubscribers(List<IdeaComment> ideaCommentsList){
        Set<String> ideasSet = new Set<String>();
        brideas_EmailNotification notificator = new brideas_EmailNotification();
        Set<String> bannedCommentsIds = brideas_Helper.getBannedItemsIds('Idea comment');

        for(IdeaComment ic : ideaCommentsList) {
            ideasSet.add(ic.IdeaId);
        }

        Map<String, List<String>> ideasEmails = brideas_DataSelector.getSubscribersEmailsByIdeas(ideasSet, false);

        for (IdeaComment comment : ideaCommentsList) {
            if (ideasEmails.get(comment.IdeaId) == NULL) continue;
            if (bannedCommentsIds.contains(comment.Id)) continue;

            for (String usrEmail : ideasEmails.get(comment.IdeaId)) {
                notificator.addNewCommentNotification(usrEmail, comment, 'NewCommentNotificationToSubscriber');
            }
        }

        notificator.sendEmails();
    }

    public void sendNotificationsToAssignedUsers(List<IdeaComment> ideaCommentsList){
        brideas_EmailNotification notificator = new brideas_EmailNotification();
        Map<String, List<String>> aMap = brideas_DataSelector.getAssignedUserEmailsByCategory();
        Set<String> bannedCommentsIds = brideas_Helper.getBannedItemsIds('Idea comment');
        List<String> categories;
        Set<String> emailsList;

        for (IdeaComment comment : ideaCommentsList) {
            if (bannedCommentsIds.contains(comment.Id)) continue;
            categories = comment.Idea.Categories.split(';');
            emailsList = new Set<String>();

            for (String category : categories) {
                if (aMap.get(category) == NULL) continue;

                emailsList.addAll(aMap.get(category));
            }

            for (String em : emailsList) {
                notificator.addNewCommentNotification(em, comment, 'NewCommentNotificationToCategoryAssignee');
            }
        }

        notificator.sendEmails();
    }
}