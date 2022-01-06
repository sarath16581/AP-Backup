@isTest
private class brideas_CommunityCtrlTest {

    @isTest
    private static void testGetUserDisplayName(){
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com', FirstName='Test',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', CommunityNickname = 'testnickname',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com');

        insert testUser;

        String uName = brideas_CommunityCtrl.getUserDisplayName(testUser.Id);

        brideas_CommunityCtrl.showUserNickname = true;

        String uName2 = brideas_CommunityCtrl.getUserDisplayName(testUser.Id);

        System.assertEquals('Test Testing', uName);
        System.assertEquals('testnickname', uName2);
    }

    @isTest
    private static void testGetSurveyURL(){
        Test.startTest();

        String testUrl = brideas_CommunityCtrl.getSurveyURL();

        Test.stopTest();

        System.assertEquals('https://example.com', testUrl);
    }
}