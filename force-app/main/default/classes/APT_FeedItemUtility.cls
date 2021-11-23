/**
Description: Copy Feed Item records
Created By - Mausam Padhiyar
Created Date - 28th Oct, 2016
*/
public without sharing class APT_FeedItemUtility {
    
    /**
        Copy Feed Item records
    */
    public static void copyFeedItems(Id originalAgreementId, Id amendedAgreementId) {
        //1310
        //feeditem
        list<FeedItem> listFeedItem = [SELECT Id, BestCommentId, Body, 
                                        LinkUrl, NetworkScope, ParentId,
                                        RelatedRecordId, Revision, Title,  
                                        Visibility
                                        FROM FeedItem 
                                        WHERE ParentId = :originalAgreementId];
        set<Id> setExistingContentVersion = new set<Id>();
        if(listFeedItem != null && listFeedItem.size() > 0) {
            list<FeedItem> listNewFeedItem = new list<FeedItem>();
            FeedItem newFeedItem;
            
            for(FeedItem fi : listFeedItem) {
                setExistingContentVersion.add(fi.RelatedRecordId);
                
                newFeedItem = new FeedItem();
                newFeedItem = fi.clone();
                newFeedItem.ParentId = amendedAgreementId;
                newFeedItem.body = APT_Constants.SOURCE_SYSTEM_APTTUS;
                
                listNewFeedItem.add(newFeedItem);
            }
            
            if(listNewFeedItem != null && listNewFeedItem.size() > 0) {
                insert listNewFeedItem;
            }
        }
        //1310
    }
}