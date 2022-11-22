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
            //get articles with related event messages with AP Network scans
            List<Article__c> articles = ArticlesSelector.newInstance()
                                        .selectByCaseIds(new Set<Id>{Id.valueOf(caseId)}, 
                                                         new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_NETWORK_DESC_ORDER, 
                                                         ArticlesSelector.Options.FILTER_NETWORK}).values();
            if (articles.size() > 0) {
                wrapper.hasPassedThroughAPNetwork = true;

                List<ArticleDetails> articleDetails = new List<ArticleDetails>();
                for (Article__c article : articles) {
                    articleDetails.add(new ArticleDetails(article));
                }           
                wrapper.articleDetails = articleDetails;     
            } else {
                wrapper.hasPassedThroughAPNetwork = false;
            }
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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
