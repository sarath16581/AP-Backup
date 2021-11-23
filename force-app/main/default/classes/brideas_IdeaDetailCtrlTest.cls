@isTest
private class brideas_IdeaDetailCtrlTest {
    @testSetup
    static void setup() {
        Test.startTest();
        TestDataFactory.createStandardUser();
        TestDataFactory.createCommunityUser();

        String cId = brideas_Helper.getCommunityId('');

        Idea idea1 = new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1', CommunityId=cId);

        insert idea1;

        User testUser = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com' LIMIT 1];

        System.runAs(testUser){
            Idea idea2 = new Idea(Title='Test idea_2', Body='Body of test idea_2', Status='New', Categories='test_2', CommunityId=cId);

            insert idea2;
        }

        Test.stopTest();

        Integer ideasCount = [SELECT COUNT() FROM Idea];

        System.assertEquals(2, ideasCount);
    }

    @isTest
    private static void testGetUserInfo(){
        Test.startTest();

        Map<String, String> userInfo = brideas_IdeaDetailCtrl.getUserInfo();

        Test.stopTest();

        System.assertEquals(false, userInfo.isEmpty() , 'result contain userInfo');
    }

    @isTest
    private static void testAddVote(){
        String ideaId = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        String message = brideas_IdeaDetailCtrl.addVote(ideaId);

        Test.stopTest();

        System.assertEquals('error', message , 'result contain error message for votes');
    }

    @isTest
    private static void testSetFlagOnIdea(){
        String ideaId = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        Boolean isSetFlag = brideas_IdeaDetailCtrl.setFlagOnIdea(ideaId);

        Test.stopTest();

        System.assertEquals(true, isSetFlag , 'result contain true value');
    }

    @isTest
    private static void testGetIdea(){
        String Id = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        brideas_IdeaWrapper wrapper = brideas_IdeaDetailCtrl.getIdea(Id);

        Test.stopTest();

        System.assertEquals(0, wrapper.NumComments , 'no comments');
        System.assertEquals('test_1', wrapper.item.Categories , 'result contains category');
        System.assertEquals(Id, wrapper.item.Id , 'result contains an idea');
    }

    @isTest
    private static void testGetMergedIdeas(){
        String parentIdeaId = [SELECT ParentIdeaId FROM Idea LIMIT 1].ParentIdeaId;

        Test.startTest();

        List<Idea> ideas = brideas_IdeaDetailCtrl.getMergedIdeas(parentIdeaId);

        Test.stopTest();

        System.assertEquals(2, ideas.size() , 'result contain two ideas');
    }

    @isTest
    private static void testGetStatus(){
        String Id = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        String status = brideas_IdeaDetailCtrl.getStatus(Id);

        Test.stopTest();

        System.assertEquals('New', status, 'result contains new status');
    }

    @isTest
    private static void testGetIdeaCommentsNumber(){
        String Id = [SELECT Id FROM Idea LIMIT 1].Id;
        List<IdeaComment> ideaComments = new List<IdeaComment>();

        for (Integer i=0;i<2;i++) {
            ideaComments.add(new IdeaComment(CommentBody='Idea comment' + i, IdeaId=Id));
        }

        insert ideaComments;

        Test.startTest();

        Integer commentsNumber = brideas_IdeaDetailCtrl.getIdeaCommentsNumber(Id);

        Test.stopTest();

        System.assertEquals(2, commentsNumber, ' two comments');
    }

    @isTest
    private static void testGetStatusColor(){
        Test.startTest();

        String statusColor = brideas_IdeaDetailCtrl.getStatusColor('Test');

        Test.stopTest();

        System.assertEquals('#FFAAAA', statusColor, 'result with status color');
    }
}