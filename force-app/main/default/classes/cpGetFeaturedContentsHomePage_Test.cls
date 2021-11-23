// Test class for fetch Featured content which returns feature content to component 
@isTest
private class cpGetFeaturedContentsHomePage_Test{
	
    private static User adminUser = new User();
    private static void loadTestData(){
        
        //create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
		
        //create Content
		Featured_Content__kav content = new Featured_Content__kav();
		content.Title = 'Test Article';
		content.UrlName = 'TestUrl';
		content.Language='en_US'; 
        content.DisplayonStoriesLandingPage__c=true;

		Database.insert(content);

		}

	@isTest
	static void testGetFeaturedContentsMethods(){
        loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            cpGetFeaturedContentsHomePage.getFeaturedContents(1);
            Test.stopTest();
        }
	}
}