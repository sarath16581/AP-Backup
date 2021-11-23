@isTest
//Test class for chatter trending topic retrieve used by component in Customer community.
private class cpGetChatterTrendingTopics_Test{
    
    private static User adminUser = new User();
	//Get trending topic
    private static ConnectApi.TopicPage testPage = new ConnectApi.TopicPage();
    //Prepare test data
    private static void loadTestData(){
    	//create Topic
        List<ConnectApi.Topic> testItemList = new List<ConnectApi.Topic>();
        testItemList.add(new ConnectApi.Topic());
        testItemList.add(new ConnectApi.Topic());
        testPage.topics = testItemList;
        ConnectApi.Topic topic = testPage.topics[0];
        topic.name = 'topicName';
        topic.talkingAbout = 12;
        
		//create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);        
    }
    
	@isTest
    //Execute testing
	static void testGetChatterTrendingTopicsMethods(){
		loadTestData();
        System.runAs(adminUser){
            ConnectApi.Topics.setTestGetTrendingTopics(null,10,testPage);
            Test.startTest();
            list<cpTrendingTopicWrapper> wrapperList = cpGetChatterTrendingTopics.getTrendingChatterTopics(2);
            Test.stopTest();
            System.assertEquals(2, wrapperList.size());
        }
	}
}