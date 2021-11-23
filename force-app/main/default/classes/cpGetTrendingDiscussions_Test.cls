@isTest
//Test class for Get Trending Discussion (used by Community Lightning Component)
private class cpGetTrendingDiscussions_Test{
	//Create Feedpage
	private static ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
    private static User adminUser = new User();
    //Load Test data
    private static void loadTestData(){

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
		
        //create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
    }

	@isTest
	//Execute test
	static void testgetTrendingDiscussionsMethods() {
		loadTestData();
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.FeedType.Home, 1, ConnectApi.FeedDensity.AllUpdates, '',10,ConnectApi.FeedSortOrder.CreatedDateDesc, ConnectApi.FeedFilter.CommunityScoped,testPage);
        System.runAs(adminUser){
            Test.startTest();
            list<cpTrendingDiscussionWrapper> wrapperList = cpGetTrendingDiscussions.getTrendingDiscussions(2,'CreatedDateDesc');
            Test.stopTest();
            System.assertEquals(1, wrapperList.size());
        }
	}
}