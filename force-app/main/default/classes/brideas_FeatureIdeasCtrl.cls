public with sharing class brideas_FeatureIdeasCtrl {
    
    @AuraEnabled
    public static List<brideas_IdeaWrapper> getIdeas(Integer ideasNumber, String pageName) {
        String field;
        if (pageName == 'Home') {
            field = 'Homepage__c';
        }
        else if(pageName == 'Featured') {
            field = 'Featured__c';
        }

        List<Idea> ideas = Database.query('SELECT Title FROM Idea WHERE ' + field + ' = true ORDER BY CreatedDate DESC LIMIT ' + ideasNumber);
        List<String> ideaIds = new List<String>();
        
        for(Idea i: ideas) {
            ideaIds.add(i.Id);
        }

        Map<String, Integer> ideasVotesNumMap = brideas_Helper.getIdeasVotesNumber(ideaIds);
        List<brideas_IdeaWrapper> ideasWrapped = new List<brideas_IdeaWrapper>();

        for (Idea idea : ideas) {
            brideas_IdeaWrapper ideaWrapped = new brideas_IdeaWrapper();
            ideaWrapped.item = idea;
            ideaWrapped.votesNum = ideasVotesNumMap.get(idea.Id) != NULL ? ideasVotesNumMap.get(idea.Id) : 0;
            ideasWrapped.add(ideaWrapped);
        }

        return ideasWrapped;
    }
    
    /*********************************************************************************
    * Created History: 2018-07-30  Rahul Kapoor 
    * Description:
    *      Method to fetch the user information from the helper class.
    **********************************************************************************/
    @AuraEnabled
    public static Map<String, String> getUserInfo(){
        return brideas_Helper.getUserInfo();
    }
    
    /*********************************************************************************
    * Created History: 2018-07-30  Rahul Kapoor 
    * Description:
    *      Method to fetch the top featured idea details to display on the Community
    *      Home Page.
    **********************************************************************************/
    @AuraEnabled
    public static List<brideas_IdeaWrapper> getTopFeaturedIdeas(Integer ideasNumber, String pageName, String orderBy) {
        String field;
        if (pageName == 'Home') {
            field = 'Homepage__c';
        }
        else if(pageName == 'Featured') {
            field = 'Featured__c';
        }
        String queryOrderBy = brideas_Helper.compileOrderByStatement(orderBy);
        //Fetch the ideas based on filter condiitons.
        List<Idea> ideas = Database.query('SELECT Title,Body,Status,CreatedDate, CreatedById, CreatedBy.Name, CreatorName, CreatorSmallPhotoUrl, Categories, ParentIdeaId,VoteTotal, (SELECT Type FROM Votes WHERE CreatedById = \''+ UserInfo.getUserId() +'\') FROM Idea WHERE ' + field + ' = true ORDER BY ' + queryOrderBy + ' LIMIT ' + ideasNumber);
        List<String> ideaIds = new List<String>();
        
        for(Idea i: ideas) {
            ideaIds.add(i.Id);
        }

        //Fetch the status colors on the idea.
        Map<String, String> statusColorsMap = getStatusColors();
        //Fetch the number of comments on the idea.
        Map<String, Integer> ideasIdcommentsNumMap = getCommentNumberForIdeas(ideaIds);
        //Fetch the number of votes on the idea.
        Map<String, Integer> ideasVotesNumMap = brideas_Helper.getIdeasVotesNumber(ideaIds);
        List<brideas_IdeaWrapper> ideasWrapped = new List<brideas_IdeaWrapper>();

        //Loop through the ideas list.
        for (Idea idea : ideas) {
            brideas_IdeaWrapper ideaWrapped = new brideas_IdeaWrapper();
            ideaWrapped.item = idea;
            ideaWrapped.voteStatus = idea.Votes.size() == 1 ? 'voted' : '';
            ideaWrapped.votesNum = ideasVotesNumMap.get(idea.Id) != NULL ? ideasVotesNumMap.get(idea.Id) : 0;

            if(statusColorsMap.containsKey(idea.Status)) {
                ideaWrapped.statusColor = statusColorsMap.get(idea.Status);
            }
            
            if(ideasIdcommentsNumMap.containsKey(idea.Id)) {
                ideaWrapped.NumComments = ideasIdcommentsNumMap.get(idea.Id);
            }

            ideasWrapped.add(ideaWrapped);
        }

        return ideasWrapped;
    }

    /*********************************************************************************
    * Created History: 2018-07-30  Rahul Kapoor 
    * Description:
    *      Method to fetch the number of comments on the idea to display on the 
    *      Community Home Page.
    **********************************************************************************/
    public static Map<String,Integer> getCommentNumberForIdeas(List<String> ideaIds) {
        brideas_Helper.performAccessCheck('read_comments');

        Map<String,Integer> ideasIdcommentsNumMap = new Map<String, Integer>();

        String query = 'SELECT IdeaId FROM IdeaComment WHERE IdeaId IN (\'' + String.join(ideaIds, '\',\'') + '\')';

        //Fetch the banned idea comment ids.
        List<String> bannedIdeaCommentIds = new List<String>(brideas_Helper.getBannedItemsIds('Idea comment'));

        if(!bannedIdeaCommentIds.isEmpty()) {
            query += ' AND Id NOT IN (\'' + String.join(bannedIdeaCommentIds, '\',\'') + '\')';
        }

        //Fetch the idea comments.
        List<IdeaComment> ideaComments = Database.query(query);

        //Loop through the idea comments list.
        for(IdeaComment ic: ideaComments) {
            if(ideasIdcommentsNumMap.containsKey(ic.IdeaId)) {
                ideasIdcommentsNumMap.put(ic.IdeaId, ideasIdcommentsNumMap.get(ic.IdeaId) + 1);
            } else {
                ideasIdcommentsNumMap.put(ic.IdeaId, 1);
            }
        }

        return ideasIdcommentsNumMap;
    }

    /*********************************************************************************
    * Created History: 2018-07-30  Rahul Kapoor 
    * Description:
    *      Method to call add vote helper method to register the vote on the idea to  
    *      display on the Community Home Page.
    **********************************************************************************/
    @AuraEnabled
    public static String addVote(String ideaId) {
        return brideas_Helper.addVote(ideaId);
    }
    
    /*********************************************************************************
    * Created History: 2018-07-30  Rahul Kapoor
    * Description:
    *      Method to fetch the status colors on the idea to  
    *      display on the Community Home Page.
    **********************************************************************************/
    public static Map<String,String> getStatusColors() {
        String statusColorsSettings = brideas_Helper.getConfigValue('status_colors');
        Map<String,String> statusColorsSettingsMap = (Map<String,String>)JSON.deserializeStrict(statusColorsSettings, Map<String,String>.class);

        return statusColorsSettingsMap;
    }
    
    /*********************************************************************************
    * Created History: 2018-08-06  Rahul Kapoor 
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