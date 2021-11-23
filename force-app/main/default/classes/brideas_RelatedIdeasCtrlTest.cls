@isTest
private class brideas_RelatedIdeasCtrlTest {
    @isTest
    private static void testGetRelatedIdeasToIdea(){
        String cId = brideas_Helper.getCommunityId('');
        List<Idea> ideas = new List<Idea>();
        Idea idea1 = new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1', CommunityId=cId);
        Idea idea2 = new Idea(Title='Test idea_2', Body='Body of test idea_2', Status='New', Categories='test_2', CommunityId=cId);
        ideas.add(idea1);
        ideas.add(idea2);

        insert ideas;

        Test.startTest();

        List<brideas_IdeaWrapper> wrappers = brideas_RelatedIdeasCtrl.getRelatedIdeasToIdea(idea1);

        Test.stopTest();

        System.assertEquals('Test idea', wrappers[0].item.Title , 'result contains one idea');
    }
}