/*
 * @Description : Test class for stp_chatterFeedItemController
 * ---------------Modification log-----------------------------------------
 * Date			Author							Description
 * 09/04/2019	Ramtej.juloori@auspost.com.au	Created
 */
@istest
public class stp_chatterFeedItemControllerTest {

    @testsetup
    public static void createTask(){
        //Test data for Task and feed items related to task

        //Insert task
        Task ts = new Task();
        ts.Status = 'Not Started';
        insert ts;
        
        //Create feed items of types record created event and post
        FeedItem createRecord = new FeedItem(ParentId = ts.Id, Type = 'CreateRecordEvent');              
        FeedItem post = new FeedItem(ParentId = ts.Id, Type = 'TextPost', Body = 'Test',  Visibility = 'AllUsers');
        insert new List<FeedItem>{createRecord, post};
        
        //Insert file to attach when a feed comment is added
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode('base64Data');
        cv.Title = 'fileName';
        cv.PathOnClient = 'filename';        
        insert cv;
        
        //Insert feed comments
        FeedComment feedCom = new FeedComment(FeedItemId = post.Id, relatedRecordId = cv.Id, CommentBody = 'Create comm1');
        FeedComment feedCom2 = new FeedComment(FeedItemId = post.Id, relatedRecordId = cv.Id, CommentBody = 'Create comm2');
        insert new List<FeedComment>{feedCom, feedCom2};
            
        //update a feed comment to test edited comment functionality
        feedCom.CommentBody = 'Edit COmm';
        update feedCom;
    }
    
    /*
     * Method to test getFeedItems method
     */
    public testmethod static void getFeedItemsTest(){
        List<Task> taskList = [SELECT Id, Depot_Role__c, Status, TaskUpdate__c FROM Task];
        Test.startTest();
        	List<stp_chatterFeedItemController.feedItemListWrapper> feedItemWrapperList = stp_chatterFeedItemController.getFeedItemList(taskList[0].Id);
        	system.assertEquals(1, feedItemWrapperList.size());
        Test.stopTest();
    }
    
    /*
     * Method to test createTrackChangeWrapper method
     */
    public testmethod static void createTrackChangeWrapperTest(){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        stp_chatterFeedItemController.feedTrackChangeWrapper changeWrap1 = stp_chatterFeedItemController.createTrackChangeWrapper('Task.Status', null, 'Not Started', schemaMap);
        system.assertEquals('A blank value', changeWrap1.oldValue);
        stp_chatterFeedItemController.feedTrackChangeWrapper changeWrap2 = stp_chatterFeedItemController.createTrackChangeWrapper('Task.Status', 'Not Started', null, schemaMap);
        system.assertEquals('a blank value', changeWrap2.newValue);
    }
    
    /*
     * Method to test isNotValidSalesforceId method
     */
    public testmethod static void isNotValidSalesforceIdTest(){
        system.assertEquals(false, stp_chatterFeedItemController.isNotValidSalesforceId([SELECT Id FROM Task LIMIT 1].Id));
        system.assertEquals(true, stp_chatterFeedItemController.isNotValidSalesforceId('Invalid SF ID'));
    }
}