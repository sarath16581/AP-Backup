public with sharing class brideas_IdeaDetailCtrl {
    private static final Integer DEFAULT_ITEMS_PER_PAGE = 5;
    private static final Integer MAX_ITEMS_PER_PAGE = 500;

    @AuraEnabled
    public static Map<String, String> getUserInfo(){
        return brideas_Helper.getUserInfo();
    }

    @AuraEnabled
    public static brideas_IdeaWrapper getIdea(String recordId) {
        brideas_Helper.performAccessCheck('read');
        brideas_IdeaWrapper ideaWrapped = new brideas_IdeaWrapper();

        //if(String.isBlank(recordId)) return null;

        String queryFields = 'Title, Body, Status, Archive__c, CreatedDate, CreatedById, CreatedBy.Name, CreatorName, CreatorSmallPhotoUrl, Categories, ParentIdeaId, '
                + '(SELECT Type FROM Votes WHERE CreatedById = \''+ UserInfo.getUserId() +'\')';
        String query = 'SELECT ' + queryFields + ' FROM Idea WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'';

        Idea ideaItem = Database.query(query);

        ideaWrapped.item = ideaItem;
        ideaWrapped.statusColor = getStatusColor(ideaItem.Status);
        ideaWrapped.NumComments = getIdeaCommentsNumber(ideaItem.Id);
        ideaWrapped.votesNum = brideas_Helper.getIdeaVotesNumber(ideaItem.Id);
        ideaWrapped.voteStatus = ideaItem.Votes.size() == 1 ? 'voted' : '';

        Integer flagCount = [SELECT COUNT() FROM brideas_Flag__c WHERE IdeaId__c = :ideaItem.Id AND userId__c = : UserInfo.getUserId()];
        ideaWrapped.flagged = flagCount > 0 ? true : false;

        return ideaWrapped;
    }

    @AuraEnabled
    public static List<Idea> getMergedIdeas(String parentId) {
        brideas_Helper.performAccessCheck('read');

        return [SELECT Title, CreatedDate FROM Idea WHERE ParentIdeaId = :parentId ORDER BY CreatedDate DESC LIMIT 10];
    }

    @AuraEnabled
    public static String addVote(String ideaId) {
        return brideas_Helper.addVote(ideaId);
    }

    @AuraEnabled
    public static String getStatus(String ideaId) {
        brideas_Helper.performAccessCheck('read');

        if (String.isBlank(ideaId)) return 'error';

        return String.valueOf([SELECT Status, VoteTotal FROM Idea WHERE Id = :ideaId].Status);
    }

    @AuraEnabled
    public static Integer getIdeaCommentsNumber(String ideaId) {
        brideas_Helper.performAccessCheck('read_comments');

        if(String.isBlank(ideaId)) return null;

        String query = 'SELECT COUNT() FROM IdeaComment WHERE IdeaId = \'' + String.escapeSingleQuotes(ideaId) + '\'';

        List<String> bannedIdeaCommentIds = new List<String>(brideas_Helper.getBannedItemsIds('Idea comment'));

        if(!bannedIdeaCommentIds.isEmpty()) {
            query += ' AND Id NOT IN (\'' + String.join(bannedIdeaCommentIds, '\',\'') + '\')';
        }

        return Database.countQuery(query);
    }

    @AuraEnabled
    public static String getStatusColor(String status) {
        String statusColorsSettings = brideas_Helper.getConfigValue('status_colors');
        Map<String,String> statusColorsSettingsMap = (Map<String,String>)JSON.deserializeStrict(statusColorsSettings, Map<String,String>.class);

        if(statusColorsSettingsMap.containsKey(status)) {
            return statusColorsSettingsMap.get(status);
        }

        return null;
    }

    @AuraEnabled
    public static Boolean setFlagOnIdea(String IdeaId) {
        return brideas_Helper.setFlagOnIdea(IdeaId);
    }
    
    /*********************************************************************************
    * Created History: 2018-08-14  Rahul Kapoor 
    * Description:
    *      Method to fetch the user type information
    **********************************************************************************/
    @AuraEnabled
    public static String getUserTypeInfo() {
        if (UserInfo.getUserType() == 'Guest') {
           return 'auth_required'; 
        }else{
           return 'auth_not_required';  
        }
    }
}