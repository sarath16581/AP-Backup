@isTest
private class brideas_EventHandlerTest {
    @isTest
    private static void testStatusUpdate(){
        String cId = brideas_Helper.getCommunityId('');
        Idea testIdea = new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1',
                CommunityId=cId);
        insert testIdea;

        Test.startTest();

        brideas_EventHandler.statusUpdate(testIdea);

        Test.stopTest();

        Idea updatedIdea = [SELECT Status FROM Idea WHERE Title='Test idea_1' LIMIT 1];

        System.assertEquals('Under Consideration', updatedIdea.Status, 'result with changed status');
    }

    @isTest
    private static void testStatusUpdateWithError(){
        String cId = brideas_Helper.getCommunityId('');
        Idea testIdea = new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1',
                CommunityId=cId);
        insert testIdea;

        Test.startTest();

        testIdea.Id = null;

        brideas_EventHandler.statusUpdate(testIdea);

        Test.stopTest();

        Idea updatedIdea = [SELECT Status FROM Idea WHERE Title='Test idea_1' LIMIT 1];

        System.assertEquals('New', updatedIdea.Status, 'result with old status');
    }
}