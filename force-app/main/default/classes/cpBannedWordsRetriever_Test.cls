@isTest
//Test class for banned words retrieve used by Customer community nickname validation
private class cpBannedWordsRetriever_Test{
    private static User adminUser = new User();
    //prepare test data
    private static void loadTestData(){
        
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
    }
    
	@isTest
    //Execute testing
	static void testBannedWordsRetrieverMethods(){
		Set<String> bannedwords = new Set<String>();
        loadTestData();
        System.runAs(adminUser){
           	Test.startTest();
			cpBannedWordsRetriever wordRetriever = new cpBannedWordsRetriever('BannedWordsKey');
        	bannedwords = wordRetriever.getWords();
			Test.stopTest(); 
        }
	}
}