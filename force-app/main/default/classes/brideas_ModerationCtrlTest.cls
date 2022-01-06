@IsTest
private class brideas_ModerationCtrlTest {

    @testSetup
    static void setup() {
        List<Idea> ideas = new List<Idea>();
        List<IdeaComment> ideaComments = new List<IdeaComment>();
        List<brideas_Banned_Idea_Item__c> bannedItems = new List<brideas_Banned_Idea_Item__c>();
        String cId = brideas_Helper.getCommunityId('');

        for (Integer i=0;i<6;i++) {
            ideas.add(new Idea(Title='Test idea_' + i, Body='Body of test idea', Status='New', Categories='test', CommunityId=cId));
        }

        insert ideas;

        for (Integer i=0;i<6;i++) {
            ideaComments.add(new IdeaComment(CommentBody='Idea comment', IdeaId=ideas[0].Id));
        }

        insert ideaComments;

        for(Integer i=0;i<ideas.size();i++) {
            if(Math.mod(i, 2) == 0) {
                bannedItems.add(new brideas_Banned_Idea_Item__c(Item_Id__c = ideas[i].Id, Type__c = 'Idea post'));
            }
        }

        for(Integer i=0;i<ideaComments.size();i++) {
            if(Math.mod(i, 3) == 0) {
                bannedItems.add(new brideas_Banned_Idea_Item__c(Item_Id__c = ideaComments[i].Id, Type__c = 'Idea comment'));
            }
        }

        insert bannedItems;
    }

    static testMethod void testRetrieveBannedIdeaItems() {

        Test.startTest();
        brideas_ModerationCtrl ctrl = new brideas_ModerationCtrl();

        ctrl.itemType = 'Idea comment';
        ctrl.retrieveBannedItems();
        Test.stopTest();

        System.assertEquals(3, ctrl.bannedIdeas.size(), 'should return a correct number of idea posts');
        System.assertEquals(2, ctrl.bannedIdeaComments.size(), 'should return a correct number of idea posts');
    }

    static testMethod void testUnbanItem() {
        String bannedItemId = [SELECT Item_Id__c FROM brideas_Banned_Idea_Item__c WHERE Type__c = 'Idea post' LIMIT 1].Item_Id__c;

        Test.startTest();

        brideas_ModerationCtrl ctrl = new brideas_ModerationCtrl();
        ctrl.itemId = bannedItemId;
        ctrl.unbanItem();

        Test.stopTest();

        List<brideas_Banned_Idea_Item__c> bannedItems = [SELECT Id FROM brideas_Banned_Idea_Item__c WHERE Item_Id__c = :bannedItemId LIMIT 1];

        System.assertEquals(0, bannedItems.size(), 'should delete banned items for specific idea post');
    }

    static testMethod void testDeleteItem() {
        String bannedItemId = [SELECT Item_Id__c FROM brideas_Banned_Idea_Item__c WHERE Type__c = 'Idea comment' LIMIT 1].Item_Id__c;

        Test.startTest();

        brideas_ModerationCtrl ctrl = new brideas_ModerationCtrl();
        ctrl.itemId = bannedItemId;
        ctrl.itemType = 'Idea comment';
        ctrl.retrieveBannedItems();
        ctrl.deleteItem();

        Test.stopTest();

        List<IdeaComment> ideas = [SELECT Id FROM IdeaComment WHERE Id = :bannedItemId LIMIT 1];

        System.assertEquals(0, ideas.size(), 'should delete idea post');
    }
}