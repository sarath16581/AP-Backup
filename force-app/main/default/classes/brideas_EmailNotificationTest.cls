@isTest
private class brideas_EmailNotificationTest {

    @testSetup
    static void setup(){
        Test.startTest();

        String cId = brideas_Helper.getCommunityId('');
        Idea testIdea = new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1',
                                CommunityId=cId);
        insert testIdea;

        IdeaComment comment = new IdeaComment(CommentBody='First comment', IdeaId=testIdea.Id);

        insert comment;

        Test.stopTest();

        testIdea = [SELECT Title FROM Idea WHERE Id = :testIdea.Id];
        comment = [SELECT IdeaId FROM IdeaComment WHERE Id = :comment.Id];

        System.assertEquals('Test idea_1', testIdea.Title);
        System.assertEquals(testIdea.Id, comment.IdeaId);
    }

    @isTest
    private static void testAddIdeaCreatedNotification(){
        Test.startTest();

        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];

        Idea testIdea = [SELECT Status, Title, Body, CommunityId, CreatorName FROM Idea LIMIT 1];

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addIdeaCreatedNotification(UserInfo.getUserEmail(), testIdea, 'NewIdeaNotificationToCategoryAssignee');
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 1, elogNum);
    }

    @isTest
    private static void testAddNewCommentNotification(){
        Test.startTest();

        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];

        Idea testIdea = [SELECT Id FROM Idea LIMIT 1];
        // Updated to retrieve CreatorName to use Nicknames in notifications to external users - Communities
        IdeaComment comment = [SELECT CommentBody, Idea.CommunityId, Idea.Title, CreatorName
                                FROM IdeaComment WHERE IdeaId = :testIdea.Id LIMIT 1];

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addNewCommentNotification(UserInfo.getUserEmail(), comment, 'NewCommentNotificationToSubscriber');
        en.addNewCommentNotification(UserInfo.getUserEmail(), comment, 'NewCommentNotificationToCategoryAssignee');
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 2, elogNum);
    }

    @isTest
    private static void testAddStatusChangeNotification(){
        Test.startTest();

        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];

        Idea testIdea = [SELECT Status, Title, Body, CommunityId FROM Idea LIMIT 1];

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addStatusChangeNotification(new List<String>{'test@test.com'}, testIdea, 'OldStatus', 'ChangeStatusNotificationToSubscriber');
        en.addStatusChangeNotification(new List<String>{'test@test.com'}, testIdea, 'OldStatus', 'ChangeStatusNotificationToCategoryAssignee');
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 2, elogNum);
    }

    @isTest
    private static void testAddIdeaModeratedNotification(){
        Test.startTest();

        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];

        Idea testIdea = [SELECT Status, Title, Body, CommunityId FROM Idea LIMIT 1];

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addIdeaModeratedNotification(testIdea);
        en.addIdeaModeratedNotification(testIdea);
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 2, elogNum);
    }

    @isTest
    private static void testAddIdeaCommentModeratedNotification(){
        Test.startTest();

        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];

        Idea testIdea = [SELECT Id FROM Idea LIMIT 1];
        IdeaComment comment = [SELECT CommentBody, Idea.CommunityId, Idea.Title FROM IdeaComment
                               WHERE IdeaId = :testIdea.Id LIMIT 1];

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addIdeaCommentModeratedNotification(comment);
        en.addIdeaCommentModeratedNotification(comment);
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 2, elogNum);
    }

    @isTest
    private static void testAddIdeaFlaggedNotification(){
        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];
        Idea testIdea = [SELECT Title, Body FROM Idea LIMIT 1];
        User currUser = [SELECT Username FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addIdeaFlaggedNotification(testIdea, currUser);
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 1, elogNum);
    }

    @isTest
    private static void testAddIdeaCommentFlaggedNotification(){
        Integer elogNumOriginal = [SELECT COUNT() FROM brideas_TestEmail__c];
        Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];
        IdeaComment testComment = [SELECT CommentBody, IdeaId, Idea.Title FROM IdeaComment WHERE IdeaId = :testIdea.Id LIMIT 1];
        User currUser = [SELECT Username FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();

        brideas_EmailNotification en = new brideas_EmailNotification();

        en.addIdeaCommentFlaggedNotification(testComment, currUser);
        en.sendEmails();

        Test.stopTest();

        Integer elogNum = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(elogNumOriginal + 1, elogNum);
    }
}