@isTest
//Test Class for retrieve more article for Customer Community project
private class cpGetMoreArticles_Test{
    
    private static User adminUser = new User();
    
	//load test data
	private static Featured_Content__kav loadTestData(){
		//create Feature content 
		Featured_Content__kav content = new Featured_Content__kav();
		content.Title = 'Test Article';
		content.UrlName = 'TestUrl';
		content.Language='en_US';
        content.DisplayonHomepage__c=true;

		database.insert(content);
        
        //create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);

		return content;

	}
	@isTest
	//execute test
	static void testGetMoreArticlesMethods(){

		Featured_Content__kav content = loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            list<Featured_Content__kav> contentList = cpGetMoreArticles.getMoreArticles(content.Id,1);
            Test.stopTest();
        }

	}
}