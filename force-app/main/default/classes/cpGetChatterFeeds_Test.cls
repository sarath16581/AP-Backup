@isTest
//Test class for chatter feeds retrieve used by component in Customer Community
private class cpGetChatterFeeds_Test {
    private static User adminUser = new User();
    //Get chatter feeds
    private static ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
    //Prepare test data
    private static void loadTestData(){
        
        //create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
        
        //create Feed elements data
        List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
        testItemList.add(new ConnectApi.FeedItem());
        testItemList.add(new ConnectApi.FeedItem());
        testPage.elements = testItemList;
        ConnectApi.FeedElement feedElement = testPage.elements[0];
        feedElement.capabilities = new ConnectApi.FeedElementCapabilities();
        feedElement.relativeCreatedDate = '47m ago';            
        feedElement.capabilities.questionAndAnswers = new ConnectAPI.QuestionAndAnswersCapability();
        feedElement.capabilities.questionAndAnswers.questionTitle = 'If a feed element has this capability, it has a question and comments on the feed element are answers to the question.';
        
        feedElement.capabilities.questionAndAnswers.bestAnswer = new ConnectApi.Comment();
        feedElement.capabilities.questionAndAnswers.bestAnswer.Id = '0D7O00000003VNTKA2';
        
        feedElement.capabilities.questionAndAnswers.bestAnswer.body = new ConnectApi.FeedBody();
        feedElement.capabilities.questionAndAnswers.bestAnswer.body.text = 'If a feed element has this capability, it has a question and comments on the feed element are answers to the question.';
        
        //Interaction records
        feedElement.capabilities.interactions = new ConnectApi.InteractionsCapability();
        feedElement.capabilities.interactions.count = 5;
        
        feedElement.capabilities.comments = new ConnectApi.CommentsCapability();
        feedElement.capabilities.comments.page = new ConnectApi.CommentPage();
        feedElement.capabilities.comments.page.total = 15;
    }
	
    @isTest
    //Execute testing
    static void testChatterFeedMethods() {
        loadTestData();
        System.runAs(adminUser){
            ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.FeedType.Home, ' ', 10, ConnectApi.FeedSortOrder.CreatedDateDesc, testPage);
            Test.startTest();
            list<cpChatterFeedWrapper> wrapperList = cpGetChatterFeeds.getFeedElements(2);
            Test.stopTest();
            System.assertEquals(1, wrapperList.size());
        }
    }
}