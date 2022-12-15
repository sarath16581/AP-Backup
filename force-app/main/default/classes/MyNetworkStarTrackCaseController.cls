/**
 * @File Name          : MyNetworkStarTrackCaseController.cls
 * @Description        : Controller class for StarTrack MyNetwork Console App
 * @Author             : Mahesh Parvathaneni
 * @changelog
 * 2022-12-12 - Mahesh Parvathaneni - Added getCriticalIncidents method and updates to getArticlesByCase method
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
            List<ArticleDetails> articleDetails = new List<ArticleDetails>();
            Set<Id> articleIds = new Set<Id>();

            //get consignment for the case
            List<Case> cases = CasesSelector.newInstance().selectById(new Set<Id>{Id.valueOf(caseId)}).values();

            if (cases.size() > 0 && cases[0].ArticleTest__c != null) {
                Id consignmentId = cases[0].ArticleTest__c;
                //get child articles for the consignments
                List<Article__c> articles = ArticlesSelector.newInstance().selectById(new Set<Id>{consignmentId}, new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES}).values();

                for(Article__c article : articles) {
                    if(article.Articles__r != null && article.Articles__r.size() > 0) {
                        for (Article__c a : article.Articles__r) {
                            articleIds.add(a.Id);
                        }
                    }
                }

                if (articleIds.size() > 0) {
                    //get articles with event messages
                    List<Article__c> articlesWithEventMessages = ArticlesSelector.newInstance().selectById(articleIds, new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_NETWORK_DESC_ORDER}).values();
                    
                    for (Article__c aem : articlesWithEventMessages) {
                        //add the articles if related event messages passed through AP network
                        if (aem.Event_Messages__r.size() > 0) {
                            articleDetails.add(new ArticleDetails(aem));
                        }
                    }
                }

                if (articleDetails.size() > 0) {
                    wrapper.hasPassedThroughAPNetwork = true;
                    wrapper.articleDetails = articleDetails;
                }
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
		// since we have multiple DML statements we use this to roll back if errors occur
		Savepoint sp = ApplicationDatabase.getInstance().dmlSetSavePoint();
		SaveResult result = new SaveResult();
        try {
            if (String.isBlank(result.errorMessage) && !recordsToSave.isEmpty()) {
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
        } catch (DmlException e) {
			// because we are doing multiple DML statements, we want all the DML's to be rolled back
			ApplicationDatabase.getInstance().dmlRollback(sp);
			result.status = Status.ERROR.name();
			for(Integer i = 0; i < e.getNumDml(); i++) {
				result.errorMessage = e.getDmlMessage(i);
				//find the custom validation message by type.
				if (e.getDmlType(i) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
					result.errorMessage = System.Label.MyNetworkDuplicateCaseInvestigationErrorMessage;
				}          
			} 
			return result;
        } catch (Exception e) {
			// because we are doing multiple DML statements, we want all the DML's to be rolled back
			ApplicationDatabase.getInstance().dmlRollback(sp);
			//throw all other exceptions
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Function to return the feed items based on network comments
     */
    @TestVisible
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

    /**
     * Function to return the critical incidents knowledge articles
     */
    @AuraEnabled(cacheable=true)
    public static List<CriticalIncidentWrapper> getCriticalIncidents() {
        List<CriticalIncidentWrapper> wrapperList = new List<CriticalIncidentWrapper>();
        Map<String, List<CriticalIncident>> criticalIncidentMap = new Map<String, List<CriticalIncident>>();
        // query critical incidents knowledge articles
        for (Critical_Incident__kav ci : CriticalIncidentsSelector.newInstance().selectCriticalIncidentsByPublishStatus('Online').values()) {
            if (!String.isBlank(ci.Network_Org_Id__c)) {
                for (String networkOrgId : ci.Network_Org_Id__c.split(';')) {
                    if(!String.isEmpty(networkOrgId)) {
                        if(criticalIncidentMap.get(networkOrgId) == null) {
                            criticalIncidentMap.put(networkOrgId, new List<CriticalIncident>());
                        }
                        CriticalIncident incident = new CriticalIncident();
                        incident.id = ci.Id;
                        incident.urlName = ci.UrlName;
                        incident.knowledgeArticleId = ci.KnowledgeArticleId;
                        criticalIncidentMap.get(networkOrgId).add(incident);
                    }
                }
            }
        }
 
        for (String networkId : criticalIncidentMap.keySet()) {
            CriticalIncidentWrapper wrapper = new CriticalIncidentWrapper();
            wrapper.networkOrgId = networkId;
            wrapper.criticalIncidentList = criticalIncidentMap.get(networkId);
            wrapperList.add(wrapper);
        }
        return wrapperList;
    }
 
    public class CriticalIncidentWrapper {
        @AuraEnabled
        public String networkOrgId {get;set;}
        @AuraEnabled
        public List<CriticalIncident> criticalIncidentList {get;set;}
    }
 
    public class CriticalIncident {
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public String urlName {get;set;}
        @AuraEnabled
        public String knowledgeArticleId {get;set;}
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
