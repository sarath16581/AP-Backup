//Test class for Trending Discussion
@isTest
private class cpTrendingDiscussionWrapper_Test{
    private static final String  feedElementId = 'testFeedElementId';
    private static final String  questionTitle = 'testQuestionTitle';
    private static final Long  toalViewCommentAndLikeCount = 34;
    private static User adminUser = new User();
    
    /* Prepare Test data*/
    private static void loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
    }

    @isTest
    //Execute test for Trending Discussion 
    static void testTrendingDiscussionWrapperMethods(){
        loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            cpTrendingDiscussionWrapper discussions = new cpTrendingDiscussionWrapper(feedElementId,questionTitle,toalViewCommentAndLikeCount);
            Test.stopTest();
        }
    }
}