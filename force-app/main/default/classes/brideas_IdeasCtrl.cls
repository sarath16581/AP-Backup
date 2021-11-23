public with sharing class brideas_IdeasCtrl {
    private static final Integer DEFAULT_ITEMS_PER_PAGE = 5;
	private static final Integer MAX_ITEMS_PER_PAGE = 500;

	@AuraEnabled
    public static Map<String, String> getUserInfo(){
        return brideas_Helper.getUserInfo();
    }

    @AuraEnabled
    public static List<brideas_IdeaWrapper> getIdeas(String community, Map<String,String> filterData, Integer page, Integer itemsPerPage, String orderBy){
        brideas_Helper.performAccessCheck('read');

		List<brideas_IdeaWrapper> ideasWrapped = new List<brideas_IdeaWrapper>();

		String queryFields = 'Id, Title, Body, Status, Archive__c, CreatedDate, CreatedById, CreatorName, CreatorSmallPhotoUrl, NumComments, Categories, '
							+ 'VoteTotal, (SELECT Type FROM Votes WHERE CreatedById = \''+ UserInfo.getUserId() +'\')';
		String query = 'SELECT ' + queryFields + ' FROM Idea'
				+' WHERE CommunityId = \'' + brideas_Helper.getCommunityId(community) + '\' AND ParentIdeaId = null';
		String queryWhere = brideas_Helper.compileWhereStatement(community, filterData);
		String queryOrderBy = brideas_Helper.compileOrderByStatement(orderBy);

		page = Integer.valueOf(page);
		itemsPerPage = Integer.valueOf(itemsPerPage);

		if (itemsPerPage < 1 || itemsPerPage > MAX_ITEMS_PER_PAGE) itemsPerPage = DEFAULT_ITEMS_PER_PAGE;
		
		query += String.isNotBlank(queryWhere) ? ' AND ' + queryWhere : '';
		query += String.isNotBlank(queryOrderBy) ? ' ORDER BY ' + queryOrderBy : '';
		query += ' LIMIT ' + itemsPerPage;
        query += (page > 1) ? ' OFFSET ' + String.valueOf(itemsPerPage*(page-1)) : '';

		List<Idea> ideas = Database.query(query);
        List<String> ideaIds = new List<String>();

        for(Idea i: ideas) {
            ideaIds.add(i.Id);
        }

        Map<String, String> statusColorsMap = getStatusColors();
        Map<String, Integer> ideasIdcommentsNumMap = getCommentNumberForIdeas(ideaIds);
        Map<String, Integer> ideasVotesNumMap = brideas_Helper.getIdeasVotesNumber(ideaIds);
        Set<String> flaggedIdeaItems = getFlaggedIdeaItems(ideaIds, 'Idea');

        for(Idea i: ideas) {
            brideas_IdeaWrapper ideaWrapped = new brideas_IdeaWrapper();
            ideaWrapped.item = i;
			ideaWrapped.voteStatus = i.Votes.size() == 1 ? 'voted' : '';
			ideaWrapped.votesNum = ideasVotesNumMap.get(i.Id) != NULL ? ideasVotesNumMap.get(i.Id) : 0;

            if(statusColorsMap.containsKey(i.Status)) {
                ideaWrapped.statusColor = statusColorsMap.get(i.Status);
            }

            if(ideasIdcommentsNumMap.containsKey(i.Id)) {
                ideaWrapped.NumComments = ideasIdcommentsNumMap.get(i.Id);
            }

            if(flaggedIdeaItems.contains(String.valueOf(i.Id))) {
                ideaWrapped.flagged = true;
            }

            ideasWrapped.add(ideaWrapped);
        }

        return ideasWrapped;
    }

    public static Map<String,Integer> getCommentNumberForIdeas(List<String> ideaIds) {
        brideas_Helper.performAccessCheck('read_comments');

        Map<String,Integer> ideasIdcommentsNumMap = new Map<String, Integer>();

        String query = 'SELECT IdeaId FROM IdeaComment WHERE IdeaId IN (\'' + String.join(ideaIds, '\',\'') + '\')';

        List<String> bannedIdeaCommentIds = new List<String>(brideas_Helper.getBannedItemsIds('Idea comment'));

        if(!bannedIdeaCommentIds.isEmpty()) {
            query += ' AND Id NOT IN (\'' + String.join(bannedIdeaCommentIds, '\',\'') + '\')';
        }

        List<IdeaComment> ideaComments = Database.query(query);

        for(IdeaComment ic: ideaComments) {
            if(ideasIdcommentsNumMap.containsKey(ic.IdeaId)) {
                ideasIdcommentsNumMap.put(ic.IdeaId, ideasIdcommentsNumMap.get(ic.IdeaId) + 1);
            } else {
                ideasIdcommentsNumMap.put(ic.IdeaId, 1);
            }
        }

        return ideasIdcommentsNumMap;
    }

	@AuraEnabled
    public static Integer getIdeasCount(String community, Map<String,String> filterData) {
		brideas_Helper.performAccessCheck('read');

		String query = 'SELECT COUNT() FROM Idea'
				+' WHERE CommunityId = \'' + brideas_Helper.getCommunityId(community) + '\' AND ParentIdeaId = null';
		String queryWhere = brideas_Helper.compileWhereStatement(community, filterData);
		Integer result_count = 0;

		query += String.isNotBlank(queryWhere) ? ' AND ' + queryWhere : '';

		result_count = Database.countQuery(query);

        return result_count;
    }

	@AuraEnabled
    public static List<Idea> getMergedIdeas(String parentId) {
		brideas_Helper.performAccessCheck('read');

		return [SELECT Title, CreatedDate FROM Idea WHERE ParentIdeaId = :parentId ORDER BY CreatedDate DESC LIMIT 10];
	}

	@AuraEnabled
    public static brideas_IdeaWrapper createNewIdea(Map<String,String> fields) {
		brideas_Helper.performAccessCheck('create');

		Idea newIdea = new Idea();
        String featuredCategory = brideas_Helper.getConfigValue('featured_category');
		newIdea.CommunityId = brideas_Helper.getCommunityId(fields.get('community'));
		newIdea.Title = fields.get('title');
		newIdea.Body = fields.get('body');
        newIdea.Categories = fields.get('category');

        if(String.isNotBlank(featuredCategory)) {
            newIdea.Categories = featuredCategory;
        }

		newIdea.Status = brideas_Helper.getDefaultStatusValue(); //TODO: check if it is necessary

		try {
			insert newIdea;
		}
		catch (DmlException e) {
			System.debug(e.getMessage());
			return null;
		}

        Map<String, String> statusColorsMap = getStatusColors();

        newIdea = [SELECT Title, Body, Status, CreatedDate, CreatedById, CreatorName, CreatorSmallPhotoUrl,
						NumComments, Categories, VoteTotal
					FROM Idea WHERE Id = :newIdea.Id];

        brideas_IdeaWrapper ideaWrapped = new brideas_IdeaWrapper();
        ideaWrapped.item = newIdea;
        ideaWrapped.voteStatus = 'voted';
        ideaWrapped.votesNum = 1;

        if(statusColorsMap.containsKey(newIdea.Status)) {
            ideaWrapped.statusColor = statusColorsMap.get(newIdea.Status);
        }

        return ideaWrapped;
    }

	@AuraEnabled
	public static Map<String, List<Map<String, String>>> getFilterOptions(Map<String, String> options) {
		brideas_Helper.performAccessCheck('read');

		Map<String, List<Map<String, String>>> data = new Map<String, List<Map<String, String>>>();
		String categoriesSource = options.get('categoriesSource');
		String zoneName = options.get('zone');

		data.put('category', brideas_Helper.getCategoryOptions(categoriesSource, zoneName));
		data.put('status', brideas_Helper.getStatusOptions());

		return data;
	}

	@AuraEnabled
	public static List<Map<String, String>> getCategoryOptions(String source, String zoneName){
		return brideas_Helper.getCategoryOptions(source, zoneName);
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
    public static List<Vote> getIdeaVotes(String ideaId) {
        brideas_Helper.performAccessCheck('read_vote');

		if(String.isBlank(ideaId)) return null;

        String query = 'SELECT CreatedById, Type, CreatedBy.SmallPhotoUrl, CreatedBy.FirstName, CreatedBy.LastName' +
						' FROM Vote WHERE ParentId = \''+ String.escapeSingleQuotes(ideaId) +'\'' +
						' ORDER BY SystemModstamp DESC' +
						' LIMIT  100';

        return Database.query(query);
    }

	@AuraEnabled
	public static Integer getIdeaVotesCount(String ideaId) {
		brideas_Helper.performAccessCheck('read_vote');

		if(String.isBlank(ideaId)) return null;

		String query = 'SELECT COUNT() FROM Vote WHERE ParentId = \''+ String.escapeSingleQuotes(ideaId) +'\'';

		return Database.countQuery(query);
	}

	@AuraEnabled
	public static List<brideas_IdeaCommentWrapper> getIdeaComments(String ideaId, String queryLimit, String orderDir, String fromDatetime) {
		brideas_Helper.performAccessCheck('read_comments');
		List<brideas_IdeaCommentWrapper> ideaCommentWrappers = new List<brideas_IdeaCommentWrapper>();

		String query = 'SELECT Id, CommentBody, CreatedDate, CreatorName, CreatedById, CreatorSmallPhotoUrl FROM IdeaComment';

		if(String.isBlank(ideaId)) return null;

        query += ' WHERE IdeaId = \'' + String.escapeSingleQuotes(ideaId) + '\'';


		List<String> bannedIdeaCommentIds = new List<String>(brideas_Helper.getBannedItemsIds('Idea comment'));

		if(!bannedIdeaCommentIds.isEmpty()) {
			query += ' AND Id NOT IN (\'' + String.join(bannedIdeaCommentIds, '\',\'') + '\')';
		}

		if (String.isNotBlank(fromDatetime)) {
			query += ' AND CreatedDate';
			query += orderDir == 'asc' ? ' > ' : ' < ';
			query += String.escapeSingleQuotes(fromDatetime);
		}
		query += orderDir == 'asc' ? ' ORDER BY CreatedDate ASC' : ' ORDER BY CreatedDate DESC';
        query += String.valueOf(queryLimit).isNumeric() ? ' LIMIT ' + String.valueOf(queryLimit) : 'LIMIT 0';

		List<IdeaComment> ideaComments = Database.query(query);
        List<String> ideaCommentIds = new List<String>();

        for (IdeaComment comment: ideaComments) {
            ideaCommentIds.add(String.valueOf(comment.Id));
        }

        Set<String> flaggedIdeaItems = getFlaggedIdeaItems(ideaCommentIds, 'IdeaComment');

		for(IdeaComment comment : ideaComments){
			brideas_IdeaCommentWrapper ideaCommentWrap = new brideas_IdeaCommentWrapper();
			ideaCommentWrap.ideaComment = comment;

            if(flaggedIdeaItems.contains(String.valueOf(comment.Id))) {
                ideaCommentWrap.Flagged = true;
            }

			ideaCommentWrappers.add(ideaCommentWrap);
		}
		return ideaCommentWrappers;
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
    public static brideas_IdeaCommentWrapper saveComment(String ideaId, String message) {
        brideas_Helper.performAccessCheck('create_comments');
        brideas_IdeaCommentWrapper ideaCommentWrap = new brideas_IdeaCommentWrapper();

        if (String.isBlank(message)) {
            throw new AuraHandledException('Empty comment');
        }

		IdeaComment comment = new IdeaComment(CommentBody = message, IdeaId = ideaId);

        try {
            insert comment;
        } catch (DmlException e) {
            System.debug(e.getMessage());
			return null;
        }

		IdeaComment ideaComment = [SELECT CommentBody, CreatedDate, CreatorName, CreatedById, CreatorSmallPhotoUrl
											FROM IdeaComment WHERE Id = :comment.Id];

        ideaCommentWrap.ideaComment = ideaComment;

		return ideaCommentWrap;
    }

	@AuraEnabled
    public static List<Idea> getSimilarIdeas(String community, String title) {

		return brideas_Helper.getSimilarIdeas(community, title);
    }

	@AuraEnabled
	public static Boolean unsubscribe(String ideaId){
		try {
            brideas_Helper.unsubscribeUserFromIdea(ideaId, UserInfo.getUserId());
        } catch(Exception ex) {
            System.debug('brideas_IdeasCtrl.unsubscribe: ' + ex.getMessage());
            return false;
        }

        return true;
	}

    @AuraEnabled
    public static Boolean unsubscribeAll(){
        try {
            brideas_Helper.unsubscribeUserFromAllIdeas(UserInfo.getUserId());
        } catch(Exception ex) {
            System.debug('brideas_IdeasCtrl.unsubscribeAll: ' + ex.getMessage());
            return false;
        }

        return true;
    }

    @AuraEnabled
    public static Boolean setFlagOnIdea(String IdeaId) {
        return brideas_Helper.setFlagOnIdea(IdeaId);
    }

    @AuraEnabled
    public static Boolean setFlagOnIdeaComment(String commentId) {
        Id usrId = UserInfo.getUserId();
        Integer unique = [SELECT COUNT() FROM brideas_Flag__c WHERE IdeaId__c = :commentId AND userId__c = :usrId];

        if(unique > 0) return false;

        commentId = String.valueOf(Id.valueOf(commentId));

        brideas_Flag__c flag = new brideas_Flag__c(IdeaId__c = commentId, userId__c = usrId, Type__c = 'IdeaComment');

        try {
            insert flag;
        } catch(Exception ex) {
            System.debug('brideas_IdeasCtrl.setFlagOnIdea: ' + ex.getMessage());
            return false;
        }

        brideas_EmailNotification notificator = new brideas_EmailNotification();
        IdeaComment flaggedComment = [SELECT CommentBody, IdeaId, Idea.Title FROM IdeaComment WHERE Id = :commentId LIMIT 1];
        User userFlagged = [SELECT Username, Email FROM User WHERE Id = :usrId];

        notificator.addIdeaCommentFlaggedNotification(flaggedComment, userFlagged);
        notificator.sendEmails();

        return true;
    }

    @AuraEnabled
    public static String getFeaturedCategory() {
        return brideas_Helper.getConfigValue('featured_category');
    }

    public static Map<String,String> getStatusColors() {
        String statusColorsSettings = brideas_Helper.getConfigValue('status_colors');
        Map<String,String> statusColorsSettingsMap = (Map<String,String>)JSON.deserializeStrict(statusColorsSettings, Map<String,String>.class);

        return statusColorsSettingsMap;
    }

    public static List<brideas_Flag__c> getBrideasFlags() {

        return [SELECT IdeaId__c FROM brideas_Flag__c WHERE userId__c = : UserInfo.getUserId()];

    }


    public static Set<String> getFlaggedIdeaItems(List<String> itemIds, String itemType) {
        Set<String> flaggedIdeaItems = new Set<String>();

        for(brideas_Flag__c flag: [SELECT IdeaId__c FROM brideas_Flag__c
        WHERE IdeaId__c IN :itemIds AND userId__c = : UserInfo.getUserId()
        AND Type__c = :itemType]) {
            flaggedIdeaItems.add(flag.IdeaId__c);
        }

        return flaggedIdeaItems;
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