public with sharing class brideas_UserProfileIdeasStatsCtrl {
    @AuraEnabled
    public static Integer getIdeasCountForUser(Id userId) {
        String cId = brideas_Helper.getCommunityId('');

        return [SELECT count() FROM Idea WHERE CreatedById = :userId AND CommunityId = :cId];
    }

    @AuraEnabled
    public static Integer getIdeaCommentsCountForUser(Id userId) {
        String cId = brideas_Helper.getCommunityId('');

        return [SELECT count() FROM IdeaComment WHERE CreatedById = :userId AND CommunityId = :cId];
    }

    @AuraEnabled
    public static Integer getIdeaVotesCountForUser(Id userId) {
        return [SELECT count() FROM Vote WHERE CreatedById = :userId AND Parent.Type = 'Idea'];
    }
}