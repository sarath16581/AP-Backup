@isTest
//Test Class for Get more Featured content for Customer Community
private class cpGetMoreFeaturedContent_Test {
    private static User adminUser = new User();
    //Load Test Data
    private static void loadTestData(){
        //create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
        
		//create content
		Featured_Content__kav content = new Featured_Content__kav();
		content.Title = 'Test Article';
		content.UrlName = 'TestUrl';
		content.Language='en_US';
        content.DisplayonStoriesLandingPage__c=true;

		Database.insert(content);
	}

    @isTest
    //Execute Test
	static void testGetFeaturedContentsMethods(){
        loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            cpGetMoreFeaturedContent.getMoreFeaturedContents(1,'test');
            Test.stopTest();
        }
	}

}