public without sharing class IdeaTriggerHandler {

    public IdeaTriggerHandler(){
        if (!Trigger.isExecuting) throw new brideas_SecurityException('This code must run in trigger context only');
        brideas_SubscriptionTriggerHandler.hasFiredIdeaTrigger = true;
    }

    public void createSubscriptions(List<Idea> ideaList) {
        List<brideas_Subscription__c> subscrList = new List<brideas_Subscription__c>();

        for (Idea idea : ideaList) {
            subscrList.add(new brideas_Subscription__c(
                    Idea__c = idea.Id,
                    User__c = idea.CreatedById,
                    Token__c = brideas_Utils.generateToken(50)
                ));
        }

        insert subscrList;
    }

    public void moderateIdeas(List<Idea> ideaList) {
        List<brideas_Banned_Idea_Item__c> bannedIdeas = new List<brideas_Banned_Idea_Item__c>();
        brideas_EmailNotification emailNotification = new brideas_EmailNotification();

        for (Idea idea : ideaList) {
            if (brideas_Helper.isItemContainsForbiddenWords(idea.Title) || brideas_Helper.isItemContainsForbiddenWords(idea.Body)) {
                bannedIdeas.add(new brideas_Banned_Idea_Item__c(
                        Item_Id__c = String.valueOf(idea.Id),
                        Type__c = 'Idea post'
                ));

                emailNotification.addIdeaModeratedNotification(idea);
            }
        }

        insert bannedIdeas;
        emailNotification.sendEmails();
    }

    public void addReputationPointOnPostIdea(Integer countIdeas) {
        brideas_Helper.updateMemberReputation('postIdeaPoints', countIdeas);
    }

    public void deleteBannedItems(List<Idea> ideaList) {
        List<String> ideaIds = new List<String>();

        for(Idea idea: ideaList) {
            ideaIds.add(String.valueOf(idea.Id));
        }


        List<brideas_Banned_Idea_Item__c> bannedItems = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c IN :ideaIds AND Type__c = 'Idea post'];

        try {
            delete bannedItems;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            return ;
        }
    }

    public void sendNewIdeaNotifications(List<Idea> ideasList) {
        Map<String, List<String>> aMap = brideas_DataSelector.getAssignedUserEmailsByCategory();
        brideas_EmailNotification notificator = new brideas_EmailNotification();
        List<String> categories;
        Set<String> emailsList;

        for (Idea idea : ideasList) {
            categories = idea.Categories.split(';');
            emailsList = new Set<String>();

            for (String category : categories) {
                if (aMap.get(category) == NULL) continue;

                emailsList.addAll(aMap.get(category));
            }

            for (String em : emailsList) {
                notificator.addIdeaCreatedNotification(em, idea, 'NewIdeaNotificationToCategoryAssignee');
            }
        }

        notificator.sendEmails();
    }

    public void sendStatusChangeNotifications(List<Idea> ideasList, Map<Id, Idea> oldMap) {
        List<Idea> filteredList = new List<Idea>();

        for (Idea idea : ideasList) {
            if(idea.Status != oldMap.get(idea.Id).Status) {
                filteredList.add(idea);
            }
        }

        if (filteredList.isEmpty()) return;

        this.sendStatusChangeNotificationsToSubscribers(filteredList, oldMap);
        this.sendStatusChangeNotificationsToManagers(filteredList, oldMap);
    }

    private void sendStatusChangeNotificationsToSubscribers(List<Idea> ideasList, Map<Id, Idea> oldMap){
        brideas_EmailNotification notificator = new brideas_EmailNotification();
        String oldStatus;
        List<String> tmpEmailsList;
        Map<Id, List<String>> ideasEmailsMap = new Map<Id, List<String>>();
        List<brideas_Subscription__c> subscriptions = [
                SELECT Idea__c, Idea__r.Id, Idea__r.Title, Idea__r.Status, Idea__r.CommunityId, Idea__r.Body, User__r.Email
                FROM brideas_Subscription__c
                WHERE Idea__c IN :ideasList LIMIT 10000];

        for (brideas_Subscription__c subscr : subscriptions) {
            if (subscr.User__r.Email != null) {
                tmpEmailsList = ideasEmailsMap.get(subscr.Idea__c) != NULL ? ideasEmailsMap.get(subscr.Idea__c) : new List<String>();
                tmpEmailsList.add(subscr.User__r.Email);
                ideasEmailsMap.put(subscr.Idea__c, tmpEmailsList);
            }
        }

        for (Idea ideaItem : ideasList) {
            if (ideasEmailsMap.get(ideaItem.Id) == NULL) continue;

            oldStatus = oldMap.get(ideaItem.Id).Status != NULL ? oldMap.get(ideaItem.Id).Status : '';
            notificator.addStatusChangeNotification(ideasEmailsMap.get(ideaItem.Id), ideaItem, oldStatus, 'ChangeStatusNotificationToSubscriber');
        }

        notificator.sendEmails();
    }

    private void sendStatusChangeNotificationsToManagers(List<Idea> ideasList, Map<Id, Idea> oldMap){
        Map<String, List<String>> aMap = brideas_DataSelector.getAssignedUserEmailsByCategory();
        brideas_EmailNotification notificator = new brideas_EmailNotification();
        List<String> categories;
        Set<String> emailsList;
        String oldStatus;

        for (Idea idea : ideasList) {
            categories = idea.Categories.split(';');
            emailsList = new Set<String>();

            for (String category : categories) {
                if (aMap.get(category) == NULL) continue;

                emailsList.addAll(aMap.get(category));
            }

            if (emailsList.size() == 0) continue;

            oldStatus = oldMap.get(idea.Id).Status != NULL ? oldMap.get(idea.Id).Status : '';
            notificator.addStatusChangeNotification(new List<String>(emailsList), idea, oldStatus, 'ChangeStatusNotificationToCategoryAssignee');
        }

        notificator.sendEmails();
    }
}