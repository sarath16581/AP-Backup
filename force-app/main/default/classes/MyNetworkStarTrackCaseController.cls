/**
 * @File Name          : MyNetworkStarTrackCaseController.cls
 * @Description        : Controller class for StarTrack MyNetwork Console App
 * @Author             : Mahesh Parvathaneni
 **/

public with sharing class MyNetworkStarTrackCaseController {

    /**
     * Function to get the articles and related event messages for a case that is associated with AP Network
     */
    @AuraEnabled
    public static ArticleResponseWrapper getArticlesByCase(String caseId){
        try {
            ArticleResponseWrapper wrapper = new ArticleResponseWrapper();
            wrapper.hasPassedThroughAPNetwork = false;
            //get articles with related event messages with AP Network scans
            List<Article__c> articles = ArticlesSelector.newInstance()
                                        .selectByCaseIds(new Set<Id>{Id.valueOf(caseId)}, 
                                                         new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_NETWORK_DESC_ORDER, 
                                                         ArticlesSelector.Options.FILTER_NETWORK}).values();
            
            //check if any of the articles related event messages passed through AP Network
            for (Article__c article : articles) {
                if (!wrapper.hasPassedThroughAPNetwork && article.Event_Messages__r.size() > 0) {
                    wrapper.hasPassedThroughAPNetwork = true;
                }
            }

            if (wrapper.hasPassedThroughAPNetwork) {
                List<ArticleDetails> articleDetails = new List<ArticleDetails>();
                for (Article__c article : articles) {
                    //add the articles if related event messages passed through AP network
                    if (article.Event_Messages__r.size() > 0) {
                        articleDetails.add(new ArticleDetails(article));
                    }
                }           
                wrapper.articleDetails = articleDetails;
            }
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Function to create the case investigation records to AP Network
     */
    @AuraEnabled
	public static SaveResult saveCaseInvestigations(List<CaseInvestigation__c> recordsToSave, String comments) {
        try {
            SaveResult result = new SaveResult();
            Set<Id> articleIds = new Set<Id>();
            Set<Id> networkIds = new Set<Id>();
            Map<Id, List<Id>> existingArticleToNetworkIdsMap = new Map<Id, List<Id>>();

            //get article and network ids
            for (CaseInvestigation__c obj : recordsToSave) {
                articleIds.add(obj.Article__c);
                networkIds.add(obj.Network__c);
            }

            //get existing case investigation related to the case, network and article ids
            List<CaseInvestigation__c> existingCaseInvestigations = CaseInvestigationsSelector.newInstance()
                                                                    .selectOpenCaseInvestigationsByCaseArticleNetworkId(new Set<Id>{recordsToSave[0].Case__c},
                                                                                                                    new Set<Id>(articleIds), new Set<Id>(networkIds)).values();
            for (CaseInvestigation__c eci : existingCaseInvestigations) {
                if (existingArticleToNetworkIdsMap.containsKey(eci.Article__c)) {
                    existingArticleToNetworkIdsMap.get(eci.Article__c).add(eci.Network__c);
                } else {
                    existingArticleToNetworkIdsMap.put(eci.Article__c, new List<Id> {eci.Network__c});
                }
            }

            for (CaseInvestigation__c ci : recordsToSave) {
                if (existingArticleToNetworkIdsMap.containsKey(ci.Article__c) && existingArticleToNetworkIdsMap.get(ci.Article__c).contains(ci.Network__c)) {
                    result.status = Status.ERROR.name();
					result.errorMessage = System.Label.MyNetworkDuplicateCaseInvestigationErrorMessage;
                }
            }

            if (String.isBlank(result.errorMessage)) {
                // insert case investigation records
			    Database.SaveResult[] srList = ApplicationDatabase.getInstance().dmlInsert(recordsToSave);
                // get feed items to post
                if (String.isNotBlank(comments)) {
                    List<FeedItem> feedItems = getChatterFeedItems(srList, comments);
                    // insert chatter feed items
                    if (feedItems.size() > 0) {
                        ApplicationDatabase.getInstance().dmlInsert(feedItems);
                        result.status = Status.SUCCESSFUL.name();
                    } 
                } else {
                    result.status = Status.SUCCESSFUL.name();
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Function to return the feed items based on network comments
     */
    private static List<FeedItem> getChatterFeedItems(Database.SaveResult[] srList, String comments) {
        Set<Id> caseInvestigationIds = new Set<Id>();
        List<FeedItem> feedItems = new List<FeedItem>();
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                caseInvestigationIds.add(sr.getId());
            }
        }

        //create feed items
        if (caseInvestigationIds.size() > 0) {
            for (Id ciId : caseInvestigationIds) {
                FeedItem item = new FeedItem();
                item.ParentId = ciId;
                item.Body = comments;
                feedItems.add(item);
            }
        }
        return feedItems;
    }

    // Status of Case Investigation creation
	public enum Status {
		SUCCESSFUL,
		ERROR
	}

	public class SaveResult {
		@AuraEnabled 
        public String status {get; set;}
		@AuraEnabled 
        public String errorMessage {get; set;}
	}

    public class ArticleResponseWrapper {
        @AuraEnabled
        public List<ArticleDetails> articleDetails {get; set;}
        @AuraEnabled
        public Boolean hasPassedThroughAPNetwork {get; set;}
    }

    public class ArticleDetails {
        @AuraEnabled
        public Article__c article {get; set;}
        @AuraEnabled
        public List<EventMessage> eventMessages {get; set;}

        public ArticleDetails(Article__c article) {
			this.article = article;
			this.eventMessages = new List<EventMessage>();
			for (EventMessage__c em: article.Event_Messages__r) {
                this.eventMessages.add(new EventMessage(em));
			}
		}
    }

    public class EventMessage {
        @AuraEnabled 
        public EventMessage__c eventMessage {get; set;}

        public EventMessage(EventMessage__c em) {
            this.eventMessage = em;
        }
    }
    
}
