//Class to retrieve featured content used by component in Customer community.
public without sharing class cpGetFeaturedContentsHomePage {
    
     @AuraEnabled
     //retrieve featured content
    public static list<Featured_Content__kav> getFeaturedContents(Integer noOfRecordsTofetch){
        try{
            Integer recordCount = 10;
            if(Integer.valueOf(noOfRecordsTofetch) > 0){
                recordCount = Integer.valueOf(noOfRecordsTofetch);
            }
            
            list<Featured_Content__kav> featuredContents = [Select Id, ArticleNumber, Content__c, ContentText__c, KnowledgeArticleId, 
                                                                UrlName, DisplayonStoriesLandingPage__c, StoriesLandingPageSequence__c  
                                                            From Featured_Content__kav 
                                                            Where PublishStatus='Online' 
                                                            and Language='en_US' 
                                                            and DisplayonHomepage__c =true
                                                            Order By HomePageSequence__c  
                                                            Limit : recordCount];
            return featuredContents;
        } catch(exception ex){
            return null;
        }
    }


}