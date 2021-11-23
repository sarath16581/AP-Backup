/* Test Class for UserProfile used by Community Cloud Project*/
@isTest
private class cpUserProfileWrapper_Test{
	private static final String userFullName = 'testUserFullName';
    private static final String smallPhotoUrl = 'testSmallPhotoUrl';
	private static User adminUser = new User();
    
    /* Prepare Test data*/
    private static void loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
    }
    
	/*Testing on community cloud homepage card component to display user profile image*/
    @isTest
	static void testUserProfileWrapperMethods(){
        loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            cpUserProfileWrapper profwprprObj = new cpUserProfileWrapper(userFullName,smallPhotoUrl);
            Test.stopTest();
        }
	}
}