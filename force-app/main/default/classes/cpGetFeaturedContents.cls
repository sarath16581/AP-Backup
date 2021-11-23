//Class to fetch Featured content and return it to Component
public without sharing class cpGetFeaturedContents {
    
     @AuraEnabled
    public static list<Featured_Content__kav> getFeaturedContents(Integer noOfRecordsTofetch){
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
                                                            Order By StoriesLandingPageSequence__c 
                                                            Limit : recordCount];
            return featuredContents;
        } catch(exception ex){
            return null;
        }
    }

}