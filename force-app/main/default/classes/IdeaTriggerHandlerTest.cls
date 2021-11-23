@isTest
private class IdeaTriggerHandlerTest {
    @testSetup
    static void setup() {
        TestDataFactory.createStandardUser();
        TestDataFactory.createCommunityUser();

        String cId = brideas_Helper.getCommunityId('');
        List<Idea> ideas = new List<Idea>();

        for (Integer i = 1; i < 3; i++) {
            ideas.add(new Idea(Title='Test idea_' + i, Body='Test body', Status='New', Categories='test_' + i, CommunityId=cId));
        }

        insert ideas;
    }

    @isTest
    static void testCreateSubscriptionsOnInsert(){
        Idea testIdea;
        User testUser;

        Test.startTest();

        testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com' LIMIT 1];
        String cId = brideas_Helper.getCommunityId('');

        System.runAs(testUser) {
            testIdea = new Idea(Title = 'Test idea', Body = 'Body of test idea', Status = 'New',
                                        Categories = 'test', CommunityId = cId);

            insert testIdea;
        }

        Test.stopTest();

        Integer subscrNumber = [SELECT COUNT() FROM brideas_Subscription__c];
        List<brideas_Subscription__c> subscr = [SELECT Idea__c, User__c FROM brideas_Subscription__c LIMIT 3];

        System.assertEquals(3, subscrNumber, 'Invalid number of subscriptions created');
        System.assertEquals(testIdea.Id, subscr[2].Idea__c, 'Invalid Idea in Subscribtion');
        System.assertEquals(testUser.Id, subscr[2].User__c, 'Invalid User in subscription');
    }

    @isTest
    static void testModerateIdeasOnInsert(){
        String cId = brideas_Helper.getCommunityId('');
        Integer existingIdeasCount = [SELECT COUNT() FROM Idea WHERE CommunityId = :cId];

        Test.startTest();

        Idea testIdea1 = new Idea(Title = 'Test idea 1', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        Idea testIdea2 = new Idea(Title = 'Test idea 2', Body = 'Body of http://google.com idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        Idea testIdea3 = new Idea(Title = 'Test ForbiddenWord 3', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        insert new List<Idea>{testIdea1,testIdea2,testIdea3};

        Test.stopTest();

        List<brideas_Banned_Idea_Item__c> bannedIdeas = [SELECT Item_Id__c FROM brideas_Banned_Idea_Item__c];
        Integer totalIdeasCount = [SELECT COUNT() FROM Idea WHERE CommunityId = :cId];

        Set<String> ideaIds = new Set<String>();

        for (brideas_Banned_Idea_Item__c bi : bannedIdeas) {
            ideaIds.add(bi.Item_Id__c);
        }

        System.assertEquals(existingIdeasCount + 3, totalIdeasCount, 'Invalid inserted number of ideas');
        System.assertEquals(2, bannedIdeas.size(), 'Invalid total number of banned items');
        System.assertNotEquals(true, ideaIds.contains(String.valueOf(testIdea1.Id)), 'banned idea item should not be created if there are no forbidden words or urls');
        System.assertEquals(true, ideaIds.contains(String.valueOf(testIdea2.Id)), 'banned idea item should be created if there are urls');
        System.assertEquals(true, ideaIds.contains(String.valueOf(testIdea3.Id)), 'banned idea item should be created if there are forbidden words');
    }

    @isTest
    static void testDeleteBannedItems(){
        String cId = brideas_Helper.getCommunityId('');

        Idea testIdea = new Idea(Title = 'Test ForbiddenWord', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        insert testIdea;

        Id testIdeaId = testIdea.Id;

        List<brideas_Banned_Idea_Item__c> bannedIdeas = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c = :testIdeaId];
        System.assertEquals(1, bannedIdeas.size());

        Test.startTest();

        delete testIdea;

        Test.stopTest();

        List<brideas_Banned_Idea_Item__c> bannedIdeasAfterDelete = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c = :testIdeaId];

        System.assertEquals(0, bannedIdeasAfterDelete.size(), 'banned items should be removed when appropriate idea posts are removed');
    }

    @isTest
    static void testSendStatusChangeNotificationsToSubscribers(){
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com' LIMIT 1];
        Idea testIdea1 = [SELECT Status FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        Idea testIdea2 = [SELECT Status FROM Idea WHERE Title='Test idea_2' LIMIT 1];

        brideas_Subscription__c subscr = new brideas_Subscription__c(User__c = testUser.Id, Idea__c = testIdea1.Id);

        insert subscr;

        testIdea1.Status = 'Delivered';

        update testIdea1;

        Test.stopTest();

        String status = [SELECT Idea__r.Status FROM brideas_Subscription__c WHERE User__c = :testUser.Id LIMIT 1].Idea__r.Status;

        System.assertEquals('Delivered', status, 'result contains delivered status');
    }

    @isTest
    static void testSendStatusChangeNotificationsToAssignedUsers(){
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com' LIMIT 1];
        Idea testIdea1 = [SELECT Status FROM Idea WHERE Title='Test idea_1' LIMIT 1];

        testIdea1.Status = 'Delivered';

        update testIdea1;

        brideas_CategoryAssignee__c assign = new brideas_CategoryAssignee__c(User__c = testUser.Id, Categories__c = 'test_1');

        insert assign;

        testIdea1.Status = 'New';

        update testIdea1;

        Test.stopTest();

        String category = [SELECT Categories__c FROM brideas_CategoryAssignee__c
        WHERE User__c = :testUser.Id LIMIT 1].Categories__c;

        String status = [SELECT Status FROM Idea WHERE Categories = :category LIMIT 1].Status;

        System.assertEquals('New', status, 'result contains new status');
    }

    @isTest
    static void testSendStatusChangeNotifications(){
        Test.startTest();

        Integer emailsCountBeforeUpdate = [SELECT COUNT() FROM brideas_TestEmail__c];
        Idea testIdea = [SELECT Status FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        testIdea.Status = 'Delivered';
        update testIdea;

        Test.stopTest();

        Integer emailsCountAfterUpdate = [SELECT COUNT() FROM brideas_TestEmail__c];

        System.assertEquals(emailsCountBeforeUpdate + 1, emailsCountAfterUpdate, 'email was not send');
    }
}