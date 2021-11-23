//Class to Retrieve Article for customer community project
public without sharing class cpGetMoreArticles {

    @AuraEnabled
    //Retrieve featured content 
    public static list<Featured_Content__kav> getMoreArticles(String articleId , Integer noOfRecordsTofetch){
        try{
            //Query to fetch Created by User Id  of the article
            String  contentCreatorId = [Select Id, CreatedById from Featured_Content__kav Where Id =: articleId Limit 1].CreatedById;
    
            //Query to fetch list of Articles for the Same ContentCreator
            list<Featured_Content__kav> contentList = new list<Featured_Content__kav>();
    
            //no of records to fetch from Query to display on UI
            Integer recordCount = 3;
    
            if(Integer.valueOf(noOfRecordsTofetch) > 0){
                recordCount = Integer.valueOf(noOfRecordsTofetch);
            }
    
            //system.debug('recordCount=from MoreArticles==>'+recordCount);
    
            contentList = [Select Id, Title from Featured_Content__kav
                                           Where CreatedById  =: contentCreatorId
                                           And PublishStatus='Online'
                                           And Language='en_US'
                                           And DisplayonHomepage__c=true
                                           LIMIT : recordCount];
    
            if(contentList.size() > 0){
                return contentList;
            } else
                return null;
            
        } catch(exception ex){
            return null;
        }
    }
}