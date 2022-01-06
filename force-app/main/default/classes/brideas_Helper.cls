public class brideas_Helper {
	private static final String IDEAS_SETTINGS_TYPE = 'brideas_MetadataType__mdt';

	public static void addSubscriberToIdea(Id usrId, Id ideaId){
		brideas_Subscription__c subscr = new brideas_Subscription__c(
				Idea__c = ideaId,
				User__c = usrId,
				Token__c = brideas_Utils.generateToken(50)
			);

		insert subscr;
	}

	public static List<Map<String, String>> getCategoryOptions(String source, String zoneName){
		List<Map<String, String>> listArray = new List<Map<String, String>>();
		Map<String, String> listItem;
		List<String> catZones;
		Boolean containZone;

		if (source == 'Custom settings') {
			List<brideas_Categories__c> rows = [SELECT Name, Label__c, Parent__c, Zone__c
                                                    FROM brideas_Categories__c
                                                    ORDER BY Order__c ASC
                                                    LIMIT 1000];

			for (brideas_Categories__c row : rows) {
				if (zoneName != null && zoneName != '') {
					if (row.Zone__c == null) continue;

					catZones = String.valueOf(row.Zone__c).split(',');
					containZone = false;

					for (String zn : catZones) {
						if (zn == zoneName) containZone = true;
					}

					if (!containZone) continue;
				}
				
				listItem = new Map<String, String>();
				listItem.put('value', row.Name);
				listItem.put('label', row.Label__c);
				listItem.put('parent', row.Parent__c);
				listArray.add(listItem);
			}
		} else {
			Schema.DescribeFieldResult fieldResult = Idea.Categories.getDescribe();
			List<Schema.PicklistEntry> categoryPicklistEntries = fieldResult.getPicklistValues();
			
			for (Schema.PicklistEntry item : categoryPicklistEntries) {
				listItem = new Map<String, String>();
				listItem.put('value', item.getValue());
				listItem.put('label', item.getLabel());
				listArray.add(listItem);
			}
		}

		return listArray;
	}


	public static List<Map<String, String>> getStatusOptions(){
		List<Map<String, String>> listArray = new List<Map<String, String>>();
		Map<String, String> listItem;
        Schema.DescribeFieldResult fieldResult = Idea.Status.getDescribe();
        List<Schema.PicklistEntry> statusPicklistEntries = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry item : statusPicklistEntries) {
			listItem = new Map<String, String>();
			listItem.put('value', item.getValue());
			listItem.put('label', item.getLabel());
			listArray.add(listItem);
		}

		return listArray;
	}

	
	public static String compileWhereStatement(String communityName,  Map<String,String> filterData) {
        String userId = UserInfo.getUserId();
		Id communityId = brideas_Helper.getCommunityId(communityName);
		List<String> whereList = new List<String>();
		List<String> searchIds;
		String searchQuery, category, status, ideaTheme, showBy, searchByTitleOnly;

		if (filterData == null) return '';

        searchQuery = filterData.get('search');
        searchByTitleOnly = filterData.get('search_by_title');
		category = filterData.get('category');
		status = filterData.get('status');
		//ideaTheme = filterData.get('idea_theme');
        showBy = filterData.get('showBy');

        if (String.isNotBlank(category))
			whereList.add('Categories INCLUDES (\'' + String.escapeSingleQuotes(category) + '\')');

        if (String.isNotBlank(status))
			whereList.add('Status = \'' + String.escapeSingleQuotes(status) + '\'');

		/*if (String.isNotBlank(ideaTheme))
			whereList.add('IdeaThemeID = \'' + String.escapeSingleQuotes(ideaTheme) + '\'');*/

        if (String.isNotBlank(showBy)) {
			if (showBy == 'createdByMe') {
                whereList.add('CreatedById = \'' + userId + '\'') ;
            }
			else if(showBy == 'archived') {
                whereList.add('Archive__c = true');
            }
			else if (showBy == 'commentedByMe') {
                searchIds = new List<String>();

                List<AggregateResult> res = [SELECT IdeaId FROM IdeaComment WHERE CommunityId = :communityId AND CreatedById = :userId GROUP BY IdeaId];

                for (AggregateResult resRow : res) {
                    searchIds.add(String.valueOf(resRow.get('IdeaId')));
                }

                whereList.add('Id IN (\'' + String.join(searchIds, '\',\'') + '\')');
            }
        }

		if (String.isNotBlank(searchQuery)) {
			searchIds = new List<String>();
			List<List<SObject>> searchList;

            if (String.isNotBlank(searchByTitleOnly) && searchByTitleOnly == 'true') {
				List<String> searchWords = String.escapeSingleQuotes(searchQuery).split('\\s+');
                List<String> titleWhereList = new List<String>();
                String titleQueryString = '(';

                for (String searchWord : searchWords) {
                    titleWhereList.add('Title LIKE \'%' + searchWord + '%\'');
                }

                titleQueryString = titleQueryString + String.join(titleWhereList, ' OR ') + ')';

                whereList.add(titleQueryString);
            } else {
                searchList = [FIND :searchQuery IN ALL FIELDS RETURNING Idea(Id) LIMIT 50];

                for (SObject obj : searchList[0]) {
                    searchIds.add(obj.Id);
                }

                whereList.add('Id IN (\'' + String.join(searchIds, '\',\'') + '\')');
            }
		}

		List<String> bannedIdeaIds = new List<String>(brideas_Helper.getBannedItemsIds('Idea post'));

		if(!bannedIdeaIds.isEmpty()) {
			whereList.add('Id NOT IN (\'' + String.join(bannedIdeaIds, '\',\'') + '\')');
		}

        return String.join(whereList, ' AND ');
    }

	/**
	 *
	 * @param itemType type of banned item ['Idea post', 'Idea comment']
	 * @return set of banned items IDs
	 */
	public static Set<String> getBannedItemsIds(String itemType) {
		Set<String> bannedItemsIds = new Set<String>();
		List<brideas_Banned_Idea_Item__c> bannedItems = [SELECT Item_Id__c FROM brideas_Banned_Idea_Item__c WHERE Type__c = :itemType];

		for (brideas_Banned_Idea_Item__c bi : bannedItems) {
			bannedItemsIds.add(bi.Item_Id__c);
		}

		return bannedItemsIds;
	}

	public static String compileOrderByStatement(String orderByData) {
        String orderByClause = 'CreatedDate DESC';

        if (String.isNotBlank(orderByData)) {
            if (orderByData == 'Trending') {
                orderByClause = 'LastCommentDate DESC NULLS LAST, CreatedDate DESC';
            } else if (orderByData == 'Popular') {
                orderByClause = 'VoteTotal DESC, CreatedDate DESC';
            } else if (orderByData == 'Oldest') {
				orderByClause = 'CreatedDate ASC';
			}
        }

        return orderByClause;
    }

    public static Map<String, Integer> getIdeasVotesNumber(List<String> ideaIds){
        Map<String, Integer> resultMap = new Map<String, Integer>();

        List<Vote> ideaVotes = [SELECT ParentId FROM Vote WHERE ParentId IN :ideaIds AND Parent.Type = 'Idea'];

        for(Vote vote: ideaVotes) {
            if(!resultMap.containsKey(vote.ParentId)) {
                resultMap.put(vote.ParentId, 1);

            } else {
                resultMap.put(vote.ParentId, resultMap.get(vote.ParentId) + 1);
            }
        }

        return resultMap;
    }


	public static String getCommunityId(String communityName) {
		communityName = brideas_Helper.getConfigValue('community');

		if (communityName == '') { 
			System.debug('Cannot find community name within settings');
			return ''; 
		}

		try {
			Community community = [SELECT Id FROM Community WHERE Name = :communityName LIMIT 1];
			return community.Id;
		} catch (Exception e) {
			System.debug('No communities with name "' + communityName + '"');
		}
		
		return '';
	}


	public static String getCommunityUrlByZoneId(Id zoneId){
        if (Test.isRunningTest()) return 'test.com';

        Community zone = [SELECT NetworkId FROM Community WHERE Id = :zoneId];
        ConnectApi.Community comm = ConnectApi.Communities.getCommunity(zone.NetworkId);

        return comm.SiteUrl;
    }


	public static String getConfigValue(String name) {
		String configValue = '';

		for (brideas_MetadataType__mdt row : [SELECT DeveloperName, Value__c FROM brideas_MetadataType__mdt LIMIT 100]) {
			if (row.DeveloperName == name) {
				configValue = row.Value__c;
			}
		}

		if (Test.isRunningTest()) {
			if (name == 'community') {
				configValue = 'TestPublic';
			} else if (name == 'forbidden_words') {
				configValue = 'ForbiddenWord,TestForbiddenWord';
			} else if (name == 'featured_category') {
				configValue = 'FeaturedCategory';
			} else if (name == 'status_colors') {
                configValue = '{"Test":"#FFAAAA"}';
            } else if (name == 'status_update') {
				configValue = '{"active":true, "threshold":10, "original_status":"New", "new_status":"Under Consideration"}';
			} else if (name == 'survey_url') {
				configValue = 'https://example.com';
			}
		}

		return configValue;
	}


	public static Map<String, String> getStatusUpdateSettings(){
		String settings = brideas_Helper.getConfigValue('status_update');
		Map<String, String> settingsMap = new Map<String, String>();
		Boolean isEnabled = false;
		Decimal threshold = 0;

		try {
			JSONParser parser = JSON.createParser(settings);
			String paramName;

			while (parser.nextToken() != null) {
				if (parser.getCurrentToken() != JSONToken.FIELD_NAME) continue;

				paramName = parser.getText();

				parser.nextToken();

				settingsMap.put(paramName, parser.getText());
			}

			isEnabled = Boolean.valueOf(settingsMap.get('active'));
			threshold = Decimal.valueOf(settingsMap.get('threshold'));

		} catch (Exception e) {
			System.debug('brideas_Helper::getStatusUpdateSettings:' + e.getMessage());
			return null;
		}

		if (isEnabled
				&& (threshold < 1
						|| String.isBlank(settingsMap.get('original_status'))
						|| String.isBlank(settingsMap.get('new_status')))
				) {

			System.debug('brideas_Helper::getStatusUpdateSettings: update status settings is not populated correctly');
			return null;
		}

		return settingsMap;
	}


	public static String getDefaultStatusValue(){
		Schema.DescribeFieldResult fieldResult = Idea.Status.getDescribe();
		List <Schema.PicklistEntry> pickVals = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry peItem : pickVals) {
			if (peItem.isDefaultValue()) {
				return peItem.getValue();
			}
		}

		return '';
	}

	public static Boolean isItemContainsForbiddenWords(String itemText){
		if(!brideas_MetadataType__mdt.sObjectType.getDescribe().isAccessible()) return null;

		if(itemText.contains('http')) return true;

		String bannedWords = brideas_Helper.getConfigValue('forbidden_words');

		bannedWords = bannedWords.toLowerCase();

		Set<String> bannedWordsSet = new Set<String>(bannedWords.split(','));

		itemText = itemText.stripHtmlTags().toLowerCase();

		Set<String> itemTextSet = new Set<String>(itemText.split('[^a-zA-Z0-9\']'));

		Integer allWordsCount = bannedWordsSet.size() + itemTextSet.size();

		itemTextSet.addAll(bannedWordsSet);

		if(allWordsCount > itemTextSet.size()) {
			return true;
		}

		return false;
	}

	public static void performAccessCheck(String accessType) {
		Schema.DescribeSObjectResult ideaDescribe = Idea.sObjectType.getDescribe();
        Schema.DescribeSObjectResult voteDescribe = Vote.sObjectType.getDescribe();
        Schema.DescribeSObjectResult commentDescribe = IdeaComment.sObjectType.getDescribe();
		Schema.DescribeSObjectResult networkDescribe = Network.sObjectType.getDescribe();

		if (!ideaDescribe.isAccessible()
				|| (accessType == 'create' && !ideaDescribe.isCreateable())
				|| (accessType == 'edit' && !ideaDescribe.isUpdateable())
				|| (accessType == 'search' && !ideaDescribe.isSearchable()))
			throw new AuraHandledException('Access not granted');

		if (accessType == 'create_vote' && !voteDescribe.isAccessible()
				|| accessType == 'create_vote' && !voteDescribe.isCreateable()) {
			throw new AuraHandledException('Access not granted');
		}
        
        if ((accessType == 'read_comments' && !commentDescribe.isAccessible())
				|| (accessType == 'create_comments') && !commentDescribe.isCreateable()) {
			throw new AuraHandledException('Access not granted');
		}

		if ((accessType == 'read_network' && !networkDescribe.isAccessible())){
			throw new AuraHandledException('Access not granted');
		}

		if (accessType == 'create') {
			User usr = [SELECT IdeasSuperUser__c FROM User WHERE Id = :UserInfo.getUserId()];

			if (usr.IdeasSuperUser__c != true) {
				System.debug('brideas_Helper::performAccessCheck: Not Super User tried to create an idea');
				throw new AuraHandledException('You are not permitted to create an idea');
			}
		}
	}

    public static void unsubscribeUserFromIdea(String ideaId, String userId) {
        brideas_Subscription__c subscr = [SELECT Id FROM brideas_Subscription__c
                                          WHERE Idea__c = :ideaId AND User__c = :userId LIMIT 1];

        delete subscr;
    }

	public static void unsubscribeUserFromAllIdeas(String userId) {
		List<brideas_Subscription__c> subscr = [SELECT Id FROM brideas_Subscription__c WHERE User__c = :userId];

		delete subscr;
	}

    public static void unsubscribeFromIdeaByToken(String tokenString) {
        brideas_Subscription__c subscr = [SELECT Id FROM brideas_Subscription__c WHERE Token__c = :tokenString LIMIT 1];

        delete subscr;
    }

	public static Integer getActionReputationPoints(String actionName) {
        Integer points = 0;

        try {
            String reputationSettings = brideas_Helper.getConfigValue('reputation_points');

            Map<String, String> reputationData = (Map<String,String>)JSON.deserializeStrict(reputationSettings, Map<String,String>.class);
            for (String key : reputationData.keySet()) {
                if (!key.equals(actionName)) continue;

                points = Integer.valueOf(reputationData.get(key));
            }
        } catch (Exception ex) {
            System.debug('brideas_Helper::getActionReputationPoints: ' + ex.getMessage());
        }

        return points;
    }

    public static void updateMemberReputation(String actionName, Integer count) {
        try {
            brideas_Helper.performAccessCheck('update_network_member');
        } catch (AuraHandledException ex) {
            System.debug('brideas_Helper::updateMemberReputation: ' + ex.getMessage());
            return;
        }

        Integer points = brideas_Helper.getActionReputationPoints(actionName);
		String userId = UserInfo.getUserId();
		String ntwrkId = Network.getNetworkId();

		if (points == 0) {
			return;
		}

		try {
			NetworkMember member = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :userId AND NetworkId = :ntwrkId LIMIT 1];
            member.ReputationPoints += points;
            update member;

		} catch (Exception ex) {
			System.debug('brideas_Helper::updateMemberReputation: ' + ex.getMessage());
		}
	}


    public static void updateCustomMetadataValue(Map<String,String> recordsNewValuesMap) {
		Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
		Map<String,String> recordsLabelsMap = new Map<String, String>();

        for(brideas_MetadataType__mdt setting: [SELECT DeveloperName, MasterLabel FROM brideas_MetadataType__mdt LIMIT 100]) {
            recordsLabelsMap.put(setting.DeveloperName, setting.MasterLabel);
        }

		for(String recordName: recordsNewValuesMap.keySet()) {

			Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
			customMetadata.fullName = IDEAS_SETTINGS_TYPE + '.' + recordName;
			customMetadata.label = recordsLabelsMap.get(recordName);

			Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
			customField.field = 'Value__c';
			customField.value = recordsNewValuesMap.get(recordName);

			customMetadata.values.add(customField);
			mdContainer.addMetadata(customMetadata);
		}

        CustomMetadataCallback callback = new CustomMetadataCallback();

        if(!Test.isRunningTest()) {
            Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }

	public static List<Idea> getSimilarIdeas(String community, String title) {
		brideas_Helper.performAccessCheck('read');
		List<Idea> similarIdeas = new List<Idea>();

		String cid = brideas_Helper.getCommunityId(community);
		Idea newIdea = new Idea(Title = title);
		List<String> ids = Ideas.findSimilar(newIdea);

        similarIdeas = [SELECT Title, VoteTotal FROM Idea WHERE CommunityId = :cid AND Id IN :ids ORDER BY CreatedDate DESC LIMIT 10];

        if (Test.isRunningTest()) {
            similarIdeas.add(new Idea(Title = 'Test idea'));
        }

        return similarIdeas;
    }

	public static Map<String, String> getUserInfo(){
		Map<String, String> uInf = new Map<String, String>();
		User usr = [SELECT IdeasSuperUser__c FROM User WHERE Id = :UserInfo.getUserId()];

		uInf.put('Id', UserInfo.getUserId());
		uInf.put('Name', UserInfo.getName());
		uInf.put('Username', UserInfo.getUserName());
		uInf.put('Email', UserInfo.getUserEmail());
		uInf.put('Type', UserInfo.getUserType());
		uInf.put('Super', usr.IdeasSuperUser__c ? 'true' : 'false');

		return uInf;
	}

	public static String addVote(String ideaId) {
		if (String.isBlank(ideaId)) return 'error';
		if (UserInfo.getUserType() == 'Guest') return 'auth_required';

		brideas_Helper.performAccessCheck('create_vote');

		try {
			insert new Vote(ParentId = ideaId, Type = 'Up'); //AustraliaPost required only vote Up feature
		}
		catch (DmlException e) {
			System.debug(e.getMessage());
			return 'error';
		}

		Idea voteIdea = [SELECT Status, VoteTotal FROM Idea WHERE Id = :ideaId];

		brideas_EventHandler.statusUpdate(voteIdea);
		brideas_Helper.addSubscriberToIdea(UserInfo.getUserId(), ideaId);

		return String.valueOf(getIdeaVotesNumber(ideaId));
	}

	public static Integer getIdeaVotesNumber(String ideaId){

		return [SELECT COUNT() FROM Vote WHERE ParentId = :ideaId];
	}

	public static Boolean setFlagOnIdea(String IdeaId) {
		Id usrId = UserInfo.getUserId();
		Integer unique = [SELECT COUNT() FROM brideas_Flag__c WHERE IdeaId__c = :IdeaId AND userId__c = :usrId];

		if(unique > 0) return false;

        IdeaId = String.valueOf(Id.valueOf(IdeaId));

		brideas_Flag__c flag = new brideas_Flag__c(IdeaId__c = IdeaId, userId__c = usrId, Type__c = 'Idea');

		try {
			insert flag;
		} catch(Exception ex) {
			System.debug('brideas_IdeasCtrl.setFlagOnIdea: ' + ex.getMessage());
			return false;
		}

		brideas_EmailNotification notificator = new brideas_EmailNotification();
		Idea flaggedIdea = [SELECT Title, Body FROM Idea WHERE Id = :IdeaId];
		User userFlagged = [SELECT Username, Email FROM User WHERE Id = :usrId];

		notificator.addIdeaFlaggedNotification(flaggedIdea, userFlagged);
		notificator.sendEmails();

		return true;
	}

    public class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
			if (result.status == Metadata.DeployStatus.Succeeded) {
				System.debug('CustomMetadataCallback - success: ' + result);
			} else {
				System.debug('CustomMetadataCallback - fail: ' + result);
			}
		}
    }
}