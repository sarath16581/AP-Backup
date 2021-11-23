@isTest
//Test class for chatter feed wrapper used by customer community.
private class cpChatterFeedWrapper_Test{
    
    private static final String feedElementId = 'testfeedElementId';
    private static final String questionTitle = 'testquestionTitle';
    private static final String imageIconUrl = 'testimageIconUrl';
    private static final String actorId = 'testactorId';
    private static final String actorNickName = 'testactorNickName';
    private static final String relativeCreatedDate = 'testrelativeCreatedDate';
    private static final String bestAnswerId = 'testbestAnswerId';
    private static final Long toalViewCommentAndLikeCount = 12;
    private static final Long commentCount = 34;
    
    @isTest
    //Execute testing
    static void testChatterFeedWrapperMethods(){    
        
        Test.startTest();
        cpChatterFeedWrapper chtrfdwrprObj = new cpChatterFeedWrapper(feedElementId,questionTitle,imageIconUrl,actorId,actorNickName,relativeCreatedDate,toalViewCommentAndLikeCount,commentCount,bestAnswerId);
        Test.stopTest();
    }
}