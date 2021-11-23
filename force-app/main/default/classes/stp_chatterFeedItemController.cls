/*
 * @Description : Controller class to get the feed item for the given task and create custom view since standard force:chatter
 * 				  is not available for portal user
 * ---------------Modification log-----------------------------------------
 * Date			Author							Description
 * 08/04/2019	Ramtej.juloori@auspost.com.au	Created
 * 02/11/2019	LJ								Partner Portal Feed visibility update
 */
public without sharing class stp_chatterFeedItemController {
	
    /*
     * method to form the feed item wrapper and pass to lightning component to create
     * custom forcechatter feed view
     */
    @AuraEnabled
    public static List<feedItemListWrapper> getFeedItemList(Id taskId){
        try{
            List<FeedItem> feedList = new List<FeedItem>();
            set<Id> insertedUserId = new set<Id>();
            set<Id> contentVersionIdList = new set<Id>();
            Map<Id,Id> contentVersionToContentDocIdMap = new Map<Id,Id>();
            List<feedItemListWrapper> feedItemWrapperList = new List<feedItemListWrapper>();
            // Show the feeds which are visible for all users.
            for(FeedItem feed :[Select Id, body, InsertedById, InsertedBy.Name, ParentId, Title, 
                                CreatedDate, Type, Parent.Name,
                                (SELECT Id, FieldName, NewValue, OldValue FROM FeedTrackedChanges),
            (SELECT Id,Title, type FROM FeedAttachments),
                                (SELECT Id, LastEditById, LastEditDate, FeedItemId, CommentType, RelatedRecordId, 
                                 CommentBody, Revision, ParentId, CreatedDate, InsertedbyId FROM FeedComments)
                                FROM FeedItem
                                WHERE ParentId = :taskId
                                AND  Visibility = 'AllUsers'
                ]){
                feedList.add(feed);
                insertedUserId.add(feed.InsertedById);
                                    
                //Iterate through feed comments and collect user ids to get photo url
                //and collect related id to get related contentdocumentid
                for(FeedComment feedCom :feed.FeedComments){
                    if(feedCom.Revision > 1){
                     	insertedUserId.add(feedCom.LastEditById);   
                    }
                    else{
                        insertedUserId.add(feedCom.InsertedbyId);
                    }
                    contentVersionIdList.add(feedCom.RelatedRecordId);
                }
            }
            
            //create a map of contentversionid and contentdocumentid in order to use in feed comment wrapper
            for(ContentVersion cv :[SELECT Id, ContentDocumentId FROM ContentVersion WHERE ID IN :contentVersionIdList]){
                contentVersionToContentDocIdMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            //Since SmallPhotoUrl is not available from feed item's InsertedBy field query seperately collecting user id
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, SmallPhotoUrl FROM User WHERE Id IN :insertedUserId]);
                    
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            
            //Iterate the feed item queried for the task
            for(FeedItem feed :feedList){
                //since fieldname field in the object holds API name of the field and not field label created
                //wrapper list to hold the field label and changed values
                List<feedTrackChangeWrapper> feedTrackChanges = new List<feedTrackChangeWrapper>();
                //if the feed type is because when record is updated
                if(feed.Type == 'TrackedChange'){
                    system.debug('feed.FeedTrackedChanges '+feed.FeedTrackedChanges);
                    for(FeedTrackedChange track :feed.FeedTrackedChanges){
                        string oldValue = string.valueOf(track.OldValue);
                        string newValue = string.valueOf(track.NewValue);
                        //for a feed item of change in reference field is created one with ids and one with name values
                        //Ignore the id changed record by checking it for a valid salesforce id
                        boolean oldValueisNotId = string.isBlank(oldValue) ? true : isNotValidSalesforceId(oldValue);
                        boolean newValueisNotId = string.isBlank(newValue) ? true : isNotValidSalesforceId(newValue);
                        //process only if old value and new value are not salesforce ids
                        if(oldValueisNotId && newValueisNotId){                        
                            //create wrapper with feed track change values
                            feedTrackChanges.add(createTrackChangeWrapper(string.valueOf(track.FieldName), oldValue, newValue, schemaMap));    
                        }                    
                    }    
                    system.debug('feedTrackChanges '+feedTrackChanges);
                }
            
                string dateString = dateTimeFormatted(feed.CreatedDate);
                //Create wrapper of feed item with feed item record, user photo, date and feed trackchanges
                String description = '';
                if (feed.Body != null){
                 	description += feed.Body.stripHtmlTags();   
                }                    
                feed.Body = description;
                feedItemWrapperList.add(new feedItemListWrapper(feed, userMap.get(feed.InsertedById).SmallPhotoUrl, 
                                                                dateString, feedTrackChanges, 
                                                                createfeedCommentWrapper(feed.FeedComments, userMap, contentVersionToContentDocIdMap)));
            }
            
            return feedItemWrapperList;
        }
        catch(exception ex){
            system.debug('error at getting feed list item '+ex.getMessage()+' at line '+ex.getStackTraceString());
            return null;
        }
    }
    
    /*
     * method to create change track wrapper. 
     * This logic is in a seperate method since feed item of type trackedChange cannot be created in test class
     * and hence cannot test the below logic.
     */
    public static feedTrackChangeWrapper createTrackChangeWrapper(string fieldName, string oldValue, string newValue, Map<String, Schema.SObjectType> schemaMap){
        //get the field label using the field API name stored in fieldname field of feedtrackedChange object        
        Schema.SObjectType objectSchema = schemaMap.get(fieldName.split('\\.')[0]);
        Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
        string fieldLabel = fieldMap.get(fieldName.split('\\.')[1]).getDescribe().getLabel();
        
        //replace null strings with text A blank value
        if(string.isBlank(oldValue)){
            oldValue = 'A blank value';
        }
        if(string.isBlank(newValue)){
            newValue = 'a blank value';
        }
        return new feedTrackChangeWrapper(fieldLabel, oldValue, newValue);
        
    }
    
    /*
     * Method to create a list of feed comment wrapper for a given feed item
     */
    public static List<feedCommentWrapper> createfeedCommentWrapper(List<FeedComment> feedCommentList, Map<Id, User> userMap, Map<Id,Id> contentVersionToContentDocIdMap){
        List<feedCommentWrapper> feedCommentWrapperList = new List<feedCommentWrapper>();
        
        for(FeedComment feedCom :feedCommentList){
            string feedCommentCreatedOrEditedByPhotoURL = '';
            string feedCommentCreatedOrEditedDate = '';            
            string feedCommentCreatedOrEditedBy = '';
            //Identify if the feed comment is edited and use edited details if edited 
            if(feedCom.Revision > 1){
                feedCommentCreatedOrEditedDate = 'Edited '+dateTimeFormatted(feedCom.LastEditDate);
                feedCommentCreatedOrEditedByPhotoURL = userMap.get(feedCom.LastEditById).SmallPhotoUrl;
                feedCommentCreatedOrEditedBy = userMap.get(feedCom.LastEditById).Name;
            }
            //else use created details
            else{
                feedCommentCreatedOrEditedDate = dateTimeFormatted(feedCom.CreatedDate);
                feedCommentCreatedOrEditedByPhotoURL = userMap.get(feedCom.InsertedById).SmallPhotoUrl;
                feedCommentCreatedOrEditedBy = userMap.get(feedCom.InsertedById).Name;
            }
            
            //create a feed comment wrapper
            feedCommentWrapper feedComWrap = new feedCommentWrapper(feedCommentCreatedOrEditedByPhotoURL, feedCommentCreatedOrEditedDate, 
                                  feedCommentCreatedOrEditedBy, contentVersionToContentDocIdMap.get(feedCom.RelatedRecordId), feedCom.CommentBody);
            feedCommentWrapperList.add(feedComWrap);
        }
        
        return feedCommentWrapperList;
    }
    
    /*
     * Method to check if the passed string is valid salesforce id 
     */
    public static Boolean isNotValidSalesforceId(String sfdcId){
        try{
            //match the string value with salesforce pattern match
            if ( Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher( sfdcId ).matches() ){
                return false;
            } 
            else{
                return true;
            }
        }
        catch ( Exception e ){
            system.debug('exception caught in id validation method '+e.getMessage()+' at '+e.getStackTraceString());
            return null;
        }
    }
    
    /*
     * Method to form a customised format of datetime
     */
    public static string dateTimeFormatted(DateTime dateTimeToBeFormatted){
        string timeFormatted = dateTimeToBeFormatted.format('hh:mm a');
        string dateFormatted = dateTimeToBeFormatted.format('dd MMMMM YYYY');
        return dateFormatted+' at '+timeFormatted;
    }
    
    /*
     * wrapper class to hold feed item data
     */
    public class feedItemListWrapper{
        @AuraEnabled public FeedItem feed {get; set;}
        @AuraEnabled public string photoURL {get; set;}
        @AuraEnabled public string feedCreatedDate {get; set;}
        @AuraEnabled public List<feedTrackChangeWrapper> feedTrackChanges {get; set;}
        @AuraEnabled public List<feedCommentWrapper> feedComments {get; set;}
        
        public feedItemListWrapper(feedItem feed, string photoURL, string feedCreatedDate, List<feedTrackChangeWrapper> feedTrackChanges,
                                  List<feedCommentWrapper> feedComments){
            this.feed = feed;
            this.photoURL = photoURL;
            this.feedCreatedDate = feedCreatedDate;
            this.feedTrackChanges = feedTrackChanges;
            this.feedComments = feedComments;
        }
    }
    
    /*
     * wrapper class to hold changed field values with field name
     */
    public class feedTrackChangeWrapper{
        @AuraEnabled public string fieldName {get; set;}
        @AuraEnabled public string oldValue {get; set;}
        @AuraEnabled public string newValue {get; set;}
        
        public feedTrackChangeWrapper(string fieldName, string oldValue, string newValue){
            this.fieldName = fieldName;
            this.oldValue = oldValue;
            this.newValue = newValue;
        }
    }
    
    /*
     * wrapper class to hold comments on the feed
     */
    public class feedCommentWrapper{
        @AuraEnabled public string feedCommentCreatedOrEditedByPhotoURL {get; set;}
        @AuraEnabled public string feedCommentCreatedOrEditedDate {get; set;}
        @AuraEnabled public string feedCommentCreatedOrEditedBy {get; set;}
        @AuraEnabled public string feedCommentrelatedRecordid {get; set;}
        @AuraEnabled public string feedCommentBody {get; set;}
        
        public feedCommentWrapper(string feedCommentCreatedOrEditedByPhotoURL, string feedCommentCreatedOrEditedDate, 
                                  string feedCommentCreatedOrEditedBy, string feedCommentrelatedRecordid, string feedCommentBody){
            this.feedCommentCreatedOrEditedByPhotoURL = feedCommentCreatedOrEditedByPhotoURL;
            this.feedCommentCreatedOrEditedDate = feedCommentCreatedOrEditedDate;
            this.feedCommentCreatedOrEditedBy = feedCommentCreatedOrEditedBy;
            this.feedCommentrelatedRecordid = feedCommentrelatedRecordid;
            this.feedCommentBody = feedCommentBody;
        }
    }

}