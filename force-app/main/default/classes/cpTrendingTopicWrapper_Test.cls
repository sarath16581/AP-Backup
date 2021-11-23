@isTest
private class cpTrendingTopicWrapper_Test{
	private static final String topicId = 'testtopicId';
    private static final String topicName = 'testtopicName';
    private static final Integer talkingAboutCount = 34;
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
	static void testTrendingTopicWrapperMethods(){	
        loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            cpTrendingTopicWrapper topic = new cpTrendingTopicWrapper(topicId,topicName,talkingAboutCount);
            Test.stopTest();
        }
	}
}