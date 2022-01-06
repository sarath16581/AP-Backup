@IsTest
private class brideas_UserProfileIdeasStatsCtrlTest {
    @testSetup
    static void setup() {
        List<Idea> ideasList;
        Idea testIdea_1;
        String cId;
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        cId = brideas_Helper.getCommunityId('');

        if (cId == NULL || cId == '') {
            throw new brideas_SetupException('To succesfully run the tests you need to crete a Zone with Name="TestPublic"');
        }

        User testUser = new User(Alias = 'testusr', Email = 'testusr@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testusr@testorg.com');

        ideasList = new List<Idea>();
        ideasList.add(new Idea(Title = 'Test idea_1', Body = 'Body of test idea_1', Status = 'New', Categories = 'test_1', CommunityId = cId));
        ideasList.add(new Idea(Title = 'Test idea_2', Body = 'Body of test idea_2', Status = 'Delivered', Categories = 'test_1', CommunityId = cId));

        System.assertEquals(2, ideasList.size(), 'Invalid number of ideas to insert');

        insert ideasList;

        testIdea_1 = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        insert new IdeaComment(CommentBody = 'First comment', IdeaId = testIdea_1.Id);

        System.runAs(testUser) {
            ideasList = new List<Idea>();
            ideasList.add(new Idea(Title = 'Test idea_5', Body = 'Body of test idea_5', Status = 'New', Categories = 'test_3', CommunityId = cId));
            ideasList.add(new Idea(Title = 'Test idea_6', Body = 'Body of test idea_6', Status = 'New', Categories = 'test_2', CommunityId = cId));
            ideasList.add(new Idea(Title = 'Test idea_7', Body = 'Body of test idea_7', Status = 'Delivered', Categories = 'test_2', CommunityId = cId));

            insert ideasList;

            insert new Vote(ParentId = testIdea_1.Id, Type = 'Up');
            insert new IdeaComment(CommentBody = 'Second comment', IdeaId = testIdea_1.Id);
        }
    }

    @isTest
    public static void testGetIdeasCountForUser() {
        User user = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com'];

        System.assertEquals(2, brideas_UserProfileIdeasStatsCtrl.getIdeasCountForUser(UserInfo.getUserId()), 'should return proper number of idea for specified user');
        System.assertNotEquals(2, brideas_UserProfileIdeasStatsCtrl.getIdeasCountForUser(user.Id), 'should return proper number of idea for specified user');
    }

    @isTest
    public static void testGetIdeaCommentsCountForUser() {
        User user = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com'];

        System.assertEquals(1, brideas_UserProfileIdeasStatsCtrl.getIdeaCommentsCountForUser(UserInfo.getUserId()), 'should return proper number of idea comments for specified user');
        System.assertEquals(1, brideas_UserProfileIdeasStatsCtrl.getIdeaCommentsCountForUser(user.Id), 'should return proper number of idea comments for specified user');
    }

    @isTest
    public static void testGetIdeaVotesCountForUser() {
        User user = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com'];

        System.assertEquals(4, brideas_UserProfileIdeasStatsCtrl.getIdeaVotesCountForUser(user.Id), 'should return proper number of idea comments for specified user');
        System.assertNotEquals(4, brideas_UserProfileIdeasStatsCtrl.getIdeaVotesCountForUser(UserInfo.getUserId()), 'should return proper number of idea comments for specified user');
    }

}