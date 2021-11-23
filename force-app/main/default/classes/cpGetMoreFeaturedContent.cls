//Class to retrieve More featured content for customer community project.
public without sharing class cpGetMoreFeaturedContent {

    @AuraEnabled
    //Retrieve more featured content
    public static list<Featured_Content__kav> getMoreFeaturedContents(Integer noOfRecordsTofetch, String articleIdToExclude){
        try{
            Integer recordCount = 3;
            if(Integer.valueOf(noOfRecordsTofetch) > 0){
                recordCount = Integer.valueOf(noOfRecordsTofetch);
            }
    
            list<Featured_Content__kav> featuredContents = [Select Id, ArticleNumber, Content__c, ContentText__c, KnowledgeArticleId,
                                                                UrlName, DisplayonStoriesLandingPage__c, StoriesLandingPageSequence__c
                                                            From Featured_Content__kav
                                                            Where PublishStatus='Online'
                                                            and Language='en_US'
                                                            and DisplayonStoriesLandingPage__c=true
                                                            and Id != : articleIdToExclude
                                                            Order By StoriesLandingPageSequence__c
                                                            Limit : recordCount];
            return featuredContents;
        } catch(exception ex){
            return null;
        }
    }

}