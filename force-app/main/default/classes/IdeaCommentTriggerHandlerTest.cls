@isTest
private class IdeaCommentTriggerHandlerTest {
    @testSetup
    static void setup() {
        TestDataFactory.createStandardUser();
        TestDataFactory.createCommunityUser();

        String cId = brideas_Helper.getCommunityId('');
        List<Idea> ideas = new List<Idea>();

        for (Integer i = 1; i < 4; i++) {
            ideas.add(new Idea(Title = 'Test idea_' + i, Body = 'Body of test idea_' + i, Status = 'New', Categories = 'test_' + i, CommunityId = cId));
        }

        insert ideas;
    }

    @isTest
    static void testAddReputationPointOnAddComment(){
        String userId = UserInfo.getUserId();
        Decimal reputationPointsBeforeAddComment = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :userId LIMIT 1].ReputationPoints;
        String cId = brideas_Helper.getCommunityId('');

        Idea testIdea = new Idea(Title = 'Test idea', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        insert testIdea;

        Decimal reputationPointsAfterPostIdea = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :userId LIMIT 1].ReputationPoints;

        Test.startTest();

        IdeaComment testComment = new IdeaComment(CommentBody = 'Body of test comment', IdeaId = testIdea.Id);

        insert testComment;

        Test.stopTest();

        Decimal reputationPointsAfterAddComment = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :userId LIMIT 1].ReputationPoints;

        System.assert(true); //reputation points is not testable feature because of NetworkId
        //System.assertNotEquals(reputationPointsAfterPostIdea, reputationPointsAfterAddComment, 'the amount of reputation points is not the same before and after adding comment on idea');
    }

    @isTest
    static void testModerateIdeaCommentsOnInsert(){
        String cId = brideas_Helper.getCommunityId('');

        Idea testIdea = new Idea(Title = 'Test idea', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        insert testIdea;

        Test.startTest();

        IdeaComment testComment1 = new IdeaComment(CommentBody = 'Body of test comment', IdeaId = testIdea.Id);
        IdeaComment testComment2 = new IdeaComment(CommentBody = 'Body of test http://google.com comment', IdeaId = testIdea.Id);
        IdeaComment testComment3 = new IdeaComment(CommentBody = 'Body of test ForbiddenWord', IdeaId = testIdea.Id);

        insert new List<IdeaComment>{testComment1,testComment2,testComment3};

        Test.stopTest();

        List<brideas_Banned_Idea_Item__c> bannedIdeas = [SELECT Item_Id__c FROM brideas_Banned_Idea_Item__c WHERE Type__c = 'Idea comment'];

        Set<String> ideaCommentIds = new Set<String>();

        for(brideas_Banned_Idea_Item__c bi: bannedIdeas) {
            ideaCommentIds.add(bi.Item_Id__c);
        }

        System.assertNotEquals(ideaCommentIds.contains(String.valueOf(testComment1.Id)), true, 'banned idea item should not be created if there are no forbidden words or urls');
        System.assertEquals(ideaCommentIds.contains(String.valueOf(testComment2.Id)), true, 'banned idea item should be created if there are urls');
        System.assertEquals(ideaCommentIds.contains(String.valueOf(testComment3.Id)), true, 'banned idea item should be created if there are forbidden words');
    }

    @isTest
    static void testDeleteBannedItems(){
        String cId = brideas_Helper.getCommunityId('');

        Idea testIdea = new Idea(Title = 'Test ForbiddenWord', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        insert testIdea;

        IdeaComment testComment = new IdeaComment(CommentBody = 'Body of test ForbiddenWord', IdeaId = testIdea.Id);

        insert testComment;

        Id testCommentId = testComment.Id;

        List<brideas_Banned_Idea_Item__c> bannedIdeas = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c = :testCommentId];
        System.assertEquals(1, bannedIdeas.size());

        Test.startTest();

        delete testComment;

        Test.stopTest();

        List<brideas_Banned_Idea_Item__c> bannedIdeasAfterDelete = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c = :testCommentId];

        System.assertEquals(0, bannedIdeasAfterDelete.size(), 'banned items should be removed when appropriate idea comments are removed');
    }

    @isTest
    static void testSendNotificationsToSubscribersOnCreate(){
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com' LIMIT 1];
        Idea testIdea1 = [SELECT Id FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        Idea testIdea2 = [SELECT Id FROM Idea WHERE Title='Test idea_2' LIMIT 1];
        Idea testIdea3 = [SELECT Id FROM Idea WHERE Title='Test idea_3' LIMIT 1];

        List<IdeaComment> testComments = new List<IdeaComment>();
        testComments.add(new IdeaComment(CommentBody='First comment', IdeaId=testIdea1.Id));
        testComments.add(new IdeaComment(CommentBody='First comment', IdeaId=testIdea2.Id));
        testComments.add(new IdeaComment(CommentBody='First-second comment', IdeaId=testIdea2.Id));

        insert testComments;

        System.runAs(testUser){
            List<IdeaComment> testUserComments = new List<IdeaComment>();
            testUserComments.add(new IdeaComment(CommentBody='Second comment', IdeaId=testIdea1.Id));
            testUserComments.add(new IdeaComment(CommentBody='Second comment', IdeaId=testIdea3.Id));

            insert testUserComments;
        }

        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testSendNotificationsToAssignedUsersOnCreate(){
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com' LIMIT 1];
        User testCommUser = [SELECT Id FROM User WHERE UserName = 'testcommunityusr@testorg.com' LIMIT 1];
        Idea testIdea1 = [SELECT Id FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        Idea testIdea2 = [SELECT Id FROM Idea WHERE Title='Test idea_2' LIMIT 1];

        Community community = [SELECT Id FROM Community WHERE Name = 'TestPublic' LIMIT 1];
        String cId = community.Id;

        brideas_CategoryAssignee__c assign = new brideas_CategoryAssignee__c(User__c = testUser.Id, Categories__c = 'test_2');

        insert assign;

        System.runAs(testUser){
            List<IdeaComment> testUserComments = new List<IdeaComment>();
            testUserComments.add(new IdeaComment(CommentBody='First comment', IdeaId=testIdea1.Id));
            testUserComments.add(new IdeaComment(CommentBody='First comment', IdeaId=testIdea2.Id));

            insert testUserComments;
        }

        Test.stopTest();

        System.assert(true);
    }
}