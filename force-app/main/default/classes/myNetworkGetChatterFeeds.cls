/*
* @author       : haraprasad.sahoo@auspost.com.au
* @date         : 23/03/2020
* @description  : Apex class controller for myNetworkChatterPublisher LWC component
--------------------------------------- History --------------------------------------------------
23.03.2020    Hara Sahoo    Created
01.05.2020    Hara Sahoo    Modified Added FeedItem Type 'TextPost'
03.03.2021    Naseer Abbasi Filtered feed items where Created by a My Network user

*/
public without sharing class myNetworkGetChatterFeeds {
    @AuraEnabled(cacheable=true)
    //Get chatter feeds
    public static list<feedItemListWrapper> getFeedElements(Integer noOfRecordsToFetch , Id recordId) { 
        try {
            //Fetch  user’s current community
            String communityId = Network.getNetworkId();
            system.debug('this is communityId'+ communityId);
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
            String commentText = '';
            Integer maxResult = 100;
            //recordCountToFetch contains the no of records to be displayed on UI
            Integer recordCountToFetch = 25;
            if(Integer.valueOf(noOfRecordsToFetch) > 0 && Integer.valueOf(noOfRecordsToFetch) < 101){
                recordCountToFetch = Integer.valueOf(noOfRecordsToFetch);
            }  
            List<FeedItem> feedList = new List<FeedItem>();
            set<Id> insertedUserId = new set<Id>();
            list<feedItemListWrapper> wrappedChatterFeed = new list<feedItemListWrapper>();
            //Get the FeedItem Map and the CreatedBy UserId Map
            if(string.isNotBlank(communityId) || test.isRunningTest()) {
                Id myNetworkProfileId = [SELECT Id FROM Profile WHERE Name = 'MyNetwork Portal'].Id;
                for(FeedItem feed :[Select Id, body, InsertedById,InsertedBy.Name, InsertedBy.ProfileId, ParentId, Title, CreatedDate, Type, Parent.Name FROM FeedItem WHERE ParentId = :recordId 
                                    AND Type ='TextPost']) {
                    feedList.add(feed);
                    insertedUserId.add(feed.InsertedById);                
                }
                for( FeedItem feeds : feedList) {
                    if(feeds.InsertedBy.ProfileId == myNetworkProfileId) {
                        commentText=feeds.Body;
                        string dateString = stp_chatterFeedItemController.dateTimeFormatted(feeds.CreatedDate);
                        wrappedChatterFeed.add(new feedItemListWrapper(feeds,commentText,feeds.insertedBy.Name,dateString));
                    }    
                }
                return wrappedChatterFeed; 
            }
            else {
                throw (new AUPostCustomException('No community found')); 
            }
            
            
        }
        
        catch(exception ex){
            return null;
        }
    }
    @AuraEnabled  
    //Post chatter feed
    public static void postNotification(String recordId, String messageBody){
        try{
            FeedItem item = new FeedItem(parentId = recordId, body = messageBody,Type='TextPost',isRichText = true);
            insert item;
        }  catch(exception ex){
            return;
        }
    }
    
    public without sharing class AUPostCustomException extends Exception {}
    /* wrapper class to hold feed item data*/
    
    public class feedItemListWrapper{
        @AuraEnabled public FeedItem feed {get; set;}
        @AuraEnabled public string postComment {get; set;}
        @AuraEnabled public string feedCreatedBy {get; set;}
        @AuraEnabled public String feedCreatedDate {get; set;}
        public feedItemListWrapper(feedItem feed, string postComment, string feedCreatedBy,String feedCreatedDate){
            this.feed = feed;     
            this.postComment = postComment;
            this.feedCreatedBy = feedCreatedBy;
            this.feedCreatedDate = feedCreatedDate;
        }
    }  
}