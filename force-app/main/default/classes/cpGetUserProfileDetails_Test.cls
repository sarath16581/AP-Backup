/****************************************************************************************
Description: Test class to cover cpGetUserProfileDetails Controller functionality
History:
-----------------------------------------------------------------------------------------
            No Created History found.
2018-06-07  TDO-38 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            Test to Retrieve Article author profile by setting Title UrlName CreatedById,
            Test for exception during Retrieve Article author profile.
*****************************************************************************************/
@isTest
private class cpGetUserProfileDetails_Test{

    private static User adminUser = new User();

    /***********************************************************
     *  Scenario:
     *      Prepare Test data to Retrieve Article author profile.
     ***********************************************************/
    private static void loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();

        Profile adminProf = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        String adminEmail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminEmail);
        Database.insert(adminUser);
    }

    /***********************************************
     *  Scenario:
     *      Test to Retrieve Article author profile.
     ***********************************************/
    /*TDO_TODO: Removing seeAllData = true caused exception - Caused by: system.UnsupportedOperationException:
    ConnectApi methods are not supported in data isolated tests. Please use @IsTest(SeeAllData=true).*/
    @isTest(seeAllData = true)
    static void retrieveArticleAuthorProfileWithTitleUrlname(){
        Featured_Content__kav content = new Featured_Content__kav();
        content.Title = 'Test Article';
        content.UrlName = 'TestUrl';
        Database.insert(content);

        //Calling the loadTestData method to prepare test data.
        loadTestData();
        cpUserProfileWrapper wrappedProfile;
        System.runAs(adminUser){
            Test.startTest();
            wrappedProfile = cpGetUserProfileDetails.GetUserProfileDetails(content.Id);
            Test.stopTest();
        }

        System.assertNotEquals(null,wrappedProfile.userFullName,
                'cpGetUserProfileDetails_Test_retrieveArticleWithTitleUrlNameCreatedById : User Full Name is retrieved.');

    }

    /*****************************************************************
     *  Scenario:
     *      Test for exception during Retrieve Article author profile.
     *****************************************************************/
    @isTest
    static void testForRetrieveException(){
        Featured_Content__kav content = new Featured_Content__kav();
        content.Title = 'Test Article';
        content.UrlName = 'TestUrl';
        Database.insert(content);

        //Calling the loadTestData method to prepare test data.
        loadTestData();
        cpUserProfileWrapper wrappedProfile;
        System.runAs(adminUser){
            Test.startTest();
                wrappedProfile = cpGetUserProfileDetails.GetUserProfileDetails(content.Id);
            Test.stopTest();
        }

        System.assertEquals(null,wrappedProfile,
                'cpGetUserProfileDetails_Test_testForRetrieveException : User Full Name and Small Photo url are not retrieved.');

    }

    /*****************************************************************************************************
     *  Scenario:
     *      Setting Featured Content with Title,UrlName,CreatedById during Retrieve Article author profile.
     *****************************************************************************************************/
    @isTest(seeAllData = true)
    static void retrieveArticleWithTitleUrlNameCreatedById(){
        User testUser = [SELECT Id FROM User LIMIT 1];

        Featured_Content__kav content = new Featured_Content__kav();
        content.Title = 'Test Article';
        content.UrlName = 'TestUrl';
        content.CreatedById = testUser.Id;
        Database.insert(content);

        //Calling the loadTestData method to prepare test data.
        loadTestData();
        cpUserProfileWrapper wrappedProfile;
        System.runAs(adminUser){
            Test.startTest();
                wrappedProfile = cpGetUserProfileDetails.GetUserProfileDetails(content.Id);
            Test.stopTest();
        }

        System.assertNotEquals(null,wrappedProfile.userFullName,
                'cpGetUserProfileDetails_Test_retrieveArticleWithTitleUrlNameCreatedById : User Full Name is retrieved.');
    }
}